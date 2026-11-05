const popup = document.getElementById('popup');
const popupResource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : '';
let frame = null;
let pending = null;

const fit = () => {
  if (frame) frame.style.transform = `scale(${popup.clientWidth / 1024})`;
};

const ensureFrame = () => {
  if (frame) return;
  frame = document.createElement('iframe');
  frame.src = `card.html?id=-1&popup=1&res=${encodeURIComponent(popupResource)}`;
  frame.onload = () => {
    fit();
    if (pending) frame.contentWindow.postMessage(pending, '*');
  };
  popup.appendChild(frame);
};

window.addEventListener('resize', fit);

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.action !== 'popup') return;

  if (!data.card) {
    popup.classList.remove('open');
    return;
  }

  pending = { action: 'card', card: data.card, photo: typeof data.photo === 'string' ? data.photo : null };
  ensureFrame();
  if (frame.contentWindow && frame.contentDocument && frame.contentDocument.readyState === 'complete') {
    frame.contentWindow.postMessage(pending, '*');
  }
  popup.classList.add('open');
});
