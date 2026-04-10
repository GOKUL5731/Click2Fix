#!/bin/bash
set -e

echo "🔨 Building Click2Fix Backend..."

cd backend

echo "📦 Installing dependencies (including devDependencies)..."
npm install

echo "🔨 Running TypeScript compilation..."
npm run build

echo "✅ Build completed successfully!"
