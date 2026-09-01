## Identify Board:

There are two (atleast) versions of this board. The one with integrated Lora card did not work for me when it came to running the packet forwarder. I was unable to get SPI communications. I am unsure if the board was just bad (i bought it secondhand off eBay) or there is something different I did not come across. So for now, This image is only recommended for Boards with an External lora card.


<img width="807" height="605" alt="good" src="https://github.com/user-attachments/assets/42a82ad0-f666-4224-918c-8c104300f755" />

<img width="807" height="605" alt="bad" src="https://github.com/user-attachments/assets/7fa4622c-56b9-405b-a843-7ff14c36c9fd" />

## Characteristics

- CPU: Rockchip RK3566
- Memory: 2GB
- Flash: 64GB (eMMC)

## Read Before Flashing



## Flashing From Windows

1. Install RKDevTool and the corresponding driver, following [these instructions](https://wiki.radxa.com/Rock5/install/rockchip-flash-tools#Option_one:_RKDevTool_on_Windows).
2. Use a USB-A to USB-C cable to connect the unit to your PC via the port labeled **FLASH USB**.
3. Connect the power adapter to your unit. The Ethernet cable is not needed.
4. Press and hold the **RESET** button.
5. Hold until PC recognizes LOADER mode.
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
5. Wait until PC recognizes device.
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
- Repeat the RESET-button procedure.
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

If you need to reflash and pushing the button on the back is unresponsive, you can short the pin in the photo to force the device into Maskrom Mode 

<img width="605" height="807" alt="maskrom" src="https://github.com/user-attachments/assets/3cec6535-31e1-4e00-8291-b7295265ec6d" />

