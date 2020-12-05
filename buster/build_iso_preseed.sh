#!/usr/bin/env bash

# Build an iso image of the debian network installer with a preseed.cfg file
# included in the iso.

# The first variable is the optional Debian version.
DEBIAN_VERSION=${1:-10.6.0}
DEBIAN_ISO_FILE_NAME=debian-${DEBIAN_VERSION}-amd64-netinst.iso
DEBIAN_NETINST_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/${DEBIAN_ISO_FILE_NAME}

apt install -y isolinux syslinux-utils xorriso wget

# Don't download the image if it has not changed.
wget --timestamping ${DEBIAN_NETINST_URL}

mkdir iso
# Restore the iso file to the filesystem in the iso directory.
xorriso -osirrox on -indev ${DEBIAN_ISO_FILE_NAME} -extract / iso/

chmod +w -R iso/install.amd/
gunzip iso/install.amd/initrd.gz
# Copy the preseed file into the archive.
echo preseed.cfg | cpio -H newc -o -A -F iso/install.amd/initrd
# Copy the sources.list file into the archive.
echo sources.list | cpio -H newc -o -A -F iso/install.amd/initrd
gzip iso/install.amd/initrd
chmod -w -R iso/install.amd/

pushd iso/
chmod +w md5sum.txt
md5sum `find -follow -type f` > md5sum.txt
popd

YEAR_MONTH_DAY=$(date "+%Y-%m-%d")

# Recreate the ISO using options to make it bootable on BIOS and EFI systems.
xorriso -as mkisofs \
	-r -V "netinst-${YEAR_MONTH_DAY}" \
	-o preseed.iso \
	-cache-inodes \
	-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	-boot-load-size 4 -boot-info-table -no-emul-boot \
	-eltorito-alt-boot \
	-e boot/grub/efi.img \
	-no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
	iso

md5sum preseed.iso > preseed-${YEAR_MONTH_DAY}.md5

rm -rf iso
