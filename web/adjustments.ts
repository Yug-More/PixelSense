export const limits = {
  exposure: 2,
  contrast: 0.5,
  saturation: 1,
  warmth: 1,
} as const;

export type Control = keyof typeof limits;
export type Recipe = Readonly<Record<Control, number>>;

export const controls = Object.keys(limits) as Control[];
export const neutral: Recipe = { exposure: 0, contrast: 0, saturation: 0, warmth: 0 };

const luma = (red: number, green: number, blue: number) =>
  0.2126 * red + 0.7152 * green + 0.0722 * blue;

const exposureCurve = 1.15;

const clamp = (value: number, min: number, max: number) =>
  Math.min(max, Math.max(min, value));

export function setAdjustment(recipe: Recipe, control: Control, value: number): Recipe {
  const limit = limits[control];
  return { ...recipe, [control]: Number.isFinite(value) ? clamp(value, -limit, limit) : 0 };
}

export function scaleRecipe(recipe: Recipe, strength: number): Recipe {
  const scale = (value: number) => Math.round(value * strength * 100) / 100;
  return {
    exposure: scale(recipe.exposure),
    contrast: scale(recipe.contrast),
    saturation: scale(recipe.saturation),
    warmth: scale(recipe.warmth),
  };
}

function percentile(histogram: number[], total: number, fraction: number) {
  let accumulated = 0;
  for (const [intensity, weight] of histogram.entries()) {
    accumulated += weight;
    if (accumulated >= total * fraction) return intensity / 255;
  }
  return 1;
}

export function analyzePixels(pixels: Uint8ClampedArray) {
  const histogram = Array<number>(256).fill(0);
  let brightness = 0;
  let saturation = 0;
  let total = 0;
  let castWeight = 0;
  let warmCast = 0;

  for (let i = 0; i < pixels.length; i += 4) {
    const weight = pixels[i + 3] / 255;
    if (!weight) continue;
    const red = pixels[i];
    const green = pixels[i + 1];
    const blue = pixels[i + 2];
    const intensity = luma(red, green, blue);
    const highest = Math.max(red, green, blue);
    histogram[Math.round(intensity)] += weight;
    brightness += intensity / 255 * weight;
    const lowest = Math.min(red, green, blue);
    const chroma = highest ? (highest - lowest) / highest : 0;
    saturation += chroma * weight;

    // Muted midtones are more useful for estimating a cast than dark noise or vivid subjects.
    if (intensity >= 32 && intensity <= 232 && chroma <= 0.26
        && green >= Math.min(red, blue) - 4 && green <= Math.max(red, blue) + 4) {
      const confidence = weight * (1 - chroma);
      warmCast += (red - blue) * confidence;
      castWeight += confidence;
    }
    total += weight;
  }

  if (!total) return null;
  const highlights = percentile(histogram, total, 0.95);
  return {
    brightness: brightness / total,
    contrast: highlights - percentile(histogram, total, 0.05),
    saturation: saturation / total,
    midtone: percentile(histogram, total, 0.5),
    warmCast: castWeight >= total * 0.12 ? warmCast / castWeight : 0,
  };
}

export function recommendAdjustment(pixels: Uint8ClampedArray): Recipe {
  const stats = analyzePixels(pixels);
  if (!stats) return neutral;

  const { brightness, saturation, midtone } = stats;
  const typicalTone = 0.75 * midtone + 0.25 * brightness;
  const target = 0.47;
  // Invert the highlight-preserving exposure curve for a representative midtone.
  const darkBoost = typicalTone > 0 && typicalTone < 0.41
    ? clamp(exposureCurve * Math.log2(target * (1 - typicalTone) / (typicalTone * (1 - target))), 0, limits.exposure)
    : 0;
  const brightCut = clamp((brightness - 0.72) * 2, 0, 0.45);
  const round = (value: number) => Math.round(value * 100) / 100;
  const exposure = round(darkBoost - brightCut);
  const lighting = { ...neutral, exposure };
  const litPixels = adjustPixels(pixels, lighting);
  const lit = analyzePixels(litPixels) ?? stats;
  // Exposure can reveal useful color evidence in pixels that originally fell below the cutoff.
  const warmth = round(Math.abs(lit.warmCast) >= 3 ? clamp(-lit.warmCast / 46, -0.35, 0.35) : 0);
  const corrected = { ...lighting, warmth };

  // Evaluate the tonal spread after lighting and temperature.
  const adjusted = warmth ? analyzePixels(adjustPixels(pixels, corrected)) ?? lit : lit;
  const visibleRange = clamp(adjusted.contrast / 0.12, 0, 1);
  const contrast = round(clamp((0.30 - adjusted.contrast) * 0.65, 0, 0.15) * visibleRange);

  return {
    ...corrected,
    contrast,
    saturation: round(saturation > 0.68
      ? -clamp((saturation - 0.68) * 0.5, 0, 0.12)
      : clamp((0.22 - saturation) * 1.4, 0, 0.18) * clamp(saturation / 0.10, 0, 1)),
  };
}

// Change only RGB. The source buffer and alpha channel stay intact.
export function adjustPixels(source: Uint8ClampedArray, recipe: Recipe) {
  const result = new Uint8ClampedArray(source);
  if (controls.every(control => recipe[control] === 0)) return result;

  // Exposure gain is approximated in gamma-encoded sRGB.
  const gain = 2 ** (recipe.exposure / exposureCurve);
  const warmth = recipe.warmth * 26;
  const contrast = 1 + recipe.contrast;
  const saturation = 1 + recipe.saturation;
  const tone = (channel: number) => (channel - 127.5) * contrast + 127.5;

  for (let i = 0; i < source.length; i += 4) {
    if (!source[i + 3]) continue;
    const peak = Math.max(source[i], source[i + 1], source[i + 2]);
    // Fade positive gain near white to lift shadows without clipping bright channels.
    const pixelGain = gain > 1 ? gain / (1 + (gain - 1) * peak / 255) : gain;
    const level = luma(source[i], source[i + 1], source[i + 2]) * pixelGain / 255;
    const temperature = warmth * 4 * level * (1 - level);
    const red = tone(source[i] * pixelGain + temperature);
    const green = tone(source[i + 1] * pixelGain);
    const blue = tone(source[i + 2] * pixelGain - temperature);
    const gray = luma(red, green, blue);
    result[i] = gray + (red - gray) * saturation;
    result[i + 1] = gray + (green - gray) * saturation;
    result[i + 2] = gray + (blue - gray) * saturation;
  }
  return result;
}
