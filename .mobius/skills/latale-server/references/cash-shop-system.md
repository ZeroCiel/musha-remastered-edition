# 彩虹岛商城系统 (Cash Shop)

商城数据存储在两个地方：LDT 文件和 SQL Server 数据库。

## LDT 文件（商品定义）

所有商城里售卖的商品定义在 SPF 包的以下 LDT 文件中：

| 文件 | 用途 |
|------|------|
| `CASH_SHOP.LDT` | 主商城商品列表 — 定义了所有类别、商品ID、价格、Icon、折扣等 |
| `CASH_SHOP_HOT.LDT` | 热卖商品 |
| `CASH_SHOP_LIMIT.LDT` | 限时商品 |
| `CASH_SHOP_BURNING.LDT` | 燃烧活动商品 |
| `BEAUTY_SHOP.LDT` | 美容院商品（发型、脸型、肤色等） |
| `CASHSHOP_DEFAULT.LDT` | 默认商城配置 |
| `CASHSHOP_HELP.LDT` | 商城帮助提示 |

### CASH_SHOP.LDT 结构

列名（从二进制头部提取）：

| 列名 | 含义 |
|------|------|
| `_CategoryView` | 类别展示序号 |
| `_CategoryIndex` | 类别 ID |
| `_CategoryInd` | 子类别索引 |
| `_PositionInd` | 在类别内的位置 |
| `_EventType` | 活动类型 (0=普通, 1=热卖, 2=打折等) |
| `_Name` | 商品显示名称（euc-kr 编码） |
| `_IconFile` / `_IconI` | Icon 文件名和索引 |
| `_Gender` | 性别限制 (0=通用, 1=男, 2=女) |
| `_Price` | 原价（克拉/点券） |
| `_CashPrice` | 现金价 |
| `_SalePrice` | 折扣价 |
| `_EventIdx` | 活动索引 |
| `_ItemID` 至 `_ItemID8` | 捆绑销售的物品 ID（1-8件套） |
| `_Item` 至 `_Item8` | 对应物品名称 |
| `_ItemCount` 至 `_ItemCount8` | 对应物品数量 |
| `_PriceRate` 至 `_PriceRate8` | 对应物品价格比例 |
| `_MotionIdx` | 动作/特效索引 |
| `_Class` | 职业限制 |
| `_Require` | 等级/属性要求 |

## SQL 数据库（库存/购买记录）

数据库 `dbLataleWorld_2` 中相关表：

| 表名 | 用途 | 状态 |
|------|------|------|
| `tbluCashShop` | 商城里显示的商品容器（ShopID + Cnt） | **当前为空表** — 商品完全由 LDT 控制 |
| `tbluItem2` / `tbluItem2Ext` | 玩家背包中的物品（含已购买的商品） | 有数据 |
| `tbluCollectItem` | 收集物品 | - |

*tbluCashShop* 字段：
- `ShopID` (int) — 商品 ID
- `Cnt` (int) — 库存数量

服务端启动时从 `CASH_SHOP.LDT` 读取商品定义到内存，客户端登录后请求列表时直接发送已解析的 LDT 数据。SQL 表 `tbluCashShop` 可能用于动态控制（限制某商品的整体库存），但当前为空。

## 上架商品的两种方式

### A. 修改 CASH_SHOP.LDT（推荐，持久化）

需要用 LaTaleTools（D:\LaTaleTools，F#/.NET 9.0）或其他 LDT 编辑器：

1. 解包 SPF（提取 CASH_SHOP.LDT）
2. 编辑 LDT，添加商品条目（ItemID、价格、类别等）
3. 打包 SPF 替换
4. 重启服务端

### B. SQL 直操作（快速验证/动态控制）

```sql
-- 插入商品到商城
INSERT INTO dbLataleWorld_2.dbo.tbluCashShop (ShopID, Cnt) VALUES (物品ID, -1)
-- Cnt=-1 表示无限库存，Cnt=0 表示已卖完
-- 注意：这只是辅助表，主商品数据仍在 LDT 中
```

### CASH_SHOP.LDT 二进制解析（已验证）

基于 LaTaleTools.Library 源码 `Ldt.fs` 和实际二进制逆向验证。

**文件头 (12 bytes)**：
| 偏移 | 大小 | 含义 |
|------|------|------|
| 0x00 | 4 | Magic (通常 0) |
| 0x04 | 4 | 列数 + 1 (含虚拟 _RowId) |
| 0x08 | 4 | 行数 |

**列名区 (从偏移 12 开始)**：
- 每列名 64 字节，null 终止 + 空格填充
- 第 0 列总是虚拟的 `_RowId`
- 列名偏移: `12 + n * 64`

**列类型区 (从偏移 8204 开始)**：
- 每列类型 4 字节 (int32)
- 类型值: 0=U32, 1=String, 2=Bool, 3=S32, 4=Float
- 类型偏移: `8204 + n * 4`

**数据区 (从偏移 8716 开始)**：
每行按列顺序依次读取：
- U32/S32/Bool/Float: 固定 4 字节
- String: 2 字节长度前缀 + 字符串数据
- 字符串编码: euc-kr (CP949)

