# DOCX Text Extraction

## Method 1: python-docx (preferred)

```python
from docx import Document
doc = Document("file.docx")
for para in doc.paragraphs:
    print(para.text)
```

Install: `pip install python-docx`

## Method 2: zipfile + xml.etree (fallback)

Use when python-docx is unavailable or pip is timing out. Works on any system with stdlib only.

```python
import zipfile
import xml.etree.ElementTree as ET

NS = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'

with zipfile.ZipFile("file.docx") as z:
    xml_content = z.read('word/document.xml')
    root = ET.fromstring(xml_content)
    texts = []
    for t in root.iter(f'{NS}t'):
        if t.text:
            texts.append(t.text)
    full_text = '\n'.join(texts)
```

## Limitations of Method 2

- No paragraph structure preservation (runs text flat)
- No formatting (bold, font size, etc.)
- No tables, headers, footers
- Good for bulk text extraction; bad for layout-preserving conversion

## When to use which

| Situation | Choice |
|-----------|--------|
| python-docx installable | Method 1 |
| pip timing out / offline | Method 2 |
| Need paragraph structure | Method 1 |
| Need formatting info | Method 1 |
| Quick text dump only | Either |

## Large documents

Both methods can handle large files. For Method 2, read `word/document.xml` only — ignore `word/header*.xml`, `word/footer*.xml` unless you need those sections.
