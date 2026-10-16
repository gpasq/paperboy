# Paperboy

A macOS menu bar app that shows Bing homepage images, from today's back to 2010, and sets any of them as your desktop wallpaper (in 4K where available).

## Build & run

    ./build.sh            # builds build/Paperboy.app
    ./build.sh --install  # also copies it to /Applications and launches it

Requires macOS 14+ and Xcode or the Xcode Command Line Tools. With only the Command Line Tools installed, `build.sh` builds against the newest macOS 26 SDK, because the macOS 27 SDK there lacks the SwiftUI macro plugin. Set `SDKROOT` to override this.

## Features

- **Recent** tab: thumbnail grid of the last ~15 days of Bing images with title and caption
- **Archive** tab: browse every Bing image back to 2010 by year and month, or hit shuffle for a random day
- **Set as Wallpaper** downloads the full-size image and applies it to every display
- **Download** saves images to `~/Pictures/Paperboy`
- **Automatically use today's image**: checks hourly and switches when Bing posts a new one
- **Launch at login** (works best once installed in /Applications)

## Archive

Bing's own API only serves about the last 15 days, so the Archive tab loads one year at a time from the community-run [Bing Wallpaper Archive](https://github.com/npanuhin/Bing-Wallpaper-Archive) (bing.npanuhin.me). It uses your region's archive when one exists and falls back to the US archive otherwise.

Images from 2019 onward come straight from Bing in UHD. Older ones are only available at their original resolution, which can be as low as 958×512 for 2010, so they may look soft on large displays.

## Notes

macOS applies wallpaper to the current Space only. If you use multiple Spaces, set the image from each one.
