import {
  type ClientMessage,
  type Device,
  type SendOutcome,
  type ServerMessage,
  type Suggestion,
  type TabInfo,
  parseServerMessage,
  ports as defaultPorts,
  protocolVersion,
} from './protocol';

/** The part of a WebSocket the client uses, so tests can fake it. */
export interface SocketLike {
  readonly readyState: number;
  send(data: string): void;
  close(code?: number, reason?: string): void;
  onopen: ((event: unknown) => void) | null;
  onclose: ((event: { code: number }) => void) | null;
  onerror: ((event: unknown) => void) | null;
  onmessage: ((event: { data: unknown }) => void) | null;
}

export type SocketFactory = (url: string) => SocketLike;

export type Status = 'offline' | 'connecting' | 'unpaired' | 'paired';

export interface ClientEvents {
  status?(status: Status): void;
  devices?(devices: Device[]): void;
  suggestions?(items: Suggestion[]): void;
  open?(message: Extract<ServerMessage, { type: 'open' }>): void;
  /** Ferret forgot this browser; the token is gone for good. */
  revoked?(): void;
}

export interface ClientOptions {
  socket: SocketFactory;
  browser: string;
  events?: ClientEvents;
  ports?: readonly number[];
  connectTimeoutMs?: number;
  requestTimeoutMs?: number;
  pingIntervalMs?: number;
}

const openState = 1;

export class BridgeError extends Error {
  constructor(
    readonly code: string,
    readonly retryAfterMs?: number,
  ) {
    super(code);
  }
}

interface Pending {
  resolve(message: ServerMessage): void;
  reject(error: Error): void;
  timer: ReturnType<typeof setTimeout>;
}

/**
 * Talks to Ferret's local bridge: finds it on one of its ports, says hello
 * (with the token once paired), and matches replies to requests.
 */
export class BridgeClient {
  private socket: SocketLike | null = null;
  private connecting: Promise<boolean> | null = null;
  private pending = new Map<string, Pending>();
  private nextId = 1;
  private pingTimer: ReturnType<typeof setInterval> | null = null;
  private token: string | null = null;
  private currentStatus: Status = 'offline';

  /** The port Ferret answered on last, tried first next time. */
  port: number | null = null;
  /** The name of the computer Ferret runs on. */
  deviceName = '';
  /** Whether Ferret has "Suggest what I'm doing" on. */
  passive = true;
  /** Why the last connect failed, such as `rate_limited`, or null. */
  lastError: string | null = null;

  constructor(private readonly options: ClientOptions) {}

  get status(): Status {
    return this.currentStatus;
  }

  get isPaired(): boolean {
    return this.currentStatus === 'paired';
  }

  /**
   * Connects and says hello with [token]. True once Ferret answered, paired
   * or not; false when Ferret isn't running.
   */
  connect(token: string | null): Promise<boolean> {
    this.token = token;
    if (this.socket?.readyState === openState && this.currentStatus !== 'connecting') {
      return Promise.resolve(true);
    }

    this.connecting ??= this.scan().finally(() => {
      this.connecting = null;
    });
    return this.connecting;
  }

  disconnect(): void {
    this.socket?.close(1000, 'bye');
    this.dropSocket();
  }

  /** Asks Ferret to pair, showing [code] there. Resolves with the token. */
  async pair(code: string): Promise<string> {
    const reply = await this.request(
      { type: 'pair', code, browser: this.options.browser },
      3 * 60 * 1000,
    );
    if (reply.type === 'pair_denied') throw new BridgeError(reply.reason);
    if (reply.type !== 'paired') throw new BridgeError('unexpected');
    this.token = reply.token;
    this.deviceName = reply.device || this.deviceName;
    this.setStatus('paired');
    return reply.token;
  }

  async devices(): Promise<Device[]> {
    const reply = await this.request({ type: 'devices', token: this.requireToken() });
    return reply.type === 'devices' ? reply.devices : [];
  }

  async send(deviceId: string, tab: TabInfo): Promise<SendOutcome> {
    const reply = await this.request({ type: 'send', token: this.requireToken(), deviceId, tab });
    if (reply.type !== 'sent') throw new BridgeError('unexpected');
    return reply.outcome;
  }

  async share(tab: TabInfo): Promise<number> {
    const reply = await this.request({ type: 'share', token: this.requireToken(), tab });
    return reply.type === 'shared' ? reply.delivered : 0;
  }

  focus(focused: boolean): void {
    if (!this.token || !this.isPaired) return;
    this.post({ type: 'focus', token: this.token, focused });
  }

  dismiss(activityId: string): void {
    if (!this.token || !this.isPaired) return;
    this.post({ type: 'dismiss', token: this.token, activityId });
  }

  answerOpen(openId: string, ok: boolean): void {
    if (!this.token) return;
    this.post({ type: 'opened', token: this.token, re: openId, ok });
  }

  async unpair(): Promise<void> {
    const token = this.token;
    this.token = null;
    if (!token || !this.isPaired) return;
    try {
      await this.request({ type: 'unpair', token });
    } finally {
      this.disconnect();
    }
  }

