# Debian Helium Miners
 
Debian Bookworm on Kernel 6.x for various Helium (IoT/Rockchip) miner hardware.
 
This project provides prebuilt Debian Bookworm images and flashing instructions for a range of Helium miner devices based on Rockchip SoCs.
 
## Supported Devices
 
## Supported Devices
 
| Miner            | SoC          | SD Boot Support | Boot Method     | Image Download | Loader File |
|-------------------|--------------|:----------------:|------------------|-----------------|-------------|
| Bobcat G280        | PX30         | ✅ Yes            | SD Card          | [Download](../../releases/download/latest/debian-helium-g280.img.xz) | — |
| Bobcat G285        | RK3566       | ✅ Yes            | SD Card          | [Download](../../releases/download/latest/debian-helium-g285.img.xz) | — |
| Bobcat 29x         | RK3566       | ❌ No             | Internal eMMC    | [Download](../../releases/download/latest/debian-helium-29x.img.xz) | [Loader](https://github.com/sicXnull/Debian-Helium-Miners/blob/main/loader-files/rk356x_spl_loader_ddr1056_v1.10.111.bin) |
| Panther X2         | RK3566       | ✅ Yes            | SD Card          | [Download](../../releases/download/latest/debian-helium-pantherx2.img.xz) | — |
| Nebra RockPi       | Rockchip     | ✅ Yes            | Internal eMMC    | [Download](../../releases/download/latest/debian-helium-nebra-rockpi.img.xz) | — |  |
| Heltec HT-M2808    | RK3328       | ❌ No             | Internal eMMC    | [Download](../../releases/download/latest/debian-helium-heltec-ht-m2808.img.xz) | [Loader](https://github.com/sicXnull/Debian-Helium-Miners/blob/main/loader-files/rk356x_spl_loader_ddr1056_v1.10.111.bin) |
 
> **Note:** Devices with "Internal eMMC" as their boot method must be flashed using RKDeveloptool with the corresponding loader file above. Update the links to point at your actual release assets.

## Default Credentials
 
All devices ship with the following default SSH login:
 
| Field    | Value  |
|----------|--------|
| Username | `root` |
| Password | `1234` |
 
> **Security Note:** Change the default password immediately after first boot with `passwd`.
 
 
## Requirements
 
- Host PC running Linux, macOS, or Windows
- microSD card (8GB minimum) for SD-boot devices
- USB-A to USB-C (or applicable) cable for eMMC flashing
- [balenaEtcher](https://etcher.balena.io/) or `dd` for writing SD images
- [RKDeveloptool](https://github.com/rockchip-linux/rkdeveloptool) for eMMC flashing (29x series only)
---
 
## SD Card Boot Instructions
 
Applies to: **Bobcat G280, Bobcat G285, Panther X2, Nebra RockPi**
 
1. Download the appropriate image for your device from the [Releases](../../releases) page.
2. Decompress the image if it is archived (e.g. `.img.xz`):
```bash
   xz -d debian-helium-<device>.img.xz
```
3. Identify your SD card device node:
```bash
   lsblk
```
   Be certain you select the correct device (e.g. `/dev/sdX` or `/dev/mmcblkX`) — writing to the wrong disk will destroy data.
4. Write the image to the SD card:
```bash
   sudo dd if=debian-helium-<device>.img of=/dev/sdX bs=4M status=progress conv=fsync
```
5. Once complete, safely eject the card:
```bash
   sudo eject /dev/sdX
```
6. Insert the SD card into the miner and power it on. The device should boot directly from the SD card.
---
 
## eMMC Flashing Instructions (Bobcat 29x)
 
 
### 1. Install RKDeveloptool
 
```bash
git clone https://github.com/rockchip-linux/rkdeveloptool.git
cd rkdeveloptool
autoreconf -i
./configure
make
sudo make install
```
 
### 2. Enter Maskrom/Loader Mode
 
1. Power off the miner completely and disconnect the power supply.
2. Hold the recovery/maskrom button (or short the required pins per device documentation).
3. Connect the USB cable to the host PC while continuing to hold the button.
4. Apply power to the miner while still holding the button, then release after ~2–3 seconds.
### 3. Verify Device Detection
 
```bash
sudo rkdeveloptool ld
```
 
You should see the device listed as `Maskrom` or `Loader` mode.
 
### 4. Flash the Loader (if required)
 
```bash
sudo rkdeveloptool db <loader_file>.bin
```
 
### 5. Write the Image to eMMC
 
```bash
sudo rkdeveloptool wl 0 debian-helium-29x.img
```
 
### 6. Reset and Boot
 
```bash
sudo rkdeveloptool rd
```
 
Disconnect the USB cable and power-cycle the miner normally. It should boot Debian Bookworm from the internal eMMC.
 
---
 
## Troubleshooting
 
| Issue | Possible Cause | Fix |
|---|---|---|
| Device not detected by `rkdeveloptool ld` | Not in maskrom mode | Retry the button/timing sequence in step 2 |
| SD card not booting | Card not written correctly, or SD boot fused off | Re-write image; confirm device supports SD boot per the table above |
| Flash fails partway through eMMC write | Bad USB cable or port | Use a rated USB-C data cable and a direct (non-hub) USB port |
