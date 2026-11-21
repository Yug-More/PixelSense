import { expect, it } from 'vitest';
import { neutral } from './adjustments';
import { newHistory, recordEdit, stepHistory } from './history';

const brighter = { ...neutral, exposure: 0.5 };
const brighterStill = { ...neutral, exposure: 1 };

it('undoes one whole slider drag and can redo it', () => {
  const first = recordEdit(newHistory(neutral), brighter);
  const dragged = recordEdit(first, brighterStill, true);
  const undone = stepHistory(dragged, 'undo');
  expect(undone.current).toEqual(neutral);
  expect(stepHistory(undone, 'redo').current).toEqual(brighterStill);
});

it('preserves redo on a no-op and discards it on a new edit', () => {
  const undone = stepHistory(recordEdit(newHistory(neutral), brighter), 'undo');
  expect(recordEdit(undone, { ...neutral })).toBe(undone);
  const changed = recordEdit(undone, brighterStill);
  expect(changed.future).toEqual([]);
  expect(stepHistory(changed, 'redo')).toBe(changed);
});

it('retains the most recent fifty edits', () => {
  let history = newHistory(neutral);
  for (let i = 1; i <= 60; i += 1) {
    history = recordEdit(history, { ...neutral, exposure: i / 100 });
  }
  expect(history.past).toHaveLength(50);
  expect(history.past[0].exposure).toBe(0.1);
});
