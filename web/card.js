const params = new URLSearchParams(location.search);
const slot = Number(params.get('id')) || 0;
const resource = params.get('res') || '';
const texture = document.getElementById('texture');
const front = document.getElementById('front');
const back = document.getElementById('back');
const SVG = 'http://www.w3.org/2000/svg';
const COLOUR = /^#[0-9a-f]{3,8}$|^rgba?\([\d\s.,%]+\)$/i;

if (params.get('popup')) document.body.classList.add('popup');

const post = (name, body) =>
  fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(body),
  }).catch(() => {});

const seeded = (text) => {
  let h = 2166136261;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return () => {
    h += 0x6d2b79f5;
    let t = h;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};

const el = (tag, className, text) => {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined && text !== null) node.textContent = String(text);
  return node;
};

const svgEl = (tag, attrs) => {
  const node = document.createElementNS(SVG, tag);
  for (const key in attrs) node.setAttribute(key, attrs[key]);
  return node;
};

const image = (className, src) => {
  const img = el('img', className);
  img.src = src;
  return img;
};

const hexPoints = (cx, cy, r) => {
  const points = [];
  for (let i = 0; i < 6; i++) {
    const a = Math.PI / 6 + (i * Math.PI) / 3;
    points.push(`${(cx + Math.cos(a) * r).toFixed(1)},${(cy + Math.sin(a) * r).toFixed(1)}`);
  }
  return points.join(' ');
};

const hexes = () => {
  const svg = svgEl('svg', { class: 'hexes', viewBox: '0 0 1024 646', preserveAspectRatio: 'none' });
  const r = 30;
  const w = Math.sqrt(3) * r;
  for (let row = -1; row * r * 1.5 < 680; row++) {
    for (let col = -1; col * w < 1060; col++) {
      const cx = col * w + (row % 2 ? w / 2 : 0);
      const cy = row * r * 1.5;
      svg.appendChild(svgEl('polygon', { points: hexPoints(cx, cy, r - 2), fill: 'none', stroke: 'currentColor', 'stroke-width': 2 }));
    }
  }
  return svg;
};

const guilloche = (lines) => {
  const svg = svgEl('svg', { class: 'security', viewBox: '0 0 1024 646', preserveAspectRatio: 'none' });
  for (let i = 0; i < lines; i++) {
    const phase = (i / lines) * Math.PI * 2;
    const amp = 16 + (i % 5) * 5;
    let d = '';
    for (let x = 0; x <= 1024; x += 8) {
      const y = 323 + Math.sin(x / 80 + phase) * amp + Math.sin(x / 27 + phase * 2) * 5 + (i - lines / 2) * (646 / lines);
      d += `${x === 0 ? 'M' : 'L'} ${x} ${y.toFixed(1)} `;
    }
    svg.appendChild(svgEl('path', { d, fill: 'none', stroke: 'currentColor', 'stroke-width': 1 }));
  }
  return svg;
};

let sealCount = 0;

const seal = (state, className) => {
  const id = `seal-${sealCount++}`;
  const svg = svgEl('svg', { class: `seal ${className}`, viewBox: '0 0 200 200' });
  const defs = svgEl('defs', {});
  defs.appendChild(svgEl('path', { id, d: 'M 100 100 m -74 0 a 74 74 0 1 1 148 0 a 74 74 0 1 1 -148 0' }));
  svg.appendChild(defs);
  svg.appendChild(svgEl('circle', { cx: 100, cy: 100, r: 96, fill: 'none', stroke: 'currentColor', 'stroke-width': 6 }));
  svg.appendChild(svgEl('circle', { cx: 100, cy: 100, r: 87, fill: 'none', stroke: 'currentColor', 'stroke-width': 2 }));
  const ring = svgEl('text', { 'font-size': 15, 'font-weight': 800, 'letter-spacing': 3, fill: 'currentColor', 'font-family': 'Roboto Condensed' });
  const path = svgEl('textPath', { href: `#${id}`, startOffset: '50%', 'text-anchor': 'middle' });
  path.textContent = `STATE OF ${String(state || '').toUpperCase()} • OFFICIAL •`;
  ring.appendChild(path);
  svg.appendChild(ring);
  svg.appendChild(svgEl('polygon', { points: hexPoints(100, 100, 50), fill: 'none', stroke: 'currentColor', 'stroke-width': 6 }));
  svg.appendChild(svgEl('polygon', { points: hexPoints(100, 100, 34), fill: 'currentColor' }));
  return svg;
};

