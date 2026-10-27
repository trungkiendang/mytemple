// Procedurally builds the 3D models used by the app (assets/models/*.glb):
//   mo.glb          wooden fish (mõ) on a red cushion, with its mallet
//   incense_N.glb   bronze censer (lư hương) holding N incense sticks (1, 3, 5)
// Usage: cd scripts && npm install && node generate_models.js
const path = require('path');
const { Document, NodeIO } = require('@gltf-transform/core');
const PNG = require('pngjs').PNG;

const OUT = path.join(__dirname, '..', 'assets', 'models');

// ── Geometry helpers ──────────────────────────────────────────────
// A mesh part is { pos: [], nor: [], uv: [], idx: [] } in flat arrays.
function newPart() {
  return { pos: [], nor: [], uv: [], idx: [] };
}

// Surface of revolution around Y. profile = [[radius, y], ...] bottom → top.
function lathe(profile, seg = 48) {
  const p = newPart();
  const n = profile.length;
  for (let i = 0; i < n; i++) {
    const prev = profile[Math.max(i - 1, 0)];
    const next = profile[Math.min(i + 1, n - 1)];
    const dr = next[0] - prev[0];
    const dy = next[1] - prev[1];
    const len = Math.hypot(dr, dy) || 1;
    // normal is the profile tangent rotated outwards
    const nr = dy / len;
    const ny = -dr / len;
    for (let j = 0; j <= seg; j++) {
      const a = (j / seg) * Math.PI * 2;
      const c = Math.cos(a), s = Math.sin(a);
      p.pos.push(profile[i][0] * c, profile[i][1], profile[i][0] * s);
      p.nor.push(nr * c, ny, nr * s);
      p.uv.push(j / seg, i / (n - 1));
    }
  }
  for (let i = 0; i < n - 1; i++) {
    for (let j = 0; j < seg; j++) {
      const a = i * (seg + 1) + j;
      const b = a + seg + 1;
      p.idx.push(a, a + 1, b, a + 1, b + 1, b);
    }
  }
  return p;
}

function ellipsoid(rx, ry, rz, seg = 40, rings = 24) {
  const p = newPart();
  for (let i = 0; i <= rings; i++) {
    const v = i / rings;
    const phi = v * Math.PI;
    for (let j = 0; j <= seg; j++) {
      const u = j / seg;
      const th = u * Math.PI * 2;
      const x = Math.sin(phi) * Math.cos(th);
      const y = Math.cos(phi);
      const z = Math.sin(phi) * Math.sin(th);
      p.pos.push(x * rx, y * ry, z * rz);
      const nx = x / rx, ny = y / ry, nz = z / rz;
      const l = Math.hypot(nx, ny, nz);
      p.nor.push(nx / l, ny / l, nz / l);
      p.uv.push(u, v);
    }
  }
  for (let i = 0; i < rings; i++) {
    for (let j = 0; j < seg; j++) {
      const a = i * (seg + 1) + j;
      const b = a + seg + 1;
      p.idx.push(a, b, a + 1, a + 1, b, b + 1);
    }
  }
  return p;
}

// Patch of an ellipsoid surface: theta around Y (front = +Z = PI/2); the height range
// (fractions -1..1 of the vertical radius) comes from yRange(u), u = 0..1 across theta.
function ellipsoidPatch(rx, ry, rz, th0, th1, yRange, seg = 48, rings = 8) {
  const p = newPart();
  for (let j = 0; j <= seg; j++) {
    const u = j / seg;
    const th = th0 + (th1 - th0) * u;
    const [y0, y1] = yRange(u);
    const a0 = Math.acos(y1), a1 = Math.acos(y0);
    for (let i = 0; i <= rings; i++) {
      const phi = a0 + (a1 - a0) * (i / rings);
      const x = Math.sin(phi) * Math.cos(th), y = Math.cos(phi), z = Math.sin(phi) * Math.sin(th);
      p.pos.push(x * rx, y * ry, z * rz);
      const nx = x / rx, ny = y / ry, nz = z / rz;
      const l = Math.hypot(nx, ny, nz);
      p.nor.push(nx / l, ny / l, nz / l);
      p.uv.push(u, i / rings);
    }
  }
  for (let j = 0; j < seg; j++) {
    for (let i = 0; i < rings; i++) {
      const a = j * (rings + 1) + i;
      const b = a + rings + 1;
      p.idx.push(a, a + 1, b, a + 1, b + 1, b);
    }
  }
  return p;
}

