"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyFirebaseIdToken = verifyFirebaseIdToken;
const admin_1 = require("../firebase/admin");
const error_1 = require("../middleware/error");
async function verifyFirebaseIdToken(idToken) {
    if (!(0, admin_1.isFirebaseConfigured)()) {
        throw (0, error_1.httpError)(503, 'Firebase auth is not configured on backend');
    }
    try {
        const decoded = await (0, admin_1.getFirebaseAuthClient)().verifyIdToken(idToken, true);
        return {
            uid: decoded.uid,
            phone: decoded.phone_number,
            email: decoded.email,
            name: decoded.name,
            picture: decoded.picture
        };
    }
    catch (error) {
        const message = error instanceof Error ? error.message : 'Invalid Firebase ID token';
        throw (0, error_1.httpError)(401, 'Firebase authentication failed', { message });
    }
}
