#!/bin/bash
# Autonomix RPM x64 Package Builder
# Creates a .rpm package for Autonomix Linux desktop application
#
# Usage: ./scripts/create-rpm-package.sh
# Requirements: Flutter SDK, rpm, rpmbuild

set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/linux/x64/release"
DIST_DIR="$PROJECT_DIR/dist/rpm-x64"
BUILD_ROOT="/tmp/autonomix-rpm-build-$$"

# === Configuration ===
APP_NAME="autonomix"
VERSION=$(grep '^version:' "$PROJECT_DIR/pubspec.yaml" | awk '{print $2}')
ARCH="x86_64"
MAINTAINER="Autonomix Team"
DESCRIPTION="A Linux package manager for GitHub releases"

# Flutter path (try FVM first, then system)
FLUTTER_PATH="/home/mxadm/fvm/versions/stable/bin/flutter"
if [ ! -f "$FLUTTER_PATH" ]; then
    FLUTTER_PATH="$(which flutter || echo '/usr/bin/flutter')"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

cleanup() {
    rm -rf "$BUILD_ROOT"
}
trap cleanup EXIT

check_dependencies() {
    log_step "Checking dependencies..."
    
    if [ ! -f "$FLUTTER_PATH" ]; then
        log_error "Flutter SDK not found at $FLUTTER_PATH"
        exit 1
    fi
    
    if ! command -v rpmbuild &> /dev/null; then
        log_error "rpmbuild not found. Install: sudo apt-get install rpm"
        exit 1
    fi
    
    log_info "All dependencies found ✓"
}

build_flutter() {
    log_step "Building Flutter Linux release..."
    
    cd "$PROJECT_DIR"
    
    log_info "Cleaning Flutter cache..."
    "$FLUTTER_PATH" clean
    
    log_info "Getting dependencies..."
    "$FLUTTER_PATH" pub get
    
    "$FLUTTER_PATH" build linux --release
    
    if [ ! -d "$BUILD_DIR" ]; then
        log_error "Build failed - output directory not found"
        exit 1
    fi
    
    log_info "Flutter build completed ✓"
}

