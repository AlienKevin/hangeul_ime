#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "$BASH_SOURCE")/.."; pwd)"
TARGET="Hangeul"
WORKSPACE="$PROJECT_ROOT/${TARGET}.xcodeproj/project.xcworkspace"

EXPORT_PATH="$PROJECT_ROOT/dist"
EXPORT_ARCHIVE="$EXPORT_PATH/archive.xcarchive"
EXPORT_APP="$EXPORT_PATH/$TARGET.app"
EXPORT_ZIP="$EXPORT_PATH/$TARGET.zip"
EXPORT_INSTALLER="$EXPORT_PATH/HangeulInstaller.pkg"
EXPORT_INSTALLER_ZIP="$EXPORT_PATH/HangeulInstaller.zip"

echo "PROJECT_ROOT=$PROJECT_ROOT"