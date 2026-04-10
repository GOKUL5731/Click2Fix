export type ActorRole = 'user' | 'worker' | 'admin';

export type AuthTokenPayload = {
  sub: string;
  role: ActorRole;
  phone?: string;
  email?: string;
  deviceId?: string;
  firebaseUid?: string;
};

export type NearbyWorker = {
  id: string;
  name: string;
  phone: string;
  category: string | null;
  rating: number;
  trust_score: number;
  current_latitude: number | null;
  current_longitude: number | null;
  distance_km: number;
  service_radius_km: number;
  availability: boolean;
};

export type AiDetectionResult = {
  category: string;
  confidence: number;
  urgency: 'low' | 'medium' | 'high' | 'critical';
  estimatedPriceMin: number;
  estimatedPriceMax: number;
  explanation: string[];
  modelVersion: string;
};

