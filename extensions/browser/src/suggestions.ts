import type { Suggestion } from './protocol';

/** The badge on the toolbar button: how many pages wait, up to "9+". */
export function badgeText(items: readonly Suggestion[]): string {
  if (items.length === 0) return '';
  if (items.length > 9) return '9+';
  return String(items.length);
}

/**
 * The suggestions not seen before, so reconnecting never replays a
 * notification for something already shown.
 */
export function freshSuggestions(items: readonly Suggestion[], seen: ReadonlySet<string>): Suggestion[] {
  return items.filter((item) => !seen.has(item.id));
}

/** One notification, never a pile: a single page by name, else a count. */
export function notificationFor(fresh: readonly Suggestion[]): { title: string; message: string } | null {
  const [first] = fresh;
  if (!first) return null;
  if (fresh.length === 1) {
    return {
      title: `Continue “${first.title || hostOf(first.url)}”`,
      message: first.from ? `From ${first.from}` : 'From another device',
    };
  }

  return {
    title: `${fresh.length} pages to continue`,
    message: 'Open Ferret in the toolbar to pick one.',
  };
}

export function hostOf(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, '');
  } catch {
    return url;
  }
}