const field = (label, value, extra) => {
  const node = el('div', `field ${extra || ''}`);
  node.appendChild(el('label', '', label));
  node.appendChild(el('b', '', value || '-'));
  return node;
};

const photoBox = (photo) => {
  const box = el('div', 'photo');
  if (photo) {
    const glow = image('glow', photo);
    box.appendChild(glow);
  }
  box.appendChild(el('div', 'frame'));
  const inner = el('div', 'inner');
  inner.appendChild(photo ? image('', photo) : el('div', 'silhouette'));
  box.appendChild(inner);
  return box;
};

const mrzText = (value) =>
  String(value || '')
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '<');

const mrzDate = (text) => {
  const m = String(text || '').match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
  return m ? `${m[3].slice(2)}${m[1]}${m[2]}` : '000000';
};

const mrz = (card) => {
  const pad = (text) => (text + '<'.repeat(44)).slice(0, 44);
  return pad(`${mrzText(card.number)}<${mrzDate(card.birthdate)}${card.sex === 'F' ? 'F' : 'M'}${mrzDate(card.expires)}<${mrzText(card.lastname)}<<${mrzText(card.firstname)}`);
};

const pdf417 = (canvas, rand) => {
  const w = (canvas.width = 940);
  const h = (canvas.height = 84);
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#252525';
  const rows = 12;
  const rowH = h / rows;
  const module = 4;
  for (let r = 0; r < rows; r++) {
    let x = 0;
    const y = r * rowH;
    let black = true;
    for (const width of [8, 1, 1, 1, 1, 1, 1, 3]) {
      if (black) ctx.fillRect(x, y, width * module, rowH);
      x += width * module;
      black = !black;
    }
    while (x < w - 18 * module) {
      const width = 1 + Math.floor(rand() * 4);
      if (black) ctx.fillRect(x, y, width * module, rowH);
      x += width * module;
      black = !black;
    }
    x = w - 18 * module;
    black = true;
    for (const width of [7, 1, 1, 3, 1, 1, 1, 2, 1]) {
      if (black) ctx.fillRect(x, y, width * module, rowH);
      x += width * module;
      black = !black;
    }
  }
};

const applyTheme = (theme) => {
  const vars = { bgColour: '--bg', bgColourSecondary: '--bg2', titleColour: '--title', textColour: '--text' };
  for (const key in vars) {
    const value = theme[key];
    if (typeof value === 'string' && COLOUR.test(value)) texture.style.setProperty(vars[key], value);
    else texture.style.removeProperty(vars[key]);
  }
};

const renderFront = (card, theme, photo) => {
  front.replaceChildren();
  front.appendChild(hexes());
  front.appendChild(guilloche(22));

  if (card.emblem) front.appendChild(image('emblem', card.emblem));

  const chip = el('div', 'chip');
  for (let i = 0; i < 8; i++) chip.appendChild(el('i'));
  front.appendChild(chip);

  const header = el('div', 'header');
  const title = el('div', 'title', theme.title || card.state);
  title.dataset.text = title.textContent;
  header.appendChild(title);
  header.appendChild(el('div', 'label', theme.label || ''));
  front.appendChild(header);

  front.appendChild(photoBox(photo));

  const fields = el('div', 'fields');
  fields.appendChild(field(card.numberLabel || 'ID', card.number, 'mono'));
  fields.appendChild(field('EXP', card.expires, 'mono'));
  fields.appendChild(field('LASTNAME', card.lastname));
  fields.appendChild(field('DOB', card.birthdate, 'mono'));
  fields.appendChild(field('FIRSTNAME', card.firstname));
  fields.appendChild(field(card.class ? 'SEX / CLASS' : 'SEX', card.class ? `${card.sex} / ${card.class}` : card.sex));
  front.appendChild(fields);

  if (theme.stamp !== false) front.appendChild(seal(card.state, 'stamp'));

  if (theme.profileStamp && photo) {
    const ghost = el('div', 'ghost');
    ghost.appendChild(image('', photo));
    front.appendChild(ghost);
  }

  if (theme.signature !== false) {
    const signature = el('div', 'signature', `${card.firstname || ''} ${card.lastname || ''}`.trim());
    front.appendChild(signature);
    front.appendChild(el('div', 'signline'));
  }

  front.appendChild(el('div', 'strip'));
  front.appendChild(el('div', 'holo'));
};

