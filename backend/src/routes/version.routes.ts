import type { Request, Response } from 'express';
import { Router } from 'express';

export const versionRoutes = Router();

/**
 * In-app update JSON for GET /api/app/ and /api/app/version
 *
 * On Render, set (example aligned with app pubspec 0.1.1+2):
 *   LATEST_APP_VERSION=0.1.1
 *   LATEST_APP_VERSION_CODE=2
 *   APP_UPDATE_URL=https://appdistribution.firebase.google.com/testerapps/yourapp
 *   FORCE_UPDATE=false
 *   RELEASE_NOTES=Fixed server connection, login, OTP, and booking issues
 */
const APP_VERSION_INFO = {
  latestVersion: process.env.LATEST_APP_VERSION ?? '0.1.1',
  latestVersionCode: Number(process.env.LATEST_APP_VERSION_CODE ?? 2),
  updateUrl: process.env.APP_UPDATE_URL ?? 'https://appdistribution.firebase.google.com/testerapps/yourapp',
  forceUpdate: process.env.FORCE_UPDATE === 'true',
  releaseNotes:
    process.env.RELEASE_NOTES ??
    'Fixed server connection, login, OTP, and booking issues',
};

const sendVersion = (_req: Request, res: Response) => {
  res.json(APP_VERSION_INFO);
};

versionRoutes.get('/', sendVersion);
versionRoutes.get('/version', sendVersion);
