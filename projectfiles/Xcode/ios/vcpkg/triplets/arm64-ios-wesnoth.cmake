set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME iOS)
set(VCPKG_OSX_SYSROOT iphoneos)

# Force autotools ports to treat iOS device as cross-compilation.
# A single option: a list here is joined with ";" by the older vcpkg_configure_make
# (openssl), which ends the shell command and drops every option after it.
# --build is left to config.guess so this works on Intel and Apple Silicon hosts.
set(VCPKG_MAKE_BUILD_TRIPLET "--host=aarch64-apple-ios")

# The Xcode project only links the release archives.
set(VCPKG_BUILD_TYPE release)
set(VCPKG_OSX_DEPLOYMENT_TARGET "15.0")
