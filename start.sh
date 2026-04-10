#!/bin/bash
set -e

echo "🚀 Starting Click2Fix Backend..."

cd backend
node dist/server.js
