import { ext } from '../api';
import { type ExtensionState, type PairingState, type Request, changedMessage, describePairing } from '../messages';
import { spaced } from '../pairing_code';

const $ = <T extends HTMLElement = HTMLElement>(id: string): T => {
  const element = document.getElementById(id);
  if (!element) throw new Error(`Missing #${id}`);
  return element as T;
};

const ask = <T>(request: Request): Promise<T> => ext.runtime.sendMessage(request) as Promise<T>;

const toggles = ['shareTab', 'notify', 'restorePosition'] as const;
type Toggle = (typeof toggles)[number];

/** What each toggle needs from the browser, asked for when it's turned on. */
const needs: Record<Toggle, chrome.permissions.Permissions | null> = {
  shareTab: { permissions: ['tabs'] },
  notify: null,
  restorePosition: { origins: ['<all_urls>'] },
};

function renderStatus(state: ExtensionState): void {
  const status = $('status');
  const help = $('status-help');
  const where = state.computerName ? ` on ${state.computerName}` : '';
  switch (state.connection) {
    case 'connecting':
      status.textContent = 'Looking for Ferret…';
      help.textContent = '';
      break;
    case 'not_running':
      status.textContent = "Ferret isn't running on this computer.";
      help.textContent =
        state.error === 'rate_limited'
          ? 'Too many tries. Wait a minute, then try again.'
          : 'Open the Ferret app, and check that “Browser extension” is on in its Handoff settings.';
      break;
    case 'not_paired':
      status.textContent = `Ferret is running${where}, but this browser isn't paired yet.`;
      help.textContent = 'Click Pair, then allow this browser in Ferret.';
      break;
    case 'paired':
      status.textContent = `Paired with Ferret${where}.`;
      help.textContent = '';
      break;
  }

  $('pair').hidden = state.connection !== 'not_paired' || state.pairing?.status === 'waiting';
  $('retry').hidden = state.connection !== 'not_running';
  $('unpair').hidden = state.connection !== 'paired';
  $('passive-off').hidden = state.passive || !state.settings.shareTab;
  renderPairing(state.pairing, state.connection === 'paired');

  for (const toggle of toggles) {
    $<HTMLInputElement>(toggle).checked = state.settings[toggle];
  }
}

function renderPairing(pairing: PairingState | null, paired: boolean): void {
  const show = pairing !== null && (pairing.status !== 'done' || paired);
  $('pairing').hidden = !show;
  if (!pairing || !show) return;
  $('code').textContent = spaced(pairing.code);
  $('code').hidden = pairing.status !== 'waiting';
  const line = $('pairing-status');
  line.textContent = describePairing(pairing.status);
  line.className = pairing.status === 'done' ? 'success' : pairing.status === 'waiting' ? 'muted' : 'danger';
}

async function refresh(connect: boolean): Promise<void> {
  const state = await ask<ExtensionState | null>({ kind: 'state', connect });
  if (state) renderStatus(state);
}

async function onToggle(toggle: Toggle, input: HTMLInputElement): Promise<void> {
  let enabled = input.checked;
  const permissions = needs[toggle];
  if (permissions && enabled) {
    // Must run straight from the click, so the browser shows its prompt.
    enabled = await ext.permissions.request(permissions).catch(() => false);
    input.checked = enabled;
  }

  if (permissions && !enabled) {
    await ext.permissions.remove(permissions).catch(() => false);
  }

  await ask({ kind: 'set', changes: { [toggle]: enabled } });
}

for (const toggle of toggles) {
  const input = $<HTMLInputElement>(toggle);
  input.addEventListener('change', () => void onToggle(toggle, input));
}

$('pair').addEventListener('click', () => void ask<PairingState>({ kind: 'pair' }).then(() => refresh(false)));
$('retry').addEventListener('click', () => void refresh(true));
$('unpair').addEventListener('click', () => void ask({ kind: 'unpair' }).then(() => refresh(true)));
ext.runtime.onMessage.addListener((message: unknown) => {
  if (typeof message === 'object' && message !== null && (message as { kind?: string }).kind === changedMessage.kind) {
    void refresh(false);
  }
});

void refresh(true);
