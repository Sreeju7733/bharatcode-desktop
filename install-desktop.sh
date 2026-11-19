#!/usr/bin/env bash
# BharatCode Universal Linux Desktop Installer
set -euo pipefail

REPO="BharatCode-ai/bharatcode-desktop"
APP_NAME="bharatcode"
DISPLAY_NAME="BharatCode"

# ANSI Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}${BLUE}==> Installing ${DISPLAY_NAME} for Linux...${NC}"

# Check architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_DEB="amd64"
        ARCH_RPM="x86_64"
        ARCH_APPIMAGE="x86_64"
        ARCH_TAR="x86_64"
        ;;
    aarch64|arm64)
        ARCH_DEB="arm64"
        ARCH_RPM="aarch64"
        ARCH_APPIMAGE="arm64"
        ARCH_TAR="arm64"
        ;;
    *)
        echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

# Get latest release tag from GitHub API
echo -e "${BLUE}==> Fetching latest release info...${NC}"
LATEST_TAG=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep -Po '"tag_name":\s*"\K[^"]+' || true)
if [ -z "$LATEST_TAG" ]; then
    # Fallback to dev/latest release tags
    LATEST_TAG="v1.15.52"
fi
VERSION="${LATEST_TAG#v}"
echo -e "${GREEN}==> Detected latest version: ${VERSION}${NC}"

# Detect distribution and package manager
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if command -v pacman >/dev/null 2>&1; then
    echo -e "${BLUE}==> Detected Arch Linux / Pacman-based system${NC}"
    # Download .deb and install with native pacman package creation
    DEB_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/bharatcode-desktop-linux-${ARCH_DEB}.deb"
    DEB_FILE="${TMP_DIR}/bharatcode.deb"
    
    echo -e "${BLUE}==> Downloading Debian package for extraction...${NC}"
    if curl -fLo "$DEB_FILE" "$DEB_URL" 2>/dev/null; then
        echo -e "${BLUE}==> Extracting and installing to system...${NC}"
        cd "$TMP_DIR"
        ar x "$DEB_FILE"
        sudo tar -xf data.tar.* -C /
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database ~/.local/share/applications /usr/share/applications || true
        command -v xdg-mime >/dev/null 2>&1 && xdg-mime default bharatcode.desktop x-scheme-handler/bharatcode || true
        echo -e "${BOLD}${GREEN}✔ Successfully installed BharatCode on Arch Linux!${NC}"
        exit 0
    fi
fi

if command -v apt-get >/dev/null 2>&1; then
    echo -e "${BLUE}==> Detected Debian / Ubuntu based system (APT)${NC}"
    DEB_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/bharatcode-desktop-linux-${ARCH_DEB}.deb"
    DEB_FILE="${TMP_DIR}/bharatcode.deb"
    echo -e "${BLUE}==> Downloading ${DEB_URL}...${NC}"
    curl -fLo "$DEB_FILE" "$DEB_URL"
    echo -e "${BLUE}==> Installing via apt...${NC}"
    sudo apt-get update -y
    sudo apt-get install -y "$DEB_FILE"
    echo -e "${BOLD}${GREEN}✔ Successfully installed BharatCode via APT!${NC}"
    exit 0
fi

if command -v dnf >/dev/null 2>&1; then
    echo -e "${BLUE}==> Detected Fedora / RHEL based system (DNF)${NC}"
    RPM_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/bharatcode-desktop-linux-${ARCH_RPM}.rpm"
    RPM_FILE="${TMP_DIR}/bharatcode.rpm"
    echo -e "${BLUE}==> Downloading ${RPM_URL}...${NC}"
    curl -fLo "$RPM_FILE" "$RPM_URL"
    echo -e "${BLUE}==> Installing via dnf...${NC}"
    sudo dnf install -y "$RPM_FILE"
    echo -e "${BOLD}${GREEN}✔ Successfully installed BharatCode via DNF!${NC}"
    exit 0
fi

# Fallback: Standalone AppImage with Desktop & Protocol Integration
echo -e "${YELLOW}==> Fallback: Installing standalone AppImage with desktop integration...${NC}"
APPIMAGE_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/bharatcode-desktop-linux-${ARCH_APPIMAGE}.AppImage"
INSTALL_DIR="$HOME/.local/share/bharatcode"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR"
curl -fLo "${INSTALL_DIR}/bharatcode.AppImage" "$APPIMAGE_URL"
chmod +x "${INSTALL_DIR}/bharatcode.AppImage"
ln -sf "${INSTALL_DIR}/bharatcode.AppImage" "${BIN_DIR}/bharatcode"

cat << EOF > "${DESKTOP_DIR}/bharatcode.desktop"
[Desktop Entry]
Name=BharatCode
Exec=${INSTALL_DIR}/bharatcode.AppImage %u
Type=Application
Terminal=false
Categories=Development;
MimeType=x-scheme-handler/bharatcode;
EOF

chmod +x "${DESKTOP_DIR}/bharatcode.desktop"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true
command -v xdg-mime >/dev/null 2>&1 && xdg-mime default bharatcode.desktop x-scheme-handler/bharatcode || true

echo -e "${BOLD}${GREEN}✔ Successfully installed BharatCode to ${INSTALL_DIR}!${NC}"
echo -e "${GREEN}Run 'bharatcode' or launch it from your application menu.${NC}"
