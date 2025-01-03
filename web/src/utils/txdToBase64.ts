export async function convertImage( //https://github.com/BaziForYou/MugShotBase64
    txd: string,
    outputFormat: string = 'image/png'
): Promise<string> {
    return new Promise<string>((resolve, reject) => {
        const img = new Image();
        img.crossOrigin = 'Anonymous';
        img.onload = async () => {
            try {
                const canvas = document.createElement('canvas');
                const ctx = canvas.getContext('2d');
                if (!ctx) {
                    throw new Error('Failed to get 2D context.');
                }
                canvas.height = img.naturalHeight;
                canvas.width = img.naturalWidth;
                ctx.drawImage(img, 0, 0);
                resolve(canvas.toDataURL(outputFormat));
                canvas.remove();
            } catch (error) {
                reject(error);
            } finally {
                img.remove();
            }
        };
        img.onerror = () => reject(new Error('Failed to load image.'));
        img.src = `https://nui-img/${txd}/${txd}`;
    });
}