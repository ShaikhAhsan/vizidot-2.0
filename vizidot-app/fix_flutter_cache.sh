#!/bin/bash
# Fix "Permission denied" on Flutter SDK (cache, packages, etc.).
# Run once: ./fix_flutter_cache.sh
# You will be prompted for your password.

set -e
FLUTTER_ROOT="/opt/homebrew/share/flutter"
if [ ! -d "$FLUTTER_ROOT" ]; then
  echo "Flutter not found at $FLUTTER_ROOT"
  exit 1
fi
echo "Fixing ownership of entire Flutter SDK for user $(whoami)..."
sudo chown -R "$(whoami):staff" "$FLUTTER_ROOT"
echo "Done. You can now run: flutter run -d android"
