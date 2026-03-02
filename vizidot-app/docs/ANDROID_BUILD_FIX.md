# Android build and run fixes

## 1. CMake 3.22.1 and Ninja required (Agora native build)

The `agora_rtc_engine` plugin needs **CMake 3.22.1** and **Ninja** for the native build. Gradle looks for them under the Android SDK.

**Install via Android Studio (recommended):**

1. Open **Android Studio**.
2. **Settings/Preferences → Appearance & Behavior → System Settings → Android SDK**.
3. Open the **SDK Tools** tab.
4. Enable **Show Package Details** (bottom right).
5. Check **CMake** and select version **3.22.1**.
6. Click **Apply** and let it download and install.

That installs CMake (and usually Ninja) to `~/Library/Android/sdk/cmake/3.22.1/`.

**If you see "Could not find Ninja":**  
A local Ninja binary was added at `android/.ninja-bin/ninja`. Run the app with:

```bash
export PATH="$(pwd)/android/.ninja-bin:$PATH"
flutter run -d R5CY909LRXP
```

Or fix Homebrew permissions and install Ninja:  
`sudo chown -R $(whoami) /opt/homebrew` then `brew install ninja`.

---

## 2. CMake install failed (ZipException: invalid distance code)

If the automatic CMake download fails with a zip error, remove the partial install and install via Android Studio as above:

```bash
rm -rf ~/Library/Android/sdk/cmake/3.22.1
```

Then install **CMake 3.22.1** from Android Studio → SDK Manager → SDK Tools (see above).

---

## Runtime: NoSuchMethodError `_Qgj` and snaplite_lib "Failed to allocate tensors"

These often come from native/ML code in **agora_rtc_engine** (or another plugin that uses TensorFlow Lite / similar):

- **snaplite_lib** – native library failing to allocate tensors (memory or compatibility).
- **_Qgj** – looks like a minified or generated symbol; can be from a plugin’s Dart/native bridge.

**Steps to try:**

1. **Clean rebuild**
   ```bash
   cd vizidot-app
   flutter clean
   flutter pub get
   flutter run -d R5CY909LRXP
   ```

2. **If it still crashes:** Ensure you’re in **debug** (no `--release`). If the crash is only in release, it may be tree-shaking/obfuscation.

3. **Agora:** The app uses `agora_rtc_engine` for live streaming. If the crash happens at startup before you open live, consider **lazy-initializing** Agora only when entering the live flow (see `CRASH_DIAGNOSIS.md`).

4. **Device:** "Failed to allocate tensors" can be device/memory related. Test on another device or emulator to see if it’s specific to SM S938B / Android 16.
