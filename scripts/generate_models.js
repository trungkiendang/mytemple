// Procedurally builds the 3D models used by the app (assets/models/*.glb):
//   mo.glb          wooden fish (mõ) on a red cushion (the mallet is a 2D overlay in the app)
//   incense_censer.glb   bronze censer (lư hương); sticks + smoke are drawn in Flutter
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
    const k = 0.88 + ring * 0.1 + (hash(Math.floor(u * 256), Math.floor(v * 256)) - 0.5) * 0.06;
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
    this.root = this.doc.createNode('root');
    this.scene.addChild(this.root);
  }

  yaw(a) {
    this.root.setRotation([0, Math.sin(a / 2), 0, Math.cos(a / 2)]);
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
    this.root.addChild(d.createNode(name).setMesh(mesh));
  }

  async write(file) {
    await new NodeIO().write(path.join(OUT, file), this.doc);
    console.log(`✓ ${file}`);
  }
}

// ── Mõ: teardrop fish dome with carved scaled fish, on a harlequin cushion ──
// Tube along a polyline; radius(t) tapers it (t = 0..1). Used for whiskers, brows, gill lines.
function tube(points, radius, seg = 8) {
  const p = newPart();
  const n = points.length;
  const norm = (v) => { const l = Math.hypot(...v) || 1; return v.map((x) => x / l); };
  const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
  for (let i = 0; i < n; i++) {
    const a = points[Math.max(i - 1, 0)], c = points[Math.min(i + 1, n - 1)];
    const T = norm([c[0] - a[0], c[1] - a[1], c[2] - a[2]]);
    const up = Math.abs(T[1]) > 0.9 ? [1, 0, 0] : [0, 1, 0];
    const N = norm(cross(T, up));
    const B = cross(T, N);
    const r = radius(i / (n - 1));
    for (let j = 0; j <= seg; j++) {
      const ang = (j / seg) * Math.PI * 2;
      const nx = Math.cos(ang), ny = Math.sin(ang);
      const d = [N[0] * nx + B[0] * ny, N[1] * nx + B[1] * ny, N[2] * nx + B[2] * ny];
      p.pos.push(points[i][0] + d[0] * r, points[i][1] + d[1] * r, points[i][2] + d[2] * r);
      p.nor.push(...d);
      p.uv.push(j / seg, i / (n - 1));
    }
  }
  for (let i = 0; i < n - 1; i++) {
    for (let j = 0; j < seg; j++) {
      const a = i * (seg + 1) + j, b = a + seg + 1;
      p.idx.push(a, a + 1, b, a + 1, b + 1, b);
    }
  }
  return p;
}

// Quadratic bezier sampled into a polyline.
function bezier(p0, p1, p2, n = 12) {
  const out = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n, a = (1 - t) * (1 - t), b = 2 * (1 - t) * t, c = t * t;
    out.push([0, 1, 2].map((k) => a * p0[k] + b * p1[k] + c * p2[k]));
  }
  return out;
}

// ── Teardrop deformation (back of the dome stays round, front tapers into a snout) ──
function deformPoint([x, y, z], R) {
  const zn = Math.max(0, z / R[2]);
  const taper = 1 - 0.3 * Math.pow(zn, 1.4);
  return [x * taper, y * taper - R[1] * 0.3 * zn * zn, z * (1 + 0.2 * zn)];
}

function recomputeNormals(part) {
  const { pos, idx } = part;
  const acc = new Map();
  const key = (i) => [0, 1, 2].map((k) => Math.round(pos[i * 3 + k] * 1e4)).join(',');
  const faces = [];
  for (let t = 0; t < idx.length; t += 3) {
    const [a, b, c] = [idx[t], idx[t + 1], idx[t + 2]];
    const u = [0, 1, 2].map((k) => pos[b * 3 + k] - pos[a * 3 + k]);
    const w = [0, 1, 2].map((k) => pos[c * 3 + k] - pos[a * 3 + k]);
    const f = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]];
    for (const i of [a, b, c]) {
      const k = key(i);
      const v = acc.get(k) || [0, 0, 0];
      acc.set(k, [v[0] + f[0], v[1] + f[1], v[2] + f[2]]);
    }
  }
  part.nor = [];
  for (let i = 0; i < pos.length / 3; i++) {
    const v = acc.get(key(i)) || [0, 1, 0];
    const l = Math.hypot(...v) || 1;
    part.nor.push(v[0] / l, v[1] / l, v[2] / l);
  }
  return faces;
}

