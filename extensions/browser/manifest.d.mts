export const firefoxId: string;
export function manifestFor(
  target: 'chromium' | 'firefox',
  version: string,
): Record<string, unknown>;
