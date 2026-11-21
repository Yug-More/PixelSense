import { expect, it } from 'vitest';
import { neutral } from './adjustments';
import { decodeRecipe, encodeRecipe, readPresets } from './recipes';

it('round trips adjustments without placing image data in the recipe', () => {
  const recipe = { ...neutral, exposure: 1.35, warmth: -0.4 };
  expect(decodeRecipe(encodeRecipe(recipe))).toEqual(recipe);
  expect(Object.keys(JSON.parse(encodeRecipe(recipe)))).toEqual(['format', 'version', 'adjustments']);
});

it('rejects malformed JSON, unknown versions, and out-of-range values', () => {
  expect(() => decodeRecipe('{')).toThrow('valid');
  expect(() => decodeRecipe(encodeRecipe(neutral).replace('"version": 1', '"version": 2'))).toThrow('unsupported');
  expect(() => decodeRecipe(encodeRecipe({ ...neutral, exposure: 9 }))).toThrow('invalid');
});

it('retains valid local presets alongside corrupted entries', () => {
  const valid = { name: 'My edit', recipe: neutral };
  const text = JSON.stringify([null, { name: 'Broken', recipe: {} }, valid]);
  expect(readPresets({ getItem: () => text })).toEqual([valid]);
});
