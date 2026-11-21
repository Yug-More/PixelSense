import { describe, expect, it } from 'vitest';
import { adjustPixels, analyzePixels, neutral, recommendAdjustment, setAdjustment } from './adjustments';
import { exportName, sizeWithin } from './photo';
import { interpretInstruction, presets } from './smart-tools';

function grayscale(...values: number[]) {
  return new Uint8ClampedArray(values.flatMap(value => [value, value, value, 255]));
}

describe('image analysis', () => {
  it('measures luminance, contrast and saturation while ignoring transparency', () => {
    const pixels = new Uint8ClampedArray([0, 0, 0, 255, 255, 0, 0, 255, 255, 255, 255, 0]);
    const stats = analyzePixels(pixels)!;
    expect(stats.brightness).toBeCloseTo(0.1063);
    expect(stats.contrast).toBeCloseTo(0.2126, 2);
    expect(stats.saturation).toBe(0.5);
    expect(recommendAdjustment(new Uint8ClampedArray(4))).toEqual(neutral);
  });

  it('brightens dark midtones and expands their contrast', () => {
    const pixels = grayscale(35, 55, 75);
    const result = recommendAdjustment(pixels);
    const original = analyzePixels(pixels)!;
    const adjusted = analyzePixels(adjustPixels(pixels, result))!;
    expect(result.exposure).toBeGreaterThan(0);
    expect(result.contrast).toBeGreaterThan(0);
    expect(adjusted.brightness).toBeGreaterThan(original.brightness);
    expect(adjusted.contrast).toBeGreaterThan(original.contrast);
  });

  it('brightens a flat dark sample without adding contrast', () => {
    const pixels = grayscale(55, 55, 55);
    const recipe = recommendAdjustment(pixels);
    expect(recipe.contrast).toBe(0);
    expect(adjustPixels(pixels, recipe)[0]).toBeGreaterThan(55);
  });

  it('keeps well-exposed photos subtle and lowers very bright exposure', () => {
    expect(recommendAdjustment(grayscale(50, 125, 210)).exposure).toBe(0);
    expect(recommendAdjustment(grayscale(50, 125, 210)).contrast).toBe(0);
    expect(recommendAdjustment(grayscale(220, 235, 250)).exposure).toBeLessThan(0);
  });

  it('lifts shadows and preserves near-white detail in a backlit photo', () => {
    const pixels = grayscale(40, 50, 65, 72, 245, 250, 255);
    const recipe = recommendAdjustment(pixels);
    const adjusted = adjustPixels(pixels, recipe);
    expect(recipe.exposure).toBeGreaterThan(0.5);
    expect(adjusted[4] - pixels[4]).toBeGreaterThanOrEqual(5);
    expect(adjusted[16]).toBeLessThan(adjusted[20]);
    expect(adjusted[20]).toBeLessThan(255);
    expect(adjusted[24]).toBe(255);
  });

  it('makes a real no-op recommendation for balanced grayscale and pure black', () => {
    expect(recommendAdjustment(grayscale(50, 125, 210))).toEqual(neutral);
    expect(recommendAdjustment(grayscale(0, 0))).toEqual(neutral);
  });

  it('brightens a dim cool image and reduces its blue cast', () => {
    const source = new Uint8ClampedArray([72, 80, 91, 255, 82, 90, 98, 255, 90, 98, 107, 255]);
    const recipe = recommendAdjustment(source);
    expect(recipe.exposure).toBeGreaterThan(0.5);
    expect(recipe.warmth).toBeGreaterThan(0);
    const adjusted = adjustPixels(source, recipe);
    expect(adjusted[1] - source[1]).toBeGreaterThan(10);
    expect(Math.abs(adjusted[2] - adjusted[0])).toBeLessThan(source[2] - source[0]);
  });

  it('recovers exposure and detects a cool cast that was too dark to measure in the original', () => {
    const source = new Uint8ClampedArray([19, 21, 24, 255, 23, 25, 29, 255, 25, 28, 32, 255]);
    expect(analyzePixels(source)?.warmCast).toBe(0);
    const recipe = recommendAdjustment(source);
    const result = adjustPixels(source, recipe);
    expect(recipe.exposure).toBe(2);
    expect(recipe.warmth).toBeGreaterThan(0);
    expect(result[1]).toBeGreaterThan(source[1] * 2);
  });

  it('cools a warm cast and ignores highly saturated subjects as temperature evidence', () => {
    const warm = new Uint8ClampedArray([149, 135, 121, 255, 169, 155, 141, 255]);
    const recipe = recommendAdjustment(warm);
    expect(recipe.warmth).toBeLessThan(0);
    const adjusted = adjustPixels(warm, recipe);
    expect(Math.abs(adjusted[0] - adjusted[2])).toBeLessThan(warm[0] - warm[2]);
    expect(recommendAdjustment(new Uint8ClampedArray([220, 20, 10, 255])).warmth).toBe(0);
  });

  it('preserves black, white and transparency under temperature correction', () => {
    const source = new Uint8ClampedArray([0, 0, 0, 255, 255, 255, 255, 255, 100, 50, 20, 0]);
    expect(adjustPixels(source, { ...neutral, warmth: 1 })).toEqual(source);
  });

  it('reduces unusually high saturation', () => {
    expect(recommendAdjustment(new Uint8ClampedArray([220, 20, 10, 255])).saturation).toBeLessThan(0);
  });
});