const renderBack = (card, theme, rand) => {
  back.replaceChildren();
  back.appendChild(hexes());
  back.appendChild(guilloche(30));

  const band = el('div', 'band');
  band.appendChild(el('span', '', `${card.numberLabel || 'ID'} ${card.number || ''}`));
  back.appendChild(band);

  const print = el('div', 'print');
  print.appendChild(el('h3', '', `${card.state || ''} ${theme.agency || ''}`.trim()));
  const grid = el('div', 'grid');
  for (const item of card.details || []) grid.appendChild(field(item.label, item.value || 'NONE'));
  grid.appendChild(field('NATIONALITY', card.nationality));
  grid.appendChild(field('DOCUMENT', card.dd, 'mono'));
  print.appendChild(grid);
  print.appendChild(el('div', 'legal', theme.legal || ''));
  back.appendChild(print);

  if (card.emblem) {
    const mark = el('div', 'mark');
    mark.appendChild(image('', card.emblem));
    back.appendChild(mark);
  }

  const barcode = el('div', 'barcode');
  const canvas = el('canvas');
  pdf417(canvas, rand);
  barcode.appendChild(canvas);
  back.appendChild(barcode);

  back.appendChild(el('div', 'mrz', mrz(card)));
  back.appendChild(el('div', 'holo'));
};

const fitText = (root) => {
  for (const node of root.querySelectorAll('.field b, .title, .print h3')) {
    let size = parseFloat(getComputedStyle(node).fontSize);
    const limit = node.classList.contains('title') ? 680 : node.tagName === 'H3' ? 640 : node.closest('.print') ? 300 : node.parentElement.clientWidth;
    while (node.scrollWidth > limit && size > 14) {
      size -= 1;
      node.style.fontSize = `${size}px`;
    }
  }
  const signature = root.querySelector('.signature');
  if (signature) {
    const scale = Math.min(1, 290 / Math.max(1, signature.scrollWidth));
    signature.style.transform = `rotate(-4deg) scale(${scale.toFixed(3)})`;
  }
};

const whenImagesLoad = () =>
  Promise.all(
    [...document.images].map((img) =>
      img.decode ? img.decode().catch(() => {}) : Promise.resolve(),
    ),
  );

const render = async (card, photo) => {
  const theme = card.theme || {};
  applyTheme(theme);
  renderFront(card, theme, photo);
  renderBack(card, theme, seeded(`${card.number}:back`));
  await document.fonts.ready;
  fitText(front);
  fitText(back);
  await whenImagesLoad();
  requestAnimationFrame(() => requestAnimationFrame(() => post('cardRendered', { id: slot })));
};

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || typeof data !== 'object') return;

  if (data.action === 'card' && data.card) {
    render(data.card, typeof data.photo === 'string' ? data.photo : null);
  } else if (data.action === 'tilt') {
    texture.style.setProperty('--tx', Math.max(-1, Math.min(1, Number(data.x) || 0)).toFixed(3));
    texture.style.setProperty('--ty', Math.max(-1, Math.min(1, Number(data.y) || 0)).toFixed(3));
    texture.style.setProperty('--glare', Math.max(0, Math.min(1, Number(data.glare) || 0)).toFixed(3));
  }
});

post('cardReady', { id: slot });
