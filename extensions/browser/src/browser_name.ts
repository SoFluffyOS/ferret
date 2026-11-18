interface Brand {
  brand: string;
}

export interface BrowserHints {
  userAgent: string;
  brands?: readonly Brand[];
  isBrave?: boolean;
}

/** The browser's name as people know it, such as "Edge" or "Firefox". */
export function browserName(hints: BrowserHints): string {
  const brands = (hints.brands ?? []).map((entry) => entry.brand);
  if (hints.isBrave) return 'Brave';
  if (brands.includes('Microsoft Edge') || /\bEdg\//.test(hints.userAgent)) return 'Edge';
  if (brands.includes('Opera') || /\bOPR\//.test(hints.userAgent)) return 'Opera';
  if (/\bVivaldi\//.test(hints.userAgent)) return 'Vivaldi';
  if (/\bFirefox\//.test(hints.userAgent)) return 'Firefox';
  if (brands.includes('Google Chrome') || /\bChrome\//.test(hints.userAgent)) return 'Chrome';
  if (brands.includes('Chromium')) return 'Chromium';
  return 'Browser';
}
