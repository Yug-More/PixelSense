import { expect, it } from 'vitest';
import { neutral, scaleRecipe } from './adjustments';
import { markClipping, measureTones } from './diagnostics';

it('weights visible near-black and near-white pixels and ignores transparent pixels', () => {
  const pixels = new Uint8ClampedArray([2, 2, 3, 255, 252, 253, 255, 128, 255, 255, 255, 0]);
  const tones = measureTones(pixels);
  expect(tones.shadows).toBeCloseTo(66.58);
  expect(tones.highlights).toBeCloseTo(33.42);
  expect(tones.bins[0]).toBe(1);
  expect(tones.bins[47]).toBeCloseTo(128 / 255);
});

it('marks extremes in the preview without altering alpha or midtones', () => {
  const pixels = new Uint8ClampedArray([0, 0, 0, 0, 3, 2, 1, 128, 253, 252, 255, 255, 90, 90, 90, 255]);
  markClipping(pixels);
  expect([...pixels]).toEqual([0, 0, 0, 0, 66, 149, 255, 128, 255, 103, 116, 255, 90, 90, 90, 255]);
});

it('scales automatic adjustments to slider precision', () => {
  const recipe = { ...neutral, exposure: 1.4, saturation: -0.1, contrast: 0.1 };
  expect(scaleRecipe(recipe, 1)).toEqual(recipe);
  expect(scaleRecipe(recipe, 0.35)).toEqual({ ...neutral, exposure: 0.49, saturation: -0.03, contrast: 0.03 });
});
