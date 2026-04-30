function hexToHsl(hex: string): [number, number, number] {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  if (max === min) return [0, 0, l * 100];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h = 0;
  switch (max) {
    case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
    case g: h = ((b - r) / d + 2) / 6; break;
    case b: h = ((r - g) / d + 4) / 6; break;
  }
  return [h * 360, s * 100, l * 100];
}

function hslToHex(h: number, s: number, l: number): string {
  const hh = h / 360, ss = s / 100, ll = l / 100;
  if (ss === 0) {
    const v = Math.round(ll * 255);
    const hex = v.toString(16).padStart(2, '0');
    return '#' + hex + hex + hex;
  }
  const hue2rgb = (p: number, q: number, t: number): number => {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  const q = ll < 0.5 ? ll * (1 + ss) : ll + ss - ll * ss;
  const p = 2 * ll - q;
  return '#' + [hue2rgb(p, q, hh + 1 / 3), hue2rgb(p, q, hh), hue2rgb(p, q, hh - 1 / 3)]
    .map(x => Math.round(x * 255).toString(16).padStart(2, '0'))
    .join('');
}

// Generate a 10-shade palette from any hex color.
// Shade index 6 = the input color (used with primaryShade: 6).
export function generateColorPalette(hex: string): [string,string,string,string,string,string,string,string,string,string] {
  const fallback: [string,string,string,string,string,string,string,string,string,string] =
    ['#fce7f3','#fbcfe8','#f9a8d4','#f472b6','#ec4899','#db2777','#be185d','#9d174d','#831843','#500724'];
  if (!hex || !hex.startsWith('#') || hex.length < 7) return fallback;
  try {
    const [h, s, l] = hexToHsl(hex);
    const deltas = [44, 34, 24, 16, 9, 4, 0, -9, -18, -27];
    return deltas.map(d => hslToHex(h, s, Math.max(6, Math.min(96, l + d)))) as typeof fallback;
  } catch {
    return fallback;
  }
}
