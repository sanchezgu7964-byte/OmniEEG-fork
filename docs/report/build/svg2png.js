// 用 Chromium 把 SVG/HTML 渲染成 PNG（2 倍分辨率）。用法：node svg2png.js 文件...
const { chromium } = require('playwright'); const path = require('path'); const fs = require('fs');
(async () => {
  const b = await chromium.launch(); const pg = await b.newPage({ deviceScaleFactor: 2 });
  for (const f of process.argv.slice(2)) {
    const abs = path.resolve(f);
    if (f.endsWith('.svg')) {
      const s = fs.readFileSync(abs, 'utf8'); const m = s.match(/width="(\d+)" height="(\d+)"/);
      await pg.setViewportSize({ width: +m[1], height: +m[2] });
      await pg.setContent(`<html><body style="margin:0">${s}</body></html>`);
    } else {
      await pg.setViewportSize({ width: 1400, height: 900 });
      await pg.goto('file://' + abs); await pg.waitForTimeout(300);
      const h = await pg.evaluate(() => document.querySelector('#fig').getBoundingClientRect());
      await pg.setViewportSize({ width: Math.ceil(h.width), height: Math.ceil(h.height) });
    }
    await pg.screenshot({ path: abs.replace(/\.(svg|html)$/, '.png'), fullPage: false });
  }
  await b.close();
})();
