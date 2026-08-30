#!/bin/bash
# Clone SD card OS to eMMC on Rock Pi 4B (smaller eMMC than SD card)
set -euo pipefail

SRC="/dev/mmcblk1"   # SD card (booted from this)
DST="/dev/mmcblk0"   # eMMC (target, smaller)
BOOT_SIZE_MB=256      # matches SD card's p1 size

if [[ $EUID -ne 0 ]]; then
    echo "Must run as root" >&2
    exit 1
fi

ROOT_DEV=$(findmnt -n -o SOURCE / | sed 's/p\?[0-9]*$//')
if [[ "$ROOT_DEV" != "$SRC" ]]; then
    echo "ERROR: root ($ROOT_DEV) doesn't match expected SRC ($SRC)." >&2
    exit 1
fi

if [[ ! -b "$DST" ]]; then
    echo "ERROR: $DST not found. Check lsblk for the correct eMMC device name." >&2
    exit 1
fi

if mount | grep -q "^${DST}"; then
    echo "ERROR: $DST has mounted partitions. Unmount first (check /mnt/boot etc)." >&2
    exit 1
fi

SRC_SIZE=$(blockdev --getsize64 "$SRC")
DST_SIZE=$(blockdev --getsize64 "$DST")
echo "SD (source):   $((SRC_SIZE/1024/1024)) MiB"
echo "eMMC (target): $((DST_SIZE/1024/1024)) MiB"

USED_ROOT_KB=$(df --output=used / | tail -1)
DST_MB=$((DST_SIZE/1024/1024))
AVAIL_ROOT_MB=$((DST_MB - BOOT_SIZE_MB - 8))   # slack for partition table/alignment
if (( USED_ROOT_KB/1024 > AVAIL_ROOT_MB )); then
    echo "ERROR: rootfs uses ~$((USED_ROOT_KB/1024))MB, only ${AVAIL_ROOT_MB}MB available on eMMC after boot partition." >&2
    echo "Free up space on / first, or this clone will not fit." >&2
    exit 1
fi

# --- Find where p1 (boot) currently starts on SRC (idbloader/U-Boot lives before this) ---
PART1_START=$(sfdisk -d "$SRC" | awk '/p1 :/{if(match($0, /start= *[0-9]+/)){s=substr($0,RSTART,RLENGTH); gsub(/start= */,"",s); print s; exit}}')
if [[ -z "$PART1_START" ]]; then
    echo "ERROR: couldn't parse partition 1 start from 'sfdisk -d $SRC'. Run it manually and check." >&2
    exit 1
fi
echo "Boot area (idbloader/U-Boot) = first $PART1_START sectors"

PART_LABEL=$(sfdisk -d "$SRC" | awk -F': ' '/^label:/{print $2; exit}')
echo "Source partition table type: $PART_LABEL"
if [[ "$PART_LABEL" != "dos" ]]; then
    echo "WARNING: expected 'dos' (MBR) label, got '$PART_LABEL'. Script assumes MBR — check before proceeding." >&2
fi

BOOT_FSTYPE=$(blkid -s TYPE -o value "${SRC}p1")
ROOT_FSTYPE=$(blkid -s TYPE -o value "${SRC}p2")
echo "Boot fs: $BOOT_FSTYPE | Root fs: $ROOT_FSTYPE"

# --- Determine real boot mountpoint from /etc/fstab (not however it's mounted right now) ---
SRC_P1_UUID=$(blkid -s UUID -o value "${SRC}p1")
SRC_P2_UUID=$(blkid -s UUID -o value "${SRC}p2")
BOOT_MOUNT=$(awk -v u="UUID=$SRC_P1_UUID" '$1==u{print $2; exit}' /etc/fstab)
if [[ -z "$BOOT_MOUNT" ]]; then
    BOOT_MOUNT=$(awk -v d="${SRC}p1" '$1==d{print $2; exit}' /etc/fstab)
fi
if [[ -z "$BOOT_MOUNT" ]]; then
    echo "WARNING: couldn't find ${SRC}p1 in /etc/fstab, defaulting to /boot" >&2
    BOOT_MOUNT="/boot"
