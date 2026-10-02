#!/bin/zsh
set -e

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Fetching Flutter dependencies..."
flutter pub get

echo "🍎 Installing CocoaPods dependencies..."
cd ios
pod install
cd ..

echo "✅ Clean and setup complete!"
