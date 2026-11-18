import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { BridgeClient, BridgeError, type Status } from '../src/bridge_client';
import type { Device, Suggestion } from '../src/protocol';
import { FakeSocket, tick } from './fake_socket';

describe('BridgeClient', () => {
  let sockets: FakeSocket[];
  let statuses: Status[];
  let devices: Device[][];
  let suggestions: Suggestion[][];
  let opens: string[];
  let revoked: number;

  const create = (overrides: Partial<ConstructorParameters<typeof BridgeClient>[0]> = {}) =>
    new BridgeClient({
      socket: (url) => {
        const socket = new FakeSocket(url);
        sockets.push(socket);
        return socket;
      },
      browser: 'Firefox',
      ports: [47650, 47651],
      connectTimeoutMs: 50,
      requestTimeoutMs: 50,
      events: {
        status: (status) => statuses.push(status),
        devices: (list) => devices.push(list),
        suggestions: (items) => suggestions.push(items),
        open: (message) => opens.push(message.url),
        revoked: () => {
          revoked += 1;
        },
      },
      ...overrides,
    });

  /** Opens the newest socket and answers its hello. */
  const welcome = async (paired: boolean) => {
    await tick();
    const socket = sockets.at(-1);
    if (!socket) throw new Error('no socket');
    socket.open();
    await tick();
    const hello = socket.last('hello');
    socket.receive({ type: 'welcome', re: hello?.id, v: 1, app: 'ferret', device: 'MacBook', paired, passive: true });
    return socket;
  };

  beforeEach(() => {
    sockets = [];
    statuses = [];
    devices = [];
    suggestions = [];
    opens = [];
    revoked = 0;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('says hello with its token and reports paired', async () => {
    const client = create();
    const connecting = client.connect('secret-token');
    const socket = await welcome(true);

    expect(await connecting).toBe(true);
    expect(socket.url).toBe('ws://127.0.0.1:47650');
    expect(socket.last('hello')).toMatchObject({ v: 1, browser: 'Firefox', token: 'secret-token' });
    expect(client.status).toBe('paired');
    expect(client.deviceName).toBe('MacBook');
    expect(statuses).toEqual(['connecting', 'paired']);
  });

  it('tries the next port when the first one is closed', async () => {
    const client = create();
    const connecting = client.connect(null);
    await tick();
    sockets[0]?.fail();
    const socket = await welcome(false);

    expect(await connecting).toBe(true);
    expect(socket.url).toBe('ws://127.0.0.1:47651');
    expect(client.port).toBe(47651);
    expect(client.status).toBe('unpaired');
  });

  it('skips a port where something else answers', async () => {
    const client = create();
    const connecting = client.connect(null);
    await tick();
    sockets[0]?.open();
    await tick();
    sockets[0]?.receive({ type: 'welcome', re: sockets[0]?.last('hello')?.id, v: 1, app: 'not-ferret' });
    await new Promise((resolve) => setTimeout(resolve, 60));
    await welcome(false);

    expect(await connecting).toBe(true);
    expect(sockets[0]?.closed).toBe(true);
    expect(client.port).toBe(47651);
  });

  it('says offline when Ferret is not running', async () => {
    const client = create();
    const connecting = client.connect(null);
    await tick();
    sockets[0]?.fail();
    await tick();
    sockets[1]?.fail();

    expect(await connecting).toBe(false);
    expect(client.status).toBe('offline');
  });

  it('remembers why Ferret turned it away', async () => {
    const client = create({ ports: [47650] });
    const connecting = client.connect('guess');
    await tick();
    sockets[0]?.open();
    await tick();
    sockets[0]?.receive({ type: 'error', re: sockets[0]?.last('hello')?.id, code: 'rate_limited', retryAfterMs: 1000 });

    expect(await connecting).toBe(false);
    expect(client.lastError).toBe('rate_limited');
  });

  it('pairs with a code and keeps the token', async () => {
    const client = create();
    const connecting = client.connect(null);
    const socket = await welcome(false);
    await connecting;

    const pairing = client.pair('123456');
    const request = socket.last('pair');
    expect(request).toMatchObject({ code: '123456', browser: 'Firefox' });
    const token = 't'.repeat(43);
    socket.receive({ type: 'paired', re: request?.id, token, client: 'c1', device: 'MacBook' });

    expect(await pairing).toBe(token);
    expect(client.status).toBe('paired');
  });

  it('reports a denied pairing', async () => {
    const client = create();
    const connecting = client.connect(null);
    const socket = await welcome(false);
    await connecting;

    const pairing = client.pair('123456');
    socket.receive({ type: 'pair_denied', re: socket.last('pair')?.id, reason: 'denied' });

    await expect(pairing).rejects.toEqual(new BridgeError('denied'));
  });

  it('sends a tab with the token and returns the outcome', async () => {
    const client = create();
    const connecting = client.connect('tok');
    const socket = await welcome(true);
    await connecting;

    const sending = client.send('pixel', { url: 'https://example.org', title: 'Example', videoTime: 12 });
    const request = socket.last('send');
    expect(request).toMatchObject({ token: 'tok', deviceId: 'pixel', tab: { url: 'https://example.org', videoTime: 12 } });
    socket.receive({ type: 'sent', re: request?.id, outcome: 'suggested' });

    expect(await sending).toBe('suggested');
  });

  it('turns a refused request into an error', async () => {
    const client = create();
    const connecting = client.connect('tok');
    const socket = await welcome(true);
    await connecting;

    const sending = client.send('pixel', { url: 'https://example.org', title: '' });
    socket.receive({ type: 'error', re: socket.last('send')?.id, code: 'unauthorized' });

    await expect(sending).rejects.toMatchObject({ code: 'unauthorized' });
  });

  it('times out when Ferret does not answer', async () => {
    const client = create();
    const connecting = client.connect('tok');
    await welcome(true);
    await connecting;

    await expect(client.devices()).rejects.toMatchObject({ code: 'timeout' });
  });

  it('passes pushes on to the background', async () => {
    const client = create();
    const connecting = client.connect('tok');
    const socket = await welcome(true);
    await connecting;

    socket.receive({ type: 'devices', devices: [{ id: 'p', name: 'Pixel', connected: true }] });
    socket.receive({ type: 'suggestions', items: [{ id: 'a', url: 'https://example.org', title: 'A' }] });
    socket.receive({ type: 'open', id: 'o1', url: 'https://example.org/open' });

    expect(devices.at(-1)?.[0]?.name).toBe('Pixel');
    expect(suggestions.at(-1)?.[0]?.id).toBe('a');
    expect(opens).toEqual(['https://example.org/open']);
  });

  it('answers an open request', async () => {
    const client = create();
    const connecting = client.connect('tok');
    const socket = await welcome(true);
    await connecting;

    client.answerOpen('o1', true);

    expect(socket.last('opened')).toEqual({ type: 'opened', token: 'tok', re: 'o1', ok: true });
  });

  it('forgets the token when Ferret revokes it', async () => {
    const client = create();
    const connecting = client.connect('tok');
    const socket = await welcome(true);
    await connecting;

    socket.receive({ type: 'revoked' });
    socket.dropBy(4003);

    expect(revoked).toBeGreaterThanOrEqual(1);
    expect(client.isPaired).toBe(false);
    await expect(client.devices()).rejects.toMatchObject({ code: 'unpaired' });
  });

  it('pings while connected and stops when the socket closes', async () => {
    vi.useFakeTimers();
    const client = create({ pingIntervalMs: 1000 });
    const connecting = client.connect('tok');
    await vi.advanceTimersByTimeAsync(0);
    const socket = sockets[0];
    if (!socket) throw new Error('no socket');
    socket.open();
    await vi.advanceTimersByTimeAsync(0);
    socket.receive({ type: 'welcome', re: socket.last('hello')?.id, v: 1, app: 'ferret', device: 'M', paired: true, passive: true });
    await connecting;

    await vi.advanceTimersByTimeAsync(2500);
    expect(socket.sent.filter((message) => message.type === 'ping')).toHaveLength(2);

    socket.dropBy(1006);
    await vi.advanceTimersByTimeAsync(5000);
    expect(socket.sent.filter((message) => message.type === 'ping')).toHaveLength(2);
    expect(client.status).toBe('offline');
  });

  it('does not send focus or dismiss before pairing', async () => {
    const client = create();
    const connecting = client.connect(null);
    const socket = await welcome(false);
    await connecting;

    client.focus(true);
    client.dismiss('a');

    expect(socket.last('focus')).toBeUndefined();
    expect(socket.last('dismiss')).toBeUndefined();
  });
});