// Torus lying in the XZ plane (axis = Y).
function torus(R, r, seg = 48, tube = 12) {
  const p = newPart();
  for (let i = 0; i <= seg; i++) {
    const a = (i / seg) * Math.PI * 2;
    for (let j = 0; j <= tube; j++) {
      const b = (j / tube) * Math.PI * 2;
      const cx = Math.cos(a), cz = Math.sin(a);
      const nx = Math.cos(b) * cx, ny = Math.sin(b), nz = Math.cos(b) * cz;
      p.pos.push((R + r * Math.cos(b)) * cx, r * Math.sin(b), (R + r * Math.cos(b)) * cz);
      p.nor.push(nx, ny, nz);
      p.uv.push(i / seg, j / tube);
    }
  }
  for (let i = 0; i < seg; i++) {
    for (let j = 0; j < tube; j++) {
      const a = i * (tube + 1) + j;
      const b = a + tube + 1;
      p.idx.push(a, b, a + 1, a + 1, b, b + 1);
    }
  }
  return p;
}

// Transform: scale → rotate (euler X, Y, Z) → translate.
function xform(part, { t = [0, 0, 0], rx = 0, ry = 0, rz = 0, s = [1, 1, 1] } = {}) {
  const rot = (v) => {
    let [x, y, z] = v;
    let c = Math.cos(rx), sn = Math.sin(rx);
    [y, z] = [y * c - z * sn, y * sn + z * c];
    c = Math.cos(ry); sn = Math.sin(ry);
    [x, z] = [x * c + z * sn, -x * sn + z * c];
    c = Math.cos(rz); sn = Math.sin(rz);
    [x, y] = [x * c - y * sn, x * sn + y * c];
    return [x, y, z];
  };
  const out = newPart();
  out.uv = part.uv.slice();
  out.idx = part.idx.slice();
  for (let i = 0; i < part.pos.length; i += 3) {
    const v = rot([part.pos[i] * s[0], part.pos[i + 1] * s[1], part.pos[i + 2] * s[2]]);
    out.pos.push(v[0] + t[0], v[1] + t[1], v[2] + t[2]);
    const n = rot([part.nor[i] / s[0], part.nor[i + 1] / s[1], part.nor[i + 2] / s[2]]);
    const l = Math.hypot(...n) || 1;
    out.nor.push(n[0] / l, n[1] / l, n[2] / l);
  }
  return out;
}

// Simple cylinder along Y, from y0 to y1, capped.
function cylinder(r0, r1, y0, y1, seg = 16) {
  return lathe([[0, y0], [r0, y0], [r1, y1], [0, y1]], seg);
}

// ── Textures ──────────────────────────────────────────────────────
function pngTexture(doc, name, w, h, pixel) {
  const png = new PNG({ width: w, height: h });
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const [r, g, b] = pixel(x / w, y / h);
      const i = (y * w + x) * 4;
      png.data[i] = Math.max(0, Math.min(255, r));
      png.data[i + 1] = Math.max(0, Math.min(255, g));
      png.data[i + 2] = Math.max(0, Math.min(255, b));
      png.data[i + 3] = 255;
    }
  }
  return doc.createTexture(name).setImage(new Uint8Array(PNG.sync.write(png))).setMimeType('image/png');
}

// Deterministic pseudo-noise so regenerated files are stable.
function hash(x, y) {
  const s = Math.sin(x * 127.1 + y * 311.7) * 43758.5453;
  return s - Math.floor(s);
}

function woodTexture(doc, base) {
  return pngTexture(doc, 'wood_grain', 256, 256, (u, v) => {
    const ring = Math.sin(v * 70 + Math.sin(u * 12 + v * 5) * 2.2) * 0.5 + 0.5;
    const k = 0.72 + ring * 0.22 + (hash(Math.floor(u * 256), Math.floor(v * 256)) - 0.5) * 0.06;
    return [base[0] * k, base[1] * k, base[2] * k];
  });
}

// ── Scene building ────────────────────────────────────────────────
// Make triangles counter-clockwise as seen from outside (glTF front faces):
// flips the winding when the face normals mostly oppose the vertex normals.
function orient(part) {
  let dot = 0;
  const { pos, nor, idx } = part;
  for (let t = 0; t < idx.length; t += 3) {
    const [a, b, c] = [idx[t] * 3, idx[t + 1] * 3, idx[t + 2] * 3];
    const u = [pos[b] - pos[a], pos[b + 1] - pos[a + 1], pos[b + 2] - pos[a + 2]];
    const w = [pos[c] - pos[a], pos[c + 1] - pos[a + 1], pos[c + 2] - pos[a + 2]];
    const f = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]];
    dot += f[0] * nor[a] + f[1] * nor[a + 1] + f[2] * nor[a + 2];
  }
  if (dot < 0) {
    for (let t = 0; t < idx.length; t += 3) [idx[t + 1], idx[t + 2]] = [idx[t + 2], idx[t + 1]];
  }
}

