import { getFirebaseAuthClient, isFirebaseConfigured } from '../firebase/admin';
import { httpError } from '../middleware/error';

export type FirebaseIdentity = {
  uid: string;
  phone?: string;
  email?: string;
  name?: string;
  picture?: string;
};

export async function verifyFirebaseIdToken(idToken: string): Promise<FirebaseIdentity> {
  if (!isFirebaseConfigured()) {
    throw httpError(503, 'Firebase auth is not configured on backend');
  }

  try {
    const decoded = await getFirebaseAuthClient().verifyIdToken(idToken, true);
    return {
      uid: decoded.uid,
      phone: decoded.phone_number,
      email: decoded.email,
      name: decoded.name,
      picture: decoded.picture
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Invalid Firebase ID token';
    throw httpError(401, 'Firebase authentication failed', { message });
  }
}
