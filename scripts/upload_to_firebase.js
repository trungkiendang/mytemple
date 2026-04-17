const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 1. Tải Service Account Key từ Firebase Console
// Project Settings -> Service accounts -> Generate new private key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadData() {
  const dataPath = path.join(__dirname, '../docs/firebase_seed.json');
  const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

  console.log('--- Bắt đầu đẩy dữ liệu Kinh văn ---');
  for (const scripture of data.scriptures) {
    await db.collection('scriptures').doc(scripture.id).set({
      title: scripture.title,
      category: scripture.category,
      content: scripture.content,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`✅ Đã cập nhật: ${scripture.title}`);
  }

  console.log('\n--- Cập nhật thông số hệ thống ---');
  await db.collection('stats').doc('global_stats').set({
    total_taps: data.stats.global_taps,
    online_users: data.stats.online_users
  }, { merge: true });
  console.log('✅ Đã cập nhật thông số Global Stats');

  console.log('\n🎉 Hoàn tất! Dữ liệu đã sẵn sàng trên Firebase.');
  process.exit();
}

uploadData().catch(err => {
  console.error('❌ Lỗi:', err);
  process.exit(1);
});
