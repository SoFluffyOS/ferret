import type { Device, SendOutcome, Suggestion } from './protocol';
import type { Settings } from './settings';

/** Where the extension stands with Ferret, as the popup and options show it. */
export type ConnectionState = 'connecting' | 'not_running' | 'not_paired' | 'paired';

export interface PairingState {
  code: string;
  status: 'waiting' | 'done' | 'denied' | 'timeout' | 'busy' | 'failed' | 'rate_limited';
}

export interface ExtensionState {
  connection: ConnectionState;
  computerName: string;
  /** Ferret's "Suggest what I'm doing" setting. */
  passive: boolean;
  devices: Device[];
  suggestions: Suggestion[];
  settings: Omit<Settings, 'token'>;
  pairing: PairingState | null;
  /** Why connecting failed, such as rate_limited. */
  error: string | null;
}

/** What the popup and options page ask the background for. */
export type Request =
  | { kind: 'state'; connect?: boolean }
  | { kind: 'send'; deviceId: string }
  | { kind: 'pair' }
  | { kind: 'unpair' }
  | { kind: 'open_suggestion'; id: string }
  | { kind: 'set'; changes: Partial<Pick<Settings, 'shareTab' | 'notify' | 'restorePosition'>> };

export type SendResult = { outcome: SendOutcome; device: string } | { error: 'not_sendable' | 'offline' | 'failed' };

/** Sent by the background whenever the state changed. */
export const changedMessage = { kind: 'changed' } as const;

/** What a send outcome means, in the same words Ferret uses. */
export function describeOutcome(outcome: SendOutcome, device: string): string {
  switch (outcome) {
    case 'opened':
      return `Opened on ${device}`;
    case 'suggested':
      return `Waiting on ${device}: tap the notification there to open it`;
    case 'failed':
      return `${device} couldn't open it.`;
    case 'unreachable':
      return `Couldn't reach ${device}. Check that it's on and on the same network.`;
  }
}

export function describePairing(status: PairingState['status']): string {
  switch (status) {
    case 'waiting':
      return 'Check that Ferret shows the same code, then click Allow there.';
    case 'done':
      return 'Paired. You can send tabs now.';
    case 'denied':
      return 'Ferret said no. Try again if that was a mistake.';
    case 'timeout':
      return 'Nobody answered in Ferret. Try again and click Allow there.';
    case 'busy':
      return 'Ferret is already asking about another browser. Answer that first.';
    case 'rate_limited':
      return 'Too many tries. Wait a minute, then try again.';
    case 'failed':
      return "Couldn't reach Ferret. Make sure it's running, then try again.";
  }
}
