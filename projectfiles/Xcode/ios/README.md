# Building Wesnoth for iOS

The iOS app is built from the same Xcode project as the macOS app. It links
its dependencies statically from a vcpkg-built prefix, so they have to be built
once before opening the project.

## Local build

Requirements: a Mac with Xcode, plus `brew install autoconf autoconf-archive automake libtool cmake`.

1. `./projectfiles/Xcode/ios/build_ios_deps.sh`
   (set `IOS_BUILD_SIMULATOR_DEPS=0` or `IOS_BUILD_DEVICE_DEPS=0` to build only one prefix).
2. Open `projectfiles/Xcode/The Battle for Wesnoth.xcodeproj`, pick the
   "The Battle for Wesnoth" scheme and an iOS device or simulator destination.
3. For a device, set your own team and bundle identifier under
   Signing & Capabilities.

## TestFlight

`projectfiles/Xcode/ios/release.sh` archives the app for a device, exports a
signed `.ipa` and uploads it to TestFlight, signing through the App Store
Connect API key in `~/.appstoreconnect/private_keys`. Build the device
dependencies first (`IOS_BUILD_SIMULATOR_DEPS=0` is enough). Pass
`--no-upload` to stop after the export.

The build number (`CFBundleVersion`) is the git commit count, so every
release needs a new commit.
