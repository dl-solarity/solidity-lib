export function reverseBytes(str: string) {
  if (str.slice(0, 2) == "0x") str = str.slice(2);

  return "0x" + Buffer.from(str, "hex").reverse().toString("hex");
}

export function reverseByte(byte: string): string {
  const binary = parseInt(byte, 16).toString(2);
  const padded = binary.padStart(8, "0");
  return padded.split("").reverse().join("");
}

export function parseCuint(data: string, offset: number): [number, number] {
  const firstByte = parseInt(data.slice(offset, offset + 2), 16);

  if (firstByte < 0xfd) return [parseInt(data.slice(offset, offset + 2), 16), 2];
  if (firstByte == 0xfd) return [parseInt(data.slice(offset + 2, offset + 6), 16), 6];
  if (firstByte == 0xfe) return [parseInt(data.slice(offset + 2, offset + 10), 16), 10];
  return [parseInt(data.slice(offset + 2, offset + 18), 16), 18];
}
