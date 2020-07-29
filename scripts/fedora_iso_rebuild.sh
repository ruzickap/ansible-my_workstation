#!/usr/bin/env bash

set -eux

TMP_ISO="/tmp/iso"
TMP_ISO2="/tmp/iso2"
DESTINATION="${HOME}/Documents/iso/"
ISO_SOURCE="${HOME}/Documents/iso/Fedora-Server-netinst-x86_64-32-1.6.iso"
VOLUME_LABEL=$(isoinfo -d -i "${ISO_SOURCE}" | awk -F': ' '/Volume id:/ { print $2 }')
BOOT_PARAMS="inst.ks=hd:LABEL=${VOLUME_LABEL}:/fedora-ks.cfg"
DESTINATION_FILE_NAME="$(basename "${ISO_SOURCE}" .iso)-my.iso"

xorriso -osirrox on -indev "${ISO_SOURCE}" -extract / "${TMP_ISO}"

mkdir "${TMP_ISO2}"
sudo mount "${TMP_ISO}/images/efiboot.img" "${TMP_ISO2}"

sudo sed -i.orig \
  -e "s@${VOLUME_LABEL} quiet@${VOLUME_LABEL} quiet ${BOOT_PARAMS}@" \
  -e "s@set timeout=60@# set timeout=60@" \
  -e "s@set default=\"1\"@set default=\"0\"@" \
${TMP_ISO}/EFI/BOOT/grub.cfg ${TMP_ISO}/EFI/BOOT/BOOT.conf ${TMP_ISO2}/EFI/BOOT/grub.cfg ${TMP_ISO2}/EFI/BOOT/BOOT.conf

sudo umount "${TMP_ISO2}"
rmdir "${TMP_ISO2}"

sed -i.orig \
  -e "s|${VOLUME_LABEL} quiet|${VOLUME_LABEL} quiet ${BOOT_PARAMS}|" \
  -e "s|^timeout|#timeout|" \
  -e "s|menu default|#menu default|" \
${TMP_ISO}/isolinux/isolinux.cfg ${TMP_ISO}/isolinux/grub.conf

tar czhf ${TMP_ISO}/fedora_workstation.tar.gz ../../ansible-my_workstation

cp ../kickstart_file/fedora-ks.cfg "${TMP_ISO}/"

test -f "${DESTINATION}/${DESTINATION_FILE_NAME}" && rm -f "${DESTINATION}/${DESTINATION_FILE_NAME}"
xorriso -as mkisofs \
  -R -J -volid "${VOLUME_LABEL}" \
  -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
  -eltorito-catalog isolinux/boot.cat \
  -eltorito-boot isolinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e images/efiboot.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -o "${DESTINATION}/${DESTINATION_FILE_NAME}" \
  ${TMP_ISO}/

rm -rf ${TMP_ISO}
