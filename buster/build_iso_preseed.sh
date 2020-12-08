#!/usr/bin/env bash

# Build an ISO image of the Debian network installer with a preseed.cfg file.

# The first variable is the optional Debian version.
DEBIAN_VERSION=${1:-10.7.0}
DEBIAN_ISO_FILE_NAME=debian-${DEBIAN_VERSION}-amd64-netinst.iso
DEBIAN_NETINST_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/${DEBIAN_ISO_FILE_NAME}
OUTPUT_FILE=preseed-${DEBIAN_ISO_FILE_NAME}
YEAR_MONTH_DAY=$(date "+%Y-%m-%d")

# Ensure the prerequisite software is installed.
apt install -y debconf isolinux syslinux-utils xorriso wget

if ! debconf-set-selections -c preseed.cfg ; then
  echo "There is an error in the preseed.cfg. Check the syntax of the preconfiguration file."
  exit 1
fi

# Do not download the image if it has not changed.
wget --timestamping ${DEBIAN_NETINST_URL}

# Create a working directory.
mkdir -p iso
# Restore the iso file to the filesystem in the iso directory.
xorriso -osirrox on -indev ${DEBIAN_ISO_FILE_NAME} -extract / iso/

chmod +w -R iso/install.amd/
# Uncompress the initrd gzip.
gunzip iso/install.amd/initrd.gz
# Copy the preseed file into the initrd archive.
echo preseed.cfg | cpio -H newc -o -A -F iso/install.amd/initrd
# Copy the sources.list file into the initrd archive.
echo sources.list | cpio -H newc -o -A -F iso/install.amd/initrd
# Compress the initrd using gzip.
gzip iso/install.amd/initrd
chmod -w -R iso/install.amd/

# Generate checksums for each file using relative paths.
pushd iso/
chmod +w md5sum.txt
md5sum `find -follow -type f` > md5sum.txt
popd

# Recreate the ISO using options to make it bootable on BIOS and EFI systems.
xorriso -as mkisofs \
	-r -V "preseed-netinst-${YEAR_MONTH_DAY}" \
	-o ${OUTPUT_FILE} \
	-cache-inodes \
	-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	-boot-load-size 4 -boot-info-table -no-emul-boot \
	-eltorito-alt-boot \
	-e boot/grub/efi.img \
	-no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
	iso

# Create a checksum of the final file for transport.
md5sum ${OUTPUT_FILE} > ${OUTPUT_FILE}.md5

# Remove the working directory.
rm -rf iso