create_rpm_structure() {
    log_step "Creating RPM build structure..."
    
    # Create RPM build directories
    mkdir -p "$BUILD_ROOT/BUILD"
    mkdir -p "$BUILD_ROOT/RPMS"
    mkdir -p "$BUILD_ROOT/SOURCES"
    mkdir -p "$BUILD_ROOT/SPECS"
    mkdir -p "$BUILD_ROOT/SRPMS"
    
    # Create SPEC file
    cat > "$BUILD_ROOT/SPECS/$APP_NAME.spec" << 'SPECEOF'
Name:           autonomix
Version:        %{version}
Release:        1%{?dist}
Summary:        Linux package manager for GitHub releases
License:        MIT

URL:            https://github.com/thexmeta/autonomix
BuildArch:      x86_64

Requires:       libgtk-3-0, libblkid1, liblzma5, libcurl4, libfreetype6

%description
Autonomix helps you track, install, update, and manage applications 
distributed via GitHub releases. It provides a clean, modern GUI for 
managing your GitHub-sourced applications with support for multiple 
package formats including DEB, RPM, AppImage, Flatpak, and Snap.

%prep
# No preparation needed - we're using pre-built binary

%build
# No build needed - we're using pre-built binary

%install
mkdir -p %{buildroot}/opt/autonomix
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps

# Copy application files
cp -r %{_builddir}/* %{buildroot}/opt/autonomix/

# Create symlink for command-line access
ln -sf /opt/autonomix/bundle/autonomix %{buildroot}/usr/bin/autonomix

# Install desktop file
cat > %{buildroot}/usr/share/applications/autonomix.desktop << 'DESKTOPEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Autonomix
Comment=Linux package manager for GitHub releases
Exec=/opt/autonomix/bundle/autonomix
Icon=autonomix
Path=/opt/autonomix/bundle
Terminal=false
Categories=System;Utility;PackageManager;
Keywords=package;github;release;manager;
StartupWMClass=com.example.autonomix
DESKTOPEOF

chmod 0644 %{buildroot}/usr/share/applications/autonomix.desktop

# Install icon if available
if [ -f "%{_builddir}/autonomix.png" ]; then
    cp %{_builddir}/autonomix.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/autonomix.png
fi

%post
# Update desktop database
if [ -d "/usr/share/applications" ]; then
    update-desktop-database /usr/share/applications || true
fi
# Update icon cache
if [ -d "/usr/share/icons/hicolor" ]; then
    touch /usr/share/icons/hicolor
    if command -v update-icon-caches &> /dev/null; then
        update-icon-caches /usr/share/icons/hicolor || true
    fi
fi
echo "Autonomix installed successfully!"
echo "You can now run 'autonomix' from the command line or find it in your applications menu."

%postun
# Remove symlink on uninstall
rm -f /usr/bin/autonomix
# Update desktop database
if [ -d "/usr/share/applications" ]; then
    update-desktop-database /usr/share/applications || true
fi
# Update icon cache
if [ -d "/usr/share/icons/hicolor" ]; then
    touch /usr/share/icons/hicolor
    if command -v update-icon-caches &> /dev/null; then
        update-icon-caches /usr/share/icons/hicolor || true
    fi
fi
echo "Autonomix removed successfully!"

%files
/opt/autonomix
/usr/bin/autonomix
/usr/share/applications/autonomix.desktop
%attr(644, root, root) /usr/share/icons/hicolor/256x256/apps/autonomix.png

%changelog
* %(date +"%a %b %d %Y") Autonomix Team <team@autonomix.dev> - %{version}-1
- Release build
SPECEOF

    # Copy built application to BUILD directory
    cp -r "$BUILD_DIR"/* "$BUILD_ROOT/BUILD/"
    
    # Copy icon if available
    if [ -f "$PROJECT_DIR/autonomix.png" ]; then
        cp "$PROJECT_DIR/autonomix.png" "$BUILD_ROOT/BUILD/"
    fi
    
    log_info "RPM structure created ✓"
}

build_rpm_package() {
    log_step "Building RPM package..."
    
    mkdir -p "$DIST_DIR"
    
    # Extract version and release
    VERSION_CLEAN="${VERSION%-*}"  # Remove build suffix if present
    
    # Build the RPM
    rpmbuild \
        --define "_topdir $BUILD_ROOT" \
        --define "version $VERSION_CLEAN" \
        --define "_builddir $BUILD_ROOT/BUILD" \
        -bb "$BUILD_ROOT/SPECS/$APP_NAME.spec"
    
    # Copy RPM to dist directory
    cp "$BUILD_ROOT/RPMS/$ARCH"/*.rpm "$DIST_DIR/"
    
    if [ ! -f "$DIST_DIR"/*.rpm ]; then
        log_error "Failed to create .rpm package"
        exit 1
    fi
    
    log_info "Package created ✓"
}

print_summary() {
    echo ""
    echo "=========================================="
    log_info "Build completed successfully!"
    echo "=========================================="
    echo ""
    echo "Package: $DIST_DIR/${APP_NAME}-*.${ARCH}.rpm"
    echo "Size: $(du -h "$DIST_DIR"/*.rpm 2>/dev/null | cut -f1 || echo 'N/A')"
    echo ""
    echo "To install:"
    echo "  sudo rpm -i $DIST_DIR/${APP_NAME}-*.${ARCH}.rpm"
    echo ""
    echo "To uninstall:"
    echo "  sudo rpm -e $APP_NAME"
    echo ""
}

# === Main ===
main() {
    echo "=========================================="
    echo "Autonomix - RPM Package Builder"
    echo "Version: $VERSION"
    echo "=========================================="
    echo ""
    
    check_dependencies
    build_flutter
    create_rpm_structure
    build_rpm_package
    print_summary
}

main "$@"