describe('shared adjustment pipeline', () => {
  it('keeps neutral pixels identical and returns a separate buffer', () => {
    const source = new Uint8ClampedArray([110, 80, 60, 128, 10, 20, 30, 0]);
    expect(adjustPixels(source, neutral)).toEqual(source);
    expect(adjustPixels(source, neutral)).not.toBe(source);
  });

  it('applies each slider without mutating the source or changing alpha', () => {
    const source = new Uint8ClampedArray([110, 80, 60, 128]);
    const exposure = adjustPixels(source, { ...neutral, exposure: 1 });
    const contrast = adjustPixels(source, { ...neutral, contrast: 0.3 });
    const saturation = adjustPixels(source, { ...neutral, saturation: -1 });
    const warmth = adjustPixels(source, { ...neutral, warmth: 0.5 });
    expect(exposure[0]).toBeGreaterThan(110);
    expect(contrast[2]).toBeLessThan(60);
    expect(saturation[0]).toBe(saturation[2]);
    expect(warmth[0]).toBeGreaterThan(110);
    expect(warmth[2]).toBeLessThan(60);
    expect([exposure, contrast, saturation, warmth].map(result => result[3])).toEqual([128, 128, 128, 128]);
    expect([...source]).toEqual([110, 80, 60, 128]);
  });

  it('clamps slider changes and leaves other adjustments intact', () => {
    expect(setAdjustment(presets.Warm, 'contrast', 10)).toEqual({ ...presets.Warm, contrast: 0.5 });
    expect(setAdjustment(presets.Warm, 'warmth', Infinity).warmth).toBe(0);
  });

  it('applies supported instructions and rejects unsupported or conflicting commands', () => {
    expect(interpretInstruction('Make this photo slightly brighter and warmer.', presets.Vibrant)).toEqual({
      ...presets.Vibrant, exposure: 0.5, warmth: 0.5,
    });
    expect(interpretInstruction('brighter and darker', neutral)).toBeNull();
    expect(interpretInstruction('brighter and remove the background', neutral)).toBeNull();
  });
});

describe('file utilities', () => {
  it('scales previews proportionally without upscaling or producing zero dimensions', () => {
    expect(sizeWithin(4000, 2000, 1400)).toEqual({ width: 1400, height: 700 });
    expect(sizeWithin(2000, 4000, 1400)).toEqual({ width: 700, height: 1400 });
    expect(sizeWithin(1, 4000, 64)).toEqual({ width: 1, height: 64 });
    expect(sizeWithin(100, 50, 1400)).toEqual({ width: 100, height: 50 });
  });

  it('gives exports recognizable PNG names', () => {
    expect(exportName('Class.demo.JPG')).toBe('Class.demo-pixelsense.png');
    expect(exportName('.png')).toBe('photo-pixelsense.png');
  });
});
