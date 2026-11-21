import { useEffect, useLayoutEffect, useMemo, useRef, useState, type ChangeEvent, type DragEvent, type FormEvent, type PointerEvent } from 'react';
import { createRoot } from 'react-dom/client';
import { adjustPixels, analyzePixels, controls, limits, neutral, recommendAdjustment, scaleRecipe, setAdjustment, type Recipe } from './adjustments';
import { exportName, exportPhoto, openPhoto, renderPreview, type Photo } from './photo';
import { interpretInstruction, presets } from './smart-tools';
import { newHistory, recordEdit, stepHistory } from './history';
import { measureTones } from './diagnostics';
import sampleUrl from './assets/alpine-lake.jpg';
import { decodeRecipe, encodeRecipe, maxPresetName, maxPresets, maxRecipeBytes, presetStorageKey, readPresets, type SavedPreset } from './recipes';
import './style.css';

const labels = { exposure: 'Exposure', contrast: 'Contrast', saturation: 'Saturation', warmth: 'Warmth' };

function saveDownload(blob: Blob, name: string) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = name;
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function App() {
  const [photo, setPhoto] = useState<Photo | null>(null);
  const [history, setHistory] = useState(() => newHistory(neutral));
  const recipe = history.current;
  const [view, setView] = useState<'before' | 'after' | 'split'>('after');
  const [split, setSplit] = useState(50);
  const [zoom, setZoom] = useState(100);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const panStart = useRef<{ x: number; y: number } | null>(null);
  const [showClipping, setShowClipping] = useState(false);
  const [strength, setStrength] = useState(100);
  const [enhanceOnOpen, setEnhanceOnOpen] = useState(true);
  const [dragging, setDragging] = useState(false);
  const [busy, setBusy] = useState<'open' | 'export' | null>(null);
  const [error, setError] = useState('');
  const [status, setStatus] = useState('');
  const [instruction, setInstruction] = useState('');
  const [presetName, setPresetName] = useState('');
  const [savedPresets, setSavedPresets] = useState(() => {
    try { return readPresets(localStorage); } catch { return []; }
  });
  const recipeInput = useRef<HTMLInputElement>(null);
  const input = useRef<HTMLInputElement>(null);
  const preview = useRef<HTMLCanvasElement>(null);
  const original = useRef<HTMLCanvasElement>(null);
  const sliderGesture = useRef<{ changed: boolean } | null>(null);
  const dragDepth = useRef(0);
  const splitView = view === 'split';
  const disabled = !photo || Boolean(busy);
  const visibleRecipe = view === 'before' ? neutral : recipe;
  const tones = useMemo(() => photo ? measureTones(adjustPixels(photo.sample.data, visibleRecipe)) : null, [photo, visibleRecipe]);

  useLayoutEffect(() => {
    if (photo && preview.current) {
      try {
        renderPreview(preview.current, photo.preview, visibleRecipe, showClipping);
      } catch {
        setError('The preview could not be rendered. Try a smaller photo.');
      }
    }
  }, [photo, visibleRecipe, showClipping]);

  useLayoutEffect(() => {
    if (!photo || !splitView || !original.current) return;
    try {
      renderPreview(original.current, photo.preview, neutral, showClipping);
    } catch {
      setError('The original preview could not be rendered.');
    }
  }, [photo, splitView, showClipping]);

  async function upload(event: ChangeEvent<HTMLInputElement>) {
    const file = event.currentTarget.files?.[0];
    event.currentTarget.value = '';
    if (file) await load(file);
  }

  async function load(file: File) {
    if (busy) return;
    setBusy('open');
    setError('');
    setStatus('');
    try {
      replacePhoto(await openPhoto(file));
    } catch (failure) {
      setError(failure instanceof Error ? failure.message : 'The photo could not be opened.');
    } finally {
      setBusy(null);
    }
  }

  function replacePhoto(next: Photo) {
    setPhoto(next);
    const start = newHistory(neutral);
    const automatic = enhanceOnOpen ? scaleRecipe(recommendAdjustment(next.sample.data), strength / 100) : neutral;
    setHistory(recordEdit(start, automatic));
    if (enhanceOnOpen) setStatus(enhancementMessage(next.sample.data, automatic));
    setView('after');
    setSplit(50);
    setZoom(100);
    setPan({ x: 0, y: 0 });
    setShowClipping(false);
    setInstruction('');
  }

  async function openSample() {
    if (busy) return;
    setBusy('open');
    setError('');
    setStatus('');
    try {
      const response = await fetch(sampleUrl);
      if (!response.ok) throw new Error('Sample unavailable');
      replacePhoto(await openPhoto(new File([await response.blob()], 'Alpine Lake.jpg', { type: 'image/jpeg' })));
    } catch {
      setError('The sample photo could not be opened.');
    } finally {
      setBusy(null);
    }
  }

  function startPan(event: PointerEvent<HTMLDivElement>) {
    if (zoom === 100 || event.button !== 0 || !event.isPrimary) return;
    event.currentTarget.setPointerCapture(event.pointerId);
    panStart.current = { x: event.clientX - pan.x, y: event.clientY - pan.y };
  }

  function movePan(event: PointerEvent<HTMLDivElement>) {
    if (!panStart.current || !event.isPrimary || !preview.current) return;
    const stage = event.currentTarget;
    const image = preview.current;
    const horizontal = Math.max(0, (image.offsetWidth * zoom / 100 - stage.clientWidth) / 2);
    const vertical = Math.max(0, (image.offsetHeight * zoom / 100 - stage.clientHeight) / 2);
    setPan({
      x: Math.max(-horizontal, Math.min(horizontal, event.clientX - panStart.current.x)),
      y: Math.max(-vertical, Math.min(vertical, event.clientY - panStart.current.y)),
    });
  }

  function drop(event: DragEvent<HTMLElement>) {
    event.preventDefault();
    dragDepth.current = 0;
    setDragging(false);
    const file = event.dataTransfer.files[0];
    if (file) void load(file);
  }

  function apply(next: Recipe, message = '', coalesce = false) {
    setHistory(current => recordEdit(current, next, coalesce));
    setView(current => current === 'before' ? 'after' : current);
    setError('');
    setStatus(message);
  }

  function moveHistory(direction: 'undo' | 'redo') {
    setHistory(current => stepHistory(current, direction));
    setView(current => current === 'before' ? 'after' : current);
    setError('');
    setStatus(direction === 'undo' ? 'Edit undone.' : 'Edit restored.');
  }

  function enhancementMessage(source: Uint8ClampedArray, next: Recipe) {
    const changes = [
      next.exposure > 0 ? 'lifted exposure' : next.exposure < 0 ? 'reduced exposure' : '',
      next.warmth > 0 ? 'warmed cool tones' : next.warmth < 0 ? 'cooled warm tones' : '',
      next.contrast ? 'increased contrast' : '',
      next.saturation ? 'balanced color' : '',
    ].filter(Boolean);
    if (!changes.length) return 'Auto Enhance found no clear correction. You can still adjust the sliders.';
    const corrected = adjustPixels(source, next);
    if (corrected.every((value, index) => value === source[index])) {
      return 'Auto Enhance found no visible difference. Try the manual controls for this photo.';
    }

    const before = Math.round((analyzePixels(source)?.brightness ?? 0) * 100);
    const after = Math.round((analyzePixels(corrected)?.brightness ?? 0) * 100);
    const brightness = before === after ? '' : ` Sample brightness: ${before}% → ${after}%.`;
    return `Auto Enhance: ${changes.join(', ')}.${brightness} Choose Before to compare.`;
  }

  function enhance() {
    if (!photo) return;
    const next = scaleRecipe(recommendAdjustment(photo.sample.data), strength / 100);
    apply(next, enhancementMessage(photo.sample.data, next));
    setView('after');
  }

  function applyInstruction(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const next = interpretInstruction(instruction, recipe);
    if (next) {
      apply(next, 'Instruction applied.');
    } else {
      setStatus('');
      setError('Try a color or tone instruction such as “Make this photo brighter and warmer.”');
    }
  }

  function savePreset(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const name = presetName.trim();
    if (!photo || !name) return;
    if (savedPresets.some(entry => entry.name.toLowerCase() === name.toLowerCase())) {
      setError('A saved preset already uses that name.');
      return;
    }
    if (savedPresets.length >= maxPresets) {
      setError('Remove a saved preset to make room for a new one.');
      return;
    }
    if (storePresets([...savedPresets, { name, recipe }], `Saved “${name}” to this browser.`)) setPresetName('');
  }

  function storePresets(next: SavedPreset[], message: string) {
    try {
      localStorage.setItem(presetStorageKey, JSON.stringify(next));
      setSavedPresets(next);
      setError('');
      setStatus(message);
      return true;
    } catch {
      setError('This browser could not save your presets. You can download a recipe instead.');
      return false;
    }
  }

  async function importRecipe(event: ChangeEvent<HTMLInputElement>) {
    const file = event.currentTarget.files?.[0];
    event.currentTarget.value = '';
    if (!photo || !file || busy) return;
    setBusy('open');
    try {
      if (file.size > maxRecipeBytes) throw new Error('This file is too large to be a PixelSense recipe.');
      apply(decodeRecipe(await file.text()), 'Recipe applied to this photo.');
      setView('after');
    } catch (failure) {
      setError(failure instanceof Error ? failure.message : 'Could not open the recipe.');
    } finally {
      setBusy(null);
    }
  }

  async function download() {
    if (!photo) return;
    setBusy('export');
    setError('');
    setStatus('');
    try {
      // Give the browser a frame to display the export state before rendering at full resolution.
      await new Promise<void>(resolve => requestAnimationFrame(() => requestAnimationFrame(() => resolve())));
      const blob = await exportPhoto(photo, recipe);
      saveDownload(blob, exportName(photo.name));
      setStatus('PNG download started.');
    } catch {
      setError('This photo could not be exported. Try a smaller image.');
    } finally {
      setBusy(null);
    }
  }

  useEffect(() => {
    function shortcuts(event: KeyboardEvent) {
      if (busy || event.defaultPrevented || event.repeat) return;
      if (event.target instanceof HTMLElement && event.target.closest('input, textarea, select, [contenteditable]')) return;
      const key = event.key.toLowerCase();
      if ((event.metaKey || event.ctrlKey) && !event.altKey && key === 'z') {
        const direction = event.shiftKey ? 'redo' : 'undo';
        if (direction === 'redo' ? history.future.length : history.past.length) {
          event.preventDefault();
          moveHistory(direction);
        }
      }
      if (photo && !event.metaKey && !event.ctrlKey && !event.altKey && key === 'b') {
        setView(current => current === 'before' ? 'after' : 'before');
      }
    }

    function paste(event: ClipboardEvent) {
      if (busy || event.defaultPrevented) return;
      if (event.target instanceof HTMLElement && event.target.closest('input, textarea, [contenteditable]')) return;
      const image = Array.from(event.clipboardData?.files ?? []).find(file => /^image\/(png|jpeg)$/.test(file.type));
      if (image) {
        event.preventDefault();
        void load(image);
      }
    }

    window.addEventListener('keydown', shortcuts);
    window.addEventListener('paste', paste);
    return () => {
      window.removeEventListener('keydown', shortcuts);
      window.removeEventListener('paste', paste);
    };
  }, [busy, enhanceOnOpen, strength, history.past.length, history.future.length, photo]);

  return (
    <div className="app">
      <header className="brand">
        <span className="mark" aria-hidden="true">✦</span>
        <div>
          <h1>PixelSense</h1>
          <p>Photo editing studio</p>
        </div>
        <div className="header-actions">
          <button className="secondary" onClick={() => input.current?.click()} disabled={Boolean(busy)}>Open photo</button>
          <button className="primary export" disabled={disabled} onClick={download}>{busy === 'export' ? 'Exporting…' : 'Download PNG'}</button>
        </div>
      </header>
      <main>
        <section className={`workspace${dragging ? ' dragging' : ''}`} aria-labelledby="photo-heading"
          onDragEnter={event => {
            if (!event.dataTransfer.types.includes('Files')) return;
            event.preventDefault();
            dragDepth.current += 1;
            setDragging(!busy);
          }}
          onDragOver={event => {
            if (!event.dataTransfer.types.includes('Files')) return;
            event.preventDefault();
            event.dataTransfer.dropEffect = busy ? 'none' : 'copy';
          }}
          onDragLeave={() => {
            dragDepth.current = Math.max(0, dragDepth.current - 1);
            if (!dragDepth.current) setDragging(false);
          }}
          onDrop={drop}>
          <div className="workspace-bar">
            <div className="file-info">
              <h2 id="photo-heading">{photo ? photo.name : 'Photo preview'}</h2>
              {photo && <p>{photo.width} × {photo.height} px</p>}
            </div>
            <div className="workspace-tools">
              <div className="history-tools" role="group" aria-label="Edit history">
                <button className="secondary" aria-label="Undo" title="Undo (⌘/Ctrl+Z)"
                  disabled={disabled || !history.past.length} onClick={() => moveHistory('undo')}>↶</button>
                <button className="secondary" aria-label="Redo" title="Redo (⌘/Ctrl+Shift+Z)"
                  disabled={disabled || !history.future.length} onClick={() => moveHistory('redo')}>↷</button>
              </div>
              <label className="zoom-control">
                <span className="sr-only">Preview zoom</span>
                <select value={zoom} disabled={disabled} onChange={event => {
                  setZoom(Number(event.currentTarget.value));
                  setPan({ x: 0, y: 0 });
                }}>
                  <option value={100}>Fit</option>
                  <option value={150}>150%</option>
                  <option value={200}>200%</option>
                  <option value={300}>300%</option>
                </select>
              </label>
            </div>
            <input ref={input} type="file" accept="image/jpeg,image/png,.jpg,.jpeg,.png" aria-label="Open photo file" onChange={upload} hidden />
          </div>
          <div className={`stage${photo ? '' : ' stage-empty'}${zoom > 100 ? ' zoomed' : ''}`}
            onPointerDown={startPan} onPointerMove={movePan}
            onLostPointerCapture={() => { panStart.current = null; }}
            style={photo ? undefined : { backgroundImage: `linear-gradient(90deg, #10151ce8 8%, #10151c80 55%, #10151c18), url(${sampleUrl})` }}>
            {photo ? (
              <>
                <canvas ref={preview} role="img" aria-label={view === 'before' ? 'Original photo' : 'Edited photo'}
                  style={{ scale: zoom / 100, translate: `${pan.x}px ${pan.y}px`, clipPath: splitView ? `inset(0 0 0 ${split}%)` : undefined }} />
                {splitView && (
                  <div className="split-overlay">
                    <canvas ref={original} role="img" aria-label="Original photo"
                      style={{ scale: zoom / 100, translate: `${pan.x}px ${pan.y}px`, clipPath: `inset(0 ${100 - split}% 0 0)` }} />
                  </div>
                )}
              </>
            ) : (
              <div className="empty">
                <h2>Bring out the detail.</h2>
                <p>Drop, paste, or open a JPEG or PNG. Your photos stay on this device.</p>
                <div className="empty-actions">
                  <button className="primary" onClick={() => input.current?.click()} disabled={Boolean(busy)}>Choose photo</button>
                  <button className="secondary" onClick={openSample} disabled={Boolean(busy)}>Try sample</button>
                </div>
              </div>
            )}
          </div>
          {error && <p className="feedback error" role="alert">{error}</p>}
          <div className="workspace-footer">
            <div className="segmented" role="group" aria-label="Compare photo">
              <button aria-pressed={view === 'before'} disabled={disabled} onClick={() => setView('before')}>Before</button>
              <button aria-pressed={view === 'split'} disabled={disabled} onClick={() => setView('split')}>Split</button>
              <button aria-pressed={view === 'after'} disabled={disabled} onClick={() => setView('after')}>After</button>
            </div>
            {splitView && (
              <label className="split-control">
                Split position
                <input type="range" min="0" max="100" value={split} disabled={disabled}
                  onChange={event => setSplit(event.currentTarget.valueAsNumber)} />
              </label>
            )}
          </div>
        </section>

        <aside className="panel" aria-label="Photo editing controls">
          <div className="panel-section scope">
            <div className="section-heading">
              <h2>Histogram</h2>
              <button className="secondary clipping" disabled={disabled} aria-pressed={showClipping}
                onClick={() => setShowClipping(active => !active)}>Clipping</button>
            </div>
            <div className="histogram" role="img" aria-label={tones
              ? `Luminance histogram. Shadows ${tones.shadows.toFixed(1)}%, highlights ${tones.highlights.toFixed(1)}%.`
              : 'Histogram available after opening a photo'}>
              {tones?.bins.map((height, index) => <i key={index} style={{ height: `${height * 100}%` }} />)}
            </div>
            <div className="scope-legend">
              <span>Shadows {tones ? `${tones.shadows.toFixed(1)}%` : '—'}</span>
              <span>Highlights {tones ? `${tones.highlights.toFixed(1)}%` : '—'}</span>
            </div>
          </div>
          <div className="panel-section">
            <div className="section-heading">
              <h2>Adjustments</h2>
              <button className="text-button" disabled={disabled} onClick={() => apply(neutral, 'Adjustments reset.')}>Reset all</button>
            </div>
            <button className="primary enhance" disabled={disabled} onClick={enhance}>
              <span aria-hidden="true">✦</span> Auto Enhance
            </button>
            <label className="strength">
              Auto strength
              <select value={strength} disabled={disabled} onChange={event => setStrength(Number(event.currentTarget.value))}>
                <option value={35}>Subtle</option>
                <option value={65}>Moderate</option>
                <option value={100}>Full</option>
              </select>
            </label>
            <label className="enhance-on-open">
              <input type="checkbox" checked={enhanceOnOpen} disabled={Boolean(busy)}
                onChange={event => setEnhanceOnOpen(event.currentTarget.checked)} />
              Enhance on open
            </label>
            <p className={status ? 'feedback edit-feedback' : 'sr-only'} role="status">{status}</p>
            <div className="sliders">
              {controls.map(control => (
                <div className="slider" key={control}>
                  <label htmlFor={control}>{labels[control]}</label>
                  <button className="value" disabled={disabled || recipe[control] === 0}
                    aria-label={`Reset ${labels[control]}`} title={`Reset ${labels[control]}`}
                    onClick={() => apply(setAdjustment(recipe, control, 0))}>
                    {recipe[control].toFixed(2)}{control === 'exposure' && ' EV'}
                  </button>
                  <input id={control} type="range" min={-limits[control]} max={limits[control]} step="0.01"
                    value={recipe[control]} disabled={disabled}
                    onPointerDown={event => {
                      event.currentTarget.setPointerCapture(event.pointerId);
                      sliderGesture.current = { changed: false };
                    }}
                    onLostPointerCapture={() => { sliderGesture.current = null; }}
                    onChange={event => {
                      const gesture = sliderGesture.current;
                      const value = event.currentTarget.valueAsNumber;
                      if (value === recipe[control]) return;
                      apply(setAdjustment(recipe, control, value), '', gesture?.changed);
                      if (gesture) gesture.changed = true;
                    }} />
                </div>
              ))}
            </div>
          </div>
          <details className="panel-section">
            <summary>Presets and instructions</summary>
            <div className="presets" role="group" aria-label="Presets">
              {Object.entries(presets).map(([name, values]) => (
                <button className="secondary" key={name} disabled={disabled} onClick={() => apply(values, name + ' preset applied.')}>{name}</button>
              ))}
            </div>
            <form onSubmit={applyInstruction}>
              <label htmlFor="instruction">Editing instruction</label>
              <input id="instruction" value={instruction} placeholder="Try “brighter and warmer”"
                onChange={event => setInstruction(event.currentTarget.value)} disabled={disabled} required />
              <button className="secondary" disabled={disabled}>Apply instruction</button>
            </form>
          </details>
          <details className="panel-section">
            <summary>Saved looks and recipes</summary>
            {savedPresets.length > 0 && <ul className="saved-presets">
              {savedPresets.map(entry => <li key={entry.name}>
                <button className="secondary preset-name" disabled={disabled}
                  onClick={() => apply(entry.recipe, `Applied “${entry.name}”.`)}>{entry.name}</button>
                <button className="text-button" aria-label={`Remove ${entry.name}`}
                  onClick={() => storePresets(savedPresets.filter(preset => preset !== entry), `Removed “${entry.name}”.`)}>Remove</button>
              </li>)}
            </ul>}
            <form className="preset-form" onSubmit={savePreset}>
              <label htmlFor="preset-name">Preset name</label>
              <div className="recipe-actions">
                <input id="preset-name" value={presetName} maxLength={maxPresetName} disabled={disabled}
                  onChange={event => setPresetName(event.currentTarget.value)} placeholder="e.g. Warm afternoon" required />
                <button className="secondary" disabled={disabled || !presetName.trim()}>Save preset</button>
              </div>
            </form>
            <div className="recipe-actions">
              <button className="secondary" disabled={disabled} onClick={() => recipeInput.current?.click()}>Import recipe</button>
              <button className="secondary" disabled={disabled} onClick={() => {
                if (photo) saveDownload(new Blob([encodeRecipe(recipe)], { type: 'application/json' }),
                  exportName(photo.name).replace(/\.png$/, '.json'));
              }}>Download recipe</button>
              <input ref={recipeInput} aria-label="Open recipe file" type="file" accept=".json,application/json" onChange={importRecipe} hidden />
            </div>
          </details>
        </aside>
      </main>
    </div>
  );
}

createRoot(document.getElementById('root')!).render(<App />);
