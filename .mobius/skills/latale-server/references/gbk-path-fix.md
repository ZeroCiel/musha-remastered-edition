# GBK 路径乱码修复方法

## 问题背景

他乡彩虹岛等私服包的 `configure.ini` / `configure_share.ini` 是 **GBK 编码**，包含中文路径如 `D:\LaTale\彩虹岛S2 他乡彩虹岛\Server\`。

用 UTF-8 编码的 `sed` 修改这些文件时，中文被破坏：`彩虹岛S2 他乡彩虹岛` 变成 `褰╄櫣宀汼2 浠栦埂褰╄櫣宀沑`。

## 修复方法

### 方法一：完整二进制替换（推荐）

```python
path = "D:\\路径\\BIN2\\configure.ini"
correct_gbk = "彩虹岛S2 他乡彩虹岛".encode('gbk')

with open(path, "rb") as f:
    data = f.read()

# 替换所有 D:\LaTale\Server2\ 或 D:\Server\ 引用
data = data.replace(b'D:\\LaTale\\Server2\\', b'D:\\LaTale\\' + correct_gbk + b'\\Server\\')
data = data.replace(b'D:\\LaTale\\Server2', b'D:\\LaTale\\' + correct_gbk + b'\\Server')
data = data.replace(b'D:\\Server\\', b'D:\\LaTale\\' + correct_gbk + b'\\Server\\')

with open(path, "wb") as f:
    f.write(data)
```

### 方法二：修复已损坏的路径

当 sed 已经破坏中文后，文件中的乱码字节是：UTF-8 编码的 `彩虹岛S2 他乡彩虹岛`（`e5 bd a9 e8 99 b9 e5 b2 9b 53 32 20 e4 bb 96 e4 b9 a1 e5 bd a9 e8 99 b9 e5 b2 9b`）被写入了 GBK 文件。

**检测方法**：
```python
prefix = b'D:\\LaTale\\'
with open(path, "rb") as f:
    data = f.read()

pos = 0
while True:
    idx = data.find(prefix, pos)
    if idx == -1: break
    rest = data[idx + len(prefix):]
    # 找 \Server 或 \SPF 等后缀
    for suffix in [b'\\Server', b'\\SPF', b'\\resource', b'\\bin2']:
        sidx = rest.find(suffix)
        if sidx > 0:
            dir_name = rest[:sidx]
            if dir_name != correct_gbk:
                print(f"CORRUPT at offset {idx}: {dir_name.hex()}")
                data = data[:idx + len(prefix)] + correct_gbk + data[idx + len(prefix) + sidx:]
            break
    pos = idx + 1
```

## 验证

```bash
# 确认无残留乱码
grep -oP 'D:\\\\LaTale\\\\[^\\\\]+' configure.ini | sort -u

# 确认中文路径正确
# 正确输出应包含"彩虹岛S2"
# 错误输出包含"褰╄"等乱码
```
