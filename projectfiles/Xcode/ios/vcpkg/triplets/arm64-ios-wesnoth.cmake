set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME iOS)
set(VCPKG_OSX_SYSROOT iphoneos)

# Force autotools ports to treat iOS device as cross-compilation.
set(VCPKG_MAKE_BUILD_TRIPLET "--build=aarch64-apple-darwin" "--host=aarch64-apple-ios")

# The Xcode project only links the release archives.
set(VCPKG_BUILD_TYPE release)
set(VCPKG_OSX_DEPLOYMENT_TARGET "15.0")

# Stop Meson ports from trying to run target binaries on the build machine.
set(VCPKG_MESON_CROSS_FILE_RELEASE "${CMAKE_CURRENT_LIST_DIR}/meson-ios-cross.ini")