fi
echo "Boot partition's real mountpoint per fstab: $BOOT_MOUNT"

# Don't rely on however the boot partition happens to be mounted right now (or not at all) —
# mount it ourselves to a scratch location purely to read from during the clone.
mkdir -p /mnt/src_boot
if mountpoint -q /mnt/src_boot; then
    umount /mnt/src_boot
fi
mount -o ro "${SRC}p1" /mnt/src_boot
SRC_BOOT_MOUNT="/mnt/src_boot"
echo "Mounted ${SRC}p1 read-only at $SRC_BOOT_MOUNT for cloning"

lsblk "$SRC" "$DST"
read -rp "This will ERASE $DST. Type 'yes' to continue: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { echo "Aborted."; exit 1; }

# --- 1. Raw-copy boot area (idbloader/U-Boot, before partition 1) ---
echo "Copying idbloader/U-Boot area..."
dd if="$SRC" of="$DST" bs=512 count="$PART1_START" conv=fsync status=progress

# --- 2. Partition eMMC: p1 = boot (same size as SD's), p2 = rest (MBR, matching source) ---
echo "Partitioning $DST..."
BOOT_END_MB=$((PART1_START/2048 + BOOT_SIZE_MB))
parted -s "$DST" mklabel msdos
parted -s "$DST" mkpart primary "${PART1_START}s" "${BOOT_END_MB}MiB"
parted -s "$DST" set 1 boot on
parted -s "$DST" mkpart primary "${BOOT_END_MB}MiB" 100%
partprobe "$DST"
sleep 2

DST_P1="${DST}p1"
DST_P2="${DST}p2"

case "$BOOT_FSTYPE" in
    ext4) mkfs.ext4 -F -L boot "$DST_P1" ;;
    vfat) mkfs.vfat -F 32 -n boot "$DST_P1" ;;
    *) echo "Unhandled boot fs type '$BOOT_FSTYPE' — mkfs manually" >&2; exit 1 ;;
esac

case "$ROOT_FSTYPE" in
    ext4) mkfs.ext4 -F -L rootfs "$DST_P2" ;;
    *) echo "Unhandled root fs type '$ROOT_FSTYPE' — mkfs manually" >&2; exit 1 ;;
esac

# --- 3. rsync root and boot ---
mkdir -p /mnt/dst_root
mount "$DST_P2" /mnt/dst_root
mkdir -p "/mnt/dst_root${BOOT_MOUNT}"
mount "$DST_P1" "/mnt/dst_root${BOOT_MOUNT}"

echo "Rsyncing root..."
rsync -aHAX --numeric-ids --info=progress2 \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","$BOOT_MOUNT/*"} \
    / /mnt/dst_root/

echo "Rsyncing boot..."
rsync -aHAX --numeric-ids --info=progress2 "${SRC_BOOT_MOUNT}/" "/mnt/dst_root${BOOT_MOUNT}/"

umount /mnt/src_boot

# --- 4. Fix UUIDs so it boots from eMMC ---
NEW_ROOT_UUID=$(blkid -s UUID -o value "$DST_P2")
NEW_BOOT_UUID=$(blkid -s UUID -o value "$DST_P1")
echo "New root UUID: $NEW_ROOT_UUID"
echo "New boot UUID: $NEW_BOOT_UUID"

EXTLINUX="/mnt/dst_root${BOOT_MOUNT}/extlinux/extlinux.conf"
if [[ -f "$EXTLINUX" ]]; then
    sed -i "s|root=[^ ]*|root=UUID=${NEW_ROOT_UUID}|" "$EXTLINUX"
else
    echo "WARNING: $EXTLINUX not found — check boot config path manually" >&2
fi

sed -i "s|UUID=${SRC_P2_UUID}|UUID=${NEW_ROOT_UUID}|; s|UUID=${SRC_P1_UUID}|UUID=${NEW_BOOT_UUID}|" \
    /mnt/dst_root/etc/fstab

umount "/mnt/dst_root${BOOT_MOUNT}"
umount /mnt/dst_root

echo "Done. Remove SD card and power-cycle to boot from eMMC."
echo "(RK3399 boot ROM checks SD before eMMC — pull the card to actually test eMMC boot.)"
