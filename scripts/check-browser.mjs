import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { chromium } from 'playwright-core';
import { preview } from 'vite';

const server = await preview({ preview: { host: '127.0.0.1', port: 0 } });
const { port } = server.httpServer.address();
const url = `http://127.0.0.1:${port}/`;
try {
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_PATH,
  });
  try {
    await checkEditor(browser, url);
  } finally {
    await browser.close();
  }
} finally {
  await server.close();
}

async function checkEditor(browser, url) {
  const page = await browser.newPage({
    viewport: { width: 1280, height: 800 },
    acceptDownloads: true,
  });
  page.setDefaultTimeout(8000);
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto(url);
  const button = (name) => page.getByRole('button', { name, exact: true });
  const slider = (name) => page.getByRole('slider', { name, exact: true });
  const canvas = page.locator('.stage canvas').first();
  const pixel = () =>
    canvas.evaluate((c) => [
      ...c.getContext('2d').getImageData(40, 20, 1, 1).data,
    ]);
  const upload = page.locator('input[type=file]');
  assert(await page.getByLabel('Enhance on open').isChecked());
  const coolFixture = await page.evaluate(() => {
    const c = document.createElement('canvas');
    c.width = 180;
    c.height = 90;
    const ctx = c.getContext('2d');
    ['rgb(72, 80, 91)', 'rgb(82, 90, 98)', 'rgb(90, 98, 107)'].forEach(
      (color, i) => {
        ctx.fillStyle = color;
        ctx.fillRect(i * 60, 0, 60, 90);
      },
    );
    return c.toDataURL().split(',')[1];
  });
  await upload.setInputFiles({
    name: 'dim-cool.png',
    mimeType: 'image/png',
    buffer: Buffer.from(coolFixture, 'base64'),
  });
  await page.getByRole('heading', { name: 'dim-cool.png' }).waitFor();
  assert(Number(await slider('Warmth').inputValue()) > 0);
  const correctedCool = await pixel();
  assert(
    correctedCool[1] > 90 && Math.abs(correctedCool[2] - correctedCool[0]) < 19,
  );
  assert.match(
    await page.getByRole('status').textContent(),
    /lifted exposure, warmed cool tones/,
  );
  assert.match(
    await page.getByRole('status').textContent(),
    /Sample brightness: \d+% → \d+%/,
  );
  await button('Before').click();
  assert.deepEqual(await pixel(), [72, 80, 91, 255]);
  await button('Undo').click();
  assert.deepEqual(await pixel(), [72, 80, 91, 255]);
  await button('Redo').click();
  assert.deepEqual(await pixel(), correctedCool);
  await button('Split').click();
  await button('Auto Enhance').click();
  assert.equal(await button('After').getAttribute('aria-pressed'), 'true');
  await page.goto(url);
  await page.getByLabel('Enhance on open').uncheck();
  await button('Try sample').click();
  await page.getByRole('heading', { name: 'Alpine Lake.jpg' }).waitFor();
  assert.equal(await slider('Exposure').inputValue(), '0');
  const strength = page.getByLabel('Auto strength');
  await strength.selectOption('35');
  await button('Auto Enhance').click();
  const subtle = Math.abs(Number(await slider('Exposure').inputValue()));
  await strength.selectOption('100');
  await button('Auto Enhance').click();
  const full = Math.abs(Number(await slider('Exposure').inputValue()));
  assert(full > subtle && subtle > 0, 'sample responds to both strengths');
  await button('Reset Exposure').click();
  assert.equal(await slider('Exposure').inputValue(), '0');
  await page.keyboard.press('Control+z');
  assert.equal(Math.abs(Number(await slider('Exposure').inputValue())), full);
  await page.keyboard.press('Control+Shift+z');
  assert.equal(await slider('Exposure').inputValue(), '0');
  await page.keyboard.press('b');
  assert.equal(await button('Before').getAttribute('aria-pressed'), 'true');
  await page.keyboard.press('b');
  assert.equal(await button('After').getAttribute('aria-pressed'), 'true');
  const zoom = page.getByLabel('Preview zoom');
  await zoom.selectOption('200');
  const stage = await page.locator('.stage').boundingBox();
  await page.mouse.move(stage.x + stage.width / 2, stage.y + stage.height / 2);
  await page.mouse.down();
  await page.mouse.move(
    stage.x + stage.width / 2 + 80,
    stage.y + stage.height / 2 + 30,
    { steps: 5 },
  );
  await page.mouse.up();
  assert(
    await canvas.evaluate(
      (element) => Math.abs(parseFloat(element.style.translate)) > 1,
    ),
  );
  await zoom.selectOption('100');
  assert.equal(
    await canvas.evaluate((element) => parseFloat(element.style.translate)),
    0,
  );
  assert((await page.locator('.histogram i').count()) === 48);
  await button('Auto Enhance').click();

  const fixture = await page.evaluate(() => {
    const c = document.createElement('canvas');
    c.width = 180;
    c.height = 90;
    const x = c.getContext('2d');
    ['#403730', '#624f3c', '#faf5ef'].forEach((color, i) => {
      x.fillStyle = color;
      x.fillRect(i * 60, 0, 60, 90);
    });
    return c.toDataURL().split(',')[1];
  });
  await upload.setInputFiles({
    name: 'bad.gif',
    mimeType: 'image/gif',
    buffer: Buffer.from('GIF'),
  });
  await page
    .getByRole('alert')
    .getByText('Choose a JPEG or PNG photo.')
    .waitFor();
  await upload.setInputFiles({
    name: 'phone.heic',
    mimeType: 'image/heic',
    buffer: Buffer.from('heic'),
  });
  await page
    .getByRole('alert')
    .getByText('Export this image as JPEG or PNG, then open it in PixelSense.')
    .waitFor();
  const corrupt = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  await upload.setInputFiles({
    name: 'broken.png',
    mimeType: 'image/png',
    buffer: corrupt,
  });
  await page
    .getByRole('alert')
    .getByText('This photo could not be opened. Try another JPEG or PNG.')
    .waitFor();
  await upload.setInputFiles({
    name: 'backlit.png',
    mimeType: 'image/png',
    buffer: Buffer.from(fixture, 'base64'),
  });
  await page.getByRole('heading', { name: 'backlit.png' }).waitFor();
  const original = await pixel();
  await button('Auto Enhance').click();
  const enhanced = await pixel();
  assert(enhanced[0] > original[0]);
  await button('Undo').click();
  assert.deepEqual(await pixel(), original);
  await button('Redo').click();
  assert.deepEqual(await pixel(), enhanced);
  const exposure = slider('Exposure');
  const value = await exposure.inputValue();
  const bounds = await exposure.boundingBox();
  await page.mouse.move(
    bounds.x + bounds.width * 0.72,
    bounds.y + bounds.height / 2,
  );
  await page.mouse.down();
  await page.mouse.move(
    bounds.x + bounds.width * 0.94,
    bounds.y + bounds.height / 2,
    { steps: 10 },
  );
  await page.mouse.up();
  assert.notEqual(await exposure.inputValue(), value);
  await button('Undo').click();
  assert.equal(await exposure.inputValue(), value);
  await button('Split').click();
  await slider('Split position').press('Home');
  await slider('Split position').press('ArrowRight');
  const clips = await page
    .locator('.stage canvas')
    .evaluateAll((list) => list.map((c) => c.style.clipPath));
  assert(clips[0].includes('1%') && clips[1].includes('99%'));
  await slider('Split position').press('End');
  await button('Before').click();
  assert.deepEqual(await pixel(), original);
  await button('After').click();
  assert.deepEqual(await pixel(), enhanced);
  for (const name of ['Exposure', 'Contrast', 'Saturation', 'Warmth']) {
    const previous = await pixel();
    await slider(name).press('Home');
    assert.notDeepEqual(await pixel(), previous, name);
    await button('Undo').click();
  }
  await page.locator('summary').click();
  await button('Portrait').click();
  await page
    .getByLabel('Editing instruction')
    .fill('Make this photo brighter and warmer.');
  await button('Apply instruction').click();
  assert.equal(await exposure.inputValue(), '1');
  await button('Reset all').click();
  assert.deepEqual(await pixel(), original);
  await button('Undo').click();
  assert.equal(await exposure.inputValue(), '1');
  await button('Auto Enhance').click();
  await button('Split').click();
  const [download] = await Promise.all([
    page.waitForEvent('download'),
    button('Download PNG').click(),
  ]);
  const bytes = await readFile(await download.path());
  assert.equal(download.suggestedFilename(), 'backlit-pixelsense.png');
  assert.equal(bytes.readUInt32BE(16), 180);
  assert.equal(bytes.readUInt32BE(20), 90);
  const exported = await page.evaluate(async (data) => {
    const image = new Image();
    image.src = 'data:image/png;base64,' + data;
    await image.decode();
    const c = document.createElement('canvas');
    c.width = 180;
    c.height = 90;
    const ctx = c.getContext('2d');
    ctx.drawImage(image, 0, 0);
    return [...ctx.getImageData(40, 20, 1, 1).data];
  }, bytes.toString('base64'));
  assert.deepEqual(exported, enhanced);
  await page.locator('.workspace').evaluate((workspace, data) => {
    const transfer = new DataTransfer();
    transfer.items.add(
      new File(
        [Uint8Array.from(atob(data), (c) => c.charCodeAt(0))],
        'dropped.png',
        { type: 'image/png' },
      ),
    );
    for (const type of ['dragenter', 'dragover', 'drop'])
      workspace.dispatchEvent(
        new DragEvent(type, {
          dataTransfer: transfer,
          bubbles: true,
          cancelable: true,
        }),
      );
  }, fixture);
  await page.getByRole('heading', { name: 'dropped.png' }).waitFor();
  assert(await button('Undo').isDisabled());
  assert(await button('Redo').isDisabled());
  assert.equal(await exposure.inputValue(), '0');
  const blackPng = await page.evaluate(() => {
    const c = document.createElement('canvas');
    c.width = 1600;
    c.height = 1200;
    const ctx = c.getContext('2d');
    ctx.fillRect(0, 0, 800, 1200);
    return c.toDataURL().split(',')[1];
  });
  await page.evaluate((data) => {
    const clipboardData = new DataTransfer();
    clipboardData.items.add(
      new File(
        [Uint8Array.from(atob(data), (c) => c.charCodeAt(0))],
        'pasted.png',
        { type: 'image/png' },
      ),
    );
    window.dispatchEvent(
      new ClipboardEvent('paste', { clipboardData, cancelable: true }),
    );
  }, blackPng);
  await page.getByRole('heading', { name: 'pasted.png' }).waitFor();
  assert.equal(await canvas.evaluate((element) => element.width), 1400);
  assert.deepEqual(await pixel(), [0, 0, 0, 255]);
  await button('Clipping').click();
  assert.deepEqual(await pixel(), [66, 149, 255, 255]);
  assert(
    (await page.locator('.histogram').getAttribute('aria-label')).includes(
      'Shadows 100.0%',
    ),
  );
  const [warningExport] = await Promise.all([
    page.waitForEvent('download'),
    button('Download PNG').click(),
  ]);
  const warningBytes = (await readFile(await warningExport.path())).toString(
    'base64',
  );
  const warningPixel = await page.evaluate(async (data) => {
    const image = new Image();
    image.src = 'data:image/png;base64,' + data;
    await image.decode();
    const c = document.createElement('canvas');
    c.width = 1600;
    c.height = 1200;
    const ctx = c.getContext('2d');
    ctx.drawImage(image, 0, 0);
    return {
      size: [image.naturalWidth, image.naturalHeight],
      black: [...ctx.getImageData(40, 20, 1, 1).data],
      transparent: [...ctx.getImageData(1599, 20, 1, 1).data],
    };
  }, warningBytes);
  assert.deepEqual(warningPixel, {
    size: [1600, 1200],
    black: [0, 0, 0, 255],
    transparent: [0, 0, 0, 0],
  });
  const jpeg = await page.evaluate(() => {
    const c = document.createElement('canvas');
    c.width = 180;
    c.height = 90;
    const ctx = c.getContext('2d');
    ctx.fillStyle = '#242b33';
    ctx.fillRect(0, 0, 180, 90);
    return c.toDataURL('image/jpeg', 0.95).split(',')[1];
  });
  await upload.setInputFiles({
    name: 'night.jpg',
    mimeType: 'image/jpeg',
    buffer: Buffer.from(jpeg, 'base64'),
  });
  await page.getByRole('heading', { name: 'night.jpg' }).waitFor();
  const nightBefore = await pixel();
  await button('Auto Enhance').click();
  const nightAfter = await pixel();
  assert(nightAfter[1] - nightBefore[1] >= 25, 'dark JPEG gets a visible lift');
  if (process.env.PIXELSENSE_DARK_TEST_JPEG) {
    const photo = await readFile(process.env.PIXELSENSE_DARK_TEST_JPEG);
    await upload.setInputFiles({ name: 'reference.jpg', mimeType: 'image/jpeg', buffer: photo });
    await page.getByRole('heading', { name: 'reference.jpg' }).waitFor();
    await button('Auto Enhance').click();
    const status = await page.getByRole('status').textContent();
    assert.match(status, /lifted exposure/);
    assert.match(status, /Sample brightness: \d+% → \d+%/);
    console.log(status);
  }

  await button('Split').click();
  await page.setViewportSize({ width: 390, height: 844 });
  assert(
    await page.evaluate(
      () => document.documentElement.scrollWidth === innerWidth,
    ),
  );
  assert.deepEqual(errors, []);

  console.log(
    'Production browser checks passed: import, automatic correction, workspace controls, and PNG export.',
  );
}
