# Mobile Setup Guide for TickTask

This guide will help you set up and run the TickTask app on iOS and Android devices/emulators.

## Current Status

✅ **Flutter**: Installed and ready  
✅ **Chrome (Web)**: Available - You can run `flutter run -d chrome`  
❌ **iOS**: Xcode not fully installed  
❌ **Android**: Android SDK not found  

---

## Option 1: iOS Setup (macOS only)

### Step 1: Install Xcode
1. Open the **App Store** on your Mac
2. Search for "Xcode"
3. Click **Get** or **Install** (this is free but large ~15GB)
4. Wait for installation to complete

### Step 2: Configure Xcode
After installation, run these commands in Terminal:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Step 3: Install CocoaPods
```bash
sudo gem install cocoapods
```

### Step 4: Install iOS Dependencies
```bash
cd ios
pod install
cd ..
```

### Step 5: Open iOS Simulator
```bash
# List available simulators
xcrun simctl list devices available

# Or open Xcode and go to: Xcode > Open Developer Tool > Simulator
```

### Step 6: Run on iOS
```bash
# List available devices
flutter devices

# Run on iOS Simulator
flutter run -d ios

# Or specify a specific simulator
flutter run -d "iPhone 15 Pro"
```

---

## Option 2: Android Setup

### Step 1: Install Android Studio
1. Download from: https://developer.android.com/studio
2. Install Android Studio
3. Open Android Studio
4. Go to **Tools > SDK Manager**
5. Install:
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - At least one Android SDK Platform (e.g., Android 13.0 "Tiramisu")

### Step 2: Set Up Android Emulator
1. In Android Studio, go to **Tools > Device Manager**
2. Click **Create Device**
3. Select a device (e.g., Pixel 7)
4. Download a system image (e.g., Android 13)
5. Click **Finish**

### Step 3: Configure Environment (Optional)
If Android SDK is in a custom location:

```bash
flutter config --android-sdk /path/to/android/sdk
```

### Step 4: Run on Android
```bash
# List available devices
flutter devices

# Run on Android Emulator
flutter run -d android

# Or specify a specific device
flutter run -d "Pixel_7_API_33"
```

---

## Quick Start Commands

### Check Setup Status
```bash
flutter doctor
```

### List Available Devices
```bash
flutter devices
```

### List Available Emulators
```bash
flutter emulators
```

### Launch an Emulator
```bash
# iOS
open -a Simulator

# Android (after starting from Android Studio)
flutter emulators --launch <emulator_id>
```

### Run the App
```bash
# On any available device
flutter run

# On specific device
flutter run -d chrome        # Web
flutter run -d ios           # iOS
flutter run -d android       # Android
flutter run -d macos         # macOS Desktop
```

---

## Troubleshooting

### iOS Issues

**Problem**: "CocoaPods not installed"  
**Solution**: 
```bash
sudo gem install cocoapods
cd ios && pod install && cd ..
```

**Problem**: "Xcode installation is incomplete"  
**Solution**: Make sure Xcode is fully installed and run:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Android Issues

**Problem**: "Unable to locate Android SDK"  
**Solution**: 
1. Install Android Studio
2. Open SDK Manager and install required components
3. Or set custom path: `flutter config --android-sdk /path/to/sdk`

**Problem**: "No devices found"  
**Solution**: 
1. Start an emulator from Android Studio Device Manager
2. Or connect a physical device with USB debugging enabled

---

## Recommended Setup Order

1. **Start with Web** (Already working!)
   ```bash
   flutter run -d chrome
   ```

2. **Then iOS** (if on macOS)
   - Install Xcode from App Store
   - Follow iOS setup steps above

3. **Then Android**
   - Install Android Studio
   - Follow Android setup steps above

---

## Current App Configuration

✅ **Portrait Mode**: Locked (mobile-optimized)  
✅ **Responsive Design**: Using Sizer package  
✅ **Theme**: Warm neutral colors with burgundy primary  
✅ **All Screens**: Splash, Login, Register, Dashboard, Tasks, Profile, Friends  

The app is ready to run on any platform once the development environment is set up!

