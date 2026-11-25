import { markClipping } from './diagnostics';
import { adjustPixels, type Recipe } from './adjustments';

export function sizeWithin(width: number, height: number, longestSide: number) {
  const scale = Math.min(1, longestSide / Math.max(width, height));
  return {
    width: Math.max(1, Math.round(width * scale)),
    height: Math.max(1, Math.round(height * scale)),
  };
}

function createCanvas(width: number, height: number) {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  return canvas;
}

function readContext(canvas: HTMLCanvasElement) {
  const context = canvas.getContext('2d', { willReadFrequently: true });
  if (!context) throw new Error('This browser could not create a photo canvas.');
  return context;
}

export async function openPhoto(file: File) {
  const signature = new Uint8Array(await file.slice(0, 8).arrayBuffer());
  const jpeg = signature[0] === 255 && signature[1] === 216 && signature[2] === 255;
  const png = [137, 80, 78, 71, 13, 10, 26, 10].every((byte, i) => signature[i] === byte);
  if (!jpeg && !png) {
    const needsConversion = /\.(heic|heif|webp|avif)$/i.test(file.name);
    throw new Error(needsConversion
      ? 'Export this image as JPEG or PNG, then open it in PixelSense.'
      : 'Choose a JPEG or PNG photo.');
  }

  const url = URL.createObjectURL(file);
  try {
    const image = new Image();
    image.src = url;
    try {
      await image.decode();
    } catch {
      throw new Error('This photo could not be opened. Try another JPEG or PNG.');
    }
    const { naturalWidth: width, naturalHeight: height } = image;
    if (!width || !height) throw new Error('This photo is empty.');
    const readPixels = (longestSide: number) => {
      const size = sizeWithin(width, height, longestSide);
      const context = readContext(createCanvas(size.width, size.height));
      context.drawImage(image, 0, 0, size.width, size.height);
      return context.getImageData(0, 0, size.width, size.height);
    };
    return { image, width, height, name: file.name, preview: readPixels(1400), sample: readPixels(128) };
  } finally {
    URL.revokeObjectURL(url);
  }
}

export type Photo = Awaited<ReturnType<typeof openPhoto>>;

export function renderPreview(canvas: HTMLCanvasElement, source: ImageData, recipe: Recipe, showClipping = false) {
  if (canvas.width !== source.width || canvas.height !== source.height) {
    canvas.width = source.width;
    canvas.height = source.height;
  }
  const pixels = adjustPixels(source.data, recipe);
  if (showClipping) markClipping(pixels);
  readContext(canvas).putImageData(new ImageData(pixels, source.width, source.height), 0, 0);
}

export async function exportPhoto(photo: Photo, recipe: Recipe, format: ExportFormat = 'png', quality = 0.92) {
  const { image, width, height } = photo;
  const canvas = createCanvas(width, height);
  try {
    const context = readContext(canvas);
    context.drawImage(image, 0, 0);
    // Process strips to bound temporary pixel buffers on large photos.
    for (let top = 0; top < height; top += 128) {
      const strip = context.getImageData(0, top, width, Math.min(128, height - top));
      const pixels = adjustPixels(strip.data, recipe);
      context.putImageData(new ImageData(pixels, width, strip.height), 0, top);
    }
    const mime = format === 'jpeg' ? 'image/jpeg' : 'image/png';
    const boundedQuality = Math.max(0.5, Math.min(1, quality));
    return await new Promise<Blob>((resolve, reject) => {
      canvas.toBlob(blob => blob ? resolve(blob) : reject(new Error('Image export failed.')), mime,
        format === 'jpeg' ? boundedQuality : undefined);
    });
  } finally {
    canvas.width = canvas.height = 0;
  }
}

export type ExportFormat = 'png' | 'jpeg';

export const exportName = (name: string, format: ExportFormat = 'png') =>
  (name.replace(/\.[^.]+$/, '').trim() || 'photo') + (format === 'jpeg' ? '-pixelsense.jpg' : '-pixelsense.png');
