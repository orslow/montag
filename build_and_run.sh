#!/bin/bash
cd "$(dirname "$0")"

echo "Building montag app..."
xcodebuild -project montag.xcodeproj -configuration Debug clean build

if [ $? -eq 0 ]; then
    echo "Build successful! Copying AppIcon.icns..."
    mkdir -p build/Debug/montag.app/Contents/Resources
    cp AppIcon.icns build/Debug/montag.app/Contents/Resources/
    
    echo "Killing any existing montag processes..."
    pkill -f montag 2>/dev/null || true
    
    echo "Opening montag app..."
    open build/Debug/montag.app
    echo "Done!"
else
    echo "Build failed!"
    exit 1
fi