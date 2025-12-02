# Agora RTC Engine Permissions

This document lists all permissions required for Agora RTC Engine as per the official documentation.

## Android Permissions

All required permissions have been added to `android/app/src/main/AndroidManifest.xml`:

### Core Permissions (Required)
- ✅ `INTERNET` - Network access for video/audio streaming
- ✅ `READ_PHONE_STATE` - Required by Agora SDK
- ✅ `RECORD_AUDIO` - Audio recording for live streaming
- ✅ `CAMERA` - Video capture for live streaming
- ✅ `MODIFY_AUDIO_SETTINGS` - Audio routing configuration
- ✅ `ACCESS_WIFI_STATE` - Network state monitoring
- ✅ `ACCESS_NETWORK_STATE` - Network connectivity checking

### Bluetooth Permissions (Required for Bluetooth devices)
- ✅ `BLUETOOTH` - Basic Bluetooth support
- ✅ `BLUETOOTH_CONNECT` - Required for Android 12+ (API 31+) devices

### App-Specific Permissions
- ✅ `WAKE_LOCK` - Keep device awake during streaming
- ✅ `FOREGROUND_SERVICE` - Background service support
- ✅ `FOREGROUND_SERVICE_MEDIA_PLAYBACK` - Media playback service

**Reference:** [Agora Flutter SDK - pub.dev](https://pub.dev/packages/agora_rtc_engine)

## iOS Permissions

All required permissions have been added to `ios/Runner/Info.plist`:

### Privacy Permissions (Required)
- ✅ `NSCameraUsageDescription` - Camera access for live streaming
  - Value: "Camera Usage require for Live Streaming"
  
- ✅ `NSMicrophoneUsageDescription` - Microphone access for live streaming
  - Value: "Microphone Usage require for Live Streaming"

### Background Modes
- ✅ `UIBackgroundModes` with `audio` - Background audio support

**Reference:** 
- [Agora Flutter SDK - pub.dev](https://pub.dev/packages/agora_rtc_engine)
- [Agora iOS Setup Documentation](https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=ios#project-setup)

## Verification

To verify permissions are correctly configured:

### Android
1. Check `android/app/src/main/AndroidManifest.xml` contains all listed permissions
2. Test on Android device - permissions should be requested automatically
3. For Android 12+, ensure `BLUETOOTH_CONNECT` permission is granted

### iOS
1. Check `ios/Runner/Info.plist` contains `NSCameraUsageDescription` and `NSMicrophoneUsageDescription`
2. Test on iOS device - system will prompt for permissions on first use
3. Verify background audio mode is enabled if needed

## Notes

- All permissions are declared at the manifest/plist level
- Runtime permission requests are handled by `permission_handler` package in the app code
- Bluetooth permissions are only needed if users connect Bluetooth audio devices
- iOS permissions require user approval at runtime

