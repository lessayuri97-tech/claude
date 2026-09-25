// Renderiza anuncio.html em MP4 (1080x1920, 30fps).
// Uso: node render.js [saida.mp4]   |   node render.js --stills 1,4,8,12,15.5
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');

const FPS = 30;
const FFMPEG = process.env.FFMPEG || 'ffmpeg';

(async () => {
  const args = process.argv.slice(2);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
  await page.goto('file://' + path.resolve(__dirname, 'anuncio.html') + '?capture=1');
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(300);

  if (args[0] === '--stills') {
    for (const t of args[1].split(',').map(Number)) {
      await page.evaluate((t) => window.render(t), t);
      await page.screenshot({ path: `still-${t}.png` });
    }
    await browser.close();
    return;
  }

  const out = args[0] || 'anuncio.mp4';
  const duration = await page.evaluate(() => window.DURATION);
  const ff = spawn(FFMPEG, ['-y', '-f', 'image2pipe', '-framerate', String(FPS), '-i', '-',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium',
    '-movflags', '+faststart', out], { stdio: ['pipe', 'ignore', 'inherit'] });
  const frames = Math.round(duration * FPS);
  for (let i = 0; i < frames; i++) {
    await page.evaluate((t) => window.render(t), i / FPS);
    const buf = await page.screenshot({ type: 'jpeg', quality: 95 });
    if (!ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once('drain', r));
  }
  ff.stdin.end();
  await new Promise((r) => ff.on('close', r));
  await browser.close();
  console.log('ok ->', out, frames, 'frames');
})();
