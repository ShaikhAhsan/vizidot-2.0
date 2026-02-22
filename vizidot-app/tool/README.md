# Vizidot tools

## Fix iOS app icon alpha (App Store validation)

If App Store Connect rejects the build with:

> Invalid large app icon. The large app icon in the asset catalog in "Runner.app" can't be transparent or contain an alpha channel.

run from the **vizidot-app** directory:

```bash
dart run tool/fix_ios_icon_alpha.dart
```

This composites `assets/icons/app_icon.png` onto an opaque white 1024×1024 background and overwrites `ios/Runner/Assets.xcassets/AppIcon.appiconset/icon-ios-1024x1024.png` so the large app icon has no alpha channel. Then re-archive and upload.

---

## Upload Symbols (dSYM) warnings for Agora

When uploading to App Store Connect you may see "Upload Symbols Failed" for Agora (e.g. `AgoraRtcKit.framework`, `AgoraAiEchoCancellationExtension.framework`, etc.). These are **warnings**, not validation errors: the Agora SDK does not ship dSYM files for its binary frameworks, so Xcode cannot upload them. Your app can still be submitted and approved. You can safely ignore these messages. If you need symbolication for Agora crashes, check Agora’s docs for any separate dSYM or symbol package.
