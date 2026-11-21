import { controls, limits, neutral, setAdjustment, type Recipe } from './adjustments';

export type SavedPreset = { name: string; recipe: Recipe };

export const presetStorageKey = 'pixelsense.presets.v1';
export const maxPresets = 20;
export const maxPresetName = 40;
export const maxRecipeBytes = 16_384;

function readRecipe(value: unknown): Recipe {
  if (!value || typeof value !== 'object') throw new Error('This file has no adjustment settings.');
  const fields = value as Record<string, unknown>;
  let recipe = neutral;
  for (const control of controls) {
    const setting = fields[control];
    if (typeof setting !== 'number' || !Number.isFinite(setting) || Math.abs(setting) > limits[control]) {
      throw new Error('This file contains an invalid adjustment.');
    }
    recipe = setAdjustment(recipe, control, Math.round(setting * 100) / 100);
  }
  return recipe;
}

export function encodeRecipe(recipe: Recipe) {
  return JSON.stringify({ format: 'pixelsense-recipe', version: 1, adjustments: recipe }, null, 2);
}

export function decodeRecipe(json: string): Recipe {
  let data: unknown;
  try {
    data = JSON.parse(json);
  } catch {
    throw new Error('Choose a valid PixelSense recipe JSON file.');
  }
  const header = data as { format?: unknown; version?: unknown; adjustments?: unknown } | null;
  if (header?.format !== 'pixelsense-recipe' || header.version !== 1) {
    throw new Error('This recipe format or version is unsupported.');
  }
  return readRecipe(header.adjustments);
}

export function readPresets(storage: Pick<Storage, 'getItem'>): SavedPreset[] {
  const list: unknown = JSON.parse(storage.getItem(presetStorageKey) ?? '[]');
  if (!Array.isArray(list)) return [];
  return list.slice(0, maxPresets).flatMap(item => {
    const name = item?.name;
    if (typeof name !== 'string' || !name.trim() || name.length > maxPresetName) return [];
    try {
      return [{ name, recipe: readRecipe(item.recipe) }];
    } catch {
      return [];
    }
  });
}
