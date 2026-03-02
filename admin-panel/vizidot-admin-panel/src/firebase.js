import { initializeApp } from 'firebase/app';
import {
  getAnalytics,
  isSupported as analyticsIsSupported
} from 'firebase/analytics';
import { getAuth } from 'firebase/auth';

const requiredKeys = [
  'REACT_APP_FIREBASE_API_KEY',
  'REACT_APP_FIREBASE_AUTH_DOMAIN',
  'REACT_APP_FIREBASE_PROJECT_ID',
  'REACT_APP_FIREBASE_STORAGE_BUCKET',
  'REACT_APP_FIREBASE_MESSAGING_SENDER_ID',
  'REACT_APP_FIREBASE_APP_ID'
];

const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
  storageBucket: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.REACT_APP_FIREBASE_APP_ID,
  ...(process.env.REACT_APP_FIREBASE_MEASUREMENT_ID
    ? { measurementId: process.env.REACT_APP_FIREBASE_MEASUREMENT_ID }
    : {})
};

requiredKeys.forEach((key) => {
  if (!process.env[key]) {
    // eslint-disable-next-line no-console
    console.warn(
      `[Firebase] Missing environment variable ${key}. Check your .env configuration.`
    );
  }
});

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

let analytics;
if (typeof window !== 'undefined') {
  analyticsIsSupported()
    .then((supported) => {
      if (supported) {
        analytics = getAnalytics(app);
      }
    })
    .catch(() => {
      // ignore analytics failures
    });
}

export { app, auth, analytics };