  private async scan(): Promise<boolean> {
    this.setStatus('connecting');
    this.lastError = null;
    const ports = this.portsInOrder();
    for (const port of ports) {
      if (await this.tryPort(port)) {
        this.port = port;
        return true;
      }
    }

    this.setStatus('offline');
    return false;
  }

  private portsInOrder(): number[] {
    const all = [...(this.options.ports ?? defaultPorts)];
    if (this.port === null || !all.includes(this.port)) return all;
    return [this.port, ...all.filter((port) => port !== this.port)];
  }

  private async tryPort(port: number): Promise<boolean> {
    let socket: SocketLike;
    try {
      socket = this.options.socket(`ws://127.0.0.1:${port}`);
    } catch {
      return false;
    }

    const opened = await new Promise<boolean>((resolve) => {
      const timer = setTimeout(() => resolve(false), this.options.connectTimeoutMs ?? 1500);
      socket.onopen = () => {
        clearTimeout(timer);
        resolve(true);
      };
      socket.onerror = () => {
        clearTimeout(timer);
        resolve(false);
      };
      socket.onclose = () => {
        clearTimeout(timer);
        resolve(false);
      };
    });
    if (!opened) {
      socket.close();
      return false;
    }

    this.attach(socket);
    try {
      const hello = await this.request({
        type: 'hello',
        v: protocolVersion,
        browser: this.options.browser,
        ...(this.token ? { token: this.token } : {}),
      });
      if (hello.type !== 'welcome') throw new BridgeError('unexpected');
      this.deviceName = hello.device;
      this.passive = hello.passive;
      this.setStatus(hello.paired ? 'paired' : 'unpaired');
      this.startPing();
      return true;
    } catch (error) {
      // Something else answers on this port, or Ferret refused the hello.
      socket.close();
      this.dropSocket();
      if (error instanceof BridgeError && error.code !== 'timeout') this.lastError = error.code;
      return false;
    }
  }

  private attach(socket: SocketLike): void {
    this.socket = socket;
    socket.onmessage = (event) => {
      if (typeof event.data !== 'string') return;
      const message = parseServerMessage(event.data);
      if (message) this.onMessage(message);
    };
    socket.onclose = (event) => {
      if (this.socket !== socket) return;
      this.dropSocket();
      if (event.code === 4003) this.onRevoked();
      // Ferret closes connections that didn't pair in time; it still runs.
      if (event.code === 4001) this.setStatus('unpaired');
    };
    socket.onerror = () => undefined;
  }

  private onMessage(message: ServerMessage): void {
    const replyTo = 're' in message ? message.re : undefined;
    if (replyTo !== undefined) {
      const pending = this.pending.get(replyTo);
      if (pending) {
        this.pending.delete(replyTo);
        clearTimeout(pending.timer);
        if (message.type === 'error') {
          pending.reject(new BridgeError(message.code, message.retryAfterMs));
        } else {
          pending.resolve(message);
        }
        if (message.type === 'devices') this.options.events?.devices?.(message.devices);
        if (message.type === 'suggestions') this.options.events?.suggestions?.(message.items);
        return;
      }
    }

    switch (message.type) {
      case 'devices':
        this.options.events?.devices?.(message.devices);
        return;
      case 'suggestions':
        this.options.events?.suggestions?.(message.items);
        return;
      case 'open':
        this.options.events?.open?.(message);
        return;
      case 'revoked':
        this.onRevoked();
        return;
      default:
        return;
    }
  }

  private onRevoked(): void {
    this.token = null;
    this.setStatus('unpaired');
    this.options.events?.revoked?.();
  }

  private request(message: ClientMessage, timeoutMs?: number): Promise<ServerMessage> {
    const id = String(this.nextId++);
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new BridgeError('timeout'));
      }, timeoutMs ?? this.options.requestTimeoutMs ?? 5000);
      this.pending.set(id, { resolve, reject, timer });
      if (!this.post({ ...message, id } as ClientMessage)) {
        clearTimeout(timer);
        this.pending.delete(id);
        reject(new BridgeError('offline'));
      }
    });
  }

  private post(message: ClientMessage): boolean {
    const socket = this.socket;
    if (!socket || socket.readyState !== openState) return false;
    socket.send(JSON.stringify(message));
    return true;
  }

  /** Keeps the socket (and a Chromium service worker) alive while paired. */
  private startPing(): void {
    this.stopPing();
    this.pingTimer = setInterval(() => {
      this.post({ type: 'ping' });
    }, this.options.pingIntervalMs ?? 20_000);
  }

  private stopPing(): void {
    if (this.pingTimer !== null) clearInterval(this.pingTimer);
    this.pingTimer = null;
  }

  private dropSocket(): void {
    this.socket = null;
    this.stopPing();
    for (const [id, pending] of this.pending) {
      clearTimeout(pending.timer);
      pending.reject(new BridgeError('offline'));
      this.pending.delete(id);
    }
    if (this.currentStatus !== 'connecting') this.setStatus('offline');
  }

  private requireToken(): string {
    if (!this.token) throw new BridgeError('unpaired');
    return this.token;
  }

  private setStatus(status: Status): void {
    if (this.currentStatus === status) return;
    this.currentStatus = status;
    this.options.events?.status?.(status);
  }
}
