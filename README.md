# ArchivePeek

ArchivePeek is a native macOS Quick Look extension for browsing archive contents without extracting the whole file first.

Select an archive in Finder, press Space, and inspect the files inside. You can expand folders, copy or extract selected items, and keep the archive intact.

## Features

- Quick Look previews for archive files directly in Finder
- Finder-style file list with folders, sizes, kinds, and modified dates
- Expand folders inside an archive without unpacking everything
- Extract only the selected file or folder
- Copy selected archive contents to Finder by staging a real temporary file or folder
- Supports common archive formats through libarchive

## Supported Formats

ArchivePeek registers support for archive content types including:

- ZIP
- RAR
- 7z
- TAR
- TGZ / GZip tarballs
- GZ
- BZip2 archives

Support depends on the libarchive capabilities available on the user's macOS installation.

## Requirements

- macOS 15.0 or later
- Xcode 16 or later for building from source
- Swift 6

## Install From a Release

1. Download the latest `.dmg` from the GitHub Releases page.
2. Open the DMG.
3. Drag `ArchivePeek.app` into `Applications`.
4. Open `ArchivePeek.app` once.
5. Click `Enable Extension`.
6. In System Settings, enable ArchivePeek under Quick Look extensions.
7. In Finder, select an archive and press Space.

If the extension does not appear immediately, log out and back in, or run:

```sh
qlmanage -r
pluginkit -m | grep ArchivePeek
```

## Build From Source

Clone the repository:

```sh
git clone https://github.com/methsithchan/ArchivePeek.git
cd ArchivePeek
```

Build with Xcode:

```sh
xcodebuild -project ArchivePeek.xcodeproj -scheme ArchivePeek -configuration Debug build
```

Or open the project:

```sh
open ArchivePeek.xcodeproj
```

The app target embeds the `ArchivePeekPreview` Quick Look extension.

## Creating a DMG

For a GitHub release, build the app and package it in a DMG with an Applications shortcut:

```sh
Scripts/create_dmg.sh
```

The DMG is written to:

```text
dist/ArchivePeek-1.0.dmg
```

Without a paid Apple Developer account, ArchivePeek can still be shared on GitHub, but the DMG will not be Developer ID signed or notarized. Users may need to right-click `ArchivePeek.app`, choose `Open`, and confirm the first launch.

For the smoothest public distribution outside the App Store, sign and notarize the app before publishing the DMG.

## Troubleshooting

If Quick Look still shows the default ZIP preview:

```sh
qlmanage -r
qlmanage -r cache
```

Then reopen Finder or log out and back in.

If the extension is installed but disabled, open ArchivePeek and use `Enable Extension`, or go to:

```text
System Settings > General > Login Items & Extensions > Quick Look
```

## Project Structure

```text
ArchivePeek/            macOS container app and onboarding UI
ArchivePeekPreview/     Quick Look extension, archive reader, and preview UI
Headers/libarchive/     libarchive headers used by the Swift bridge
project.yml             XcodeGen project definition
```

## Status

ArchivePeek is early software. The core Quick Look browsing, selected extraction, and copy-to-Finder flow are working, but release signing and notarization still need to be configured before publishing a production DMG.
