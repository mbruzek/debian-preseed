#!/usr/bin/env bash

# Download an ISO file, extract the contents, copy in preseed.cfg and generate
# a new ISO image.

# Ensure the prerequisite software is installed.
apt install -y debconf isolinux syslinux-utils xorriso wget

# Check the syntax of the preseed file.
if ! debconf-set-selections -c preseed.cfg ; then
  echo "There is an error in the preseed.cfg. Check the syntax of the preconfiguration file."
  exit 1
fi

# The URL to the SHA512SUMS of the CD directory.
CHECKSUM_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA512SUMS
# Download the checksum file, do not duplicate if unchanged.
wget --timestamping ${CHECKSUM_URL}

# The name of the ISO file is on the first line second column.
ISO_FILE_NAME=$(head -n 1 $(basename ${CHECKSUM_URL}) | awk '{print $2}')
# Construct the URL to the specific ISO file.
ISO_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/${ISO_FILE_NAME}

# Download the ISO file, do not duplicate if the image has not changed.
wget --timestamping ${ISO_URL}

# Create a working directory.
mkdir -p iso
# Restore the iso file to the filesystem in the iso directory.
xorriso -osirrox on -indev ${ISO_FILE_NAME} -extract / iso/

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

# Create the output file name.
OUTPUT_FILE=preseed-${ISO_FILE_NAME}
YEAR_MONTH_DAY=$(date "+%Y-%m-%d")

# Recreate the ISO using options to make it bootable on BIOS and EFI systems.
xorriso -as mkisofs \
	-r -V "preseed-iso-${YEAR_MONTH_DAY}" \
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
