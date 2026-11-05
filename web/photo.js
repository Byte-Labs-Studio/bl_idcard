const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : '';
const MAX_SIZE = 256;
const QUALITY = 0.8;
const MAX_LENGTH = 80 * 1024;

const reply = (id, data) =>
  fetch(`https://${resource}/photo`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify({ id, data }),
  }).catch(() => {});

const encode = (img) => {
  const scale = Math.min(1, MAX_SIZE / Math.max(img.naturalWidth, img.naturalHeight));
  const width = Math.max(1, Math.round(img.naturalWidth * scale));
  const height = Math.max(1, Math.round(img.naturalHeight * scale));
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(img, 0, 0, width, height);

  const webp = canvas.toDataURL('image/webp', QUALITY);
  if (webp.startsWith('data:image/webp')) return webp;

  const flat = document.createElement('canvas');
  flat.width = width;
  flat.height = height;
  const flatCtx = flat.getContext('2d');
  flatCtx.fillStyle = '#d9dde3';
  flatCtx.fillRect(0, 0, width, height);
  flatCtx.drawImage(canvas, 0, 0);
  return flat.toDataURL('image/jpeg', QUALITY);
};

const capture = (id, src) => {
  const img = new Image();
  img.crossOrigin = 'Anonymous';
  img.onload = () => {
    try {
      const data = encode(img);
      reply(id, data.length <= MAX_LENGTH ? data : null);
    } catch {
      reply(id, null);
    }
  };
  img.onerror = () => reply(id, null);
  img.src = src;
};

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.action !== 'photo') return;

  if (typeof data.source === 'string' && data.source.startsWith('data:image/')) capture(data.id, data.source);
  else if (typeof data.txd === 'string') capture(data.id, `https://nui-img/${data.txd}/${data.txd}?t=${Date.now()}`);
});
