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

## CI and TestFlight

`.github/workflows/ios.yml` builds the app on a macOS runner. Without further
setup it only verifies that the app compiles and links.

To have it upload to TestFlight:

1. Join the Apple Developer Program and note your Team ID.
2. Register a bundle identifier of your own (`org.wesnoth.Wesnoth` belongs to
   the Wesnoth project) and create an app with it in App Store Connect.
3. In App Store Connect → Users and Access → Integrations, create an
   App Store Connect API key with the Admin role and download the `.p8` file.
4. In the GitHub repository settings → Secrets and variables → Actions, add
   - variables `APPLE_TEAM_ID` and `IOS_BUNDLE_ID`
   - secrets `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_P8` (the contents of the `.p8` file)
5. Run the "iOS" workflow manually with "testflight" ticked, or push a commit
   whose message contains `[testflight]`.

The build number (`CFBundleVersion`) is set to the workflow run number.
