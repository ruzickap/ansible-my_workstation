#!/usr/bin/env bash

set -eux

TMP_ISO="/tmp/iso"
DESTINATION="${HOME}/Documents/iso/"
ISO_SOURCE="${DESTINATION}/Fedora-Server-netinst-x86_64-33-1.2.iso"
VOLUME_LABEL=$(isoinfo -d -i "${ISO_SOURCE}" | awk -F': ' '/Volume id:/ { print $2 }')
BOOT_PARAMS="inst.ks=hd:LABEL=${VOLUME_LABEL}:/fedora-ks.cfg"
DESTINATION_FILE_NAME="$(basename "${ISO_SOURCE}" .iso)-my.iso"

xorriso -osirrox on -indev "${ISO_SOURCE}" -extract / "${TMP_ISO}"

# MacOS workaround - MacOS can not mount the /iso/images/efiboot.img
docker run -t --rm -e VOLUME_LABEL -e BOOT_PARAMS -v "${TMP_ISO}:/iso" --privileged ubuntu /bin/bash -c "set -x \
&& mount /iso/images/efiboot.img /mnt \
&& sed -i.orig \
     -e \"s@${VOLUME_LABEL} quiet@${VOLUME_LABEL} quiet ${BOOT_PARAMS}@\" \
     -e \"s@set timeout=60@# set timeout=60@\" \
     -e 's@set default=\"1\"@set default=\"0\"@' \
   /iso/EFI/BOOT/grub.cfg /iso/EFI/BOOT/BOOT.conf /mnt/EFI/BOOT/grub.cfg /mnt/EFI/BOOT/BOOT.conf \
&& umount /mnt"

sed -i.orig \
  -e "s|${VOLUME_LABEL} quiet|${VOLUME_LABEL} quiet ${BOOT_PARAMS}|" \
  -e "s|^timeout|#timeout|" \
  -e "s|menu default|#menu default|" \
${TMP_ISO}/isolinux/isolinux.cfg ${TMP_ISO}/isolinux/grub.conf

tar czhf ${TMP_ISO}/fedora_workstation.tar.gz ../../ansible-my_workstation

cp ../kickstart_file/fedora-ks.cfg "${TMP_ISO}/"

test -f "${DESTINATION}/${DESTINATION_FILE_NAME}" && rm -f "${DESTINATION}/${DESTINATION_FILE_NAME}"
# wget -c http://download.bmsoft.de/archiv/boot/syslinux/mbr/isohdpfx.bin -O /tmp/isohdpfx.bin
dd if="${ISO_SOURCE}" of=/tmp/isohdpfx.bin bs=512 count=1
xorriso -as mkisofs \
  -R -J -volid "${VOLUME_LABEL}" \
  -isohybrid-mbr /tmp/isohdpfx.bin \
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
