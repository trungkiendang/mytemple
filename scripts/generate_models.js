const { Document, Accessor, Primitive, Mesh, Node, Material, NodeIO } = require('@gltf-transform/core');
const fs = require('fs');
const path = require('path');

const ASSETS_DIR = path.resolve(__dirname, '..', 'assets', 'models');

function createRevolvedGeometry(profile, segments, withCap = false) {
  const positions = [];
  const normals = [];
  const uvs = [];
  const n = profile.length;
  const totalSegments = segments;

  for (let i = 0; i <= totalSegments; i++) {
    const theta = (i / totalSegments) * 2 * Math.PI;
    const sinT = Math.sin(theta);
    const cosT = Math.cos(theta);
    for (let j = 0; j < n; j++) {
      const [rx, ry] = profile[j];
      positions.push(rx * cosT, ry, rx * sinT);
      normals.push(cosT, 0, sinT);
      uvs.push(i / totalSegments, j / (n - 1));
    }
  }

  const indices = [];
  for (let i = 0; i < totalSegments; i++) {
    for (let j = 0; j < n - 1; j++) {
      const a = i * n + j;
      const b = i * n + j + 1;
      const c = (i + 1) * n + j;
      const d = (i + 1) * n + j + 1;
      indices.push(a, c, b);
      indices.push(b, c, d);
    }
  }

  if (withCap && profile[0][0] === 0) {
    const centerIdx = positions.length / 3;
    positions.push(0, profile[0][1], 0);
    normals.push(0, -1, 0);
    for (let i = 0; i <= totalSegments; i++) {
      const theta = (i / totalSegments) * 2 * Math.PI;
      const idx = i * n;
      if (i < totalSegments) {
        const nextIdx = (i + 1) * n;
        indices.push(centerIdx, nextIdx, idx);
      }
    }
  }

  return { positions, normals, uvs, indices };
}

function createCylinderGeometry(radiusBottom, radiusTop, height, segments, heightSegments) {
  const positions = [];
  const normals = [];
  const indices = [];

  for (let j = 0; j <= heightSegments; j++) {
    const y = (j / heightSegments) * height - height / 2;
    const r = radiusBottom + (radiusTop - radiusBottom) * (j / heightSegments);
    for (let i = 0; i <= segments; i++) {
      const theta = (i / segments) * 2 * Math.PI;
      const x = r * Math.cos(theta);
      const z = r * Math.sin(theta);
      positions.push(x, y, z);
      const len = Math.sqrt(x * x + height * height + z * z);
      const ny = (radiusTop - radiusBottom) / height;
      const nx = x / Math.sqrt(x * x + z * z);
      const nz = z / Math.sqrt(x * x + z * z);
      const nl = Math.sqrt(nx * nx + ny * ny + nz * nz);
      normals.push(nx / nl, ny / nl, nz / nl);
    }
  }

  for (let j = 0; j < heightSegments; j++) {
    for (let i = 0; i < segments; i++) {
      const a = j * (segments + 1) + i;
      const b = a + 1;
      const c = (j + 1) * (segments + 1) + i;
      const d = c + 1;
      indices.push(a, c, b);
      indices.push(b, c, d);
    }
  }

  return { positions, normals, indices: indices };
}

function createSphereGeometry(radius, latSegs, lonSegs, startLat = 0, endLat = Math.PI) {
  const positions = [];
  const normals = [];
  const indices = [];

  for (let lat = 0; lat <= latSegs; lat++) {
    const theta = startLat + (lat / latSegs) * (endLat - startLat);
    const sinT = Math.sin(theta);
    const cosT = Math.cos(theta);
    for (let lon = 0; lon <= lonSegs; lon++) {
      const phi = (lon / lonSegs) * 2 * Math.PI;
      const x = radius * Math.sin(phi) * sinT;
      const y = radius * cosT;
      const z = radius * Math.cos(phi) * sinT;
      positions.push(x, y, z);
      const len = Math.sqrt(x * x + y * y + z * z);
      normals.push(x / len, y / len, z / len);
    }
  }

  for (let lat = 0; lat < latSegs; lat++) {
    for (let lon = 0; lon < lonSegs; lon++) {
      const a = lat * (lonSegs + 1) + lon;
      const b = a + 1;
      const c = (lat + 1) * (lonSegs + 1) + lon;
      const d = c + 1;
      indices.push(a, c, b);
      indices.push(b, c, d);
    }
  }

  return { positions, normals, indices };
}

function buildMesh(doc, geometry, material) {
  const posArr = new Float32Array(geometry.positions);
  const normArr = new Float32Array(geometry.normals);
  const idxArr = geometry.indices.length < 65536
    ? new Uint16Array(geometry.indices)
    : new Uint32Array(geometry.indices);

  const posAcc = doc.createAccessor()
    .setArray(posArr)
    .setType(Accessor.Type.VEC3);
  const normAcc = doc.createAccessor()
    .setArray(normArr)
    .setType(Accessor.Type.VEC3);
  const idxAcc = doc.createAccessor()
    .setArray(idxArr)
    .setType(Accessor.Type.SCALAR);

  const prim = doc.createPrimitive()
    .setIndices(idxAcc)
    .setAttribute('POSITION', posAcc)
    .setAttribute('NORMAL', normAcc);

  if (material) prim.setMaterial(material);

  const mesh = doc.createMesh();
  mesh.addPrimitive(prim);
  return mesh;
}

