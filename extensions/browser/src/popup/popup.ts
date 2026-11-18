import { ext } from '../api';
import { type ExtensionState, type Request, type SendResult, changedMessage, describeOutcome } from '../messages';
import { hostOf } from '../suggestions';

const $ = <T extends HTMLElement = HTMLElement>(id: string): T => {
  const element = document.getElementById(id);
  if (!element) throw new Error(`Missing #${id}`);
  return element as T;
};

const ask = <T>(request: Request): Promise<T> => ext.runtime.sendMessage(request) as Promise<T>;

function row(title: string, sub: string, onClick: (() => void) | null): HTMLButtonElement {
  const button = document.createElement('button');
  button.className = 'row';
  button.disabled = onClick === null;
  const text = document.createElement('span');
  text.className = 'text';
  const titleLine = document.createElement('div');
  titleLine.className = 'title';
  titleLine.textContent = title;
  const subLine = document.createElement('div');
  subLine.className = 'sub';
  subLine.textContent = sub;
  text.append(titleLine, subLine);
  button.append(text);
  if (onClick) button.addEventListener('click', onClick);
  return button;
}

async function send(deviceId: string): Promise<void> {
  const result = $('result');
  result.className = 'muted';
  result.textContent = 'Sending…';
  const answer = await ask<SendResult | null>({ kind: 'send', deviceId });
  if (answer && 'outcome' in answer) {
    result.textContent = describeOutcome(answer.outcome, answer.device);
    result.className = answer.outcome === 'opened' || answer.outcome === 'suggested' ? 'success' : 'danger';
    return;
  }

  result.className = 'danger';
  result.textContent =
    answer?.error === 'not_sendable'
      ? 'Only web pages can be sent. This one is a browser page.'
      : answer?.error === 'offline'
        ? "Lost Ferret. Make sure it's running, then try again."
        : "Couldn't send it. Try again.";
}

function render(state: ExtensionState): void {
  $('connecting').hidden = state.connection !== 'connecting';
  $('not-running').hidden = state.connection !== 'not_running';
  $('limited').hidden = state.error !== 'rate_limited';
  $('not-paired').hidden = state.connection !== 'not_paired';
  $('paired').hidden = state.connection !== 'paired';
  if (state.connection !== 'paired') return;

  const devices = $('devices');
  const sorted = [...state.devices].sort((a, b) => Number(b.connected) - Number(a.connected));
  devices.replaceChildren(
    ...sorted.map((device) =>
      row(
        device.name,
        device.connected ? (device.id === state.settings.lastDeviceId ? 'Connected · used last' : 'Connected') : 'Not connected',
        device.connected ? () => void send(device.id) : null,
      ),
    ),
  );
  $('no-devices').hidden = state.devices.length > 0;

  $('suggestions-section').hidden = state.suggestions.length === 0;
  $('suggestions').replaceChildren(
    ...state.suggestions.map((item) =>
      row(item.title || hostOf(item.url), `From ${item.from || 'another device'}`, () => {
        void ask<boolean>({ kind: 'open_suggestion', id: item.id }).then((opened) => {
          if (opened) window.close();
        });
      }),
    ),
  );
}

async function refresh(connect: boolean): Promise<void> {
  const state = await ask<ExtensionState | null>({ kind: 'state', connect });
  if (state) render(state);
}

$('retry').addEventListener('click', () => void refresh(true));
$('pair').addEventListener('click', () => void ext.runtime.openOptionsPage());
$('settings').addEventListener('click', () => void ext.runtime.openOptionsPage());
ext.runtime.onMessage.addListener((message: unknown) => {
  if (typeof message === 'object' && message !== null && (message as { kind?: string }).kind === changedMessage.kind) {
    void refresh(false);
  }
});

$('connecting').hidden = false;
void refresh(true);
