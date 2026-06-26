# SleepyCat Screen Off

Chinese name: 猫猫熄屏

<p align="center">
  <img src="assets/icon-cropped-preview.png" width="128" alt="SleepyCat Screen Off icon">
</p>

A small local-only macOS utility. Double-click `猫猫熄屏.app` to put all connected displays into real display sleep while keeping the Mac awake for 8 hours so downloads, computation, syncing, or local tasks can continue.

## Download and Use

1. Download `SleepyCat-Screen-Off-macOS.zip` from GitHub Releases.
2. Unzip it to get `猫猫熄屏.app`.
3. Move the app to Applications or Desktop.
4. Double-click it.

If macOS blocks the app because it is from an unidentified developer, right-click `猫猫熄屏.app` and choose Open the first time.

If you pin it to the Dock, click it once. This is the fixed 8-hour version, not an indefinite mode.

## What It Does

- Turns off all built-in and external displays.
- Keeps the Mac itself running for a fixed 8 hours.
- Turns off all connected extended displays while keeping the computer running normally, which is useful for downloads, long local tasks, and vibe coding.
- Uses no network connection and collects no data.
- Uses macOS native `pmset displaysleepnow`; it does not use a blackout overlay fallback.

## Important Notes

- Use it while connected to power.
- Do not close the laptop lid; closing the lid usually triggers system sleep.
- This is not macOS system sleep, screen lock, screen saver, or a video-player screen-off button.
- It only puts displays to sleep while keeping the computer awake for 8 hours so downloads, computation, syncing, or research tasks can continue.
- Behavior can vary across macOS versions, monitors, docks, and power settings.
- This is the fixed 8-hour version; the wake-keeping process ends automatically after 8 hours.

## Build from Source

Maintainers can run this from the project root:

```bash
./scripts/build_release.sh
```

Outputs:

- `build/猫猫熄屏.app`
- `dist/SleepyCat-Screen-Off-macOS.zip`

## Disclaimer

This tool is free, local-only, and provided as is, without warranty of any kind. Users are responsible for deciding whether it is suitable for their Mac, displays, docks, and workloads. The author is not responsible for data loss, interrupted tasks, hardware issues, system issues, or any other damage or loss arising from use of this tool.
