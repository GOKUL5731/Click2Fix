"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isFirebaseConfigured = isFirebaseConfigured;
exports.getFirebaseAuthClient = getFirebaseAuthClient;
exports.getFirebaseMessagingClient = getFirebaseMessagingClient;
exports.getFirebaseFirestoreClient = getFirebaseFirestoreClient;
const app_1 = require("firebase-admin/app");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const config_1 = require("../config");
let firebaseApp = null;
function getFirebaseOptions() {
    return {
        credential: (0, app_1.cert)({
            projectId: config_1.config.firebaseProjectId,
            clientEmail: config_1.config.firebaseClientEmail,
            privateKey: config_1.config.firebasePrivateKey
        }),
        ...(config_1.config.firebaseStorageBucket ? { storageBucket: config_1.config.firebaseStorageBucket } : {}),
        ...(config_1.config.firebaseDatabaseUrl ? { databaseURL: config_1.config.firebaseDatabaseUrl } : {})
    };
}
function ensureFirebaseApp() {
    if (!config_1.config.firebaseEnabled) {
        throw new Error('Firebase is not configured. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY.');
    }
    if (firebaseApp) {
        return firebaseApp;
    }
    firebaseApp = (0, app_1.getApps)()[0] ?? (0, app_1.initializeApp)(getFirebaseOptions());
    return firebaseApp;
}
function isFirebaseConfigured() {
    return config_1.config.firebaseEnabled;
}
function getFirebaseAuthClient() {
    return (0, auth_1.getAuth)(ensureFirebaseApp());
}
function getFirebaseMessagingClient() {
    return (0, messaging_1.getMessaging)(ensureFirebaseApp());
}
function getFirebaseFirestoreClient() {
    return (0, firestore_1.getFirestore)(ensureFirebaseApp());
}
