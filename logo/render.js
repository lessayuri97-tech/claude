// Gera PNGs das logos: node render.js
const { chromium } = require('/opt/node22/lib/node_modules/playwright');
const fs = require('fs'), path = require('path');
const jobs = [
  ['icone.svg', 'icone.png', 512, 512, 'transparent'],
  ['logo-horizontal.svg', 'logo-horizontal.png', 920, 280, 'transparent'],
  ['logo-horizontal-branca.svg', 'logo-horizontal-branca.png', 920, 280, 'transparent'],
  ['logo-horizontal.svg', 'preview-fundo-claro.png', 920, 280, '#FFFFFF'],
  ['logo-horizontal-branca.svg', 'preview-fundo-escuro.png', 920, 280, '#0F2A44'],
];
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const [src, out, w, h, bg] of jobs) {
    const svg = fs.readFileSync(path.join(__dirname, src), 'utf8');
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(`<html><body style="margin:0;background:${bg}">${svg}</body></html>`);
    await page.screenshot({ path: path.join(__dirname, out), omitBackground: bg === 'transparent' });
  }
  await browser.close();
})();
