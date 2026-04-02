#!/bin/bash

# BSD 3-Clause License
# ____________________
# 
# Copyright © 2026, Jaisal E. K.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -euo pipefail

source ./release.vars

DEBIAN_MIRROR="https://snapshot.debian.org/archive/debian/${UPSTREAM_OS_SNAPSHOT}"
ARTIFACT_NAME="ouress-v${VERSION}.ress"
BUILD_DIR="build"
ROOTFS_DIR="${BUILD_DIR}/rootfs"

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)."
    exit 1
fi

if ! command -v debootstrap >/dev/null 2>&1; then
    echo "Error: debootstrap is required but not installed."
    exit 1
fi

if ! command -v xz >/dev/null 2>&1; then
    echo "Error: xz-utils is required but not installed."
    exit 1
fi

umount "${ROOTFS_DIR}/dev/pts" 2>/dev/null || true
umount "${ROOTFS_DIR}/dev" 2>/dev/null || true
umount "${ROOTFS_DIR}/sys" 2>/dev/null || true
umount "${ROOTFS_DIR}/proc" 2>/dev/null || true

echo "==> Initialising build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${ROOTFS_DIR}"

echo "==> Bootstrapping ${UPSTREAM_OS_NAME} ${UPSTREAM_OS_VERSION_FULL} (${UPSTREAM_OS_VERSION_CODENAME}) from snapshot (${UPSTREAM_OS_SNAPSHOT})..."
debootstrap --variant=minbase "${UPSTREAM_OS_VERSION_CODENAME}" "${ROOTFS_DIR}" "${DEBIAN_MIRROR}"

echo "==> Configuring chroot environment..."
cp rootfs-setup.sh "${ROOTFS_DIR}/tmp/"
chmod +x "${ROOTFS_DIR}/tmp/rootfs-setup.sh"

if [ -f packages.list ]; then
    cp packages.list "${ROOTFS_DIR}/tmp/"
else
    echo "Warning: packages.list not found. External binaries will be skipped."
fi

echo "==> Resolving Ouress documentation..."
mkdir -p "${ROOTFS_DIR}/usr/share/doc/ouress"
sed '1s/^\xEF\xBB\xBF//' ../LICENSE > "${ROOTFS_DIR}/usr/share/doc/ouress/copyright"
echo -e "\n\nThird-Party Notices\n___________________\n" >> "${ROOTFS_DIR}/usr/share/doc/ouress/copyright"
sed '1s/^\xEF\xBB\xBF//' ../NOTICE >> "${ROOTFS_DIR}/usr/share/doc/ouress/copyright"

echo "==> Applying release metadata..."
mkdir -p "${ROOTFS_DIR}/etc/ouress"
cat > "${ROOTFS_DIR}/etc/ouress/release" << EOF
NAME="${NAME}"
FULL_NAME="${FULL_NAME}"
VERSION="${VERSION}"
BUILD_DATE="$(date +%Y-%m-%d)"
TARGET_ARCHITECTURE="${TARGET_ARCHITECTURE}"
COPYRIGHT="${COPYRIGHT}"
UPSTREAM_OS="${UPSTREAM_OS_NAME} ${UPSTREAM_OS_VERSION_FULL} (${UPSTREAM_OS_VERSION_CODENAME})"
HOME_URL="${HOME_URL}"
SOURCE_URL="${SOURCE_URL}"
EOF

echo "==> Mounting virtual filesystems..."
mount -t proc /proc "${ROOTFS_DIR}/proc"
mount -t sysfs /sys "${ROOTFS_DIR}/sys"
mount --bind /dev "${ROOTFS_DIR}/dev"
mount --bind /dev/pts "${ROOTFS_DIR}/dev/pts"

cleanup() {
    set +e
    umount "${ROOTFS_DIR}/dev/pts" 2>/dev/null || true
    umount "${ROOTFS_DIR}/dev" 2>/dev/null || true
    umount "${ROOTFS_DIR}/sys" 2>/dev/null || true
    umount "${ROOTFS_DIR}/proc" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "==> Configuring apt sources..."
echo "deb ${DEBIAN_MIRROR} ${UPSTREAM_OS_VERSION_CODENAME} main" > "${ROOTFS_DIR}/etc/apt/sources.list"

echo "==> Running rootfs setup..."
chroot "${ROOTFS_DIR}" /usr/bin/env LANG=C.UTF-8 LC_ALL=C.UTF-8 /bin/bash /tmp/rootfs-setup.sh

echo "==> Purging build artifacts..."
rm -f "${ROOTFS_DIR}/tmp/rootfs-setup.sh"
rm -f "${ROOTFS_DIR}/tmp/packages.list"

echo "==> Unmounting virtual filesystems..."
cleanup
trap - EXIT INT TERM

echo "==> Packaging distribution artifact..."
mkdir -p ../releases
env XZ_OPT="-9e -T0" tar -cJf "../releases/${ARTIFACT_NAME}" -C "${ROOTFS_DIR}" .

echo "==> Build successful: $(cd ../releases && pwd)/${ARTIFACT_NAME}"
ls -lh "../releases/${ARTIFACT_NAME}"