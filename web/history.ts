import { controls, type Recipe } from './adjustments';

export type History = {
  past: Recipe[];
  current: Recipe;
  future: Recipe[];
};

export function newHistory(current: Recipe): History {
  return { past: [], current, future: [] };
}

export function recordEdit(history: History, current: Recipe, coalesce = false): History {
  if (controls.every(control => history.current[control] === current[control])) return history;
  const past = coalesce ? history.past : [...history.past.slice(-49), history.current];
  return { past, current, future: [] };
}

export function stepHistory(history: History, direction: 'undo' | 'redo'): History {
  const { past, current, future } = history;
  if (direction === 'undo' && past.length) {
    return { past: past.slice(0, -1), current: past[past.length - 1], future: [current, ...future] };
  }
  if (direction === 'redo' && future.length) {
    return { past: [...past, current], current: future[0], future: future.slice(1) };
  }
  return history;
}
