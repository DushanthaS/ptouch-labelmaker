# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the App

```bash
python labelmaker.py
# or with a custom port:
PORT=8080 python labelmaker.py
```

The app runs on `0.0.0.0:5000` by default (debug mode enabled).

## Dependencies

No requirements file exists yet. Key dependencies:
- `flask` — web framework
- `Pillow` — image generation
- `qrcode` — QR code generation
- `cairosvg` (optional) — SVG icon support; app gracefully degrades without it

The external binary `/opt/ptouch-print/build/ptouch-print` must be present and accessible to actually communicate with the printer. The app handles its absence gracefully (printer shown as unavailable).

## Architecture

This is a single-file Flask app (`labelmaker.py`) with a single-page frontend (`templates/index.html` + `static/app.js`).

**Server-side flow:**
1. `GET /` — renders the UI, queries printer info, injects config into the template as `window.PTOUCH_CONFIG`
2. `POST /api/preview` — renders a 1-bit PNG label image in `/tmp/ptouch_web/`, returns a `file_id`
3. `POST /api/print` — sends the previously-generated PNG to `ptouch-print --image=<path>`
4. `GET /api/printer_status` — returns live printer status (polled by the frontend)
5. `GET /api/icons` — browses `static/icons/` directory tree for the icon picker

**Label rendering pipeline** (`render_label_png`):
- Composes icon (left) + QR code (middle) + text (right) horizontally
- Font size auto-shrinks to fit the tape height
- Output is a 1-bit (black/white) PIL Image

**Key classes/globals:**
- `PrinterInfo` (dataclass) — parsed output from `ptouch-print --info`
- `FontCatalog` — discovers system fonts via `fc-list`, builds a keyed library; result is LRU-cached
- `BORDER_STYLES` — dict defining available border styles (none/thin/thick/double/dashed)
- `ERROR_CODES` — loaded from `error_codes.json` at startup (with hardcoded fallback)

**Icon system:**
- Icons live under `static/icons/` and are organized in subdirectories
- `resolve_icon_path()` enforces path traversal safety (no escaping the icons dir)
- SVG support requires `cairosvg`; the `supports_svg` flag is passed to the frontend

**Frontend** (`static/app.js`):
- Vanilla JS (no framework), wrapped in an IIFE
- Reads `window.PTOUCH_CONFIG` injected by the template for defaults
- Icon picker is a modal that browses `/api/icons` with breadcrumb navigation
- Preview is fetched from `/api/preview` and displayed as an `<img>`; `file_id` is stored for the subsequent print call

## Adding Error Codes

Edit `error_codes.json` — keys are 4-digit hex strings (e.g. `"0001"`), values are human-readable messages. The file is loaded once at startup.
