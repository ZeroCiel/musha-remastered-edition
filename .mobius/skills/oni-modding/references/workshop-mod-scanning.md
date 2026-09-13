# Workshop Mod Scanning

## Finding which subscription mod changed a specific mechanic

### 1. List all installed workshop mods

```python
import os
workshop = r"C:\Program Files (x86)\Steam\steamapps\workshop\content\457140"
for folder in sorted(os.listdir(workshop)):
    print(folder)
```

### 2. Search for DLL strings matching keywords

Most workshop mod `.bin` files are actually ZIP archives (PK header). Scan each one:

```python
import zipfile, io, re, os

workshop = r"C:\Program Files (x86)\Steam\steamapps\workshop\content\457140"
keywords = ['CarbonDioxide', 'Petroleum', 'CrudeOil', 'Skimmer', 'Sieve', 'Diffuser']

for folder in sorted(os.listdir(workshop)):
    mod_dir = os.path.join(workshop, folder)
    for fn in os.listdir(mod_dir):
        fp = os.path.join(mod_dir, fn)
        with open(fp, "rb") as f:
            header = f.read(4)
        if header != b'PK\x03\x04':
            continue
        with open(fp, "rb") as f:
            try:
                z = zipfile.ZipFile(io.BytesIO(f.read()))
                for name in z.namelist():
                    if not name.endswith('.dll'):
                        continue
                    data = z.read(name)
                    txt = data.decode('ascii', errors='ignore')
                    hits = [k for k in keywords if k in txt]
                    if hits:
                        print(f"\n=== {folder} / {name} ===")
                        print(f"  Hits: {hits}")
                        # Show context
                        for m in re.finditer(rb'[\x20-\x7e]{4,}', data):
                            s = m.group().decode('ascii', errors='ignore')
                            if any(k in s for k in ['outputElements', 'ElementConverter'] + keywords):
                                if not any(k in s for k in ['Product', 'AssemblyProduct']):
                                    print(f"  {s}")
            except:
                pass
```

### 3. Check for YAML/JSON config files in ZIP

```python
import zipfile, io, os

workshop = r"C:\Program Files (x86)\Steam\steamapps\workshop\content\457140"
for folder in sorted(os.listdir(workshop)):
    mod_dir = os.path.join(workshop, folder)
    for fn in os.listdir(mod_dir):
        fp = os.path.join(mod_dir, fn)
        with open(fp, "rb") as f:
            if f.read(4) != b'PK\x03\x04':
                continue
        with open(fp, "rb") as f:
            try:
                z = zipfile.ZipFile(io.BytesIO(f.read()))
                for name in z.namelist():
                    if name in ['config.json', 'mod.yaml', 'mod_info.yaml']:
                        content = z.read(name).decode('utf-8', errors='ignore')
                        # Check for relevant keywords
                        if any(k in content.lower() for k in ['petroleum', 'crudeoil', 'skimmer']):
                            print(f"\n=== {folder} / {name} ===")
                            print(content[:500])
            except:
                pass
```

### 4. Get mod name from Steam Workshop

Once you have a candidate workshop ID:

```bash
curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id={workshop_id}" | grep -oP '<div class="workshopItemTitle">[^<]+'
```

## Common mods that modify building outputs

| Workshop ID | Name | What it does |
|---|---|---|
| `3557584850` | Ronivan's Legacy - Industrial Revolution (Chemical Processing) | Adds CO2 compressor, changes many building outputs |
| `2877460966` | Configurable Automatic Machine | Auto-runs machines, can modify outputElements |
| `1818138009` | Customize Buildings | Configurable building properties including outputs |
| `2836775275` | AutomaticOilRefinery | (Your mod — only patches OilRefinery) |

## What to check when "Water Purifier produces Petroleum"

This is almost always a **Harmony patch gone wrong** rather than a single building being changed:

1. **ElementConverter is a shared component** — GameObjects in ONI get components added at build time. If a Harmony patch targets `ElementConverter` generically (or targets a null method and Harmony's auto-scan matches something else), it can overwrite **every** building's outputElements
2. **Your own mod is the first suspect** — Patch `OilRefineryConfig.DoPostConfigureComplete` (correct) not `OilRefinery.OnPrefabInit` (doesn't exist in 2026)
3. **Ronivan's Legacy** (`3557584850`) is also a strong candidate — it contains `Chemical_CarbonDioxideCompressorConfig` and `Chemical_CrudeOilRefineryConfig`
