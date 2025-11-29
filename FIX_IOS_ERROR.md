# Fix iOS Xcode Error

## Problem
```
xcrun: error: unable to find utility "xcodebuild", not a developer tool or in PATH
```

## Root Cause
Xcode.app is **not installed**. Only Command Line Tools are installed, which is not sufficient for iOS development.

## Solution

### Option 1: Install Xcode (Required for iOS)

1. **Open App Store** on your Mac
2. **Search for "Xcode"**
3. **Click "Get" or "Install"** (Free, but ~15GB download)
4. **Wait for installation** (this can take 30-60 minutes depending on your internet)

5. **After installation, run these commands:**
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

6. **Accept the license:**
   ```bash
   sudo xcodebuild -license accept
   ```

7. **Install CocoaPods:**
   ```bash
   sudo gem install cocoapods
   ```

8. **Install iOS dependencies:**
   ```bash
   cd ios
   pod install
   cd ..
   ```

9. **Now you can run:**
   ```bash
   flutter run -d ios
   ```

### Option 2: Use Web/Chrome (Works Right Now!)

Since Xcode installation takes time, you can use Chrome for mobile preview:

```bash
# Run on Chrome (mobile preview)
flutter run -d chrome

# Or use device frame in Chrome DevTools
# Press F12 → Toggle device toolbar (Ctrl+Shift+M)
```

### Option 3: Use Android (If You Have Android Studio)

If you have Android Studio installed:

```bash
# Start an Android emulator from Android Studio
# Then run:
flutter run -d android
```

## Quick Check Commands

```bash
# Check if Xcode is installed
test -d "/Applications/Xcode.app" && echo "✅ Xcode installed" || echo "❌ Xcode not found"

# Check current developer directory
xcode-select -p

# Should show: /Applications/Xcode.app/Contents/Developer
# Currently shows: /Library/Developer/CommandLineTools (not enough)
```

## Recommendation

**For immediate testing:** Use `flutter run -d chrome` - it works right now!

**For iOS development:** Install Xcode from App Store (one-time setup, takes ~1 hour)

The app is fully functional and ready - you just need the development tools installed for iOS/Android.

