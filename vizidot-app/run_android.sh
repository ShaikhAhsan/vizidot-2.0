#!/bin/bash
# Run the app on the connected Android device (e.g. SM S938B).
# Requires: CMake 3.22.1 installed via Android Studio SDK Manager (SDK Tools → CMake 3.22.1).
# This script adds a local Ninja binary to PATH if "Could not find Ninja" occurred before.

set -e
cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
export PATH="${SCRIPT_DIR}/android/.ninja-bin:${PATH}"
flutter run -d R5CY909LRXP "$@"
