<div align="center">

# ArchivePeek

**Quick Look inside your archives, without touching them.**

Select a ZIP, RAR, 7z, or tarball in Finder. Press Space. Done.

![ArchivePeek in action](ReleaseAssets/demo.gif)

</div>

---

## The problem

Every time you want to peek inside an archive, you extract the whole thing — only to find it's the wrong file, or you only needed one folder. You clean up, try again.

ArchivePeek fixes that. It hooks into macOS Quick Look so you can browse archive contents directly in Finder, open folders, and extract *only what you need* — without touching the archive itself.

No new window to open. No app to launch. Just press **Space**.

---

## What's new in 2.0

ArchivePeek 2.0 is a full UI refresh built to feel like browsing a folder in Finder — inside Quick Look.

- **Finder-style icon grid** — large native file icons with names, system materials, and selection highlight
- **In-window back/forward navigation** — AppKit chevrons at the top of the preview (Quick Look hides toolbars, so nav lives inside the panel)
- **Double-click to open** — folders open in-place; files can be extracted with a save panel
- **Keyboard shortcuts** — ← / → to navigate, ⌘C to copy the selected item
- **Native file icons** — pulled from `NSWorkspace` / UTType, same as Finder
- **Refreshed onboarding** — updated setup screen with the real app icon and v2.0 branding
- **Snappier navigation** — back/forward and deep folder browsing no longer rebuild the whole grid on every click

---

## What you can do

| Action | How |
|---|---|
| Browse any archive | Select it in Finder, press Space |
| Open a folder | Double-click the folder icon |
| Go back / forward | Click the chevrons or press ← / → |
| Extract a file | Double-click, or right-click → Extract… |
| Copy to Finder | Right-click → Copy (or ⌘C), then paste in Finder |
| Select an item | Single-click an icon |

---

## Supported formats

`ZIP` `RAR` `7z` `TAR` `TGZ` `GZ` `BZ2`

Powered by **libarchive** — the same library used by BSD tar and countless other tools. Format support reflects whatever libarchive version ships with your macOS installation.

---

## Install

### From a release (recommended)

1. Download **ArchivePeek-2.0.dmg** from [Releases](https://github.com/methsithchan/ArchivePeek/releases)
2. Open the DMG and drag **ArchivePeek.app** to Applications
3. Launch ArchivePeek once and click **Enable Extension**
4. In System Settings → General → Login Items & Extensions → Quick Look, enable ArchivePeek

Now go to Finder, select any archive, and hit Space.

> **Note:** Distributed without an Apple Developer ID signature, so on first launch you may need to right-click → Open to bypass Gatekeeper. This is a one-time step.

### From source

Requirements: macOS 15, Xcode 16, Swift 6

```sh
git clone https://github.com/methsithchan/ArchivePeek.git
cd ArchivePeek
open ArchivePeek.xcodeproj
```

Build the `ArchivePeek` scheme, then run it once from Xcode to register the extension.

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) — if you want to regenerate `project.pbxproj` from `project.yml`, install XcodeGen and run `xcodegen generate`.

---

## How it works

ArchivePeek is a native macOS Quick Look extension — it never runs as a standalone app. When you press Space on an archive, macOS launches the extension inside its own sandboxed process.

```text
Finder (Space) ──► macOS Quick Look server ──► ArchivePeekPreview extension
                                                         │
                                              ArchiveReader (Swift actor)
                                                         │
                                              libarchive (C, streaming)
                                                         │
                                              ArchiveNode tree (immutable)
                                                         │
                                              PreviewContentView (SwiftUI)
```

**The key design decisions:**

- **`ArchiveReader` is a Swift actor.** libarchive is not thread-safe. The actor boundary ensures all archive reads are serialized without locks or manual synchronization.
- **Stream-only reads.** `readTree()` walks the archive header stream without decompressing entry data. For a 2 GB archive, memory use stays flat because content is never loaded — just metadata.
- **`ArchiveNode` is immutable and `Sendable`.** The tree is built via a mutable inner class during parsing, then converted to an immutable value type. This means the SwiftUI view layer can never accidentally mutate archive state.
- **Targeted extraction.** When you extract or copy a single file, `ArchiveReader` re-opens and streams the archive from scratch, skipping entries until it hits the target path. Slightly slower than random access, but it keeps the implementation simple and correct across all libarchive-supported formats.

---

## Project structure

```text
ArchivePeek/              Container app — onboarding UI only
ArchivePeekPreview/       Quick Look extension
  ArchiveReader.swift       libarchive bridge (Swift actor)
  ArchiveNode.swift         Immutable archive tree model
  ArchiveIconView.swift     Finder-style icon grid
  ArchiveAppKitNavBar.swift Native back/forward nav bar
  PreviewContentView.swift  SwiftUI preview UI
  PreviewViewController.swift  QLPreviewingController glue
Headers/libarchive/       libarchive C headers
Scripts/                  DMG packaging script
project.yml               XcodeGen project definition
```

---

## Troubleshooting

**Quick Look still shows the default ZIP preview**

```sh
qlmanage -r
qlmanage -r cache
```

Then reopen Finder, or log out and back in.

**Extension not showing up in System Settings**

```sh
pluginkit -m | grep ArchivePeek
```

If it's not listed, re-run the app. If it's listed but disabled, open System Settings → General → Login Items & Extensions → Quick Look and enable it manually.

---

## Roadmap

- [ ] Code signing & notarization for frictionless first launch
- [ ] File preview panel (inline image and text previews)
- [ ] Compression ratio and total size stats
- [ ] XZ / ZSTD format support

---

## Contributing

Issues and PRs are welcome. For larger changes, open an issue first to discuss the direction.

The project is early but the core (Quick Look integration, libarchive bridge, tree navigation, extraction) is solid. Good first areas: format edge cases, accessibility improvements, and UI polish.

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

Built with Swift 6 and libarchive · Runs entirely in the macOS Quick Look sandbox · No telemetry, no network requests, no background processes

</div>