async function generateBell() {
  const doc = new Document();
  doc.createBuffer().setURI('mo.bin');

  const woodColor = [0.45, 0.25, 0.1];
  const woodMat = doc.createMaterial()
    .setBaseColorFactor(woodColor)
    .setMetallicFactor(0.0)
    .setRoughnessFactor(0.8);

  // Bell body profile (revolved) - wooden fish/bowl shape
  const profile = [
    [0.0, 0.0],
    [0.5, 0.0],
    [0.7, 0.02],
    [0.85, 0.05],
    [0.95, 0.12],
    [1.0, 0.25],
    [0.98, 0.4],
    [0.9, 0.55],
    [0.75, 0.68],
    [0.55, 0.78],
    [0.3, 0.85],
    [0.1, 0.88],
    [0.0, 0.9],
  ];

  const bodyGeo = createRevolvedGeometry(profile, 32, true);
  const bodyMesh = buildMesh(doc, bodyGeo, woodMat);

  // Knob on top
  const knobProfile = [
    [0.0, 0.9],
    [0.08, 0.9],
    [0.06, 0.95],
    [0.03, 0.98],
    [0.0, 1.0],
  ];
  const knobGeo = createRevolvedGeometry(knobProfile, 16);
  const knobMesh = buildMesh(doc, knobGeo, woodMat);

  const bodyNode = doc.createNode()
    .setMesh(bodyMesh)
    .setTranslation([0, 0, 0]);

  const knobNode = doc.createNode()
    .setMesh(knobMesh)
    .setTranslation([0, 0, 0]);

  const rootNode = doc.createNode();
  rootNode.addChild(bodyNode);
  rootNode.addChild(knobNode);

  doc.createScene().addChild(rootNode);

  const io = new NodeIO();
  const outPath = path.join(ASSETS_DIR, 'mo.glb');
  await io.write(outPath, doc);
  console.log('✓ Generated bell model:', outPath);
}

async function generateIncense() {
  const doc = new Document();
  doc.createBuffer().setURI('incense_bowl.bin');

  // Brown for bowl and stick
  const brownMat = doc.createMaterial()
    .setBaseColorFactor([0.35, 0.2, 0.08])
    .setMetallicFactor(0.0)
    .setRoughnessFactor(0.9);

  // Red/orange for the burning tip
  const tipMat = doc.createMaterial()
    .setBaseColorFactor([0.9, 0.2, 0.05])
    .setEmissiveFactor([0.6, 0.1, 0.0])
    .setMetallicFactor(0.0)
    .setRoughnessFactor(0.7);

  // Bowl at the bottom
  const bowlProfile = [
    [0.0, 0.0],
    [0.25, 0.0],
    [0.3, 0.02],
    [0.35, 0.05],
    [0.32, 0.08],
    [0.25, 0.1],
    [0.0, 0.12],
  ];
  const bowlGeo = createRevolvedGeometry(bowlProfile, 24, true);
  const bowlMesh = buildMesh(doc, bowlGeo, brownMat);

  // Incense stick - thin cylinder going up from bowl center
  const stickGeo = createCylinderGeometry(0.015, 0.012, 0.7, 12, 8);
  const stickMesh = buildMesh(doc, stickGeo, brownMat);

  // Burning tip - small sphere on top of stick
  const tipGeo = createSphereGeometry(0.025, 8, 8);
  const tipMesh = buildMesh(doc, tipGeo, tipMat);

  const bowlNode = doc.createNode()
    .setMesh(bowlMesh)
    .setTranslation([0, 0, 0]);

  const stickNode = doc.createNode()
    .setMesh(stickMesh)
    .setTranslation([0, 0.12 + 0.35, 0]);

  const tipNode = doc.createNode()
    .setMesh(tipMesh)
    .setTranslation([0, 0.12 + 0.7, 0]);

  const rootNode = doc.createNode();
  rootNode.addChild(bowlNode);
  rootNode.addChild(stickNode);
  rootNode.addChild(tipNode);

  doc.createScene().addChild(rootNode);

  const io = new NodeIO();
  const outPath = path.join(ASSETS_DIR, 'incense_bowl.glb');
  await io.write(outPath, doc);
  console.log('✓ Generated incense model:', outPath);
}

async function main() {
  fs.mkdirSync(ASSETS_DIR, { recursive: true });
  await generateBell();
  await generateIncense();
  console.log('Done!');
}

main().catch(e => {
  console.error('Error:', e.message);
  process.exit(1);
});
