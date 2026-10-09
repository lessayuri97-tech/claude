const { chromium } = require('/opt/node22/lib/node_modules/playwright');
const fs = require('fs'), path = require('path');
const d = path.join(__dirname, 'v2');
const jobs = process.argv.slice(2).length ? [] : [];
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const [src, out, w, h, bg] of [
    ['icone.svg', 'icone.png', 600, 514, 'transparent'],
    ['logo.svg', 'logo.png', 1000, 300, 'transparent'],
    ['logo-branca.svg', 'logo-branca.png', 1000, 300, 'transparent'],
    ['logo.svg', 'preview-fundo-claro.png', 1000, 300, '#FFFFFF'],
    ['logo-branca.svg', 'preview-fundo-escuro.png', 1000, 300, '#0B1220'],
  ]) {
    if (!fs.existsSync(path.join(d, src))) continue;
    const svg = fs.readFileSync(path.join(d, src), 'utf8');
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(`<html><body style="margin:0;background:${bg}">${svg}</body></html>`);
    await page.screenshot({ path: path.join(d, out), omitBackground: bg === 'transparent' });
  }
  await browser.close();
})();
