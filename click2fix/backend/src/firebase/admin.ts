import { cert, getApps, initializeApp, type App, type AppOptions } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { config } from '../config';

let firebaseApp: App | null = null;

function getFirebaseOptions(): AppOptions {
  return {
    credential: cert({
      projectId: config.firebaseProjectId,
      clientEmail: config.firebaseClientEmail,
      privateKey: config.firebasePrivateKey
    }),
    ...(config.firebaseStorageBucket ? { storageBucket: config.firebaseStorageBucket } : {}),
    ...(config.firebaseDatabaseUrl ? { databaseURL: config.firebaseDatabaseUrl } : {})
  };
}

function ensureFirebaseApp(): App {
  if (!config.firebaseEnabled) {
    throw new Error('Firebase is not configured. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY.');
  }

  if (firebaseApp) {
    return firebaseApp;
  }

  firebaseApp = getApps()[0] ?? initializeApp(getFirebaseOptions());
  return firebaseApp;
}

export function isFirebaseConfigured() {
  return config.firebaseEnabled;
}

export function getFirebaseAuthClient() {
  return getAuth(ensureFirebaseApp());
}

export function getFirebaseMessagingClient() {
  return getMessaging(ensureFirebaseApp());
}

export function getFirebaseFirestoreClient() {
  return getFirestore(ensureFirebaseApp());
}
