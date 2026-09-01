# Heltec HT-M2808 — Custom OS Flashing Guide
 
## Board Layout
 
<img width="2040" height="2198" alt="heltec-layout" src="https://github.com/user-attachments/assets/7ba87ff1-cb82-471e-b0ef-cb489166dcc1" />

 
## Characteristics
 
- CPU: Rockchip RK3328 (quad-core Cortex-A53, 1.5GHz)
- Memory: 2GB DDR4
- Flash: 32GB eMMC 5.1
## Read Before Flashing
 
> **WARNING:** Flashing your unit with a custom, 3rd-party OS will erase the original OS along with all existing settings and user data. There is no easy way to back up the existing OS/data, so proceed with caution. There were reports of some users losing I2C functionality which means Helium WILL NOT WORK. When testing on my unit, I2C functionality was fine, but keep this in mind before flashing 
 
## Flashing From Windows
 
1. Install RKDevTool and the corresponding driver, following [these instructions](https://wiki.radxa.com/Rock5/install/rockchip-flash-tools#Option_one:_RKDevTool_on_Windows).
2. Use a USB-C cable to connect the unit to your PC via the board's **Type-C** port (labeled for firmware flash/system recovery).
3. Connect the power adapter to your unit. The Ethernet cable is not needed.
4. Trigger recovery mode — hold the recovery/reset with a small Pin in the reset hole on the back of the unit.
5. Hold until PC Recognizes LOADER mode.
6. Release.
7. Run `RKDevTool.exe`. The bottom-left status should read "Found One LOADER Device." If not detected, repeat from step 3. If it instead shows "MASKROM," skip to step 11.
8. Erase the flash:
   - Click the **Advanced Function** tab.
   - Click **EraseAll**.
   - Wait for the process to complete.
9. Reset the board by unplugging and replugging the power cable.
10. Verify the board is in Maskrom mode: the status should read "Found One MASKROM Device."
11. Download the bootloader required for flashing:
    [rk3328_loader_ddr333_v1.16.250.bin](https://github.com/sicXnull/Debian-Helium-Miners/blob/main/loader-files/rk3328_loader_ddr333_v1.16.250.bin)
12. Push the bootloader onto the board:
    - Click the **Advanced Function** tab.
    - Select the downloaded bootloader next to "Boot."
    - Click **Download**.
13. Optional — if you haven't erased the flash yet, do it now:
    - Click **EraseAll**.
    - Wait for the process to complete.
14. Confirm the board is ready to flash:
    - Click **TestDevice**.
    - Verify the log panel reads "Test Device Success."
15. Flash your OS image:
    - Click the **Download Image** tab.
    - Make sure the first item is unchecked and the second is checked.
    - For the second item, set **Storage** to `EMMC` and **Address** to `0x00000000`.
    - Check **Write by Address**.
    - Click **Run** and wait for completion.
16. Reset the board by unplugging and replugging power. It should now boot your OS.
## Flashing From Linux/macOS
 
1. Install `rkdeveloptool`, following [these instructions](https://wiki.radxa.com/Rock3/install/rockchip-flash-tools#Install_Rockchip_flashing_tools) or others specific to your OS.
2. Use a USB-C cable to connect the unit to your PC via the board's **Type-C** flash/recovery port.
3. Connect the power adapter. The Ethernet cable is not needed.
4. Trigger recovery mode (see note in step 4 of the Windows procedure above).
5. Wait until PC recognizes the device.
6. Release.
7. Confirm Loader mode:
```
   sudo rkdeveloptool ld
```
   Expected output (confirm the exact VID/PID against what shows up on your system — RK3328 uses different values than other Rockchip chips, so don't assume a hex value not shown here):
```
   DevNo=1  Vid=0x2207,Pid=<RK3328 PID>,LocationID=304  Loader
```
   If not detected, repeat from step 3. If it shows "Maskrom" instead, skip to step 11.
8. Erase the flash (takes ~1–2 minutes; do not interrupt, even if it appears stalled):
```
   sudo rkdeveloptool ef
```
9. Reset the board by unplugging and replugging power.
10. Confirm Maskrom mode:
```
    sudo rkdeveloptool ld
```
11. Download the bootloader required for flashing:
    [rk3328_loader_ddr333_v1.16.250.bin](https://github.com/sicXnull/Debian-Helium-Miners/blob/main/loader-files/rk3328_loader_ddr333_v1.16.250.bin) (same file as noted in the Windows section).
12. Push the bootloader onto the board:
```
    sudo rkdeveloptool db /path/to/rk3328_loader_ddr333_v1.16.250.bin
```
13. Optional — if you haven't erased the flash yet, do it now:
```
    sudo rkdeveloptool ef
```
14. Confirm the board is ready to flash:
```
    sudo rkdeveloptool td
```
    Expected output: `Test Device OK.`
15. Flash your OS image (this step takes a while — do not interrupt):
```
    sudo rkdeveloptool wl 0 HeltecBookworm.img
```
16. Reset the board by unplugging and replugging power. It should now boot your OS.
## Troubleshooting
 
### Device not detected by the flashing tool
- Repeat the recovery-trigger procedure.
- Use a known-good USB-C **data** cable (some cables are power/charge-only).
- Make sure no SD card is inserted.
- Confirm the device is powered.
- If none of the above works, see [Force Maskrom Mode](#force-maskrom-mode) below.
### Device shows up in Maskrom mode instead of Loader mode
Skip directly to step 11 in the relevant procedure above — but don't skip the optional erase step.
 
### "Test Device quit, creating comm object failed!" or similar
Make sure you're running `rkdeveloptool` commands with `sudo` or as root.
 
### The `rkdeveloptool db` command is stuck
- Confirm you downloaded the correct bootloader binary (`rk3328_loader_ddr333_v1.16.250.bin` — not an RK3566/RK3568 loader, which won't work on this chip).
- Try a different USB cable or port.
### All flashing steps succeeded but the OS won't boot
- Make sure the OS image was fully extracted before flashing.
- Some OS images aren't raw images — they lack the "boot" portion and use a different format, which won't work with this method.
- Try the [UART Debugging](#uart-debugging) procedure below to inspect the boot log.
## Force Maskrom Mode
 
You need the device in Maskrom mode to flash a raw OS image. The standard method works because erasing the flash causes the device to fall back to Maskrom mode automatically when nothing bootable remains.
 
*(A "FLASH DISABLE" pad short-to-ground trick is a common fallback on similar boards. Short the following pin on the front of the board, you'll need to remove the heatsink assembly*

<img width="2162" height="2163" alt="Heltec-maskrom-pin" src="https://github.com/user-attachments/assets/60e78f09-0ca4-4862-9255-d695858b0cd4" />

 
## UART Debugging
 
UART debugging isn't needed for a normal OS flash, but it's useful for diagnosing issues.
 
| USB wire | Adapter pin |
|----------|-------------|
| Black    | GND         |
| Green    | RXD         |
| White    | TXD         |
| Red      | *(leave unconnected)* |
 
Steps:
 
1. Connect the UART pins/pads to your laptop using the adapter cable. *(Exact pad location on this board not confirmed — verify against your own board notes.)*
2. Your laptop should recognize the USB-to-UART adapter; install drivers if prompted.
3. Use a serial terminal (PuTTY, minicom, etc.) to read the log. Configure the port as **1500000 8N1**.
If you get no output or garbled characters:
- Try swapping the RXD/TXD wiring.
- Try a different USB-to-UART adapter (voltage level or baud rate mismatch).
- Some onboard serial ports are fragile and may be damaged — you might have a defective one.
