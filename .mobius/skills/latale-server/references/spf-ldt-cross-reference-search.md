# SPF/LDT 跨文件引用搜索方法

当需要查找某个道具（如暖呼呼粉嫩大衣 51776811）在所有 LDT 文件中的引用时：

## 搜索范围

他乡端解包后的 LDT 目录（pack=0 可用时）：
- `D:\Server\resource\ROWID\DATA\LDT\` — ROWID.SPF 解包内容（LDT 配置表）
- `D:\Server\DATA\LDT\` — 服务端直接读取的 LDT（可能和 SPF 内版本不同）
- `D:\Server\SPF\DATA\LDT\` — 从 SPF 提取到 SPF 目录的副本

S4chd 解包 LDT：
- `D:\LaTale\S4chd\resource\ROWID\DATA\LDT\`

## 搜索目标

| 目标 | 搜索方式 | 含义 |
|------|---------|------|
| 中文字符串 | `"暖呼呼粉嫩大衣".encode('gbk')` | 道具名/描述文本 |
| 4 字节 ItemID | `struct.pack('<I', 51776811)` | 道具编号引用 |
| 2 字节小整数 | `struct.pack('<H', 1709)` | 图标索引/分类ID |

## Python 批量搜索脚本

```python
import struct, os

target_str = "暖呼呼粉嫩大衣".encode('gbk')
target_id = struct.pack('<I', 51776811)
target_id2 = struct.pack('<I', 1709)

results = {}

search_dirs = [
    "D:\\Server\\resource\\ROWID\\DATA\\LDT",
    "D:\\Server\\DATA\\LDT",
    "D:\\Server\\SPF\\DATA\\LDT",
    "D:\\Server\\SPF\\extracted\\DATA\\LDT",
]

for base in search_dirs:
    if not os.path.isdir(base): continue
    for f in os.listdir(base):
        if not f.endswith('.LDT'): continue
        fpath = os.path.join(base, f)
        try:
            with open(fpath, "rb") as fh:
                data = fh.read(10*1024*1024)  # 最多读10MB
            if f not in results:
                results[f] = set()
            if target_str in data:
                results[f].add("STR")
            if target_id in data:
                results[f].add("ID51776811")
            if target_id2 in data:
                results[f].add("ID1709")
        except:
            pass

for fname, refs in sorted(results.items()):
    print(f"{fname:<30} {', '.join(sorted(refs))}")
```

## 快速搜索未解包 SPF

如果 SPF 未解包，可以直接在 .SPF 文件中搜索二进制：

```python
import struct, os

targets = {
    "暖呼呼粉嫩大衣": None,
    "ID51776811": struct.pack('<I', 51776811),
    "ID1709": struct.pack('<I', 1709),
}

for spf in os.listdir("D:\\LaTale\\彩虹岛S2 他乡彩虹岛"):
    if not spf.endswith('.SPF'): continue
    fpath = f"D:\\LaTale\\彩虹岛S2 他乡彩虹岛\\{spf}"
    size = os.path.getsize(fpath)
    with open(fpath, "rb") as f:
        for chunk_start in range(0, min(size, 50*1024*1024), 10*1024*1024):
            f.seek(chunk_start)
            data = f.read(10*1024*1024)
            for name, pat in targets.items():
                if pat and pat in data:
                    print(f"{spf}: {name}")
```

## 已知引用分布（以暖呼呼粉嫩大衣为例）

| LDT 文件 | 暖呼呼文字 | ID 51776811 | ID 1709 |
|----------|-----------|-------------|---------|
| CASH_SHOP.LDT | ✅ | ✅ | ✅ |
| ITEM_2.LDT | ✅ | ✅ | - |
| BEATTACKED.LDT | - | - | ✅ |
| 约 20 个其他 LDT | - | - | ✅（作为图标索引） |

**ID 1709 大量出现在非商城 LDT 中**，说明 1709 不是唯一的道具ID，而是通用的图标索引/分类ID。CASH_SHOP 和 ITEM_2 里的 1709 才是道具引用。

## 不同端搜索同一道具的结果差异

| 端 | 结果 |
|----|------|
| 他乡S2 (`D:\Server\DATA\LDT`) | CASH_SHOP + ITEM_2 都有 |
| 彩虹岛单机（重装后） | 全都没有 ← 被覆盖掉了 |
| S2 Server2 (`D:\LaTale\Server2\ROWID\DATA\LDT`) | CASH_SHOP 有，ITEM_2 没有 |

**不同端的 ITEM_1/2.LDT 内容完全不同**，不能跨端直接引用 ItemID。如果要在 A 端使用来自 B 端的道具，需要把 B 端的 ITEM 表记录也搬过来。
