# Release Assets

Put a custom DMG background here:

```text
ReleaseAssets/DMGBackground.png
```

Recommended size:

```text
3200 x 1920 px
```

The DMG window is `800 x 480` points. Use `3200 x 1920` source artwork for easy editing; the script embeds it as a `1600 x 960`, `144 DPI` Retina Finder background.

The DMG script will use this PNG automatically. Keep the background as artwork only; Finder will place the real `ArchivePeek.app` icon and the real `Applications` shortcut on top.

Default icon positions:

```text
ArchivePeek.app: 196, 268
Applications:    612, 268
Icon size:       128
Window size:     800 x 480
```

You can override those when building:

```sh
DMG_BACKGROUND=/path/to/background.png \
DMG_WINDOW_WIDTH=900 \
DMG_WINDOW_HEIGHT=540 \
DMG_APP_ICON_X=220 \
DMG_APP_ICON_Y=300 \
DMG_APPLICATIONS_ICON_X=680 \
DMG_APPLICATIONS_ICON_Y=300 \
Scripts/create_dmg.sh
```
