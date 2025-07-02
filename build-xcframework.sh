#!/bin/bash

SCHEME_NAME="union-buttons"
FRAMEWORK_NAME="UnionButtons"
BUILD_DIR="./build"

echo "Building Swift Package for XCFramework..."

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Building for iOS device..."
xcodebuild build \
  -scheme "$SCHEME_NAME" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$BUILD_DIR/ios" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

echo "Building for iOS Simulator..."
xcodebuild build \
  -scheme "$SCHEME_NAME" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$BUILD_DIR/ios-simulator" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

echo "Looking for built frameworks..."
IOS_FRAMEWORK=$(find "$BUILD_DIR/ios" -name "$FRAMEWORK_NAME.framework" -type d | head -1)
SIMULATOR_FRAMEWORK=$(find "$BUILD_DIR/ios-simulator" -name "$FRAMEWORK_NAME.framework" -type d | head -1)

echo "Found frameworks:"
echo "iOS: $IOS_FRAMEWORK"
echo "Simulator: $SIMULATOR_FRAMEWORK"

echo "Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "$IOS_FRAMEWORK" \
  -framework "$SIMULATOR_FRAMEWORK" \
  -output "./$FRAMEWORK_NAME.xcframework"

if [ $? -eq 0 ]; then
    echo "XCFramework created successfully!"
    
    swift package compute-checksum "$FRAMEWORK_NAME.xcframework.zip"
else
    echo "❌ Failed to create XCFramework"
    exit 1
fi
