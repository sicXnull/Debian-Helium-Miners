# Rock Pi 4B — Clone SD Card to eMMC

This guide walks through cloning a running SD card install to the onboard eMMC on a Rock Pi 4B, so the board can boot without the SD card.

## Requirements

- Rock Pi 4B with a bootable SD card already running
- Network access to the board
- eMMC module installed on the board and smaller than (or equal to) the used space on the SD card's rootfs

## 1. Boot from the SD card

Boot the Rock Pi 4B from the SD card as usual.

## 2. SSH into the unit

```bash
ssh root@<board-ip>
```

Default credentials:

- **Username:** `root`
- **Password:** `1234`

## 3. Install required tools

```bash
apt update && apt install -y dosfstools
```

## 4. Download the clone script

```bash
wget https://raw.githubusercontent.com/sicXnull/Debian-Helium-Miners/refs/heads/main/scripts/rockpi-sd2emmc.sh
```

## 5. Make it executable

```bash
chmod +x rockpi-sd2emmc.sh
```

## 6. Run the script

```bash
./rockpi-sd2emmc.sh
```

The script will:

1. Verify you're booted from the SD card (`/dev/mmcblk1`) and that the eMMC (`/dev/mmcblk0`) is present and unmounted.
2. Check that the eMMC has enough free space for the current rootfs usage.
3. Print the detected SD card and eMMC sizes, plus the boot partition layout, for review.
4. Prompt for confirmation before touching the eMMC:

   ```
   This will ERASE /dev/mmcblk0. Type 'yes' to continue:
   ```

   Type **`yes`** and press Enter to proceed.

5. Copy the idbloader/U-Boot area, partition the eMMC, format boot and root partitions, and `rsync` both filesystems over.
6. Update UUIDs in `extlinux.conf` and `fstab` on the eMMC so it boots correctly on its own.

Wait for the script to finish — it prints progress for each copy step and ends with:

```
Done. Remove SD card and power-cycle to boot from eMMC.
(RK3399 boot ROM checks SD before eMMC — pull the card to actually test eMMC boot.)
```

## 7. Boot from eMMC

Power off the board, **remove the SD card**, then power it back on. The RK3399 boot ROM checks the SD card slot before eMMC, so the card must be physically removed to test/confirm an eMMC boot.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `ERROR: root (...) doesn't match expected SRC` | Not booted from the SD card, or device names differ from `/dev/mmcblk1` |
| `ERROR: /dev/mmcblk0 not found` | eMMC module not installed/seated, or device name differs — check `lsblk` |
| `ERROR: rootfs uses ~XMB, only YMB available` | SD card rootfs usage exceeds available eMMC space — free up space on `/` first |
