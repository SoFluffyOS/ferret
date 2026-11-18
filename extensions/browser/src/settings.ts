import { ext } from './api';

/** What the extension keeps in its own local storage. Never synced. */
export interface Settings {
  /** The secret Ferret gave this browser when the user allowed it. */
  token: string | null;
  /** The port Ferret answered on last. */
  port: number | null;
  /** The device "Send this tab" and the shortcut used last. */
  lastDeviceId: string | null;
  /** Offer the tab you're on to your other devices when you leave the browser. */
  shareTab: boolean;
  /** Show a notification when another device offers a page. */
  notify: boolean;
  /** Put pages back at the same video time and scroll position. */
  restorePosition: boolean;
}

export const defaults: Settings = {
  token: null,
  port: null,
  lastDeviceId: null,
  shareTab: false,
  notify: true,
  restorePosition: false,
};

export async function loadSettings(): Promise<Settings> {
  const stored = await ext.storage.local.get(Object.keys(defaults));
  return { ...defaults, ...(stored as Partial<Settings>) };
}

export async function saveSettings(changes: Partial<Settings>): Promise<void> {
  await ext.storage.local.set(changes);
}
