# GarageBand Export Script

A Bash script to batch export GarageBand `.band` projects into MP4 files and optionally copy the raw audio files, fully organized and with optional step-by-step control.

---

## Features

- Batch export all `.band` projects in a folder.
- Exports **MP4 audio mixes** using `ffmpeg`.
- Optional **RAW export** of uncompressed audio files directly into a `RAW/` folder.
- Step mode: prompt before processing each project (skip option available).
- Verbose mode: detailed logging of operations.
- Automatically handles duplicate project names by adding `_1`, `_2`, etc.
- Organizes output into:
  - `MP4/` → exported MP4 files
  - `RAW/` → raw audio files (if `--raw` is enabled)

---

## Requirements

- macOS or Linux  
- **Bash 4+** (or compatible)  
- [`ffmpeg`](https://ffmpeg.org/) installed and in your PATH  

```bash
brew install ffmpeg      # macOS
sudo apt install ffmpeg  # Ubuntu/Debian

Usage
./exportBand.sh -i "/path/to/band/folder" -o "/path/to/output/folder" [options]
```
## Options
| Flag | Description |
|------|-------------|
| `-i, --input`  | Path to folder containing `.band` projects (required) |
| `-o, --output` | Path to output folder (optional, defaults to `Exports` in input folder) |
| `-v, --verbose` | Enable detailed logging |
| `-s, --step`   | Step mode: prompt before exporting each project (skip with `s`) |
| `-r, --raw`    | Copy raw audio files into `RAW/` folder, renamed to project name |

---

## Output Structure
```
├── MP4
│   ├── Project-1.mp4
│   ├── Project-2.mp4
│   └── Project-3.mp4
└── RAW
    ├── Project-1.wav
    ├── Project-2.wav
    └── Project-3.wav
```

## Notes
- If multiple audio files exist in the same .band project, the script numbers them when copying to RAW/.
- Step mode allows pressing Enter to export or S to skip project.
- Duplicate MP4 file names are automatically resolved by numbering.
- RAW files are renamed based on the project name and placed directly in the RAW folder.

## License
MIT License – free to use, modify, and distribute.
