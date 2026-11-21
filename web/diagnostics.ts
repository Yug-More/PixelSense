const binCount = 48;

function clipping(red: number, green: number, blue: number) {
  if (Math.max(red, green, blue) <= 3) return 'shadow';
  if (Math.min(red, green, blue) >= 252) return 'highlight';
  return null;
}

export function measureTones(pixels: Uint8ClampedArray) {
  const bins = Array<number>(binCount).fill(0);
  let shadows = 0;
  let highlights = 0;
  let total = 0;

  for (let offset = 0; offset < pixels.length; offset += 4) {
    const weight = pixels[offset + 3] / 255;
    if (!weight) continue;
    const [red, green, blue] = [pixels[offset], pixels[offset + 1], pixels[offset + 2]];
    const luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
    bins[Math.floor(luma * binCount / 256)] += weight;
    const clip = clipping(red, green, blue);
    if (clip === 'shadow') shadows += weight;
    if (clip === 'highlight') highlights += weight;
    total += weight;
  }

  const peak = Math.max(1, ...bins);
  return {
    bins: bins.map(count => count / peak),
    shadows: total ? 100 * shadows / total : 0,
    highlights: total ? 100 * highlights / total : 0,
  };
}

// Called on an already-rendered preview buffer. Export never uses this overlay.
export function markClipping(pixels: Uint8ClampedArray) {
  for (let offset = 0; offset < pixels.length; offset += 4) {
    if (!pixels[offset + 3]) continue;
    const clip = clipping(pixels[offset], pixels[offset + 1], pixels[offset + 2]);
    if (clip === 'shadow') {
      pixels[offset] = 66;
      pixels[offset + 1] = 149;
      pixels[offset + 2] = 255;
    } else if (clip === 'highlight') {
      pixels[offset] = 255;
      pixels[offset + 1] = 103;
      pixels[offset + 2] = 116;
    }
  }
}
