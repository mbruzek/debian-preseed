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

BASE_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd
if [[ $1 == "firmware" ]] ; then
  BASE_URL=https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/current/amd64/iso-cd
fi

# The URL to the SHA512SUMS of the CD directory.
CHECKSUM_URL=${BASE_URL}/SHA512SUMS
# Download the checksum file, do not duplicate if unchanged.
wget --timestamping ${CHECKSUM_URL}

# The name of the ISO file is on the first line second column.
ISO_FILE_NAME=$(head -n 1 $(basename ${CHECKSUM_URL}) | awk '{print $2}')
# Construct the URL to the specific ISO file.
ISO_URL=${BASE_URL}/${ISO_FILE_NAME}

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

mv iso/boot/grub/grub.cfg iso/boot/grub/original_grub.cfg
cat << EOF > iso/boot/grub/grub.cfg
if loadfont $prefix/font.pf2 ; then
  set gfxmode=800x600
  set gfxpayload=keep
  insmod efi_gop
  insmod efi_uga
  insmod video_bochs
  insmod video_cirrus
  insmod gfxterm
  insmod png
  terminal_output gfxterm
fi

if background_image /isolinux/splash.png; then
  set color_normal=light-gray/black
  set color_highlight=white/black
elif background_image /splash.png; then
  set color_normal=light-gray/black
  set color_highlight=white/black
else
  set menu_color_normal=cyan/blue
  set menu_color_highlight=white/blue
fi

default="0"
timeout=5

echo ""
echo "The install starting automatically in 5 seconds, hit 'c' or 'e' to abort."
echo ""

insmod play
play 2000 400 4 0 1 500 4 0 1 600 4 0 1 800 6
menuentry --hotkey=a 'Start automated install...' {
    set background_color=black
    linux    /install.amd/vmlinuz auto=true priority=critical vga=788 --- quiet
    initrd   /install.amd/initrd.gz
}
EOF

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
