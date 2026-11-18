import { describe, expect, it } from 'vitest';

import { isSendableUrl, parseServerMessage, ports } from '../src/protocol';

describe('parseServerMessage', () => {
  it('reads a welcome from Ferret', () => {
    const message = parseServerMessage(
      JSON.stringify({ type: 'welcome', re: '1', v: 1, app: 'ferret', device: 'MacBook', paired: true, passive: false }),
    );
    expect(message).toEqual({ type: 'welcome', re: '1', v: 1, app: 'ferret', device: 'MacBook', paired: true, passive: false });
  });

  it('refuses a welcome from something that is not Ferret', () => {
    expect(parseServerMessage(JSON.stringify({ type: 'welcome', v: 1, app: 'other' }))).toBeNull();
  });

  it('drops garbage and unknown types', () => {
    expect(parseServerMessage('not json')).toBeNull();
    expect(parseServerMessage('[]')).toBeNull();
    expect(parseServerMessage(JSON.stringify({ type: 'surprise' }))).toBeNull();
  });

  it('never trusts a link that is not http(s)', () => {
    expect(parseServerMessage(JSON.stringify({ type: 'open', id: 'a', url: 'javascript:alert(1)' }))).toBeNull();
    const suggestions = parseServerMessage(
      JSON.stringify({
        type: 'suggestions',
        items: [
          { id: 'a', url: 'https://example.org', title: 'Ok', from: 'Pixel' },
          { id: 'b', url: 'file:///etc/hosts' },
          { url: 'https://no-id.example' },
        ],
      }),
    );
    expect(suggestions?.type === 'suggestions' && suggestions.items.map((item) => item.id)).toEqual(['a']);
  });

  it('keeps only sane positions', () => {
    const message = parseServerMessage(
      JSON.stringify({ type: 'open', id: 'a', url: 'https://example.org', videoTime: -1, scrollY: 40 }),
    );
    expect(message).toMatchObject({ videoTime: undefined, scrollY: 40 });
  });

  it('wants a real token when paired', () => {
    expect(parseServerMessage(JSON.stringify({ type: 'paired', token: 'short', client: 'c' }))).toBeNull();
    const token = 'x'.repeat(43);
    expect(parseServerMessage(JSON.stringify({ type: 'paired', token, client: 'c' }))).toMatchObject({ token });
  });

  it('maps unknown outcomes to failed', () => {
    expect(parseServerMessage(JSON.stringify({ type: 'sent', outcome: 'exploded' }))).toMatchObject({ outcome: 'failed' });
  });

  it('reads devices', () => {
    const message = parseServerMessage(
      JSON.stringify({ type: 'devices', devices: [{ id: 'p', name: 'Pixel', platform: 'android', connected: true }, { id: 3 }] }),
    );
    expect(message).toEqual({
      type: 'devices',
      devices: [{ id: 'p', name: 'Pixel', platform: 'android', formFactor: 'unknown', connected: true }],
    });
  });
});

describe('ports', () => {
  it('match the range Ferret listens on', () => {
    expect(ports).toEqual([47650, 47651, 47652, 47653, 47654]);
  });
});

describe('isSendableUrl', () => {
  it('only takes web pages', () => {
    expect(isSendableUrl('https://example.org')).toBe(true);
    expect(isSendableUrl('chrome://settings')).toBe(false);
    expect(isSendableUrl('about:blank')).toBe(false);
    expect(isSendableUrl(undefined)).toBe(false);
  });
});
