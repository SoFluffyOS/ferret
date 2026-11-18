import { describe, expect, it } from 'vitest';

import { firefoxId, manifestFor } from '../manifest.mjs';
import { browserName } from '../src/browser_name';
import { linkCarriesTime, withVideoTime } from '../src/media_time';
import { describeOutcome, describePairing } from '../src/messages';
import { newPairingCode, spaced } from '../src/pairing_code';
import type { Suggestion } from '../src/protocol';
import { badgeText, freshSuggestions, notificationFor } from '../src/suggestions';

const suggestion = (id: string, title = 'A page'): Suggestion => ({
  id,
  title,
  url: `https://example.org/${id}`,
  from: 'Pixel',
  fromId: 'pixel',
  explicit: false,
  receivedAtMs: 0,
  expiresAtMs: 0,
});

describe('withVideoTime', () => {
  it('adds t= to YouTube links', () => {
    expect(withVideoTime('https://www.youtube.com/watch?v=abc', 95.7)).toBe('https://www.youtube.com/watch?v=abc&t=95s');
    expect(withVideoTime('https://youtu.be/abc?t=3', 61)).toBe('https://youtu.be/abc?t=61s');
    expect(withVideoTime('https://m.youtube.com/watch?v=abc', 10)).toBe('https://m.youtube.com/watch?v=abc&t=10s');
  });

  it('uses the fragment for Vimeo and plain video files', () => {
    expect(withVideoTime('https://vimeo.com/123', 42)).toBe('https://vimeo.com/123#t=42s');
    expect(withVideoTime('https://example.org/clip.mp4', 42)).toBe('https://example.org/clip.mp4#t=42');
  });

  it('leaves other pages and tiny times alone', () => {
    expect(withVideoTime('https://example.org/article', 42)).toBe('https://example.org/article');
    expect(withVideoTime('https://www.youtube.com/watch?v=abc', 0.4)).toBe('https://www.youtube.com/watch?v=abc');
    expect(withVideoTime('https://www.youtube.com/watch?v=abc', undefined)).toBe('https://www.youtube.com/watch?v=abc');
    expect(withVideoTime('not a url', 42)).toBe('not a url');
  });

  it('knows which links resume on their own', () => {
    expect(linkCarriesTime('https://youtu.be/abc')).toBe(true);
    expect(linkCarriesTime('https://example.org/article')).toBe(false);
  });
});

describe('pairing code', () => {
  it('is always six digits', () => {
    expect(newPairingCode(() => new Uint32Array([7]))).toBe('000007');
    expect(newPairingCode(() => new Uint32Array([4_294_967_295]))).toBe('967295');
    expect(newPairingCode()).toMatch(/^\d{6}$/);
  });

  it('reads in two groups', () => {
    expect(spaced('123456')).toBe('123 456');
  });
});

describe('browserName', () => {
  it('names the common browsers', () => {
    const chrome = 'Mozilla/5.0 (Macintosh) AppleWebKit/537.36 Chrome/131.0 Safari/537.36';
    expect(browserName({ userAgent: chrome })).toBe('Chrome');
    expect(browserName({ userAgent: `${chrome} Edg/131.0` })).toBe('Edge');
    expect(browserName({ userAgent: chrome, isBrave: true })).toBe('Brave');
    expect(browserName({ userAgent: `${chrome} OPR/115` })).toBe('Opera');
    expect(browserName({ userAgent: 'Mozilla/5.0 (X11; Linux) Gecko/20100101 Firefox/133.0' })).toBe('Firefox');
    expect(browserName({ userAgent: 'x', brands: [{ brand: 'Microsoft Edge' }] })).toBe('Edge');
  });
});

describe('suggestions', () => {
  it('counts on the badge', () => {
    expect(badgeText([])).toBe('');
    expect(badgeText([suggestion('a')])).toBe('1');
    expect(badgeText(Array.from({ length: 12 }, (_, index) => suggestion(String(index))))).toBe('9+');
  });

  it('never replays what was seen', () => {
    expect(freshSuggestions([suggestion('a'), suggestion('b')], new Set(['a'])).map((item) => item.id)).toEqual(['b']);
  });

  it('notifies once, by name or as a count', () => {
    expect(notificationFor([])).toBeNull();
    expect(notificationFor([suggestion('a', 'Cats')])).toEqual({ title: 'Continue “Cats”', message: 'From Pixel' });
    expect(notificationFor([suggestion('a', '')])?.title).toBe('Continue “example.org”');
    expect(notificationFor([suggestion('a'), suggestion('b')])?.title).toBe('2 pages to continue');
  });
});

describe('messages', () => {
  it('uses the same words as Ferret', () => {
    expect(describeOutcome('opened', 'Pixel')).toBe('Opened on Pixel');
    expect(describeOutcome('unreachable', 'Pixel')).toContain("Couldn't reach Pixel");
    expect(describePairing('waiting')).toContain('Allow');
  });
});

describe('manifest', () => {
  it('runs a service worker on Chromium', () => {
    const manifest = manifestFor('chromium', '1.2.3');
    expect(manifest).toMatchObject({ manifest_version: 3, version: '1.2.3', background: { service_worker: 'background.js' } });
    expect(manifest).not.toHaveProperty('browser_specific_settings');
  });

  it('runs background scripts with an add-on id on Firefox', () => {
    const manifest = manifestFor('firefox', '1.2.3');
    expect(manifest).toMatchObject({
      manifest_version: 3,
      background: { scripts: ['background.js'] },
      browser_specific_settings: { gecko: { id: firefoxId } },
    });
  });

  it('asks only for what it needs up front', () => {
    const manifest = manifestFor('chromium', '1.0.0') as { permissions: string[]; optional_permissions: string[]; host_permissions?: string[] };
    expect(manifest.permissions).not.toContain('tabs');
    expect(manifest.optional_permissions).toEqual(['tabs']);
    expect(manifest.host_permissions).toBeUndefined();
  });
});