class Builder {
  constructor() {
    this.doc = new Document();
    this.buf = this.doc.createBuffer();
    this.scene = this.doc.createScene();
  }

  material(name, { color, metal = 0, rough = 0.6, emissive, tex }) {
    const m = this.doc.createMaterial(name)
      .setBaseColorFactor([...color, 1])
      .setMetallicFactor(metal)
      .setRoughnessFactor(rough);
    if (emissive) m.setEmissiveFactor(emissive);
    if (tex) m.setBaseColorTexture(tex);
    return m;
  }

  add(name, part, mat) {
    const d = this.doc;
    orient(part);
    const acc = (type, arr, Arr) => d.createAccessor().setType(type).setArray(new Arr(arr)).setBuffer(this.buf);
    const prim = d.createPrimitive()
      .setAttribute('POSITION', acc('VEC3', part.pos, Float32Array))
      .setAttribute('NORMAL', acc('VEC3', part.nor, Float32Array))
      .setAttribute('TEXCOORD_0', acc('VEC2', part.uv, Float32Array))
      .setIndices(acc('SCALAR', part.idx, Uint16Array))
      .setMaterial(mat);
    const mesh = d.createMesh(name).addPrimitive(prim);
    this.scene.addChild(d.createNode(name).setMesh(mesh));
  }

  async write(file) {
    await new NodeIO().write(path.join(OUT, file), this.doc);
    console.log(`✓ ${file}`);
  }
}

// ── Mõ: wooden fish on a cushion, with mallet ─────────────────────
async function buildMo() {
  const b = new Builder();
  const wood = b.material('wood_bell', {
    color: [1, 1, 1], rough: 0.55, tex: woodTexture(b.doc, [185, 80, 40]),
  });
  const dark = b.material('wood_dark', { color: [0.1, 0.04, 0.02], rough: 0.9 });
  const velvet = b.material('cushion', { color: [0.42, 0.03, 0.04], rough: 1 });
  const gold = b.material('gold', { color: [0.95, 0.72, 0.25], metal: 0.9, rough: 0.3 });

  // Round red cushion with a gold rim
  b.add('cushion', lathe([
    [0, 0], [0.9, 0], [1.0, 0.05], [1.02, 0.12], [0.95, 0.2], [0.7, 0.24], [0, 0.25],
  ], 64), velvet);
  b.add('cushion_rim', xform(torus(1.0, 0.02, 64, 8), { t: [0, 0.07, 0] }), gold);

  // Monk's round wooden fish: flattened lacquered dome, crescent-shaped mouth across the front
  const R = [0.86, 0.6, 0.8];
  const cy = 0.25 + R[1] * 0.92;
  const grow = (k) => R.map((r) => r * k);
  b.add('body', xform(ellipsoid(R[0], R[1], R[2], 72, 40), { t: [0, cy, 0] }), wood);
  const th = [Math.PI / 2 - 1.35, Math.PI / 2 + 1.35];
  const lens = (u) => Math.sqrt(Math.max(0, 1 - (2 * u - 1) ** 2)); // 0 at the ends, 1 in the middle
  const mouth = (extra = 0, k = 1) => (u) => {
    const h = lens(u);
    return [-0.52 - extra - 0.0 * h - 0.0, -0.52 + 0.0].map((_, n) => n === 0
      ? -0.04 - (0.2 + extra) * h * k // lower edge dips in the middle
      : -0.04 + (0.2 + extra) * h * k); // upper edge rises in the middle
  };
  // dark cavity
  b.add('mouth', xform(ellipsoidPatch(...grow(1.03), ...th, mouth(0), 64, 8), { t: [0, cy, 0] }), dark);
  // thick lips following the crescent edges
  const lipTop = (u) => { const [, hi] = mouth(0)(u); return [hi - 0.015, hi + 0.12 * Math.max(lens(u), 0.2)]; };
  const lipBot = (u) => { const [lo] = mouth(0)(u); return [lo - 0.12 * Math.max(lens(u), 0.2), lo + 0.015]; };
  b.add('lip_top', xform(ellipsoidPatch(...grow(1.06), th[0] + 0.12, th[1] - 0.12, lipTop, 64, 4), { t: [0, cy, 0] }), wood);
  b.add('lip_bottom', xform(ellipsoidPatch(...grow(1.06), th[0] + 0.12, th[1] - 0.12, lipBot, 64, 4), { t: [0, cy, 0] }), wood);
  // carved scale bands around the crown
  for (const y of [0.45, 0.65, 0.82]) {
    b.add(`ridge${y}`, xform(torus(1.0, 0.018, 72, 8), {
      t: [0, cy + R[1] * y, 0], s: [R[0] * Math.sqrt(1 - y * y) * 1.02, 1, R[2] * Math.sqrt(1 - y * y) * 1.02],
    }), gold);
  }
  // fish head/tail handle at the back: short neck + upright fin, with a pearl
  b.add('neck', xform(ellipsoid(0.2, 0.17, 0.3, 24, 14), { t: [0, cy + 0.1, -0.84] }), wood);
  b.add('pearl', xform(ellipsoid(0.07, 0.07, 0.07, 12, 8), { t: [0, cy + 0.2, -1.1] }), gold);

  // Mallet resting on the cushion in front
  const mz = 0.8;
  b.add('mallet_handle', xform(cylinder(0.028, 0.022, 0, 0.7, 12), {
    t: [-0.3, 0.3, mz], rz: -Math.PI / 2,
  }), wood);
  b.add('mallet_head', xform(ellipsoid(0.1, 0.1, 0.1), { t: [0.4, 0.31, mz] }), velvet);

  await b.write('mo.glb');
}

