type Random = (bytes: Uint32Array<ArrayBuffer>) => Uint32Array<ArrayBuffer>;

const secureRandom: Random = (bytes) => crypto.getRandomValues(bytes);

/** Six random digits for the user to compare in Ferret. */
export function newPairingCode(random: Random = secureRandom): string {
  const [value = 0] = random(new Uint32Array(1));
  return String(value % 1_000_000).padStart(6, '0');
}

/** "123456" as "123 456", easier to compare at a glance. */
export const spaced = (code: string): string =>
  code.length === 6 ? `${code.slice(0, 3)} ${code.slice(3)}` : code;
