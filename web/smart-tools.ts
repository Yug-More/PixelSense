import { limits, neutral, setAdjustment, type Control, type Recipe } from './adjustments';

export const presets: Record<string, Recipe> = {
  Natural: neutral,
  Portrait: { exposure: 0.3, contrast: 0.05, saturation: -0.1, warmth: 0.15 },
  Vibrant: { exposure: 0.1, contrast: 0.15, saturation: 0.45, warmth: 0.05 },
  Warm: { exposure: 0.1, contrast: 0.05, saturation: 0.1, warmth: 0.55 },
  Cinematic: { exposure: -0.15, contrast: 0.25, saturation: -0.2, warmth: -0.1 },
};

const phrases: Record<string, [Control, number]> = {
  brighter: ['exposure', 1],
  brighten: ['exposure', 1],
  lighter: ['exposure', 1],
  darker: ['exposure', -1],
  darken: ['exposure', -1],
  warmer: ['warmth', 1],
  'warm up': ['warmth', 1],
  cooler: ['warmth', -1],
  'cool down': ['warmth', -1],
  'more colorful': ['saturation', 1],
  'more vibrant': ['saturation', 1],
  'less colorful': ['saturation', -1],
  desaturate: ['saturation', -1],
};

const nouns: Record<string, Control> = {
  exposure: 'exposure', brightness: 'exposure', contrast: 'contrast',
  warmth: 'warmth', saturation: 'saturation', vibrance: 'saturation',
};

export function interpretInstruction(text: string, current: Recipe): Recipe | null {
  const clauses = text.toLowerCase().replace(/[^a-z\s]/g, ' ').trim().split(/\s+and\s+/);
  const seen = new Map<Control, number>();
  let next = current;

  for (const clause of clauses) {
    const command = clause.replace(/\s+/g, ' ')
      .replace(/^(please )?(make )?(this photo |the photo |it )?/, '')
      .trim();
    const strength = command.match(/^(slightly|a little|a bit|much|a lot) /)?.[1];
    const phrase = strength ? command.slice(strength.length + 1) : command;
    const match = phrase.match(/^(increase|raise|add|boost|more|reduce|lower|decrease|less) (?:the )?(exposure|brightness|contrast|warmth|saturation|vibrance)$/);
    const operation = match
      ? [nouns[match[2]], /^(reduce|lower|decrease|less)$/.test(match[1]) ? -1 : 1] as const
      : Object.hasOwn(phrases, phrase) ? phrases[phrase] : undefined;
    if (!operation) return null;
    const [control, direction] = operation;
    if (seen.has(control) && seen.get(control) !== direction) return null;
    seen.set(control, direction);
    const fraction = strength ? (/^(much|a lot)$/.test(strength) ? 1 : 0.25) : 0.5;
    next = setAdjustment(next, control, Math.round(direction * fraction * limits[control] * 100) / 100);
  }

  return next;
}
