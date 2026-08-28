# PantherX2/MerryIOT — Custom OS Flashing Guide
 
## Board Layout
 
<img width="2104" height="1672" alt="panther-x2-layout" src="https://github.com/user-attachments/assets/135e7111-e147-4f35-8ad1-1a718acf0262" />
 
## Characteristics
 
- CPU: Rockchip RK3566
- Memory: 2GB
- Flash: 64GB
## Read Before Flashing
 
The PantherX2/MerryIOT running its original OS might be able to boot off the SD card if present. Try this first by writing your OS image onto an SD card and inserting it into the slot. If this doesn't work, proceed with the flashing instructions below.
 

> **WARNING:** Flashing your unit with a custom, 3rd-party OS will erase the original OS along with all existing settings and user data. There is no easy way to back up the existing OS/data, so proceed with caution.
 
 
## Flashing From Windows
 
1. Install RKDevTool and the corresponding driver, following [these instructions](https://wiki.radxa.com/Rock5/install/rockchip-flash-tools#Option_one:_RKDevTool_on_Windows).
2. Use a USB-A to USB-A cable to connect the unit to your PC via the port labeled **FLASH USB**.
3. Connect the power adapter to your unit. The Ethernet cable is not needed.
4. Press and hold the **RESET** button.
5. Hold until PC Recognizes LOADER mode
6. Release the **RESET** button.
7. Run `RKDevTool.exe`. The bottom-left status should read "Found One LOADER Device." If not detected, repeat from step 3. If it instead shows "MASKROM," skip to step 11.
8. Erase the flash:
   - Click the **Advanced Function** tab.
   - Click **EraseAll**.
   - Wait for the process to complete.
9. Reset the board by unplugging and replugging the power cable.
10. Verify the board is in Maskrom mode: the status should read "Found One MASKROM Device."
11. Download the bootloader required for flashing:
    [rk356x_spl_loader_ddr1056_v1.10.111.bin](https://dl.radxa.com/rock3/images/loader/rock-3a/rk356x_spl_loader_ddr1056_v1.10.111.bin)
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
2. Use a USB-A to USB-A cable to connect the unit to your PC via the **FLASH USB** port.
3. Connect the power adapter. The Ethernet cable is not needed.
4. Press and hold **RESET**.
5. Wait until PC recognizes device
6. Release **RESET**.
7. Confirm Loader mode:
```
   sudo rkdeveloptool ld
```
   Expected output:
```
   DevNo=1  Vid=0x2207,Pid=0x350a,LocationID=304  Loader
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
    Expected output:
```
    DevNo=1  Vid=0x2207,Pid=0x350a,LocationID=304  Maskrom
```
11. Download the bootloader required for flashing:
    [rk356x_spl_loader_ddr1056_v1.10.111.bin](https://dl.radxa.com/rock3/images/loader/rock-3a/rk356x_spl_loader_ddr1056_v1.10.111.bin)
12. Push the bootloader onto the board:
```
    sudo rkdeveloptool db /path/to/rk356x_spl_loader_ddr1056_v1.10.111.bin
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
    sudo rkdeveloptool wl 0 /path/to/your_os.img
```
16. Reset the board by unplugging and replugging power. It should now boot your OS.
## Troubleshooting
 
### Device not detected by the flashing tool
- Repeat the RECOVERY-button procedure.
- Use a known-good micro USB **data** cable (some cables are power-only).
- There are two micro USB ports on the board — make sure you're using the one labeled **FLASH USB**.
- Make sure no SD card is inserted.
- Confirm the device is powered.
- If none of the above works, try the [Force Maskrom Mode](#force-maskrom-mode) method below.
### Device shows up in Maskrom mode instead of Loader mode
Skip directly to step 11 in the relevant procedure above — but don't skip the optional erase step.
 
### "Test Device quit, creating comm object failed!" or similar
Make sure you're running `rkdeveloptool` commands with `sudo` or as root.
 
### The `rkdeveloptool db` command is stuck
- Confirm you downloaded the correct bootloader binary.
- Try a different USB cable or port.
### All flashing steps succeeded but the OS won't boot
- Make sure the OS image was fully extracted before flashing.
- Some OS images aren't raw images — they lack the "boot" portion and use a different format, which won't work with this method.
- Try the [UART Debugging](#uart-debugging) procedure below to inspect the boot log.
## Force Maskrom Mode
 
You need the device in Maskrom mode to flash a raw OS image. The standard method works because erasing the flash causes the device to fall back to Maskrom mode automatically when nothing bootable remains.
 
If you can't reach the point of erasing the flash, you can temporarily disable the flash chip by cutting its power. Find the pad marked **FLASH DISABLE** in the board photo and short it to ground with a wire (preferably attached to a sharp metallic tool).
 
With the pad shorted, reset the board via the **RESET** button, then release the short. Continue the flashing procedure from step 9 (Windows) / step 9 (Linux/macOS).
 
## UART Debugging
 
UART debugging isn't needed for a normal OS flash, but it's useful for diagnosing issues.


| USB wire | Adapter pin |
|----------|-------------|
| Black    | GND         |
| Green    | RXD         |
| White    | TXD         |
| Red      | *(leave unconnected)* |
 
Steps:
 
1. Connect the **UART** connector to your laptop using the adapter cable.
2. Your laptop should recognize the USB-to-UART adapter; install drivers if prompted.
3. Use a serial terminal (PuTTY, minicom, etc.) to read the log. Configure the port as **1500000 8N1**.
If you get no output or garbled characters:
- Try swapping the RXD/TXD wiring.
- Try a different USB-to-UART adapter (voltage level or baud rate mismatch).
- Some onboard serial ports are fragile and may be damaged — you might have a defective one.