// Orient the winding outwards, deform the vertices, then rebuild smooth normals.
function deform(part, R) {
  orient(part);
  for (let i = 0; i < part.pos.length; i += 3) {
    const p = deformPoint([part.pos[i], part.pos[i + 1], part.pos[i + 2]], R);
    part.pos[i] = p[0]; part.pos[i + 1] = p[1]; part.pos[i + 2] = p[2];
  }
  recomputeNormals(part);
  return part;
}

function scaleTexture(doc, base) {
  const rows = 16, cols = 22;
  return pngTexture(doc, 'fish_scales', 256, 256, (u, v) => {
    const rowf = v * rows, row = Math.floor(rowf);
    const cu = u * cols + (row % 2) * 0.5;
    const fx = cu - Math.floor(cu) - 0.5, fy = rowf - row - 0.5;
    const d = Math.hypot(fx, fy);
    const t = Math.min(1, Math.max(0, (d - 0.32) / 0.2));
    const k = 1.08 - 0.5 * t * t * (3 - 2 * t);
    return [base[0] * k, base[1] * k, base[2] * k];
  });
}

function harlequinTexture(doc) {
  return pngTexture(doc, 'cushion_diamonds', 256, 256, (u, v) => {
    // diamonds: checker rotated 45 degrees
    const a = Math.floor(u * 8), c = Math.floor(v * 4);
    return (a + c) % 2 === 0 ? [196, 26, 30] : [236, 178, 44];
  });
}

