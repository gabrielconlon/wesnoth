#!/bin/sh

# Build the static dependency prefixes that the iOS configuration of the Xcode
# project links against.
#
# Output layout (matches the [sdk=iphone*] search paths in the Xcode project):
#   projectfiles/Xcode/temp/iOSCompileStuff-<tag>/<triplet>/include
#   projectfiles/Xcode/temp/iOSCompileStuff-<tag>/<triplet>/lib
#
# Environment overrides:
#   IOS_BUILD_DEVICE_DEPS=0     skip the device (iphoneos) prefix
#   IOS_BUILD_SIMULATOR_DEPS=0  skip the simulator prefix
#   VCPKG_ROOT                  reuse an existing vcpkg git checkout

set -e

root_dir=$(cd "$(dirname "$0")/../../.." && pwd)
ios_tag=${IOS_TAG:-v0.0.1}

ios_sim_triplet=${IOS_SIM_TRIPLET:-arm64-ios-simulator-wesnoth}
ios_device_triplet=${IOS_DEVICE_TRIPLET:-arm64-ios-wesnoth}
ios_build_simulator_deps=${IOS_BUILD_SIMULATOR_DEPS:-1}
ios_build_device_deps=${IOS_BUILD_DEVICE_DEPS:-1}

manifest_root="$root_dir/projectfiles/Xcode/ios/vcpkg"
ios_deps_base="$root_dir/projectfiles/Xcode/temp/iOSCompileStuff-${ios_tag}"
vcpkg_install_base="$ios_deps_base/vcpkg_installed"
vcpkg_root=${VCPKG_ROOT:-$root_dir/projectfiles/Xcode/temp/vcpkg-ios}
overlay_ports_root="$ios_deps_base/overlay-ports"
gettext_overlay_port="$overlay_ports_root/gettext-libintl"
gettext_port_patch="$manifest_root/patches/gettext-libintl-ios.patch"
vcpkg_baseline=$(sed -n 's/.*"builtin-baseline": "\([^"]*\)".*/\1/p' "$manifest_root/vcpkg.json")

need_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Error: missing required command: $1" >&2
		exit 1
	fi
}

ensure_vcpkg_checkout() {
	if [ ! -d "$vcpkg_root/.git" ]; then
		echo "==> Cloning vcpkg into $vcpkg_root"
		rm -rf "$vcpkg_root"
		git clone --filter=blob:none https://github.com/microsoft/vcpkg "$vcpkg_root"
	fi
	if ! git -C "$vcpkg_root" cat-file -e "${vcpkg_baseline}^{commit}" 2>/dev/null; then
		git -C "$vcpkg_root" fetch --filter=blob:none origin
	fi
	if [ ! -x "$vcpkg_root/vcpkg" ]; then
		"$vcpkg_root/bootstrap-vcpkg.sh" -disableMetrics
	fi
}

prepare_gettext_overlay() {
	# Take the port from the manifest's baseline so the overlay matches the
	# versions of everything else, then apply the iOS configure overrides.
	echo "==> Preparing gettext-libintl overlay from vcpkg baseline $vcpkg_baseline"
	rm -rf "$gettext_overlay_port"
	mkdir -p "$gettext_overlay_port"
	git -C "$vcpkg_root" archive "$vcpkg_baseline" ports/gettext-libintl \
		| tar -x -C "$gettext_overlay_port" --strip-components=2
	patch -d "$gettext_overlay_port" -p1 <"$gettext_port_patch"
}

build_prefix() {
	triplet_name=$1
	prefix_dir="$ios_deps_base/$triplet_name"
	install_root="$vcpkg_install_base/$triplet_name"

	echo "==> Installing iOS dependencies via vcpkg for $triplet_name"
	"$vcpkg_root/vcpkg" install \
		--x-manifest-root="$manifest_root" \
		--triplet="$triplet_name" \
		--x-install-root="$install_root" \
		--overlay-triplets="$manifest_root/triplets" \
		--overlay-ports="$overlay_ports_root"

	mkdir -p "$prefix_dir/include" "$prefix_dir/lib"
	rsync -a --delete "$install_root/$triplet_name/include/" "$prefix_dir/include/"
	rsync -a --delete "$install_root/$triplet_name/lib/" "$prefix_dir/lib/"

	echo "==> iOS dependency prefix ready: $prefix_dir"
}

need_cmd git
need_cmd cmake
need_cmd rsync
need_cmd patch
need_cmd xcrun

mkdir -p "$ios_deps_base"
ensure_vcpkg_checkout
prepare_gettext_overlay

if [ "$ios_build_simulator_deps" = "1" ]; then
	build_prefix "$ios_sim_triplet"
fi

if [ "$ios_build_device_deps" = "1" ]; then
	build_prefix "$ios_device_triplet"
fi

echo "==> Done."
