import { Router } from 'express';

export const versionRoutes = Router();

// In-app update check endpoint
// Update latestVersion when you publish a new APK
const APP_VERSION_INFO = {
  latestVersion: process.env.LATEST_APP_VERSION ?? '0.1.0',
  latestVersionCode: Number(process.env.LATEST_APP_VERSION_CODE ?? 1),
  updateUrl: process.env.APP_UPDATE_URL ?? 'https://appdistribution.firebase.google.com/testerapps/yourapp',
  forceUpdate: process.env.FORCE_UPDATE === 'true',
  releaseNotes: process.env.RELEASE_NOTES ?? 'Bug fixes and performance improvements',
};

versionRoutes.get('/', (_req, res) => {
  res.json(APP_VERSION_INFO);
});
