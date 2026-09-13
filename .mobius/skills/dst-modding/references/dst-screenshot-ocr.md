# DST 截图分析 — EasyOCR 文字提取

当无法直接"看"图片时，用 EasyOCR 提取 DST 截图中的中英文文字来定位 UI 元素。

## 安装

```bash
pip install easyocr -i https://pypi.tuna.tsinghua.edu.cn/simple
```

首次使用会自动下载模型（约 100MB，需几分钟）。

### 预下载模型 (避免首次等待)

```bash
# 后台下载，不阻塞
python -c "import easyocr; reader = easyocr.Reader(['ch_sim', 'en'], gpu=False); print('done')"
```

下载一次后 `Reader()` 实例化只需几秒。

## 使用

```python
import easyocr

reader = easyocr.Reader(['ch_sim', 'en'], gpu=False)
results = reader.readtext("bug.png")

for bbox, text, confidence in results:
    if confidence > 0.2:
        y = (bbox[0][1] + bbox[2][1]) / 2
        x = (bbox[0][0] + bbox[2][0]) / 2
        print(f"[{confidence:.2f}] ({x:.0f},{y:.0f}) \"{text}\"")
```

## 对 DST 截图的效果

- DST 的像素字体 OCR 识别率约 30-80%
- 纯白文字在深色背景上效果好
- 金色文字（如传送点名称）识别率较低
- 窗口标题栏文字通常能识别
- 适合用来定位 UI 元素的**位置和内容**

## 结合 PIL 像素分析

OCR 只能读文字，结合 PIL 扫描亮暗分布可以找到 UI 面板边界：

```python
from PIL import Image

img = Image.open("bug.png")
w, h = img.size

# 扫描每行平均亮度，找 UI 面板的 Y 边界
for y in range(0, h, 5):
    row = img.crop((0, y, w, y+1))
    px = list(row.getdata())
    avg = sum((p[0]+p[1]+p[2])/3 for p in px) / len(px)
    if avg > 80:  # 亮色 = UI 区域
        print(f"y={y}: avg={avg:.1f}")
```
