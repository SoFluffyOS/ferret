import { ext } from './api';
import { BridgeClient, BridgeError, type SocketLike } from './bridge_client';
import { browserName } from './browser_name';
import { linkCarriesTime, withVideoTime } from './media_time';
import {
  type ConnectionState,
  type ExtensionState,
  type PairingState,
  type Request,
  type SendResult,
  changedMessage,
  describeOutcome,
} from './messages';
import { newPairingCode } from './pairing_code';
import { type Device, type Suggestion, type TabInfo, isSendableUrl } from './protocol';
import { readPosition, restorePosition } from './read_position';
import { loadSettings, saveSettings } from './settings';
import { badgeText, freshSuggestions, notificationFor } from './suggestions';

const reconnectAlarm = 'ferret-reconnect';
const menuLink = 'ferret-link';
const menuPage = 'ferret-page';
const menuPair = 'ferret-pair';
const sentNotice = 'ferret-sent';
const suggestionNotice = 'ferret-suggestion:';

let devices: Device[] = [];
let suggestions: Suggestion[] = [];
let pairing: PairingState | null = null;

const client = new BridgeClient({
  socket: (url) => new WebSocket(url) as unknown as SocketLike,
  browser: browserName({
    userAgent: navigator.userAgent,
    brands: (navigator as Navigator & { userAgentData?: { brands: { brand: string }[] } }).userAgentData?.brands,
    isBrave: 'brave' in navigator,
  }),
  events: {
    status: () => {
      void rebuildMenus();
      changed();
    },
    devices: (list) => {
      devices = list;
      void rebuildMenus();
      changed();
    },
    suggestions: (items) => void onSuggestions(items),
    open: (message) => void openHere(message.id, message.url, message.videoTime, message.scrollY),
    revoked: () => void forget(),
  },
});

function changed(): void {
  ext.runtime.sendMessage(changedMessage).catch(() => undefined);
}

function connectionState(): ConnectionState {
  switch (client.status) {
    case 'paired':
      return 'paired';
    case 'unpaired':
      return 'not_paired';
    case 'connecting':
      return 'connecting';
    case 'offline':
      return 'not_running';
  }
}

/** Connects when there is a reason to: paired, or someone is looking. */
async function ensureConnected(evenUnpaired: boolean): Promise<boolean> {
  const settings = await loadSettings();
  if (!settings.token && !evenUnpaired) return false;

  if (settings.port !== null && client.port === null) client.port = settings.port;
  const sentToken = settings.token;
  const reached = await client.connect(sentToken);
  if (!reached) return false;

  if (client.port !== settings.port) await saveSettings({ port: client.port });
  if (sentToken && client.status === 'unpaired') {
    // Ferret no longer knows this browser, such as after "Remove" there.
    await forget();
  }

  if (client.isPaired) await reportFocus();
  return true;
}

async function forget(): Promise<void> {
  await saveSettings({ token: null });
  devices = [];
  suggestions = [];
  await ext.action.setBadgeText({ text: '' });
  await rebuildMenus();
  changed();
}

async function state(connect: boolean): Promise<ExtensionState> {
  if (connect && client.status !== 'paired') await ensureConnected(true);
  const { token: _token, ...settings } = await loadSettings();
  return {
    connection: connectionState(),
    computerName: client.deviceName,
    passive: client.passive,
    devices,
    suggestions,
    settings,
    pairing,
    error: client.lastError,
  };
}

async function describeTab(tab: chrome.tabs.Tab | undefined, linkUrl?: string): Promise<TabInfo | null> {
  if (linkUrl !== undefined) {
    return isSendableUrl(linkUrl) ? { url: linkUrl, title: '' } : null;
  }

  if (!tab || !isSendableUrl(tab.url)) return null;
  let position: { videoTime?: number; scrollY?: number } = {};
  if (tab.id !== undefined) {
    try {
      const [frame] = await ext.scripting.executeScript({ target: { tabId: tab.id }, func: readPosition });
      position = (frame?.result as typeof position | undefined) ?? {};
    } catch {
      // Pages like the Web Store don't allow scripts; send the link alone.
    }
  }

  return {
    url: withVideoTime(tab.url, position.videoTime),
    title: tab.title ?? '',
    ...position,
  };
}

async function activeTab(): Promise<chrome.tabs.Tab | undefined> {
  const [tab] = await ext.tabs.query({ active: true, currentWindow: true });
  return tab;
}

async function sendTo(deviceId: string, tab: TabInfo | null): Promise<SendResult> {
  if (!tab) return { error: 'not_sendable' };
  if (!(await ensureConnected(false)) || !client.isPaired) return { error: 'offline' };

  const device = devices.find((candidate) => candidate.id === deviceId)?.name ?? 'your device';
  try {
    const outcome = await client.send(deviceId, tab);
    await saveSettings({ lastDeviceId: deviceId });
    return { outcome, device };
  } catch (error) {
    return { error: error instanceof BridgeError && error.code === 'offline' ? 'offline' : 'failed' };
  }
}

