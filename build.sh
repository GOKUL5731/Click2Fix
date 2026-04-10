#!/bin/bash
set -e

echo "================================"
echo "🔨 Building Click2Fix Backend..."
echo "================================"

cd backend

echo ""
echo "📦 Step 1: Installing dependencies (including devDependencies)..."
npm install
if [ $? -ne 0 ]; then
  echo "❌ npm install failed"
  exit 1
fi
echo "✅ Dependencies installed"

echo ""
echo "🔨 Step 2: Running TypeScript compilation..."
npm run build
if [ $? -ne 0 ]; then
  echo "❌ TypeScript compilation failed"
  exit 1
fi
echo "✅ TypeScript compilation successful"

echo ""
echo "✅ Build completed successfully!"
echo "================================"
