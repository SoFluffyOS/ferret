import type { SocketLike } from '../src/bridge_client';

/** A WebSocket the test drives: it records what the client sent. */
export class FakeSocket implements SocketLike {
  readyState = 0;
  sent: Record<string, unknown>[] = [];
  closed = false;
  onopen: ((event: unknown) => void) | null = null;
  onclose: ((event: { code: number }) => void) | null = null;
  onerror: ((event: unknown) => void) | null = null;
  onmessage: ((event: { data: unknown }) => void) | null = null;

  constructor(readonly url: string) {}

  send(data: string): void {
    this.sent.push(JSON.parse(data) as Record<string, unknown>);
  }

  close(): void {
    if (this.closed) return;
    this.closed = true;
    this.readyState = 3;
  }

  open(): void {
    this.readyState = 1;
    this.onopen?.({});
  }

  fail(): void {
    this.onerror?.({});
  }

  receive(message: Record<string, unknown>): void {
    this.onmessage?.({ data: JSON.stringify(message) });
  }

  dropBy(code: number): void {
    this.readyState = 3;
    this.onclose?.({ code });
  }

  last(type: string): Record<string, unknown> | undefined {
    return [...this.sent].reverse().find((message) => message.type === type);
  }
}

export const tick = (): Promise<void> => new Promise((resolve) => setTimeout(resolve, 0));
