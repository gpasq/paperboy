# Paperboy

A macOS menu bar app that shows the last ~15 days of Bing homepage images and sets any of them as your desktop wallpaper (in 4K).

## Build & run

    ./build.sh            # builds build/Paperboy.app
    ./build.sh --install  # also copies it to /Applications and launches it

Requires macOS 14+ and Xcode command-line tools.

## Features

- Thumbnail grid of recent Bing images with title and caption
- **Archive** tab browses every Bing image back to 2010 by year and month (plus a shuffle button), via the community-run [Bing Wallpaper Archive](https://github.com/npanuhin/Bing-Wallpaper-Archive). Images from before ~2019 are only available at their original resolution (as low as 958×512).
- **Set as Wallpaper** downloads the UHD image and applies it to every display
- **Download** saves images to `~/Pictures/Paperboy`
- **Automatically use today's image**: checks hourly and switches when Bing posts a new one
- **Launch at login** (works best once installed in /Applications)

macOS applies wallpaper to the current Space only. If you use multiple Spaces, set the image from each one.
