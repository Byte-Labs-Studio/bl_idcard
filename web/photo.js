const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : '';
const SIZE = 256;

const reply = (id, data) =>
  fetch(`https://${resource}/photo`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify({ id, data }),
  }).catch(() => {});

const capture = (id, txd) => {
  const img = new Image();
  img.crossOrigin = 'Anonymous';
  img.onload = () => {
    try {
      const canvas = document.createElement('canvas');
      canvas.width = SIZE;
      canvas.height = SIZE;
      const ctx = canvas.getContext('2d');
      ctx.imageSmoothingQuality = 'high';
      ctx.drawImage(img, 0, 0, SIZE, SIZE);
      let data = canvas.toDataURL('image/webp', 0.9);
      if (!data.startsWith('data:image/webp')) data = canvas.toDataURL('image/png');
      reply(id, data);
    } catch {
      reply(id, null);
    }
  };
  img.onerror = () => reply(id, null);
  img.src = `https://nui-img/${txd}/${txd}?t=${Date.now()}`;
};

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data && data.action === 'photo' && typeof data.txd === 'string') capture(data.id, data.txd);
});