**CASH_SHOP.LDT 的 64 列关键信息**：
| 列索引 | 列名 | 类型 | 含义 |
|--------|------|------|------|
| 1 | `_CategoryView` | Bool | 1=上架可见, 0=隐藏 |
| 2 | `_CategoryIndex` | S32 | 类别 ID |
| 3-4 | `_CategoryIndex2/3` | S32 | 子类别 |
| 7 | `_Name` | Str | 商品名 (euc-kr) |
| 9-10 | `_IconFile`/`_IconIndex` | S32 | Icon 资源 |
| 11 | `_Gender` | S32 | 性别限制 |
| 12-14 | `_PriceType`/`_CashPrice`/`_SalePrice` | S32 | 价格 |
| 16-47 | `_ItemID1-8`/`_ItemRare1-8`/`_ItemCount1-8`/`_PriceRate1-8` | S32 | 最多 8 件捆绑道具 |

**完整 Python 行读取（含所有类型处理）**：

```python
import struct

def read_ldt_full(path):
    with open(path, 'rb') as f:
        data = f.read()
    
    col_count = struct.unpack('<I', data[4:8])[0] + 1
    row_count = struct.unpack('<I', data[8:12])[0]
    
    # 列名
    col_names = ['_RowId']
    for n in range(col_count - 1):
        name_off = 12 + n * 64
        end = data.find(b'\\x00', name_off)
        name = data[name_off:end].decode('utf-8') if end > 0 else ''
        col_names.append(name)
    
    # 列类型 (0=U32, 1=Str, 2=Bool, 3=S32, 4=Float)
    col_types = []
    for n in range(col_count - 1):
        t = struct.unpack('<I', data[8204 + n*4:8204 + n*4 + 4])[0]
        col_types.append(t)
    
    type_names = {0: 'U32', 1: 'Str', 2: 'Bool', 3: 'S32', 4: 'Float'}
    
    # 读取行
    rows = []
    pos = 8716  # 数据区起始偏移
    for _ in range(row_count):
        if pos >= len(data):
            break
        row = []
        for ci in range(col_count):
            ct = col_types[ci-1] if ci > 0 else 3  # _RowId = S32
            
            if ci == 0:  # _RowId
                val = struct.unpack('<i', data[pos:pos+4])[0]
                pos += 4
            elif ct == 1:  # String: 2-byte length prefix
                slen = struct.unpack('<H', data[pos:pos+2])[0]
                val = data[pos+2:pos+2+slen].decode('euc-kr', errors='replace').rstrip('\\x00')
                pos += 2 + slen
            elif ct == 0:  # U32
                val = struct.unpack('<I', data[pos:pos+4])[0]
                pos += 4
            elif ct in (2, 3):  # Bool / S32
                val = struct.unpack('<i', data[pos:pos+4])[0]
                pos += 4
            elif ct == 4:  # Float
                val = struct.unpack('<f', data[pos:pos+4])[0]
                pos += 4
            else:
                val = None
                pos += 4
            row.append(val)
        rows.append(row)
    
    return col_names, col_types, rows
```

### 批量上架所有隐藏商品（已验证 941 个）

```python
def un_hide_all(path):
    with open(path, 'rb') as f:
        data = bytearray(f.read())
    
    col_count = struct.unpack('<I', data[4:8])[0] + 1
    row_count = struct.unpack('<I', data[8:12])[0]
    
    col_types = [struct.unpack('<I', data[8204 + n*4:8204 + n*4 + 4])[0] for n in range(col_count - 1)]
    
    changed = 0
    pos = 8716
    
    for _ in range(row_count):
        if pos >= len(data):
            break
        cat_view_pos = pos + 4  # skip _RowId
        cat_view = struct.unpack('<I', data[cat_view_pos:cat_view_pos+4])[0]
        
        if cat_view == 0:
            struct.pack_into('<I', data, cat_view_pos, 1)
            changed += 1
        
        # Skip entire row
        p = pos
        for ci in range(col_count):
            ct = col_types[ci-1] if ci > 0 else 3
            if ci == 0:
                p += 4
            elif ct == 1:
                slen = struct.unpack('<H', data[p:p+2])[0]
                p += 2 + slen
            else:
                p += 4
        pos = p
    
    with open(path, 'wb') as f:
        f.write(data)
    return changed
```

### 当前商城数据统计 (2026-05-24)

| 类别 ID | 类别名称 | 总商品 | 已上架 | 隐藏 |
|---------|----------|--------|--------|------|
| 1 | 推荐/新品 | 1922 | 1097 | 825 |
| 2 | 装扮 | 39 | 0 | **39 (全隐藏)** |
| 3 | 发型 | 33 | 32 | 1 |
| 6 | 套装 | 256 | 189 | 67 |
| 7 | 武器 | 1893 | 1884 | 9 |

上架所有隐藏后，CASH_SHOP.LDT 会新增 941 个可见商品。

### 发型 ItemID 查找

发型券（Hair Coupon）属于道具类，需要从以下 LDT 或 SQL 表获取 ItemID：

**LDT 文件**（位于 SPF 包内）：
- `ITEM.LDT` — 所有物品定义
- `ITEM_GENERAL.LDT` — 通用物品
- `ITEM_HAIR.LDT` 或 `HAIR.LDT`（如果存在）

**SQL 表**：
```sql
-- 查看所有物品 ID 和名称
SELECT ItemID, Name FROM dbLataleWorld_2.dbo.tbluItem2 WHERE Name LIKE '%发%' OR Name LIKE '%hair%'
```

具体发型 ItemID 需要在服务端运行后从数据库中查询或从 LDT 文件中提取。