/** A quiet note for sends without the popup open: shortcut and menu. */
async function confirm(result: SendResult): Promise<void> {
  const message =
    'outcome' in result
      ? describeOutcome(result.outcome, result.device)
      : result.error === 'not_sendable'
        ? 'Only web pages can be sent.'
        : result.error === 'offline'
          ? "Ferret isn't running on this computer, or this browser isn't paired yet."
          : "Couldn't send it. Try again.";
  await ext.notifications.create(sentNotice, {
    type: 'basic',
    iconUrl: ext.runtime.getURL('icons/icon-128.png'),
    title: 'Ferret',
    message,
    silent: true,
  });
}

/** The device the shortcut sends to: the last one used, or the only one. */
async function shortcutTarget(): Promise<string | null> {
  const { lastDeviceId } = await loadSettings();
  const connected = devices.filter((device) => device.connected);
  if (lastDeviceId && connected.some((device) => device.id === lastDeviceId)) return lastDeviceId;
  if (connected.length === 1) return connected[0]?.id ?? null;
  return null;
}

async function openHere(openId: string | null, url: string, videoTime?: number, scrollY?: number): Promise<boolean> {
  try {
    const tab = await ext.tabs.create({ url: withVideoTime(url, videoTime), active: true });
    if (tab.windowId !== undefined) await ext.windows.update(tab.windowId, { focused: true });
    if (openId) client.answerOpen(openId, true);
    void restoreIn(tab, url, videoTime, scrollY);
    return true;
  } catch {
    if (openId) client.answerOpen(openId, false);
    return false;
  }
}

/** Seeks and scrolls once the page loaded, when the user allowed it. */
async function restoreIn(tab: chrome.tabs.Tab, url: string, videoTime?: number, scrollY?: number): Promise<void> {
  const seek = videoTime !== undefined && !linkCarriesTime(url) ? videoTime : null;
  const scroll = scrollY ?? null;
  if (tab.id === undefined || (seek === null && scroll === null)) return;

  const { restorePosition: allowed } = await loadSettings();
  if (!allowed || !(await ext.permissions.contains({ origins: ['<all_urls>'] }))) return;

  const tabId = tab.id;
  await new Promise<void>((resolve) => {
    const timer = setTimeout(done, 30_000);
    function done(): void {
      clearTimeout(timer);
      ext.tabs.onUpdated.removeListener(listener);
      resolve();
    }
    function listener(id: number, info: chrome.tabs.OnUpdatedInfo): void {
      if (id === tabId && info.status === 'complete') done();
    }
    ext.tabs.onUpdated.addListener(listener);
  });

  try {
    await ext.scripting.executeScript({ target: { tabId }, func: restorePosition, args: [seek, scroll] });
  } catch {
    // The page didn't allow it; it's open at the top, which is fine.
  }
}

async function openSuggestion(id: string): Promise<boolean> {
  const suggestion = suggestions.find((item) => item.id === id);
  if (!suggestion) return false;
  const opened = await openHere(null, suggestion.url, suggestion.videoTime, suggestion.scrollY);
  if (opened) client.dismiss(id);
  return opened;
}

async function onSuggestions(items: Suggestion[]): Promise<void> {
  suggestions = items;
  await ext.action.setBadgeText({ text: badgeText(items) });
  changed();

  const seenKey = 'seenSuggestions';
  const session = ext.storage.session;
  const stored = (await session.get(seenKey))[seenKey];
  const seen = new Set<string>(Array.isArray(stored) ? (stored as string[]) : []);
  const fresh = freshSuggestions(items, seen);
  if (fresh.length === 0) return;

  await session.set({ [seenKey]: [...seen, ...fresh.map((item) => item.id)].slice(-200) });
  const { notify } = await loadSettings();
  const note = notificationFor(fresh);
  if (!notify || !note) return;

  const id = fresh.length === 1 ? `${suggestionNotice}${fresh[0]?.id}` : `${suggestionNotice}many`;
  await ext.notifications.create(id, {
    type: 'basic',
    iconUrl: ext.runtime.getURL('icons/icon-128.png'),
    title: note.title,
    message: note.message,
  });
}

async function reportFocus(windowId?: number): Promise<void> {
  const focused =
    windowId !== undefined
      ? windowId !== ext.windows.WINDOW_ID_NONE
      : await ext.windows.getLastFocused().then((window) => window.focused === true, () => false);
  client.focus(focused);
}

/** Leaving the browser offers its tab to your other devices, when allowed. */
async function shareLeftTab(): Promise<void> {
  const { shareTab } = await loadSettings();
  if (!shareTab || !client.isPaired || !(await ext.permissions.contains({ permissions: ['tabs'] }))) return;

  const [tab] = await ext.tabs.query({ active: true, lastFocusedWindow: true });
  if (!tab || tab.incognito || !isSendableUrl(tab.url)) return;
  try {
    await client.share({ url: tab.url, title: tab.title ?? '' });
  } catch {
    // Ferret went away meanwhile; the next focus change tries again.
  }
}

let menus: Promise<void> = Promise.resolve();

