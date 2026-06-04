const { NodeIO } = require('@gltf-transform/core');
const PNG = require('pngjs').PNG;

const io = new NodeIO();
const ASSETS = '/Volumes/KunX/Workspace/mytemple/assets/models';

// ── Wood Texture Generator ────────────────────────────────────────
function createWoodTexture(doc) {
  const width = 256, height = 256;
  const png = new PNG({ width, height });
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const idx = (y * width + x) * 4;
      const grain = Math.sin(y * 0.08 + Math.sin(x * 0.04 + y * 0.02) * 2) * 0.12 + 0.78;
      const knot = Math.exp(-((x - 128) ** 2 + (y - 90) ** 2) / 1500) * 0.3;
      const val = Math.min(255, Math.max(0, Math.floor((grain - knot + Math.random() * 0.04) * 200)));
      png.data[idx] = Math.min(255, Math.floor(val * 1.1));
      png.data[idx + 1] = Math.floor(val * 0.65);
      png.data[idx + 2] = Math.floor(val * 0.25);
      png.data[idx + 3] = 255;
    }
  }
  const tex = doc.createTexture('wood_grain');
  tex.setImage(new Uint8Array(PNG.sync.write(png)));
  tex.setMimeType('image/png');
  return tex;
}

// ── Improve Bell Model ─────────────────────────────────────────────
async function improveBell() {
  const doc = await io.read(`${ASSETS}/mo.glb`);
  const tex = createWoodTexture(doc);

  const mat = doc.getRoot().listMaterials()[0] || doc.createMaterial('wood_bell');
  mat.setName('wood_bell');
  mat.setBaseColorTexture(tex);
  mat.setBaseColorFactor([1, 1, 1, 1]);
  mat.setMetallicFactor(0.02);
  mat.setRoughnessFactor(0.6);
  mat.setEmissiveFactor([0, 0, 0]);

  await io.write(`${ASSETS}/mo.glb`, doc);
  console.log('✓ Bell model improved');
}

// ── Stick Position Layouts ────────────────────────────────────────
const STICK_LAYOUTS = {
  1: [[0, 0]],
  3: [[-0.08, 0], [0.08, 0], [0, 0.08]],
  5: [[-0.08, -0.08], [0.08, -0.08], [-0.08, 0.08], [0.08, 0.08], [0, 0]]
};

// ── Create Incense Variants ────────────────────────────────────────
async function createIncenseVariant(count) {
  // Read source model
  const doc = await io.read(`${ASSETS}/incense_bowl.glb`);
  const root = doc.getRoot();

  // Create wood texture
  const tex = createWoodTexture(doc);

  // ── Update existing materials ──
  const srcMats = root.listMaterials();
  srcMats[0].setName('bowl_wood');
  srcMats[0].setBaseColorTexture(tex);
  srcMats[0].setBaseColorFactor([0.9, 0.85, 0.7, 1]);
  srcMats[0].setMetallicFactor(0.0);
  srcMats[0].setRoughnessFactor(0.8);

  // Update stick material (also dark brown, make it lighter)
  // Both bowl and stick used srcMats[0]. Let's make a separate material for stick
  const stickMat = doc.createMaterial('stick');
  stickMat.setBaseColorFactor([0.82, 0.7, 0.45, 1]);
  stickMat.setMetallicFactor(0.0);
  stickMat.setRoughnessFactor(0.9);

  // Update ember material
  srcMats[1].setName('ember');
  srcMats[1].setBaseColorFactor([0.9, 0.15, 0.05, 1]);
  srcMats[1].setEmissiveFactor([3, 0.5, 0.1]);
  srcMats[1].setMetallicFactor(0.0);
  srcMats[1].setRoughnessFactor(0.4);

  // ── Remove existing stick/tip nodes (keep bowl) ──
  const scene = root.listScenes()[0];
  const children = [...scene.listChildren()];
  const bowlNode = children[0]; // first node is bowl at [0,0,0]
  // Clear scene children
  for (const child of children) {
    scene.removeChild(child);
  }
  scene.addChild(bowlNode);

  // ── Assign stick material ──
  // Find stick/tip meshes by vertex count
  const meshes = root.listMeshes();
  const stickMesh = meshes.find(m => m.listPrimitives()[0].getAttribute('POSITION').getCount() === 117);
  const tipMesh = meshes.find(m => m.listPrimitives()[0].getAttribute('POSITION').getCount() === 81);
  if (stickMesh) stickMesh.listPrimitives()[0].setMaterial(stickMat);
  if (tipMesh) tipMesh.listPrimitives()[0].setMaterial(srcMats[1]); // ember mat

  // ── Add stick nodes ──
  const positions = STICK_LAYOUTS[count] || STICK_LAYOUTS[1];
  for (const [dx, dz] of positions) {
    const sNode = doc.createNode();
    sNode.setMesh(stickMesh);
    sNode.setTranslation([dx, 0.47, dz]);
    scene.addChild(sNode);

    const tNode = doc.createNode();
    tNode.setMesh(tipMesh);
    tNode.setTranslation([dx, 0.82, dz]);
    scene.addChild(tNode);
  }

  const filename = `incense_${count}.glb`;
  await io.write(`${ASSETS}/${filename}`, doc);
  console.log(`✓ Created ${filename} with ${count} stick(s)`);
}

// ── Main ───────────────────────────────────────────────────────────
async function main() {
  await improveBell();
  for (const count of [1, 3, 5]) {
    await createIncenseVariant(count);
  }
  console.log('\nDone!');
}

main().catch(e => { console.error('✗ Error:', e.message); process.exit(1); });
