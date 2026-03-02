const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let db, auth;

function fixPrivateKey(parsed) {
  if (!parsed.private_key || typeof parsed.private_key !== 'string') return parsed;
  let key = parsed.private_key;
  // Replace literal \n (backslash-n) with real newlines
  if (key.includes('\\n')) key = key.replace(/\\n/g, '\n');
  // If key has no newlines but has PEM markers, restore 64-char line breaks
  if (!key.includes('\n') && key.includes('-----BEGIN')) {
    const header = '-----BEGIN PRIVATE KEY-----';
    const footer = '-----END PRIVATE KEY-----';
    const body = key.replace(header, '').replace(footer, '').replace(/\s/g, '');
    const lines = [];
    for (let i = 0; i < body.length; i += 64) lines.push(body.substring(i, i + 64));
    key = header + '\n' + lines.join('\n') + '\n' + footer;
  }
  parsed.private_key = key;
  return parsed;
}

const initializeFirebase = async () => {
  try {
    if (admin.apps.length > 0) {
      console.log('Firebase already initialized');
      db = admin.firestore();
      auth = admin.auth();
      return { admin, db, auth };
    }

    const serviceAccount = (() => {
      // Prefer file path - avoids all .env escaping issues
      const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS;
      if (filePath) {
        const resolved = path.isAbsolute(filePath) ? filePath : path.resolve(process.cwd(), filePath);
        if (fs.existsSync(resolved)) {
          const parsed = JSON.parse(fs.readFileSync(resolved, 'utf8'));
          return fixPrivateKey(parsed);
        }
      }

      const rawValue = (process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '').trim();
      if (!rawValue) {
        throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH is required.');
      }

      const maybeDecoded = rawValue.startsWith('{')
        ? rawValue
        : Buffer.from(rawValue, 'base64').toString('utf8');

      try {
        const parsed = JSON.parse(maybeDecoded);
        return fixPrivateKey(parsed);
      } catch (error) {
        console.error('Invalid FIREBASE_SERVICE_ACCOUNT_JSON. Use base64 or FIREBASE_SERVICE_ACCOUNT_PATH=.');
        throw error;
      }
    })();
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://vizidot-4b492.firebaseio.com',
      projectId: process.env.FIREBASE_PROJECT_ID || 'vizidot-4b492',
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'vizidot-4b492.appspot.com'
    });

    db = admin.firestore();
    auth = admin.auth();

    // Configure Firestore settings
    db.settings({
      ignoreUndefinedProperties: true
    });

    console.log('Firebase Admin SDK initialized successfully');
    return { admin, db, auth };
  } catch (error) {
    console.error('Error initializing Firebase:', error);
    throw error;
  }
};

const getFirebaseInstance = () => {
  if (!db || !auth) {
    throw new Error('Firebase not initialized. Call initializeFirebase() first.');
  }
  return { admin, db, auth };
};

// Firebase utility functions
const firebaseUtils = {
  // Create a new document with auto-generated ID
  createDocument: async (collection, data) => {
    const { db } = getFirebaseInstance();
    const docRef = await db.collection(collection).add({
      ...data,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });
    return docRef;
  },

  // Update a document
  updateDocument: async (collection, docId, data) => {
    const { db } = getFirebaseInstance();
    await db.collection(collection).doc(docId).update({
      ...data,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });
  },

  // Get a document
  getDocument: async (collection, docId) => {
    const { db } = getFirebaseInstance();
    const doc = await db.collection(collection).doc(docId).get();
    return doc.exists ? { id: doc.id, ...doc.data() } : null;
  },

  // Get all documents in a collection
  getCollection: async (collection, orderBy = null, limit = null) => {
    const { db } = getFirebaseInstance();
    let query = db.collection(collection);
    
    if (orderBy) {
      query = query.orderBy(orderBy.field, orderBy.direction || 'asc');
    }
    
    if (limit) {
      query = query.limit(limit);
    }
    
    const snapshot = await query.get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  },

  // Delete a document
  deleteDocument: async (collection, docId) => {
    const { db } = getFirebaseInstance();
    await db.collection(collection).doc(docId).delete();
  },

  // Set up real-time listener
  setupRealtimeListener: (collection, docId, callback) => {
    const { db } = getFirebaseInstance();
    return db.collection(collection).doc(docId).onSnapshot(callback);
  },

  // Batch operations
  batch: () => {
    const { db } = getFirebaseInstance();
    return db.batch();
  },

  // Create timestamp
  timestamp: () => {
    return admin.firestore.FieldValue.serverTimestamp();
  },

  // Array operations
  arrayUnion: (...elements) => {
    return admin.firestore.FieldValue.arrayUnion(...elements);
  },

  arrayRemove: (...elements) => {
    return admin.firestore.FieldValue.arrayRemove(...elements);
  },

  // Increment operations
  increment: (value) => {
    return admin.firestore.FieldValue.increment(value);
  }
};

module.exports = {
  initializeFirebase,
  getFirebaseInstance,
  firebaseUtils
};