/** Rebuilds one at a time, so two quick changes never clash on ids. */
function rebuildMenus(): Promise<void> {
  menus = menus.then(buildMenus, buildMenus);
  return menus;
}

async function buildMenus(): Promise<void> {
  await ext.contextMenus.removeAll();
  if (!client.isPaired) {
    ext.contextMenus.create({ id: menuPair, title: 'Pair with Ferret…', contexts: ['link', 'page'] });
    return;
  }

  ext.contextMenus.create({ id: menuLink, title: 'Send link to', contexts: ['link'] });
  ext.contextMenus.create({ id: menuPage, title: 'Send page to', contexts: ['page'] });
  const connected = devices.filter((device) => device.connected);
  for (const parentId of [menuLink, menuPage]) {
    if (connected.length === 0) {
      ext.contextMenus.create({
        id: `${parentId}:none`,
        parentId,
        title: 'No device connected',
        enabled: false,
        contexts: parentId === menuLink ? ['link'] : ['page'],
      });
      continue;
    }

    for (const device of connected) {
      ext.contextMenus.create({
        id: `${parentId}:${device.id}`,
        parentId,
        title: device.name,
        contexts: parentId === menuLink ? ['link'] : ['page'],
      });
    }
  }
}

async function startPairing(): Promise<PairingState> {
  const code = newPairingCode();
  pairing = { code, status: 'waiting' };
  changed();

  void (async () => {
    let status: PairingState['status'] = 'failed';
    try {
      if (!(await ensureConnected(true))) {
        status = client.lastError === 'rate_limited' ? 'rate_limited' : 'failed';
      } else {
        const token = await client.pair(code);
        await saveSettings({ token, port: client.port });
        status = 'done';
        await rebuildMenus();
        await reportFocus();
      }
    } catch (error) {
      const known = ['denied', 'timeout', 'busy', 'rate_limited'] as const;
      const code = error instanceof BridgeError ? error.code : '';
      status = known.find((reason) => reason === code) ?? 'failed';
    }

    if (pairing?.code === code) pairing = { code, status };
    changed();
  })();

  return pairing;
}

async function handle(request: Request): Promise<unknown> {
  switch (request.kind) {
    case 'state':
      return state(request.connect === true);
    case 'send':
      return sendTo(request.deviceId, await describeTab(await activeTab()));
    case 'pair':
      return startPairing();
    case 'unpair':
      try {
        await client.unpair();
      } catch {
        // Ferret isn't there; forgetting the token here is what matters.
      }
      pairing = null;
      await forget();
      return state(false);
    case 'open_suggestion':
      return openSuggestion(request.id);
    case 'set':
      await saveSettings(request.changes);
      changed();
      return state(false);
  }
}

ext.runtime.onMessage.addListener((message: unknown, sender, respond) => {
  if (sender.id !== ext.runtime.id || typeof message !== 'object' || message === null || !('kind' in message)) {
    return false;
  }
  if ((message as { kind: string }).kind === changedMessage.kind) return false;

  handle(message as Request).then(respond, () => respond(null));
  return true;
});

ext.contextMenus.onClicked.addListener((info, tab) => {
  const id = String(info.menuItemId);
  if (id === menuPair) {
    void ext.runtime.openOptionsPage();
    return;
  }

  const [parent, deviceId] = id.split(':');
  if (!deviceId || deviceId === 'none') return;
  void (async () => {
    const described = parent === menuLink ? await describeTab(tab, info.linkUrl ?? '') : await describeTab(tab);
    await confirm(await sendTo(deviceId, described));
  })();
});

ext.commands.onCommand.addListener((command, tab) => {
  if (command !== 'send-tab') return;
  void (async () => {
    await ensureConnected(false);
    const deviceId = await shortcutTarget();
    if (!deviceId) {
      await ext.notifications.create(sentNotice, {
        type: 'basic',
        iconUrl: ext.runtime.getURL('icons/icon-128.png'),
        title: 'Ferret',
        message: client.isPaired
          ? 'Pick a device once in the Ferret button, then the shortcut sends there.'
          : "This browser isn't paired with Ferret yet. Open the extension's settings to pair.",
      });
      return;
    }

    await confirm(await sendTo(deviceId, await describeTab(tab ?? (await activeTab()))));
  })();
});

ext.notifications.onClicked.addListener((id) => {
  void ext.notifications.clear(id);
  if (!id.startsWith(suggestionNotice)) return;
  const suggestionId = id.slice(suggestionNotice.length);
  if (suggestionId !== 'many') void openSuggestion(suggestionId);
});

ext.windows.onFocusChanged.addListener((windowId) => {
  void reportFocus(windowId);
  if (windowId === ext.windows.WINDOW_ID_NONE) void shareLeftTab();
});

ext.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === reconnectAlarm && client.status === 'offline') void ensureConnected(false);
});

ext.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') void ext.runtime.openOptionsPage();
});

void ext.action.setBadgeBackgroundColor({ color: '#d9822b' });
void ext.alarms.create(reconnectAlarm, { periodInMinutes: 1 });
void rebuildMenus();
void ensureConnected(false);
