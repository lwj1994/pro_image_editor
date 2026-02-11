#!/bin/bash

# Exit on error
set -e

echo "🔍 Starting release checks..."

# 1. Check formatting
echo "📝 Checking formatting (line-length=80)..."
dart format --output=none --set-exit-if-changed --line-length=80 .

# 2. Analyze code
echo "🧐 Running flutter analyze..."
flutter analyze .

# 3. Run tests using ff
echo "🧪 Running tests..."
ff test

echo "✅ All checks passed! Ready for release."
