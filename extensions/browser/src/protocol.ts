// The messages between the extension and the Ferret app on this computer.
// Documented in PROTOCOL.md; keep both in step.

export const protocolVersion = 1;
export const firstPort = 47650;
export const portCount = 5;
export const ports: readonly number[] = Array.from(
  { length: portCount },
  (_, offset) => firstPort + offset,
);

export type SendOutcome = 'opened' | 'suggested' | 'failed' | 'unreachable';

export interface Device {
  id: string;
  name: string;
  platform: string;
  formFactor: string;
  connected: boolean;
}

export interface Suggestion {
  id: string;
  title: string;
  url: string;
  from: string;
  fromId: string;
  explicit: boolean;
  receivedAtMs: number;
  expiresAtMs: number;
  videoTime?: number;
  scrollY?: number;
}

/** A tab as the extension describes it to Ferret. */
export interface TabInfo {
  url: string;
  title: string;
  videoTime?: number;
  scrollY?: number;
}

export type ServerMessage =
  | {
      type: 'welcome';
      re?: string;
      v: number;
      app: 'ferret';
      device: string;
      paired: boolean;
      passive: boolean;
    }
  | { type: 'paired'; re?: string; token: string; client: string; device: string }
  | { type: 'pair_denied'; re?: string; reason: 'denied' | 'timeout' | 'busy' | string }
  | { type: 'devices'; re?: string; devices: Device[] }
  | { type: 'suggestions'; re?: string; items: Suggestion[] }
  | { type: 'sent'; re?: string; outcome: SendOutcome }
  | { type: 'shared'; re?: string; delivered: number }
  | { type: 'open'; id: string; url: string; title: string; videoTime?: number; scrollY?: number }
  | { type: 'unpaired'; re?: string }
  | { type: 'revoked' }
  | { type: 'pong'; re?: string }
  | { type: 'error'; re?: string; code: string; retryAfterMs?: number };

export type ClientMessage =
  | { type: 'hello'; id?: string; v: number; browser: string; token?: string }
  | { type: 'pair'; id?: string; code: string; browser: string }
  | { type: 'ping'; id?: string }
  | { type: 'devices'; id?: string; token: string }
  | { type: 'suggestions'; id?: string; token: string }
  | { type: 'send'; id?: string; token: string; deviceId: string; tab: TabInfo }
  | { type: 'share'; id?: string; token: string; tab: TabInfo }
  | { type: 'focus'; token: string; focused: boolean }
  | { type: 'dismiss'; token: string; activityId: string }
  | { type: 'opened'; token: string; re: string; ok: boolean }
  | { type: 'unpair'; id?: string; token: string };

type Json = Record<string, unknown>;

const isObject = (value: unknown): value is Json =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const str = (value: unknown): value is string => typeof value === 'string';

const optionalNumber = (value: unknown): number | undefined =>
  typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value : undefined;

const webUrl = (value: unknown): value is string => {
  if (!str(value)) return false;
  try {
    const { protocol } = new URL(value);
    return protocol === 'http:' || protocol === 'https:';
  } catch {
    return false;
  }
};

const reOf = (json: Json): { re?: string } => (str(json.re) ? { re: json.re } : {});

function parseDevice(value: unknown): Device | null {
  if (!isObject(value) || !str(value.id) || !str(value.name)) return null;
  return {
    id: value.id,
    name: value.name,
    platform: str(value.platform) ? value.platform : 'unknown',
    formFactor: str(value.formFactor) ? value.formFactor : 'unknown',
    connected: value.connected === true,
  };
}

function parseSuggestion(value: unknown): Suggestion | null {
  if (!isObject(value) || !str(value.id) || !webUrl(value.url)) return null;
  return {
    id: value.id,
    url: value.url,
    title: str(value.title) ? value.title : '',
    from: str(value.from) ? value.from : '',
    fromId: str(value.fromId) ? value.fromId : '',
    explicit: value.explicit === true,
    receivedAtMs: optionalNumber(value.receivedAtMs) ?? 0,
    expiresAtMs: optionalNumber(value.expiresAtMs) ?? 0,
    videoTime: optionalNumber(value.videoTime),
    scrollY: optionalNumber(value.scrollY),
  };
}

const listOf = <T>(value: unknown, parse: (item: unknown) => T | null): T[] =>
  Array.isArray(value) ? value.map(parse).filter((item): item is T => item !== null) : [];

/**
 * Reads one message from Ferret. Anything malformed, or a link that isn't
 * http(s), is dropped rather than trusted.
 */
export function parseServerMessage(text: string): ServerMessage | null {
  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    return null;
  }

  if (!isObject(json) || !str(json.type)) return null;

  switch (json.type) {
    case 'welcome':
      if (json.app !== 'ferret' || typeof json.v !== 'number') return null;
      return {
        type: 'welcome',
        ...reOf(json),
        v: json.v,
        app: 'ferret',
        device: str(json.device) ? json.device : '',
        paired: json.paired === true,
        passive: json.passive !== false,
      };
    case 'paired':
      if (!str(json.token) || json.token.length < 32 || !str(json.client)) return null;
      return {
        type: 'paired',
        ...reOf(json),
        token: json.token,
        client: json.client,
        device: str(json.device) ? json.device : '',
      };
    case 'pair_denied':
      return { type: 'pair_denied', ...reOf(json), reason: str(json.reason) ? json.reason : 'denied' };
    case 'devices':
      return { type: 'devices', ...reOf(json), devices: listOf(json.devices, parseDevice) };
    case 'suggestions':
      return { type: 'suggestions', ...reOf(json), items: listOf(json.items, parseSuggestion) };
    case 'sent': {
      const outcomes = ['opened', 'suggested', 'failed', 'unreachable'];
      const outcome = str(json.outcome) && outcomes.includes(json.outcome) ? json.outcome : 'failed';
      return { type: 'sent', ...reOf(json), outcome: outcome as SendOutcome };
    }
    case 'shared':
      return { type: 'shared', ...reOf(json), delivered: optionalNumber(json.delivered) ?? 0 };
    case 'open':
      if (!str(json.id) || !webUrl(json.url)) return null;
      return {
        type: 'open',
        id: json.id,
        url: json.url,
        title: str(json.title) ? json.title : '',
        videoTime: optionalNumber(json.videoTime),
        scrollY: optionalNumber(json.scrollY),
      };
    case 'unpaired':
      return { type: 'unpaired', ...reOf(json) };
    case 'revoked':
      return { type: 'revoked' };
    case 'pong':
      return { type: 'pong', ...reOf(json) };
    case 'error':
      return {
        type: 'error',
        ...reOf(json),
        code: str(json.code) ? json.code : 'unknown',
        retryAfterMs: optionalNumber(json.retryAfterMs),
      };
    default:
      return null;
  }
}

/** Whether a tab's link can go to Ferret at all. */
export const isSendableUrl = (url: string | undefined): url is string => webUrl(url);