// ── Lư hương: bronze censer with N incense sticks ─────────────────
const STICK_TOP = 1.25; // ember height reference, keep in sync with incense_screen.dart

async function buildIncense(count) {
  const b = new Builder();
  const bronze = b.material('bronze', { color: [0.55, 0.32, 0.1], metal: 0.55, rough: 0.5 });
  const gold = b.material('gold', { color: [0.95, 0.75, 0.3], metal: 0.9, rough: 0.3 });
  const ash = b.material('ash', { color: [0.32, 0.3, 0.28], rough: 1 });
  const stick = b.material('stick', { color: [0.55, 0.14, 0.08], rough: 0.9 });
  const ember = b.material('ember', {
    color: [0.95, 0.25, 0.05], rough: 0.4, emissive: [2.5, 0.6, 0.1],
  });

  // Body of the censer (profile bottom → top, closed at the top by the ash)
  b.add('censer', lathe([
    [0, 0.1], [0.2, 0.1], [0.28, 0.14], [0.36, 0.22], [0.4, 0.32], [0.38, 0.42],
    [0.36, 0.48], [0.41, 0.52], [0.43, 0.56], [0.4, 0.58], [0.34, 0.55],
  ], 56), bronze);
  b.add('ash', lathe([[0, 0.53], [0.34, 0.55], [0.36, 0.55]], 56), ash);
  b.add('band', xform(torus(0.39, 0.012, 56, 8), { t: [0, 0.3, 0] }), gold);
  b.add('lip', xform(torus(0.42, 0.014, 56, 8), { t: [0, 0.575, 0] }), gold);

  // Three feet
  for (let i = 0; i < 3; i++) {
    const a = (i / 3) * Math.PI * 2 + Math.PI / 6;
    b.add(`foot${i}`, xform(ellipsoid(0.06, 0.1, 0.06, 12, 8), {
      t: [Math.cos(a) * 0.23, 0.07, Math.sin(a) * 0.23],
    }), bronze);
  }
  // Two ear handles
  for (const sx of [-1, 1]) {
    b.add(`ear${sx}`, xform(torus(0.09, 0.016, 24, 8), {
      t: [sx * 0.47, 0.42, 0], rx: Math.PI / 2,
    }), bronze);
  }

  // Sticks fan out of the ash, tilted away from the centre
  const base = 0.5;
  const len = STICK_TOP - base;
  // [base x, base z, lean direction x, lean direction z]; lean angle is 0.18 rad
  const layouts = {
    1: [[0, 0, 0, 0]],
    3: [[-0.05, 0, -1, 0], [0.05, 0.03, 1, 0.5], [0.05, -0.03, 0.5, -1]],
    5: [[0, 0, 0, 0], [-0.07, 0, -1, 0], [0.07, 0, 1, 0], [0, 0.07, 0, 1], [0, -0.07, 0, -1]],
  }[count];
  const lean = count === 1 ? 0 : 0.18;
  layouts.forEach(([x, z, dx, dz], i) => {
    const geo = (part) => xform(part, { t: [x, base, z], rz: -dx * lean, rx: dz * lean });
    b.add(`stick${i}`, geo(cylinder(0.011, 0.011, 0, len, 10)), stick);
    b.add(`ember${i}`, geo(cylinder(0.0125, 0.0125, len - 0.07, len + 0.005, 10)), ember);
  });

  await b.write(`incense_${count}.glb`);
}

async function main() {
  await buildMo();
  for (const n of [1, 3, 5]) await buildIncense(n);
}

main().catch((e) => { console.error(e); process.exit(1); });
