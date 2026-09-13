# DST Bug Screenshot Analysis (Without Vision Tools)

When vision/OCR tools are unavailable, PIL (Pillow) pixel analysis can extract useful information from DST bug screenshots to narrow down the issue.

## Quick Reference: Pixel Signatures

| Pixel Pattern | What It Means |
|--------------|---------------|
| 93%+ dark pixels (<80 brightness) | Game world view (not a menu) |
| 50%+ dark pixels, many red/white | Crash or error screen |
| 50%+ beige/tan pixels | Mod config screen or server browser |
| Top row full-bright | Windows title bar |
| Gold pixels (R>200,G>180,B<50) | Selection highlight / UI |
| Green pixels (R<80,G>180,B<80) | Health bar UI |
| Red pixels (R>200,G<60,B<60) | Warning or health deficit |
| Blue pixels (R<60,G<100,B>200) | Sanity meter elements |

## Analysis Steps

### 1. Basic Image Metadata

```python
from PIL import Image
img = Image.open("bug.png")
print(f"尺寸: {img.size}, 模式: {img.mode}")
```

Compare dimensions to DST window size (from client_log.txt: `CreateWindow: Requesting W,H`).

### 2. Dark/Light Ratio

```python
pixels = list(img.getdata())
dark = sum(1 for p in pixels if (p[0]+p[1]+p[2])/3 < 80)
bright = sum(1 for p in pixels if (p[0]+p[1]+p[2])/3 > 200)
print(f"暗色: {dark/len(pixels)*100:.1f}%, 亮色: {bright/len(pixels)*100:.1f}%")
```

- >90% dark = in-game world view
- >50% dark + significant red/white = error dialog
- Balanced = likely a UI screen (config, server list, etc.)

### 3. UI Color Detection

```python
# Check center area for game UI colors
center = img.crop((400, 200, 1520, 800))
cp = list(center.getdata())

gold = sum(1 for p in cp if p[0] > 200 and p[1] > 180 and p[2] < 50)
green = sum(1 for p in cp if p[0] < 80 and p[1] > 180 and p[2] < 80)
red = sum(1 for p in cp if p[0] > 200 and p[1] < 60 and p[2] < 60)

print(f"金色UI: {gold}, 绿色UI: {green}, 红色UI: {red}")
```

- Abundant gold/green/red = game HUD is visible and active
- None of these = possibly inventory closed or obscured

### 4. Text Region Detection

Scan row by row for bright pixel clusters:

```python
for y in range(h):
    row = img.crop((0, y, w, y+1))
    row_pixels = list(row.getdata())
    bright = sum(1 for p in row_pixels if (p[0]+p[1]+p[2])/3 > 150)
    if bright > 20:
        print(f"y={y}: {bright} bright pixels")
```

Text regions in DST are typically white/gray on dark background. Group consecutive bright rows to find text blocks (chat messages, item labels, status text).

### 5. Panel/Inventory Detection

```python
# Check if side panels are open (inventory, crafting)
left = img.crop((0, 50, 400, 950))
right = img.crop((1520, 50, w, 950))

left_medium = sum(1 for p in list(left.getdata()) if 100 < (p[0]+p[1]+p[2])/3 < 200)
right_medium = sum(1 for p in list(right.getdata()) if 100 < (p[0]+p[1]+p[2])/3 < 200)

print(f"左侧面板色: {left_medium/len(list(left.getdata()))*100:.1f}%")
```

- >20% medium-bright on one side = likely a UI panel (inventory, crafting menu) is open
- <5% on both sides = no panels open, just game world

### 6. Cross-Reference with Client Log

Always check `client_log.txt` for:
- Timestamps near the screenshot time
- Error/warning lines with the mod name
- Last logged activity (did the game crash or keep running?)

```python
# from hermes_tools import search_files
search_files("(?i)(error|warning|crash|mingsheng)", 
             path="C:\\Users\\Administrator\\Documents\\Klei\\DoNotStarveTogether",
             file_glob="client_log.txt")
```

## Texture Loss Detection (Magenta Blocks)

DST uses magenta/pink (R>200, G<30, B>200) as the "missing texture" fallback. If a mod's asset fails to load, affected areas render as solid magenta blocks.

```python
all_pixels = list(img.getdata())
magenta = sum(1 for p in all_pixels if p[0] > 200 and p[1] < 30 and p[2] > 200)
cyan = sum(1 for p in all_pixels if p[0] < 30 and p[1] > 200 and p[2] > 200)
print(f"品红色块(贴图丢失): {magenta}, 青色块: {cyan}")
```

- **magenta > 100**: texture/asset loading failure — check modmain.lua Assets registration
- **magenta == 0**: no texture loss, bug is elsewhere (logic, UI, animation, etc.)

## Bottom HUD Analysis

The DST bottom bar (y > 950 in 1080p) contains the inventory hotbar. Analyzing its pixel density reveals game state:

```python
hud = img.crop((0, 960, w, h))  # w=width, h=height
hud_pixels = list(hud.getdata())
bright_in_hud = sum(1 for p in hud_pixels if (p[0]+p[1]+p[2])/3 > 150)
print(f"HUD亮色占比: {bright_in_hud/len(hud_pixels)*100:.1f}%")
```

- **>3% bright pixels in HUD**: inventory bar is visible with items
- **<1% bright pixels**: HUD is hidden or barely visible (F12 screenshot mode, or game in cinematic)
- Repeating grid patterns with separators indicate individual item slots are rendered

## OCR Options for Text Extraction

When you need to actually read text from a screenshot:

### easyocr (recommended for Chinese + English)

**Installation:**
```bash
pip install easyocr
```

**Model download (first run only — ~100MB, takes 1-3 minutes):**
Run as a background process to avoid blocking the session:
```python
# Run via terminal() with background=true + notify_on_complete=true
# Command:
.venv/Scripts/python.exe -c "import easyocr; reader = easyocr.Reader(['ch_sim', 'en'], gpu=False); print('done')"
```

After models are cached, `readtext()` takes ~40s for a 1920×1021 screenshot.

**Text extraction:**
```python
import easyocr
reader = easyocr.Reader(['ch_sim', 'en'], gpu=False)
results = reader.readtext("bug.png")
for bbox, text, conf in results:
    if conf > 0.3:
        print(f"[{conf:.2f}] (x={bbox[0][0]:.0f}, y={bbox[0][1]:.0f}) {text}")
```

**Real example** — mingsheng bug.png (1920×1021):
```
[0.80] (x=107, y=12) Dont Stare Together       ← window title
[0.75] (x=1833, y=101) 天1                      ← Day 1 counter
[0.37] (x=955, y=279) RECORDED WAYPOINTS       ← teleport screen title
```
Low confidence (0.37) on the title is normal for game fonts with decorative styling.

### pytesseract (requires system tesseract binary)

Windows: download from https://github.com/UB-Mannheim/tesseract/releases
Install with Chinese language pack, then:
```python
import pytesseract
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
text = pytesseract.image_to_string(img, lang='chi_sim+eng')
```

### browser_vision (requires vision-capable model)

Only works when the active LLM model supports image inputs (GPT-4o, Claude, Gemini).
Not supported by: DeepSeek models. Switch model with `hermes config set model <vision_model>`.

## Limitations

- Cannot read actual text content without OCR (pytesseract or easyocr)
- Cannot identify specific visual glitches (texture corruption, model issues)
- Color analysis is approximate and depends on DST's specific color palette
- browser_vision depends on model capability — check if current model supports image inputs