async function buildMo() {
  const b = new Builder();
  b.yaw(-0.6);
  const lacquer = [178, 66, 36];
  const wood = b.material('wood_bell', { color: [1, 1, 1], rough: 0.4, tex: woodTexture(b.doc, lacquer) });
  const scales = b.material('fish_scales', { color: [1, 1, 1], rough: 0.4, tex: scaleTexture(b.doc, [188, 76, 42]) });
  const carved = b.material('carved_edge', { color: [0.42, 0.14, 0.07], rough: 0.55 });
  const dark = b.material('wood_dark', { color: [0.09, 0.03, 0.02], rough: 0.9 });
  const cushion = b.material('cushion', { color: [1, 1, 1], rough: 0.7, tex: harlequinTexture(b.doc) });
  const cream = b.material('mallet_head', { color: [0.95, 0.93, 0.86], rough: 0.5 });
  const gold = b.material('gold', { color: [0.95, 0.72, 0.25], metal: 0.85, rough: 0.3 });

  // Puffy round cushion with red / gold diamonds
  b.add('cushion', lathe([
    [0, 0.04], [0.8, 0], [1.12, 0.08], [1.22, 0.26], [1.15, 0.44], [0.85, 0.54], [0.35, 0.56], [0, 0.52],
  ], 64), cushion);
  b.add('cushion_piping', xform(torus(1.2, 0.028, 72, 8), { t: [0, 0.27, 0] }), gold);
  b.add('cushion_button', xform(ellipsoid(0.07, 0.05, 0.07, 14, 8), { t: [0, 0.52, 0] }), gold);

  // Teardrop dome: round at the back, tapering into the fish snout at the front (+Z)
  const R = [0.82, 0.66, 0.8];
  const cy = 0.5 + R[1] * 0.82;
  const at = (p) => deformPoint(p, R);
  const lift = ([x, y, z]) => [x, y + cy, z];
  const grow = (k) => R.map((r) => r * k);
  const lens = (u) => Math.sqrt(Math.max(0, 1 - (2 * u - 1) ** 2));
  // patch/part builder: ellipsoid-based part → deformed → lifted
  const place = (part, k = 1) => xform(deform(part, grow(k)), { t: [0, cy, 0] });

  b.add('body', place(ellipsoid(R[0], R[1], R[2], 72, 44)), wood);

  // Carved fish on the right flank: dark carved outline, scaled body, smooth head.
  // u runs from the tail (back, 0) to the head (front, 1); the centre line climbs toward the tail.
  const thTail = -1.0, thHead = 1.15, thGill = 0.45;
  const centre = (u) => 0.42 - 0.62 * u;
  const half = (u, m) => m * (0.12 + 0.88 * Math.pow(lens(u * 0.92 + 0.04), 0.8));
  const uOf = (th) => (th - thTail) / (thHead - thTail);
  // yRange for a sub-range [t0, t1] of theta, expressed with the global fish parameter
  const sub = (t0, t1, m) => (u) => {
    const g = uOf(t0 + (t1 - t0) * u);
    return [centre(g) - half(g, m), centre(g) + half(g, m)];
  };
  b.add('fish_outline', place(ellipsoidPatch(...grow(1.02), thTail - 0.06, thHead + 0.05,
    sub(thTail - 0.06, thHead + 0.05, 0.5), 72, 10), 1.02), carved);
  b.add('fish_scales', place(ellipsoidPatch(...grow(1.035), thTail, thGill,
    sub(thTail, thGill, 0.4), 64, 10), 1.035), scales);
  b.add('fish_head', place(ellipsoidPatch(...grow(1.04), thGill, thHead,
    sub(thGill, thHead, 0.4), 40, 10), 1.04), wood);

  // point on the finished surface at azimuth th / height fraction yf (pushed out by k)
  const surf = (th, yf, k = 1.0) => {
    const sp = Math.sqrt(1 - yf * yf);
    return lift(at([R[0] * sp * Math.cos(th) * k, R[1] * yf, R[2] * sp * Math.sin(th) * k]));
  };
  const faceOut = (th) => ({ ry: Math.PI / 2 - th });

  // Gill lines: three carved arcs behind the head
  [0.5, 0.4, 0.3].forEach((th, i) => {
    const pts = [];
    for (let k = 0; k <= 10; k++) {
      const yf = -0.3 + (k / 10) * 0.55;
      pts.push(surf(th - 0.05 * Math.sin((k / 10) * Math.PI), yf, 1.045));
    }
    b.add(`gill${i}`, tube(pts, (t) => 0.014 * Math.sin(Math.PI * Math.min(1, t * 0.85 + 0.08)) + 0.004), carved);
  });

  // Head: snout, jaws, nostrils, brow, eye, whiskers
  const tip = lift(at([0, -0.12 * R[1], R[2] * 0.985]));
  b.add('mouth', xform(ellipsoid(0.18, 0.032, 0.1, 16, 8), { t: [tip[0], tip[1] - 0.06, tip[2] - 0.03] }), dark);
  b.add('upper_jaw', xform(ellipsoid(0.19, 0.055, 0.15, 16, 10), { t: [tip[0], tip[1] + 0.0, tip[2] - 0.08] }), wood);
  b.add('lower_jaw', xform(ellipsoid(0.17, 0.05, 0.13, 16, 10), { t: [tip[0], tip[1] - 0.13, tip[2] - 0.09] }), wood);
  for (const sx of [-1, 1]) {
    b.add(`nostril${sx}`, xform(ellipsoid(0.03, 0.024, 0.03, 8, 6), { t: [tip[0] + sx * 0.08, tip[1] + 0.11, tip[2] - 0.16] }), dark);
    // whiskers curling forward and out
    const w = [[0, 0.02, -0.06], [sx * 0.16, 0.05, 0.14], [sx * 0.34, -0.04, 0.2]];
    b.add(`whisker${sx}`, tube(bezier(
      [tip[0] + sx * 0.12 + w[0][0], tip[1] - 0.02, tip[2] + w[0][2]],
      [tip[0] + w[1][0] + sx * 0.12, tip[1] + w[1][1], tip[2] + w[1][2]],
      [tip[0] + w[2][0] + sx * 0.12, tip[1] + w[2][1] - 0.1, tip[2] + w[2][2]]), (t) => 0.024 * (1 - t) + 0.006, 8), carved);
  }
  const eyeTh = 0.88, eyeY = 0.1;
  const eyeP = surf(eyeTh, eyeY, 1.045);
  b.add('eye_ring', xform(torus(0.07, 0.02, 24, 8), { rx: Math.PI / 2, ...faceOut(eyeTh), t: eyeP }), carved);
  b.add('eye', xform(ellipsoid(0.045, 0.045, 0.025, 12, 8), { ...faceOut(eyeTh), t: eyeP }), dark);
  b.add('eye_glint', xform(ellipsoid(0.012, 0.012, 0.008, 6, 4), {
    ...faceOut(eyeTh), t: [eyeP[0] + 0.02, eyeP[1] + 0.02, eyeP[2] + 0.015],
  }), cream);
  const brow = [];
  for (let k = 0; k <= 10; k++) {
    const t = k / 10;
    brow.push(surf(eyeTh + 0.14 - 0.34 * t, eyeY + 0.2 + 0.09 * Math.sin(Math.PI * t), 1.05));
  }
  b.add('brow', tube(brow, (t) => 0.02 * Math.sin(Math.PI * (t * 0.9 + 0.05)) + 0.004), carved);

  // Tail: a fan of three flat fins curling off the top-back end of the fish
  const tp = surf(thTail - 0.05, 0.5, 1.02);
  [-0.6, 0, 0.6].forEach((rz, i) => {
    const fin = xform(xform(ellipsoid(0.03, 0.14, 0.08, 12, 8), { t: [0, 0.1, 0], rz }), { ...faceOut(thTail - 0.05), t: tp });
    b.add(`tail${i}`, fin, scales);
  });
  // Pectoral fin below the head
  const fp = surf(0.1, -0.22, 1.03);
  b.add('fin', xform(xform(ellipsoid(0.04, 0.13, 0.22, 12, 8), { t: [0, -0.02, 0.0], rz: 0.3 }), { ...faceOut(0.1), t: fp }), scales);

  // Round hole with a raised rim on the left-back flank
  const holeTh = [Math.PI + 0.05, Math.PI + 0.4];
  b.add('hole_rim', place(ellipsoidPatch(...grow(1.03), holeTh[0] - 0.06, holeTh[1] + 0.06,
    (u) => [0.02 - 0.3 * lens(u), 0.02 + 0.3 * lens(u)], 24, 8), 1.03), carved);
  b.add('hole', place(ellipsoidPatch(...grow(1.045), ...holeTh,
    (u) => [0.02 - 0.23 * lens(u), 0.02 + 0.23 * lens(u)], 24, 8), 1.045), dark);

  // The mallet is drawn by the app (2D overlay that follows the mouse / touch).

  await b.write('mo.glb');
}

// ── Lư hương: bronze censer with N incense sticks ─────────────────

async function buildIncense() {
  const b = new Builder();
  const bronze = b.material('bronze', { color: [0.55, 0.32, 0.1], metal: 0.55, rough: 0.5 });
  const gold = b.material('gold', { color: [0.95, 0.75, 0.3], metal: 0.9, rough: 0.3 });
  const ash = b.material('ash', { color: [0.32, 0.3, 0.28], rough: 1 });

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

  // The incense sticks, their glowing tips, ash and smoke are drawn by the app (lib/features/incense/incense_effects.dart)
  // so they can burn down and emit smoke from the right place.

  await b.write('incense_censer.glb');
}

async function main() {
  await buildMo();
  await buildIncense();
}

main().catch((e) => { console.error(e); process.exit(1); });
