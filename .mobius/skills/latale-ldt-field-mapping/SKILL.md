---
name: latale-ldt-field-mapping
description: 彩虹岛LDT数据表编辑 — 字段名中英文对照、二进制格式解析、Python读写工具、查找替换工具、CASH_SHOP商城编辑
category: gaming
---

# 彩虹岛 LDT 数据表编辑

## LDT格式说明

LDT是彩虹岛服务端/客户端的数据表文件（二进制）。

## 三种LDT格式（重要）

当前有**三种不同格式**的LDT，对应不同的端版本。**不能用同一套解析规则处理所有LDT文件。**

### 格式A — CASH_SHOP类（S2他乡端/当前单机端）
标准彩虹岛格式，列类型区有值。

### 格式B — ITEM_2/CROP类（S2他乡端/当前单机端）

⚠️ **他乡端（D:\LaTale\S2）ITEM_2.LDT的二进制解析缺陷（2026-06-04）**
- 用标准binary解析（格式B解析器：数据偏移8512，行大小500字节）**只读出22条Type=1,SubType=2的道具**
- 但用彩虹岛编辑器导出TXT能看到大量Type=4,SubType=3的结晶/强化道具（彩虹泡泡+0~MAX等）
- 说明他乡端的ITEM_2.LDT的binary行结构可能和怀旧端（D:\彩虹岛）不一致
- **结论：他乡端ITEM_2.LDT必须用彩虹岛编辑器导出TXT，不要用任何binary解析脚本**
- 编辑器导出TXT格式：TAB分隔，第9列=_Type，第10列=_SubType，第5列=_Name（道具名）
| 特征 | 值 |
|------|-----|
| 列类型区 | **全为0**（所有列标记为string，但数据区前48列实际以4字节int存储） |
| 数据区 | **\x00分隔**的可变长字段 |
| _ItemID列 | **无** — 用`_Num`[1]作为物品ID |
| _PosID1实际意义 | **值范围0~40亿+，不能直接映射** |
| 解析难度 | **困难**（需\x00扫字段边界） |
| _Name | string，直接存中文名 |

### 格式C — ITEM_1/2/3类（S1端 彩虹岛S1）
S1版本使用的标准格式，列类型区有值，但字段类型分布和S2不同。

| 特征 | 值 |
|------|-----|
| 列类型区 | 有值（type=0/1/2/3/4/5） |
| 数据区 | 固定宽度（int 4B, string 2B长度+GBK） |
| 列数 | **109列** |
| _Name | **type=1（unsigned short int），存字符串表索引ID，不是中文名！** |
| _Description | **type=1，同样是索引ID** |
| _Category | **type=3（float），实际存的是int分类值** |
| _Type | type=3（float） |
| _SubType | type=3（float） |
| _GamePrice | type=3（float） |
| 道具名称来源 | 不在ITEM表内，需查 `GLOBAL_STRING.LDT` 或其他字符串表 |
| 解析难度 | 中等（按类型号解析即可，但_Name/Description需查字符串表） |
| 行数 | ITEM_1=6029行, ITEM_2=2901行, ITEM_3=7068行 |
| SPF路径 | `resource/ROWID/DATA/LDT/` |

**S1端ITEM表重要差异**：
- 所有关键分类字段（_Category/_Type/_SubType）都是type=3(float)，解析时按float读
- _Name是索引ID（int），不是道具名。**不能通过二进制搜索GBK中文名来搜索道具！**
- CASH_SHOP.LDT结构和其他版本一致（64列标准格式）
- S1端行数少：ITEM_1+2+3合计约15998行，而当前端ITEM_2单表就有9582行

**实操建议**：S1端的道具数据最好用彩虹岛编辑器打开查看，或通过CASH_SHOP.LDT的ItemID反查。

**推断**：格式B可能是S2早期版本或某种编译/导出时的中间格式。彩虹岛编辑器可正常读写，但二进制直接解析非常困难。

**实操建议**：
- ITEM_2.LDT（大表，539万字节/9582行）→ 用彩虹岛编辑器看，不要用代码解析
- CASH_SHOP.LDT（小表）→ 65列TXT导出+彩虹岛编辑器编辑
- CROP.LDT（小表）→ 可直接二进制对比（最简单的文本替换差异）
- 文件大小相同时大概率只是繁简差异，可用`python -c "if open(f1,'rb').read()==open(f2,'rb').read(): print('same')"`快速判断

### 格式B (ITEM_2/CROP类) 实测

参见 `references/item2-ldt-binary-format-notes.md` 详细解析。

**核心发现**：
- ITEM_2.LDT的列类型区全部为0（标记为string），但数据区前48列实际以4字节int存储
- `_Name`列（索引3）不是string，是int32（GLString引用ID或值0/3），中文名称在别处存储
- `_Num`列（索引1）就是物品ID（ItemID）
- 直接代码解析极困难：_Name读不到中文名，大部分工具（ldt_writer、彩虹岛编辑器）才能正常读写
- `_PosID1=15` 在本端中对应**武器**，但ITEM_2中PosID1=15的武器非常少（仅3件）。大部分武器道具的PosID1是大数值ID（`3亿+`），不是常规装备部位分类
- **判断武器的方法**：不能用PosID1筛，彩虹岛编辑器内看_Use_Type或者按_Icon/_IconIndex模式判断
- 行大小(row_size) = **500字节**，数据区偏移(data_off) = **8512**（= 12 + 125*64 + 125*4）
- 二进制修改时：读整行500B，改前48个4字节int，再改`48*4`后的字符串区域
- 彩虹岛编辑器导出的竖线格式（`|`分隔）可直接对应行内字段顺序

**推荐做法**：ITEM_2.LDT 用彩虹岛编辑器操作，不要写代码解析。

### ITEM_2.LDT改名：去掉前缀（等长字节替换）

当需要批量去掉道具名前缀（如"【韩国专属合作道具，其他国家服无法使用】"共32字节）时：

```python
prefix_gbk = '【韩国专属合作道具，其他国家服无法使用】'.encode('gbk')
# 在数据区搜索prefix_gbk
# 找到后：新名 = 原名去掉前缀，编码为GBK
# 如果新名长度 <= 旧名长度：直接覆盖，剩余字节补0x20(空格)
# 如果新名长度 > 旧名长度：不能用批量替换，需用编辑器手动改
```

**注意**：原始LDT中某些条目末尾有非法GBK字节（0x9b, 0x9c, 0x85等），导致`encode('gbk')`报错。解决方案：
1. 用字节操作（不是字符串解码）处理后缀
2. 跳过非法字节对
3. 用空格(0x20)填充剩余区域，不要用0x00（避免破坏字符串边界）

详见 `scripts/fix_korea_ldt.py` 和 `item2-clean-strategy` skill。

### 二进制搜索名称的局限

ITEM_2.LDT中通过GBK字节搜索中文名是可行的，但需要注意：
- 搜索返回的是整个文件中所有出现该关键字的位置（包含_Name和_Description等所有文本字段）
- 道具名通常以`/`或换行结束（如`活动铅笔短剑/`），描述则包含`\\n※参考※`等标记
- 同一个道具的名称和描述都会命中搜索，需要用`text.split('\\\\n')[0]`或检查末尾`/`来区分
- **无法通过搜索得到ItemID**，因为_Num列是int32不参与文本搜索。搜到名称后需通过彩虹岛编辑器或行号计算定位

### 本端无独立武器时装栏

**重要**：此S2怀旧端（他乡包衍生物）没有独立的武器时装栏位。武器和真武器共用同一个装备槽位。这和国服S1/S4不同。

所以：
- 不能直接参考国服的"武器时装"概念来筛选
- 所有可装备到武器栏的道具都是**带属性的真正武器**，不是装饰外观
- 如果要新增"武器外观"类道具，需要确认服务端是否支持外观覆盖机制
- 当前端ITEM_2中**没有"冰弓"、"雪女弓"**这类武器外观道具，仅有"活动铅笔短剑"等极少数武器外观（通过彩虹岛编辑器编辑添加）

## BANX图标文件映射

他乡端图标解包在 `D:\\LaTale\\彩虹岛S2 他乡彩虹岛\\解包目录\\BANX\\DATA\\GLOBALRES\\{IconIndex:04d}.PNG`。
当前单机端图标在 BANX.SPF 压缩包中（未解包），无法直接查看。

**映射规则**：ITEM_2中 `_Icon=10001212` + `_IconIndex=204` 对应 GLOBALRES 的 `0204.PNG`。
跨服对照：看他乡端PNG是否存在 + 查当前端ITEM_2是否有对应Icon引用。

### VSSVER.SCC 文件说明

解包后的 BANX 目录下每个子目录都有 `VSSVER.SCC` 文件。这是 Microsoft Visual SourceSafe 的版本元数据文件，内容纯二进制（版本号+GUID+时间戳），**不可打开/编辑，可安全删除**。不影响游戏运行。

```bash
find "/d/LaTale/S2x/解包目录/" -name "VSSVER.SCC" -delete
```

## ITEM_2 字段速查

| 索引 | 字段 | 类型 | 说明 |
|------|------|------|------|
| 3 | _Name | string | 道具名 — 三种形态：直接中文名、数字GLString引用、描述截取 |
| 4 | _Description | string | 道具描述 |
| 6 | _Icon | int | 图标文件ID |
| 7 | _IconIndex | int | 图标索引 |
| 10 | _CashCheck | bool(int) | 0=禁止上架商城, 1=允许。**注意：他乡端有些时装原始CC=1但CASH_SHOP无记录或_CategoryView=0隐藏** |
| 13 | _Type | int | 物品大类(1=装备/时装, 2=消耗品) |
| 14 | _SubType | int | 子类(**2=时装**, 1=普通装备) |
| 15 | _PosID1 | int | 装备位置(1=头饰/联动特殊, 2=武器, 3=发型, 4=衣服, 5=裤子, 6=戒指/特殊, **7=手套**, **8=鞋子**, 9=翅膀, 10=面部装饰, 11=翅膀/任务道具(混入)) |
| 87 | _Time_Type | int | 时限类型(0=永久) |
| 88 | _Lifetime | int | 时限(小时)

| 字段 | 说明 |
|------|------|
| `_Category` | 分类 |
| `_Num` | 编号 |
| `_ColorID` | 颜色ID |
| `_Name` | 名称(string) — 有三种实际存储形态见references |
| `_Description` | 描述(string) |
| `_Icon` | 图标文件ID（如10001212） |
| `_IconIndex` | 图标索引（如204=0204.PNG） |
| `_CashCheck` | 布尔开关(type=2, uint32: 0=禁止购买, non-0=允许)。注意：他乡端部分时装原始_CashCheck=1但CASH_SHOP可能无记录或_CategoryView=0隐藏。检测方法：搜CASH_SHOP._Name含"雪ミク""Magic_Ver""コラボ"等关键词，检查_CategoryView值。 |
| `_CashPoint` | 红利点券价格 |
| `_CategoryView` | 分类视图(bool) |
| `_CategoryIndex` | 分类索引(CASH_SHOP用) |
| `_CategoryIndex2` | 商城中分类 |
| `_CategoryIndex3` | 商城细分类 |
| `_PositionIndex` | 商城排序位置 — 同一分类下数值越小越靠前显示。唯一递增，不是道具ID。 |
| `_EventType` | 活动类型 |
| `_PriceType` | 1=点券 0=游戏币 |
| `_SalePrice` | 折扣价 |
| `_EventIcon` | 活动图标 |
| `_Buy_Disable` | 购买禁用(bool, CASH_SHOP必须=1) |
| `_Give_Disable` | 赠送禁用(bool, CASH_SHOP必须=1) |
| `_ItemID1~_ItemID8` | 物品ID(商城) |
| `_ItemRare1~8` | 稀有度(商城, 常用1) |
| `_ItemCount1~8` | 数量(商城, 常用1) |
| `_Gender` | 性别 |
| `_Time_Type` | 时限类型(0=永久, 1=限时) |
| `_Lifetime` | 时限小时数(168=7天, 720=30天) |
| `_RareLimit` | 稀有度限制 |
| `_Type` | 物品大类(1=装备, 2=消耗品, 4=材料, 5=宠物) |
| `_SubType` | 子类(1=普通装备, 2=时装子类) |
| `_PosID1` | 装备位置(**1=头饰/联动特殊, 2=武器, 3=发型, 4=衣服, 5=裤子, 6=戒指/特殊, 7=手套, 8=鞋子, 9=翅膀, 10=面部装饰, 11=翅膀/任务道具(混入), 12~14=戒指盾牌**) |

判断时装的**终极标准**：`_Type=1 AND _SubType=2`（此时无论_PosID1=？都是时装）。
PosID1=11混有任务物品，永远不要在时装筛选中包含。
注意：`_Limited_Time_Type` = CASH_PRICE_RATIO.LDT的RowId（1001=7天, 1002=30天），不是简单的0/1/2。**GS验证逻辑**：GS启动时校验每行CASH_SHOP，_Limited_Time_Type必须匹配CASH_PRICE_RATIO中的RowId或=0。设成1或2等值会报：`CASH_PRICE_RATIO.LDT No Data {RowId} {Name} {CashPrice} {PriceType} {WrongLimited}` → GS崩溃。
详见 `references/session-20260529-limited-type-fix-and-earring-append.md`、`references/cashshop-limited-type-and-gs-startup-debug.md` 和 `cashshop-append-rules` 技能。

### 怀旧端CASH_SHOP.LDT解析陷阱（2026-05-29）

怀旧端（D:\彩虹岛）CASH_SHOP.LDT的type=3（float）列**实际存的是int32值**，不是float。

```python
# ❌ 错误（读到极小科学计数法）
val = struct.unpack('<f', data, off)[0]  # → 2.35e-38

# ✅ 正确
val = struct.unpack('<i', data, off)[0]  # → 实际值如230
```

此问题在怀旧端 CASH_SHOP.LDT 和 ITEM_1/2/3.LDT 中都存在。诊断方法：如果解析出的_CashPrice、_ItemID1等值都是科学计数法（2.35e-38量级），说明在用float读int。

**行大小**：type=3占4字节（同int32），行固定大小=252字节（=64列，每列按实际type大小求和，type=3占4B）。

### CASH_SHOP.XLS写入（2026-06-04 安全方案）

### 致命事故：直接改ITEM_2.LDT字符串导致BayServer SIGSEGV

**永远不要在二进制LDT中改字符串字段（Name/Description）**。int字段（CashCheck等）可以，因为固定4字节无边界问题。

### 推荐工作流
1. **编辑XLS文件**（TAB分隔GBK文本）→ 改CashCheck、改名、改分类
2. **彩虹岛编辑器打开XLS** → 导入到LDT
3. **打包BARY.SPF**
4. **重启服务端测试**

比直接二进制改LDT安全得多。

### CASH_SHOP.xls 分类体系

| 分类 | _CategoryIndex | _CategoryIndex2 | _CategoryIndex3 |
|------|---------------|----------------|----------------|
| 普通时装 | 1 | 1 | 1~5 |
| 发型 | 1 | 2 | 5 |
| 鞋子 | 1 | 3 | 8 |
| 手套 | 1 | 4 | 10 |
| 面部/耳环 | 1 | 5 | 12 |
| 宠物领养券 | 2 | 7 | 0 |
| 宠物用品 | 2 | 8 | 0 |
| 宠物本体（活体） | 7 | 23 | 0 |
| 宠物装备 | 7 | 22 | 0 |

### 宠物vs宠物主题时装区分

**宠物本体**：名称=动物名（白虎、熊猫、企鹅），无装备部位后缀
**宠物装备**：名称含"帽子/衣服/靴子"等部位 → Cat=7,22或24
**宠物主题时装**：同名但Cat=1,1,x的普通时装——**不要**移进宠物分类

| 索引 | 字段 | 类型 | 说明 |
|------|------|------|------|
| 0 | _CategoryView | bool | 1=可见, 0=隐藏（联动物品常隐藏） |
| 1 | _CategoryIndex | int | 商城大分类 |
| 2 | _CategoryIndex2 | int | 子分类 |
| 3 | _CategoryIndex3 | int | 细分类（发型=5, 衣服=4） |
| 4 | _PositionIndex | int | 排序位置 |
| 5 | _EventType | int | 活动类型 |
| 6 | _Name | string | 商城显示名称 |
| 7 | _Description | string | 描述 |
| 8 | _IconFile | int | 图标文件ID |
| 9 | _IconIndex | int | 图标索引 |
| 10 | _Gender | int | 性别限制 |
| 11 | _PriceType | int | 1=点券 |
| 12 | _CashPrice | int | 价格（时装240） |
| 15 | _ItemID1 | int | 道具ID |
| 61 | _Buy_Disable | bool | 必须=1 |
| 62 | _Give_Disable | bool | 必须=1 |
| 63 | _Limited_Time_Type | int | 0=永久, **1001=7天限时, 1002=30天限时**（指向CASH_PRICE_RATIO.LDT的RowId，不是简单的0/1/2！） |

### 常见GS崩溃模式（2026-06-04 新增）

| 错误信息 | 根因 | 修复 |
|---------|------|------|
| `Item Info Loading... FAILED ! iItemID = X, EffectID = 16777216` | ITEM_2某行的EffectID/SetID字段被误写为无效值（0x1000000） | 把该行的EffectID/SetID列改为0 |
| `SetID does not exist in SETITEM_B. iSetID(65536)` | ITEM_2某行引用了不存在的套装ID 0x10000，且SETITEM_B.LDT文件不存在 | **批量：先搜LDT所有65536/16777216 → 清0，再改CashCheck** |
| `LoadQuizInfoLDT() : [FAILED]` | QUIZ_INFO.LDT不存在或损坏 | 从完整端复制。已知来源：`D:\LaTale\S4chd\resource\ROWID\DATA\LDT\` 下有 QUIZ.LDT, QUIZ_A.LDT, QUIZ_BONUS.LDT, QUIZ_Q.LDT, QUIZ_REWARD.LDT 共5文件 |
| `GLOBAL_SYS.LDT : FAILED ! (This LDT is Not Exist.)` | 这个LDT确实可以不存在，非致命报错 | 忽略 |
| `GlobalSys::Init() : [OK]` 后无日志直接退（exit 139） | ITEM_2或其他GlobalSys加载的LDT损坏 | 恢复原版LDT，确保二进制修改字符串时等长填充 |
| BayServer无dmp生成 | 启动后立即SIGSEGV，通常LDT字符串修改导致结构破坏 | 恢复原版LDT |

**核心理念（重要）**：改 CashCheck 0→1 **本身不会崩**，崩的原因是**之前CashCheck=0时GS跳过该行，所以没发现该行的坏数据**。改成1后GS加载全部列，暴露了被65536/16777216污染的EffectID/SetID。

详见 `references/session-20260604-cashcheck-batch-and-pet-classification.md`。

**诊断流程**：哪个服务报错就看哪个服务的log。Bay对应`Latalebayserver.log`，GS对应`Latalegameserver_XXX.log`，Room对应`Lataleroomserver.log`。

**ITEM_2修改导致Bay崩溃的修复**：
1. 从BARY.rar解包原版ITEM_2.LDT覆盖
2. 或用彩虹岛编辑器从原版xls重新导入
3. 修改LDT字符串时，新字符串必须与原名**等长或更长**（短了用0x20空格填充），否则破坏\x00边界

```
NPCTRADE.LDT._IDx → NPCTRADE_DETAIL.item_id → _ItemID → ITEM_3.LDT.item_id
```

### pack模式

configure.ini中的`pack`参数：
- **pack=1**: 读SPF包文件，修改LDT后必须重新打包才能生效
- **pack=0**: 直接读目录文件，修改后重启GS即可

单机端通常为pack=1。改LDT后不打包直接重启GS → 旧数据不变。

## ITEM_2 模糊搜索名称方法（不用编辑器）

当需要从ITEM_2.LDT中按中文名搜索道具时，可以用GBK二进制搜索代替用彩虹岛编辑器打开：

```python
# 1. 搜索关键词（GBK编码）
kw = '冰'.encode('gbk')  # b'\xb1\xf9'
kw = '弓'.encode('gbk')  # b'\xb9\xad'

# 2. 在文件中搜索
with open('ITEM_2.LDT', 'rb') as f:
    data = f.read()
pos = 0
while True:
    idx = data.find(kw, pos)
    if idx == -1: break
    # 3. 读附近的\0结束字符串（道具名在关键字附近）
    text = b''
    for i in range(idx, min(idx + 80, len(data))):
        b = data[i]
        if b >= 0x80: text += bytes([b])
        elif b == 0: break
        elif b == 0x0a: text += b' '
        elif 0x20 <= b < 0x7f: text += bytes([b])
        else: break
    print(text.decode('gbk', errors='replace'))
    pos = idx + 2
```

**说明**：ITEM_2的_Name列（索引3）在二进制层不是独立string字段，而是混在数据块中的GBK文本。直接从`_Name`偏移读不到中文名。这个搜索方法在文件的所有字节流中搜GBK编码，找到的是所有出现该关键词的字段（包含_Name和_Description等）。

### 区分名称和描述
- 名称通常简短（2~20字符），且是搜索结果中第一次碰到的字符串
- 描述通常很长（20~100字符），含`\n※参考※\n不可交易`等标记
- 可通过`\n`分割：`text.split('\\n')[0]`取第一行就是道具名
- **注意**：同一个道具的名称和描述都会命中GBK搜索，需要用`split`或检查末尾`/`来区分

### 从名称反查行号/ItemID

当通过二进制搜索找到道具名称后，如果需要知道该道具的ItemID（_Num列）或行号：

```python
data_off = 12 + 125 * 64 + 125 * 4  # ITEM_2数据区起始
row_size = 500
row_num = (idx - data_off) // row_size
offset = data_off + row_num * row_size
item_id = struct.unpack_from('<I', data, offset + 1*4)[0]  # _Num列
```

注意：`idx`是名称在文件中的绝对偏移，不是相对数据区的偏移。

⚠️ **格式B的int列偏移不可靠**：在S4的ITEM_2.LDT（10053行，5.6MB）中实测，用col*4偏移读到的_Type/_SubType/_PosID1全是乱值（如0/16777216/3145729等）。名称通过GBK搜索能准确定位，但int列值受格式B的\x00分隔变长影响可能错位。唯一可靠的int字段定位方式是用`struct.pack('<I', target_id)`搜索ItemID的4字节编码——因为ItemID本身是int32，在行内固定位置。详见 `references/item2-binary-itemid-search.md`。

## 时装武器（本版本无独立武器时装栏）

**重要**：此S2怀旧端（他乡包衍生物）没有独立的武器时装栏位。武器和真武器共用同一个装备槽位（PosID1=15对应武器）。这和国服S1/S4不同，S1有独立武器时装栏。

所以：
- 不能直接参考国服的"武器时装"概念来筛选
- 所有PosID1=15的道具都是可装备的武器（带属性），不是装饰外观
- 如果要新增武器外观类道具，需要确认服务端是否支持武器外观覆盖机制

### 已知武器相关的字段值
- `_PosID1 = 15` = 武器（在ITEM_2中确认），但**仅3件道具使用此值**
- 大部分武器道具（如弓/剑/法杖等）的PosID1是大数值ID（`3亿+`），说明这个端PosID1不按常规定义存储
- `_Use_Type` = 各种值，暂无确定对应关系
- ITEM_2中`_PosID1 = 15`的武器非常少（仅3件），大部分武器道具的PosID1是大数值ID（可能是GLString引用或其他用途）
- **实际判断是否武器**：不用PosID1筛，而是彩虹岛编辑器内看_Use_Type或者按道具名关键词（弓/剑/杖/斧/锤等）配合_Icon/IconIndex判断

### 新增武器时装的推荐方式
- **首选**：彩虹岛编辑器打开ITEM_2.LDT，找一个空行或复制现有武器行后修改
- **备选**：二进制直接改行数据（备份！），改_PosID1=15，改字符串区_Name/Description
- 新增后_Num（ItemID）要唯一，_CashCheck保持0（等后续测试通过再上架商城）
- 属性（物理/魔法攻击）通过修改StatusType[22/24/26/28]和StatusValue[23/25/27/29]成对设置
- StatusType的枚举值（物理攻击/魔法攻击分别是几号）尚未完全确认，需要通过彩虹岛编辑器查看已有带攻击属性的武器来逆向

## HELP_MENU/HELP_CONTENT 结构解析

详见 `references/help-menu-structure-analysis.md`。

**核心结论**：
- HELP_MENU.LDT的按钮文本是LDT直接渲染的，但数据区字符串/坐标/颜色混合存储，不可直接二进制改
- HELP_CONTENT.LDT的页面文字在PNG图片上（SPF包内），LDT只控制位置和颜色
- S2 HELP_MENU乱码是繁体BIG5被当GBK解码，不是数据损坏

## LDT按文件分技能原则（2026-05-29 用户确认）

每个LDT文件的列结构和功能高度特化，**一个LDT文件对应一类独立操作**，不适合跨文件混用处理逻辑。

**例子**：
| LDT文件 | 用途 | 操作方式 |
|---------|------|---------|
| CASH_SHOP.LDT | 商城道具上架 | 65列TXT→彩虹岛编辑器手动复制 |
| ITEM_2.LDT | 道具属性定义 | 彩虹岛编辑器编辑 |
| NPCTRADE*.LDT | NPC商店贩卖 | 彩虹岛编辑器编辑 |
| HELP_MENU.LDT | 帮助菜单按钮 | 数据区字符串+坐标混合，不可直接二进制改 |
| HELP_CONTENT.LDT | 帮助内容页面 | 文字在PNG上，LDT只存布局引用 |
| EFFECT.LDT | 效果/BUFF属性定义 | 二进制直接改（70列全string，需等长替换） |

详见 `references/effect-ldt-structure-and-modification.md`。

**推论**：如果要创建技能，应该按LDT文件分（如`cashshop-append-rules`已做到），不要混到一个通用"LDT操作"技能里。

## HELP_MENU.LDT 乱码诊断（2026-05-29 新增）

当用户反映HELP_MENU.LDT乱码时，按以下步骤诊断：

### 检查文件结构
```python
# 读取头部
unk = struct.unpack_from('<I', data, 0)[0]  # =0
col = struct.unpack_from('<I', data, 4)[0]  # =70
row = struct.unpack_from('<I', data, 8)[0]  # =500
```

HELP_MENU.LDT（示例：159KB）的列全是string类型（type=0），数据区以`\x00`分隔变长字段。

### 乱码判断标准
- 数据区起始处有大量00块（如8726字节空区才出现内容）
- 字符串内容含半日文半乱码（如"蛔昼 シ卫"）——这是UTF-8被当GBK解码导致的编码损坏
- 中文GBK字节被解释为不同编码的结果（"薄後""导晦"等）

### 修复方法
1. **优先**：从他乡端解包目录复制完好的HELP_MENU.LDT替换
2. **备选**：从备份目录找原版繁体文件恢复
3. **不推荐**：手动修复——编码损坏后内容不可逆还原

## SKILL.LDT 编码错位修复（跨版本XLS对照法）

### 现象
技能名/描述显示乱码（如"饭骇捞"、"剧颊八 付胶磐府[檬鞭]"、"沥飞狼 泪犁仿"）。
GS启动报 `SKILL_USE.LDT : FAILED ! Not Exist in Skill.LDT (iKey = 8000302)` → 原因是SKILL.LDT里的_Name/Description被编码破坏，GS加载时找不到对应ID。

### 根因
原始文本用UTF-8或其他编码写入，被彩虹岛编辑器当GBK读出，字节边界错位导致乱码。这是**不可逆的编码损坏**，不能用转码算法修复。

### 修复方法（跨版本XLS对照）
SKILL数据虽然版本不同（S2/S3/S4），但**ID体系一致**（_ID是同一套编号）。可通过以下步骤修复：

1. **准备对照端XLS**：找一个同体系但文本正常的版本（如怀旧端D:\ROWID\DATA\XLS\或S3台服）的SKILL.xls
2. **构建ID映射**：从对照端读取_ID→_Name/_Description映射
3. **扫描乱码行**：对当前端SKILL.xls，按ID匹配，如果_Name的CJK字符比例<30%则判定为乱码
4. **替换**：用对照端的好文本覆盖当前端的_Name和_Description
5. **验证**：写回xls后搜"饭骇"、"剧颊"等已知乱码关键词确认无残留

```python
# 核心判断逻辑
cjk = sum(1 for c in cur_name if '\u4e00' <= c <= '\u9fff')
is_garbled = cjk < len(cur_name) * 0.3 if len(cur_name) > 0 else True
s3_cjk = sum(1 for c in s3_name if '\u4e00' <= c <= '\u9fff')
s3_good = s3_cjk >= len(s3_name) * 0.3 if len(s3_name) > 0 else False
if is_garbled and s3_good:
    # 替换_Name
```

### 注意
- 对照端也可能有乱码（S3有260条乱码Name），需要过滤
- 只有xls修改是不够的——必须用彩虹岛编辑器把修好的xls**写回SKILL.LDT**，GS才生效
- SKILL_USE.LDT引用SKILL.LDT的ID，如果ID本身损坏（非_NAME文本），修复后GS就能找到

### ⚠️ 批量替换致命陷阱：会覆盖已有正确数据

**不要用乱码检测+自动替换的批量方式修复SKILL.xls**。原因是：

1. **乱码检测不可靠**：CJK比例<30%的判断不能区分"被编码损坏的数据"和"正常但包含非中文字符的数据（如英文/数字/符号）"
2. **一损俱损**：某个ID的_Description可能是好的，但_Name是乱码。批量替换会连好的_Description一起覆盖成对照端的版本
3. **对照端数据不一定对**：S3台服SKILL.xls也有260条_Name乱码和更多_Description错误

**安全做法（用户确认）**：
1. 从原始xls（D:\\彩虹岛S2\\ROWID\\DATA\\XLS\\SKILL.xls或其他备份）中搜索目标ID的原始行
2. 只替换**确认有问题的_Name**，保持_Description不变
3. **多级备份**：每一步备份加后缀（.bak1/.bak2/.bak3），不要覆盖上一个备份
4. 用户最终手动用彩虹岛编辑器逐ID校对后写回LDT

**GS启动报错SKILL相关时的排查顺序**：
1. `SKILL_USE.LDT : FAILED ! Not Exist in Skill.LDT (iKey = XXX)` → 该ID在SKILL.LDT中不存在（非_Name/Description问题，是ID本身找不到）
2. `DATA/LDT/SKILL.LDT : FAILED ! iSkillID = [XXX]` → LDT加载时找不到该ID，需要确认xls→LDT同步状态
3. 大部分报错是因为**xls修改了但没写回LDT**，GS读的还是旧LDT数据

### SKILL 相关文件速查
| 文件 | 大小参考 | 说明 |
|------|---------|------|
| SKILL.LDT | ~1.5MB | 技能定义主表（_Name, _Description） |
| SKILL_TXT.LDT | ~784KB | 技能名称/描述文本（部分版本） |
| SKILL_USE.LDT | ~2.2MB | 技能效果/伤害公式 |
| SKILL_CONTENT.LDT | ~283KB | 技能内容（UI显示用） |
| SKILL.xls (XLS) | ~1.1MB | 编辑器导出，43~44列 |

GS启动报 `Not Exist in Skill.LDT (iKey = XXX)` 时：
1. 确认SKILL.xls中有该ID
2. 检查SKILL.LDT（二进制）是否与xls同步——LDT可能还是旧的乱码数据
3. 用编辑器从修好的xls写回LDT即可

### SKILL 修复核心教训（2026-06-07 补充）

本次会话确认了以下关键修复规则：

**禁止简单替换 Name 列文本**：
- 直接用 Python 把 Name 列的中文替换回原始乱码字节 → GS 继续报错
- 根因：之前在 SKILL.xls 上的操作（编辑→重新写入等）可能破坏了**整行数据的其他字段**（不仅仅是 Name），单纯改 Name 不够

**正确做法 — 从参考端逐行覆盖**：
1. 准备同结构参考文件（如 `SKILL2.xls`，来自同 ID 体系的另一个版本的端）
2. 按 `_ID` 匹配，从参考文件取**整行 TAB 数据**覆盖当前 SKILL.xls 的对应行
3. 这样确保了所有列（_Name, _Description, _BaseSlv, _MaxSlv, _UpRequire 等）都是正确完整的

```python
# 核心：按ID从SKILL2取整行替换
for line in skill2_lines[2:]:
    parts = line.split(b'\t')
    sid = int(parts[0])
    skill2_map[sid] = line  # 建立ID→整行映射

# 在SKILL.xls中按ID匹配替换
for i in range(2, len(skill_lines)):
    parts = skill_lines[i].split(b'\t')
    sid = int(parts[0])
    if sid in target_ids and sid in skill2_map:
        skill_lines[i] = skill2_map[sid]  # 整行替换！
```

**SKILL_USE.LDT 引用缺失 ID 的修复**：
- GS 报 `SKILL_USE.LDT : FAILED ! Not Exist in Skill.LDT (iKey = XXXX)` → 该 ID 在 SKILL.xls 中不存在
- 从参考端（SKILL2）找到该 ID 的整行数据
- 按 ID 排序插入到 SKILL.xls 中（注意 TAB 格式，每行以 `\n` 分隔，保持文件结构一致）
- 插入位置：找到文件中原有数据中紧邻该 ID 的上一行和下一行，插入在它们之间

**按技能种类分批修复**：
- 每个技能种类（相同 _Name）是一个批次（如"生存本能"25行、"觉醒"50行）
- 一次只处理一个种类 → 用户跑 GS 验证 → 没问题再继续下一个
- ID 通常以 +100 步进递增（如 3812406, 3812506, 3812606...）
- 同一个种类的 ID 可能跨越不同号段（如 3802404~3807304 都是"觉醒"）

**备份策略**：
- 每步操作前备份：`SKILL.xls.bak_before_linerow_<种类名>`
- 保留上次替换前备份（.bak_before_survival, .bak_before_awaken 等）

**用户最终确认**：
- 从参考端逐行覆盖后，用户仍需手动用彩虹岛编辑器改回正确中文名
- 这个手动改中文的操作不会破坏格式——因为整行数据都是对的，只改 Name 列的文本内容是安全的

### SKILL 描述格式注意事项
- Description列通常以 `[技能名]` 或 `[标记名]` 开头（如 `[传奇] 以觉醒的螺旋石...`）
- S3台服SKILL.xls也有约260条_Name乱码，不能完全信赖
- 跨版本修复时，Description可能因版本差异仍需手动修正
- xls修改后GS启动报 `SKILL.LDT : FAILED ! iSkillID = [XXXX]` → 说明LDT还没同步，需要编辑器写回

## GLOBAL_STRING.LDT 系统消息序列定位与ID对应

### 搜索方法
系统提示消息（如"彩虹岛有您更精彩~"、"现在无法连接"）可能在ROWID.SPF包中，不在单独的LDT文件里。

**定位步骤：**
1. 在ROWID.SPF中GBK搜索目标文本 → 找到偏移
2. 看上下文——这些消息是连续序列，每条有消息ID前缀
3. 该序列对应GLOBAL_STRING.LDT里的连续行

### 已知消息序列结构（从ROWID.SPF提取）
```
[行148] [%s]获得了物品。
[行150] 找不到对方。
[行152] 现在无法连接。
[行153] 对方现在没有回应。
[行154] 坐着的状态时，不能移动频道。
[行155] 全体聊天有2秒的等待时间。
[行156] 现在不能移动频道。请稍后再试。
[行157] "%d"秒后可以移动频道。
[行158] 频道已被瘫痪或是不存在的频道。
[行159] 现在连线中的频道。请再试一次。
[行160] 彩虹岛有您更精彩~
```

### 80011~90016 消息码（GLOBAL_STRING.LDT内）
直接按消息码逐条替换GBK编码即可。注意：部分字（如哪/什/迎/回/助/本/步/告/存）的繁简GBK编码相同，不需替换。

## SAVEPOINT.xls 繁转简操作

### 文件结构
SAVEPOINT.xls是彩虹岛编辑器导出的TAB分隔GBK文本，44列：
- _ID, _BGM1~4, _NpcName1~4, _Message1~4, _BoxType1~4, _CutInImage1~4, _CutInEffect1~4
- _Event_BGM~_Event_Message, _Yes/No_系列（BGM/Name/Message/BoxType/Image/ImageEffect）
- _Story

### 操作步骤
1. **备份**：shutil.copy('SAVEPOINT.xls', 'SAVEPOINT.xls.bak')
2. **二进制繁转简**：bytearray.replace按GBK编码批量替换
3. **验证残留**：搜已知繁体字，排除GBK编码相同字
4. **写回LDT**：用彩虹岛编辑器从xls导入写回SAVEPOINT.LDT

## GLOBAL_STRING / CLASS_STRING 本地化

详见 `references/global-string-localization-guide.md`。

包含：
- 职业名映射表（骑士→盾卫、剑斗士→双刀）
- 30000系列消息文本完整改文方案
- XLS文件GBK二进制替换技术要点
- `\n` 在xls中的存储格式坑（`5C 6E`双反斜杠 vs `0A`换行符）

## XLS文件结构（彩虹岛编辑器导出格式）

彩虹岛编辑器导出的 `.xls` 文件实际上是 **TAB分隔的GBK文本文件**（魔数 `Type\t3\t3`），不是真正的Excel二进制格式。可以直接用Python或文本编辑器修改。

| 行 | 内容 | 示例 |
|---|------|------|
| 第1行 | 列类型号 | `Type\t3\t3\t1...` |
| 第2行 | 列名 | `_ID\t_Category\t_Num...` |
| 第3行起 | 数据 | TAB分隔的行数据 |

**ITEM_2.xls关键列：** `_Name(3)`=`道具名`, `_CashCheck(11)`=`可上架开关(0/1)`, `_Type(14)`, `_SubType(15)`

**CASH_SHOP.xls关键列：** `_CategoryView(1)`, `_CategoryIndex(2)`, `_CategoryIndex2(3)`, `_CategoryIndex3(4)`, `_Name(7)`, `_ItemID1(16)`, `_Buy_Disable(62)=1`, `_Give_Disable(63)=1`

**注意**：CASH_SHOP的ItemID1(列16)指向ITEM_2的`_Num`(列1)，不是编辑器RowId(列0)。写入商城前必须去重。

彩虹岛编辑器导出的数据为`|`分隔的一行格式，字段顺序对应LDT列索引：
```
RowId|Category|Num|ColorID|Name|Description|Icon|IconIndex|GamePrice|CashPrice|CashCheck|Update_Date|null|...
```

**实际写入ITEM_2.LDT行时**：
- 前48列映射为4字节int，从数据区偏移+0开始
- 字符串从数据区偏移+192(=48*4)开始，以`\x00`分隔
- 行大小固定500字节
- 写入后字符串总长不能超过500-192=308字节（含\`\x00\`分隔符）

## ITEM_2.LDT二进制行写入实战（2026-05-29 新增）

### 场景：在已有行（行10768）写入冰弓武器时装

行10768是彩虹岛编辑器新增的行，但INT列全是乱值（看起来是二进制数据被当int解析），需要清空重写。

### 写入步骤

```python
import struct

# 1. 清空整行
for i in range(500):
    data[offset + i] = 0

# 2. 设置INT列（行内偏移 = 列索引 * 4）
struct.pack_into('<I', data, offset + 1*4, 702)   # _Num (ItemID)
struct.pack_into('<I', data, offset + 2*4, 497)   # _ColorID
struct.pack_into('<I', data, offset + 6*4, 10001207)  # _Icon
struct.pack_into('<I', data, offset + 7*4, 155)   # _IconIndex
struct.pack_into('<I', data, offset + 15*4, 15)   # _PosID1 (武器)

# 3. 设置字符串区域（行内偏移=192开始）
str_pos = 48 * 4  # = 192
def ws(s):
    global str_pos
    b = s.encode('gbk')
    data[offset + str_pos : offset + str_pos + len(b)] = b
    str_pos += len(b)
    data[offset + str_pos] = 0  # null终止
    str_pos += 1

ws('0')            # 占位
ws('冰弓（活动）]')  # _Name（加]匹配编辑器格式）
ws('道具描述')      # _Description
ws('null')         # _Update_Date
```

### 注意事项
- **备份先行**：每行500字节，备份取 `data[offset:offset+500]`
- **字符串长度**：写入后字符串总长度不能超过308字节（500-192），超出会覆盖到下一行数据区
- **ItemID唯一性**：\_Num必须唯一，不要和已有道具冲突
- **StatusType待填**：物理/魔法攻击的属性通过\_StatusType[22/24]和\_StatusValue[23/25]成对设置，但Type枚举值尚未确认
- **数据区定位**：`data_off = 12 + col_count*64 + col_count*4`（ITEM_2=8512），`row_size=500`

### 彩虹岛编辑器新增行的坑
- 如果在编辑器中新增行，新增的行可能在文件末尾非标准区域
- 新增行的INT列可能全是乱值（二进制废数据被当int解析）
- 建议：在现有空行上修改，或用彩虹岛编辑器直接编辑（改已有行的字段值，不改行结构）

### S1端ITEM表解析陷阱总结（2026-05-29 新增）

当用Python代码解析S1端（彩虹岛S1）的ITEM_1/2/3.LDT时，注意以下关键差异：

**1. 类型号3(float)的实际含义**
- S1端ITEM表中的`_Category`、`_Type`、`_SubType`、`_Icon`、`_IconIndex`、`_GamePrice`等字段
- 类型号全是3（标记为float），但**实际存的是整数（int32）**
- 如果用Python `struct.unpack('<f')` 解析会得到极小的科学计数法值（如2.35e-38）
- 必须按int32解析才能得到正确的分类值

```python
# ❌ 错误（得到垃圾值）
val = struct.unpack_from('<f', data, o)[0]
# → 2.350988701644575e-38 而不是 1

# ✅ 正确
val = struct.unpack_from('<i', data, o)[0]
# → 1
```

**2. _Name字段是索引ID，不是道具名**
- _Name类型号=1（unsigned short int）
- 存的不是中文名，而是GLOBAL_STRING.LDT或者其他字符串表的索引ID
- 0=空，非0值（如304、12288）指向字符串表的某一行
- **不可以通过二进制搜索GBK中文名来定位S1端的道具行！**

**3. 列数差异**
- S1 ITEM_2: 109列 2901行
- 当前怀旧端 ITEM_2: 125列 10591行
- 直接复制行数据时，必须手动配对字段，不能整行拷贝

**4. GLOBAL_STRING.LDT**
- S1的GLOBAL_STRING是2列（`_STRING`、`_DESC`），2100行
- 两列的取值都是0（空），实际文字内容不在这个表里
- 说明S1端把名称存在别的位置（或是彩虹岛编辑器另外管理的）

**5. ICON字段也是索引ID**
- _Icon（如10001212）和 _IconIndex（如155）在S1端也是int
- 和怀旧端一致，IconFileID指向BANX.SPF内的贴图文件

### S1端数据提取的推荐方法
- **优先用彩虹岛编辑器打开**，不要写代码解析
- 如果一定要代码提取，按type号解析后把type=3字段当int32处理
- _Name列的值不能用于搜索道具，只能通过编辑器查看
- 通过CASH_SHOP.LDT的ItemID反查ITEM表更可靠

## GLOBAL_STRING.LDT 系统消息文本定位

### 搜索方法
系统提示消息（如"彩虹岛有您更精彩~"、"现在无法连接"）可能在ROWID.SPF包中，不在单独的LDT文件里。

**定位步骤：**
1. 在ROWID.SPF中GBK搜索目标文本 → 找到偏移
2. 看上下文——这些消息是连续序列，每条有消息ID前缀
3. 该序列对应GLOBAL_STRING.LDT里的连续行

### 版本B文件对比（修复技能文本用）
当用两个版本（D:\ROWID\DATA\LDT 版本B 和 D:\LaTale\S4\resource\ROWID\DATA\LDT）对比修复文本时，先确认文件结构一致（同列数和行数），可以直接在二进制中搜索目标字符串定位行号。SKILL_TXT.LDT存放技能名称和描述，LDT格式为全string（type=0），行间\0分隔。

### XLS/LDT 繁转简批量处理

当需要批量处理彩虹岛文本文件的繁转简时：

### 适用文件类型

| 类型 | 格式 | 修改方式 | 注意事项 |
|------|------|---------|---------|
| XLS（编辑器导出） | TAB分隔GBK文本 | 二进制GBK替换 | `\\n`存储为`5C 6E`（双反斜杠+n），非`0A` |
| LDT标准格式 | 二进制(int+string) | 二进制GBK替换 | 等长替换安全；不等长会破坏结构→GS闪退 |
| LDT全string格式（EFFECT类） | 变长\\x00分隔 | 仅等长替换 | 不等长→GlobalSys::Init()后闪退无ERROR日志 |
| SAVEPOINT.LDT | 二进制(embedded GBK) | 二进制GBK替换 | 含大量爱丽丝石塔对话，全表可整体繁转简 |

### 方法1: GBK二进制替换（XLS推荐）

```python
T2S = {'愛':'爱', '麗':'丽', '絲':'丝', '儲':'储', '戰':'战', '鬥':'斗', '騎士':'盾卫', ...}
data = bytearray(open(file, 'rb').read())
for tw, cn in T2S.items():
    data = data.replace(tw.encode('gbk'), cn.encode('gbk'))
open(file, 'wb').write(data)
```

**注意**：直接binary替换字符串是安全的，XLS是TAB分隔的文本文件，LDT中string字段也是独立区域。

### 方法2: LDT繁转简（全表覆盖法）

对于SAVEPOINT.LDT这类含大量繁体的二进制LDT：
```python
# 先备份，再逐词替换
mapping = {"愛麗絲":"爱丽丝", "儲存":"储存", "戰鬥":"战斗", ...}
for old, new in mapping.items():
    raw = raw.replace(old.encode('gbk'), new.encode('gbk'))
```
完成后验证：搜常见繁体字（愛/麗/鬥/戰/儲等）看残留。

### XLS中`\n`的坑

XLS文件里实际存储为`5C 6E`（反斜杠+n两个ASCII字符），不是单个`0A`。替换含换行的长文本时：
- Python字符串中写成 `"\\\\n"`（双反斜杠+n）
- 如果要匹配实际内容，xls里的换行就是`\\n`两个字

### 处理记录

| 文件 | 类型 | 修改内容 | 处数 |
|------|------|---------|------|
| QUEST.xls | XLS | 繁转简 | 289行 |
| QUEST_1.xls | XLS | 繁转简 | 1行 |
| QUEST_2.xls | XLS | 繁转简+艾丽丝→爱丽丝+耶比→龙猫 | 45行 |
| GLOBAL_STRING.xls | XLS | 骑士→盾卫、剑斗士→双刀；30011~30029消息文本本地化 | 19处+12条 |
| SKILL_TXT.xls | XLS | 配戴→佩戴 | 16处 |
| NPCTALK.xls | XLS | 配戴→佩戴、回覆→回复 | 2处 |
| SAVEPOINT.LDT | LDT二进制 | 全表繁转简（爱丽丝石塔对话等） | 全表 |

### 65536/16777216污染批量清理

## ITEM_1.xls 结构（S4端，126列，17566行）

彩虹岛编辑器导出的TAB分隔GBK文本。关键定价列：\n\n| 列索引(0-based) | 字段 | 说明 |\n|:---:|:---|:---|\n| 0 | _ID | 编辑器RowId |\n| 1 | _Category | 分类 |\n| **2** | **_Num** | **物品ID** |\n| 4 | _Name | 道具名 |\n| **9** | **_GamePrice** | **卖给商店的回收价** |\n| 10 | _CashPrice | 点券价 |\n| 11 | _CashCheck | 0=禁止, 1=允许上架 |\n| 13 | _RareLimit | 品质(1=白, 3=绿, 4=蓝, 5=紫) |\n| 14 | _Type | 物品大类 |\n| 15 | _SubType | 子类 |\n| 62 | _ItemLv | 装备等级 |\n| 65 | _Trade | 可交易 |\n| **68** | **_Sell** | **1=可卖给商店, 0=不可** |\n\n### GamePrice分档定价规则（2026-06-09）

```python
price_table = {
    (1, '1~30'): 100,   # 白装低等
    (1, '31~60'): 500,
    (1, '61+'): 2000,
    (3, '1~30'): 500,   # 绿装
    (3, '31~60'): 2000,
    (3, '61+'): 8000,
    (4, '1~30'): 2000,  # 蓝装
    (4, '31~60'): 8000,
    (4, '61+'): 30000,
    (5, '1~30'): 5000,  # 紫装
    (5, '31~60'): 20000,
    (5, '61+'): 80000,
}
```

修改方法：遍历所有`_Sell=1`的行，按`_RareLimit`+`_ItemLv`查表设`_GamePrice`。备份先行。改完XLS后用编辑器写回LDT。\n\n（2026-06-04 新增）

**现象**：ITEM_2.LDT中有大量int列值为 65536(0x10000) 和 16777216(0x1000000)——这是编辑器/打包工具的**位标记值**污染了数据字段。本端实测发现 **12830处65536**。

**影响**：当某个道具改CashCheck=1（允许上架）后，GS启动时会完整加载该道具，如果EffectID或SetID列被污染为这些值 → GS崩溃。

**批量清理脚本**：
```python
targets = [65536, 16777216]
for row in range(行数):
    off = DATA_OFF + row * ROW_SIZE
    for ci in range(48):
        val = struct.unpack_from('<I', data, off + ci*4)[0]
        if val in targets:
            struct.pack_into('<I', data, off + ci*4, 0)
```

**预防**：改CashCheck 0→1前先跑清理，避免改完才暴露坏数据。

### QUIZ文件位置（RoomServer启动相关）

RoomServer启动时如果QUIZ文件缺失会报 `LoadQuizInfoLDT() : [FAILED]`。
S4端和S1端均无QUIZ文件，需从S4chd复制。

**已知来源**（S4chd）：
```
D:\LaTale\S4chd\resource\ROWID\DATA\LDT\QUIZ.LDT
D:\LaTale\S4chd\resource\ROWID\DATA\LDT\QUIZ_A.LDT
D:\LaTale\S4chd\resource\ROWID\DATA\LDT\QUIZ_BONUS.LDT
D:\LaTale\S4chd\resource\ROWID\DATA\LDT\QUIZ_Q.LDT
D:\LaTale\S4chd\resource\ROWID\DATA\LDT\QUIZ_REWARD.LDT
```

转简体需先用彩虹岛编辑器导出XLS。

| 工具 | 路径 | 说明 |
|------|------|------|
| 彩虹岛编辑器 | `D:\LaTale\小九三合一\彩虹岛编辑器.exe` | GUI编辑LDT |
| LDT修改器 | `D:\LaTale\LDT修改器.exe` | 易语言+UPX 3.91改版壳，需脱壳 |
| ldt-find-replace | `D:\LaTale\ldt-find-replace.exe` | 模糊搜索替换string字段 |
| 解包-打包 | `D:\LaTale\解包-打包.EXE` | SPF解包/打包 |
| ldt_writer | `C:\Users\Administrator\Temp\ldt_writer.py` | Python LDT读写库 |

### 导出TXT列映射陷阱（最高危）

**现象**：GS报 `Invalid Data {RowId} {Name} 240 1 2`，事件类型值异常（如912008而不是0/1）。

**根因**：TXT有65列（col0=_RowId+64个CASH_SHOP字段），CASH_SHOP.LDT只有64列（无_RowId列）。  
当 `for ci in range(cs_cc): v = parts[ci]` 时，取到的是 `parts[0]=_RowId`，造成所有列向前错位1。  
_EventType(col5 in LDT, col6 in TXT) 被填入了 _PositionIndex的值，导致GS启动崩溃。

**修复**：
1. TXT发CASH_SHOP时：写入循环用 `parts[ci+1]`（跳过第0列_RowId）
2. 写入后立即验证：读回新行的_Name字段看是否=道具名（而不是0或空），EvType看是否∈{0,1}
3. 如果GS报`Invalid Data {RowId}`，检查该行的_EventType值是否异常

**验证写后读方法**：
```python
# 二进制读回新行验证
fp = row_start + 4  # 跳过RowId
# col0~4 都是int
fp += 5 * 4  # 跳过col0~4
ev_type = struct.unpack('<I', d[fp:fp+4])[0]  # col5 = EventType
fp += 4
# col6 = _Name (string)
slen = struct.unpack('<H', d[fp:fp+2])[0]
fp += 2
name = d[fp:fp+slen].decode('gbk', errors='replace') if slen > 0 else ''
```

### ITEM_2 TXT预过滤规则（2026-06-04）

从编辑器导出的完整ITEM_2 TXT提取数据前，先过滤无用道具：

| 关键词 | 排除原因 | 示例 |
|--------|---------|------|
| `不使用` | 测试/预留道具，无游戏内用途 | `不使用_翅膀`、`不使用_女_旗袍` |
| `定制` | 预留占位道具 | `定制预留帽子`、`定制预留上衣` |

**标准脚本**（输出到桌面`item2_clean.txt`）：
```python
import csv
SRC = r'C:\\Users\\Administrator\\Desktop\\item2.txt'
DST = r'C:\\Users\\Administrator\\Desktop\\item2_clean.txt'
def bad(n):
    n = n.strip()
    return '不使用' in n or '定制' in n
with open(SRC, encoding='utf-8') as fin, \
     open(DST, 'w', encoding='utf-8', newline='') as fout:
    reader = csv.reader(fin, delimiter='\t')
    writer = csv.writer(fout, delimiter='\t')
    for p in reader:
        if len(p) > 4 and not bad(p[4]):
            writer.writerow(p)
```

### ITEM_2 TXT逐步筛选流程（2026-06-04）

从编辑器导出完整ITEM_2 TXT后，按以下步骤逐步筛选到`item2_clean.txt`：

**Step 1 — 基础过滤：** 去掉"不使用"和"定制"类道具。

**Step 2 — 去重：** 排除已在商店.txt上架的（商店ItemID1=item2 RowId）。

**Step 3 — 按类型/规则过滤：**
- **勋章/徽章类（Type=4,SubType=11）**：同系列只保留最高强化等级，+0~+N-1全删。
  - 找到每个系列的最大强化等级 → 删除所有低于该等级的条目
  - 无强化版本（如"勤快的劳动者徽章"）直接删除
- **眼睛类**：名称含`眼镜` `墨镜` `眼罩` `眼睛` `眼尾` `瞳孔` 的条目全部删除
  - ⚠️ 注意："眼镜蛇XXX"系列（衣服/鞋子/皇冠）不是眼部装饰，需捞回
- **发型**：暂时保留不动，最后再处理
- **强化结晶装备（Type=1,SubType=0 如彩虹泡泡/玫瑰盛典）**：同系列只保留+9和MAX，+0~+8删除。
  - 注意可能有跨类型的同名系列（玫瑰盛典在Type=4,SubType=11也有+15版本）

**Step 4 — 统计分类型数量：** 输出未上架的各类Type/SubType分布供用户选择。

**Step 5 — 根据用户指令：** 定向筛选要上架的品类，生成65列CASH_SHOP追加TXT。

### ITEM_2 二进制直接修改 Name 字段（2026-06-04）

场景：需要在 ITEM_2.LDT 二进制中搜索道具名中的某个长前缀，替换为短前缀（或去掉）。

**方法**：直接在整个文件中搜索前缀的GBK编码，找到后定位字符串边界（往前找\x00做start，往后找\x00做end），覆盖写入新名，剩余部分用空格填充（0x20）保持长度不变。

```python
prefix_gbk = '要去掉的前缀'.encode('gbk')
data = bytearray(open('ITEM_2.LDT', 'rb').read())

pos = 0
while True:
    idx = data.find(prefix_gbk, pos)
    if idx == -1: break
    if idx < data_off:  # 跳过列名区
        pos = idx + 1; continue

    # 找字符串范围
    start = idx
    while start > 0 and data[start - 1] != 0: start -= 1
    end = idx + len(prefix_gbk)
    while end < len(data) and data[end] != 0: end += 1
    if end <= start: pos = idx + 1; continue

    # 新名字（去掉前缀后的剩余部分）
    suffix_raw = data[idx + len(prefix_gbk):end]
    try:
        new_gbk = suffix_raw.decode('gbk').strip().encode('gbk')
    except:
        # 有非法GBK字节，逐字节过滤
        new_gbk = bytearray()
        i = 0
        while i < len(suffix_raw):
            b = suffix_raw[i]
            if b < 0x80:
                if 0x20 <= b <= 0x7e: new_gbk.append(b)
                i += 1
            elif 0x81 <= b <= 0xfe:
                if i+1 < len(suffix_raw):
                    pair = suffix_raw[i:i+2]
                    try:
                        pair.decode('gbk')
                        new_gbk.extend(pair)
                    except: pass
                    i += 2
                else: i += 1
            else: i += 1
        new_gbk = bytes(new_gbk)

    if len(new_gbk) <= old_len:
        data[start:start+len(new_gbk)] = new_gbk
        for i in range(start+len(new_gbk), end):
            data[i] = 0x20  # 空格填充
        found += 1
    pos = idx + 1
```

**⚠️ 陷阱**：
- 编辑器RowId（TXT第0列）和二进制行索引**不是同一套编号**。RowId是几亿~几十亿的编辑器ID，LDT行号是0~N-1。不要用RowId做二进制定位。
- 直接在LDT字节中搜索字符串更可靠（find + 边界定位）。
- 如果原名含`\ufffd`（替换字符）或非GBK编码字节，必须逐字节过滤而不是直接`.encode('gbk')`。
- 剩余位置用`0x20`填充而不是`0x00`，否则会破坏后续string字段的\x00边界。

### ITEM_2 名称去除合作前缀的完整例子（2026-06-04 实战）

将 `【韩国专属合作道具，其他国家服无法使用】初音假发` 改为 `初音假发`：
1. TXT：直接替换字符串（单纯文字操作）
2. LDT：在二进制中搜索前缀GBK，找到后去掉前缀（保留后缀），剩余空间用空格填充
3. 共131处，116处正常GBK解码替换 + 15处非法字节逐字节过滤替换
4. 更新LDT后无需打包重启GS即可看到效果（pack=1模式下需要）

### 恢复误删道具的方法（2026-06-04）

当关键词过滤误删了名称含关键字但不是该类的道具（如"眼镜蛇XXX"衣服被当眼睛类误删）：

1. 从原始item2.txt中找到被误删的道具完整行
2. 追加回item2_clean.txt
3. 确认名称不含其他要过滤的词

```python
# 从原始文件捞回
RECOVER = {'眼镜蛇下衣', '眼镜蛇凉鞋', ...}
with open('item2.txt') as fin, open('item2_clean.txt', 'a') as fout:
    seen = set()
    for line in fin:
        name = line.split('\t')[4].strip()
        if name in RECOVER and name not in seen:
            seen.add(name)
            fout.write(line)
```

**常见过滤关键词对照：**
| 过滤目标 | 关键词 | col位置 |
|---------|--------|---------|
| 测试/废弃 | `不使用` `测试用` | col4=Name |
| 预留空位 | `定制` `定制预留` | col4=Name |
| 眼睛类 | `眼镜` `墨镜` `眼罩` `眼睛` `眼尾` `瞳孔` | col4=Name |
| 韩国独占 | `韩国专属合作` | col4=Name |
| 强化结晶 | Type=1, SubType=0 | col9, col10 |
| 徽章 | Type=4, SubType=11 | col9, col10 |
| 服装 | Type=100, SubType=0 | col9, col10 |

### 用户偏好（最新更新 2026-06-04）

- **ITEM_2 TXT导出后先过滤再分析**：编辑器导出完整TXT后，先按上述规则去"不使用"和"定制"类，再处理剩余数据
- **排除ItemID**：商城已上架的道具用`商店.txt`的ItemID1列（col16, 0-based）匹配`item2.txt`的RowId（col0），两者是同一套编号。
- **限时版处理规则**（2026-06-04 用户确认）：
  1. 同系列同时有永久版和限时版的 → **保留永久版，删除所有限时版**
  2. 只有限时版没有永久版的 → **暂时保留不动**（后续再考虑改成永久）
  3. 多个限时版本同系列的 → 之前已做了删短留长（只留最长天数）
- **强化道具筛选策略**：
  1. 勋章/徽章类（Type=4,SubType=11）：同系列只保留最高等级
  2. 强化结晶类（Type=1,SubType=0）：保留+9和MAX/最高级，删+0~+8
  3. 翅膀类（七彩/千机等）：保留+15，删+0~+14，可上架商城
  4. 超高强化废弃活动道具（如Miss戒指+0~+100、图腾+0~+99）：暂保留待定
- **眼睛类过滤**：名称含`眼镜` `墨镜` `眼罩` `眼睛` `眼尾` `瞳孔` → 全部删除
  - ⚠️ 注意：`眼镜蛇XXX`系列不是眼睛类，需捞回
- **残像镜子**：系列多色（红蓝绿黄黑透明等），各系列保留+9纯版，删除+0~+8和所有限时版
- **韩国合作前缀**：`【韩国专属合作道具，其他国家服无法使用】` → 去掉前缀，只留道具名。TXT和LDT都要改。
- **发型**：暂时保留不动
- **选择偏好**（2026-06-04 确认）：提问方式偏好封闭式多选（A/B/C）。用户说"你决定"时AI自行选择后直接执行。不要让用户在一堆选项里做决定。
- **去重警钟**：每次写入/追加后必须检查CASH_SHOP是否有重复ItemID。本轮发现耳环重复93行（同一批耳环写入两次），原因是用户恢复备份后未清空旧数据就追加了新行。写入前要先确认CASH_SHOP中目标ItemID不存在。
- **GS启动后验证"连接"问题**：单机版出现"现在无法连接"提示通常与CASH_SHOP无关，是客户端残留的死代码/缺少后端接口。不影响游戏功能和后续联机。
- **写入前必须检查ITEM_2.CashCheck**：追加商城道具前如果ITEM_2的_CashCheck=0，GS会报Invalid Data。必须先在ITEM_2中改CashCheck=1。
- **Name字段填错修复方式**：如果CASH_SHOP的_Name写成了_Description，因Name比描述短，可直接二进制覆盖（新GBK长度≤旧长度）。循环每行找到_Name位置→覆盖→清剩余字节。
- **翅膀类时装（PosID1=9）多混入丝袜**：筛翅膀时要排除名称含"丝袜""袜子""及膝袜""紧身裤"的道具。
- **PosID1=9的+1~+15翅膀**：恶魔翅膀+1~+9、天使翅膀+1~+9、七彩蝴蝶翅膀+1~+15、千机翅膀+1~+15、金龙翅膀+1~+15。这些是数值型装备翅膀不是装饰时装，但仍可用CASH_SHOP上架。需注意它们的CashCheck多数=1（已允许上架），但CASH_SHOP中无记录。
- **"未命名"道具一律过滤**：商城Name为"未命名"的道具无法识别用途，追加前要剔除。

### 改CashCheck 0→1前必须预检

**根因**：当CashCheck=0时，GS启动时不加载该道具的全部数据列。改CashCheck=1后，GS会完整加载→可能暴露**被隐藏的坏数据**（EffectID/SetID被填了65536/16777216等位标记值）。

**预检步骤**：
1. 搜ITEM_2.LDT中所有值为65536(0x10000)和16777216(0x1000000)的int列
2. 批量清0（Python struct按偏移写4字节）
3. 再改CashCheck
4. 否则改完CashCheck后GS报如 `iItemID=30371402, EffectID=16777216` 或 `SetID does not exist in SETITEM_B`

65536/16777216是编辑器/打包工具写入的位标记污染，本端ITEM_2中有**12830处**。

- **沟通极度简短单字**：1/2/好/行/删。反感AI绕弯子/选项列表/揣测废话。
- **"你先停让我来"** = 立刻停手，不要试第三次。把TXT生成好交给用户即可。
- **"试试怎么炸"**：改一个→打包→看GS崩不崩，迭代推进。
- **连续失败两次立刻换方案**：第三次他手动来，AI停手。
- **AI直接追加二进制写入无效**（GS闪退/数据错位），必须导出TXT让用户用彩虹岛编辑器手动复制。
- **防止一次性发大文件**：先发小批量（10~50件）测试，确认能用了再继续。
- **不要用sed修改含中文/GBK编码的文件**——会破坏中文字符。改配置用Python或手动记事本。
- **行号/序号在TXT第一列是有效的**：第0列可以是行序号，真正写入LDT时要跳过它用`parts[ci+1]`。
- **"你不是二进制的问题，你需要测试验证"**：GS加载失败不是二进制格式问题，是字段值的语义问题。不要怀疑格式，去检查字段值。生成数据文件让用户验证，不要替用户判断。
- **去掉"未命名"的道具**：商城Name为"未命名"的道具无实际用途，追加前应过滤掉。


### ITEM_2 迭代筛选工作流（2026-06-04 新增）

详见 `references/item2-iterative-filtering-workflow.md`。

包含从全量TXT逐步筛除不需要类别的完整流程记录，以及ITEM_2.LDT二进制批量改名的Python代码模板。

## CLASS_STRING.LDT — 职业定位与装备限制解码

彩虹岛编辑器导出的 CLASS_STRING.xls（3列，149行）存储了职业名与位掩码的映射。

**装备限制解码**（ITEM_1.xls分析时经常用到）：
- `_RequireX_Type` = 0 → 无限制；= 1 → **职业限制**
- `_RequireX_ID` = **ClassID**（1=战士, 2=盾卫/骑士, 3=法师, 4=游侠...）
- 雪女冰弓案例：R1(type=0, 无限制), R2(type=1, id=1=战士) → 限战士装备
- 脏数据（col45大数 2199024305160）是编辑器位标记污染，视为 0

详见 `references/class-string-and-item-restrictions.md`（含CLASS_STRING完整职业名映射、ITEM_1装备限制解码、SKILL_TXT本地化、脏数据处理）。

### ITEM_2 StatusType/StatusValue 映射（未完全确认）

| StatusType值 | 推测含义 | 确认状态 |
|:---:|:---|:---:|
| 62 | 物理攻击力最大值 | ❓ |
| 66 | 物理攻击力最小值 | ❓ |
| 70 | 魔法攻击力最大值 | ❓ |
| 218 | 魔法攻击力最小值 | ❓ |

**确认方法**：用彩虹岛编辑器打开怀旧端 ITEM_2，找一个已知属性的武器（如"活动铅笔短剑"），查看其 StatusType 对的值，作为参考标准。

详见 `references/session-20260529-icebow-StatusType-uncertainty.md`。

**注意**：StatusValue[23/25/27/29] 填的是绝对值还是百分比标志，取决于 StatusType 的高位标记。如果 StatusType 高位标记了百分比，则 StatusValue=74 表示 74% 而不是 74点。

### 彩虹岛编辑器126字段格式陷阱

当用户从彩虹岛编辑器复制数据（`|`分隔的一行）给你看时：
- **实际有126个字段**：第1个是RowId（编辑器显示用），后面125个才是ITEM_2真正的LDT列
- 第0列RowId可以是任何数字如518160621，写二进制时**要忽略**
- 如果你要写代码处理，注意跳过第0列用 `parts[1:]`
- 这条同样适用于CASH_SHOP编辑器的数据：65个字段（RowId + 64列）

示例用户粘贴的126字段数据：
```
518160621|809|40|1|雪女冰弓（专用）|+35% ... |10001101|174|...
```
这里第0字段518160621是RowId(编辑器显示)，第1字段809是_Category。

### 彩虹岛编辑器导出格式详解（2026-05-29 更新）

彩虹岛编辑器导出的数据为`|`分隔的一行格式，字段顺序对应LDT列索引：
```
RowId|Category|Num|ColorID|Name|Description|Icon|IconIndex|GamePrice|CashPrice|CashCheck|Update_Date|null|...
```

**重要**：编辑器显示/导出的行有 **126个字段**（RowId + 125个ITEM_2列），但 ITEM_2.LDT 二进制只有125列数据，**没有_RowId列**。RowId只是彩虹岛编辑器为了方便用户识别而添加的显示字段。实际写入时编辑器会忽略第一个字段。

**当用户从编辑器复制数据给你看时**，注意126字段格式，第1个是RowId，后面125个才是真正的LDT字段。

### 实际写入ITEM_2.LDT行时：
- 前48列映射为4字节int，从数据区偏移+0开始
- 字符串从数据区偏移+192(=48*4)开始，以`\x00`分隔
- 行大小固定500字节
- 写入后字符串总长不能超过500-192=308字节（含`\x00`分隔符）

### ITEM_2.LDT二进制行写入实战

**场景**：在已有行（行10768）写入冰弓武器时装。

行10768是彩虹岛编辑器新增的行，但INT列全是乱值（二进制废数据被当int解析），需要清空重写。

**写入步骤**：
```python
import struct
# 清空行、设INT、写字符串区（见上述代码模板）
```

**注意事项**：
- 备份先行：每行500字节，备份取 `data[offset:offset+500]`
- 字符串总长 ≤ 308字节
- ItemID（_Num）必须唯一
- StatusType待填：物理/魔法攻击的Type枚举值尚未确认，需从已有带攻击属性的装备逆向

### CASH_SHOP追加工作流（核心）

### 铁律

**不要直接写入CASH_SHOP.LDT。** 用户确认AI二进制追加导致GS闪退/数据错位（报错 `CASH_SHOP.LDT : Invalid Data {RowId} {Name} {CashPrice} {PriceType} {Limited} {BuyDisable}` → `CASH_PRICE_RATIO.LDT No Data` → GS关闭）。正确方式：生成65列TXT → 用户用彩虹岛编辑器逐行/批量复制。

**"两次失败"法则**：前两次自动写入失败（GS崩/零效果/编辑器报乱码），第三次必须停手并切换手动方式。不要尝试第三次自动写入。

### 步骤

1. **ITEM_2._CashCheck 0→1** — 允许物品上架商城。筛选PosID∈{3,4,5,6,7,8}，排除基础发型。**不要包含PosID1=11。**
2. **生成TXT清单**（65列含_RowId）→ 桌面
3. **用户手动复制**到彩虹岛编辑器 → 追加到CASH_SHOP.LDT
4. **打包SPF** → 启动GS测试

### 导出TXT列映射陷阱（最高危）

**现象**：GS报 `Invalid Data {RowId} {Name} 240 1 2`，事件类型值异常（如912008而不是0/1）。

**根因**：TXT有65列（col0=_RowId+64个CASH_SHOP字段），CASH_SHOP.LDT只有64列（无_RowId列）。  
当 `for ci in range(cs_cc): v = parts[ci]` 时，取到的是 `parts[0]=_RowId`，造成所有列向前错位1。  
_EventType(col5 in LDT, col6 in TXT) 被填入了 _PositionIndex的值，导致GS启动崩溃。

**修复**：
1. TXT发CASH_SHOP时：写入循环用 `parts[ci+1]`（跳过第0列_RowId）
2. 写入后立即验证：读回新行的_Name字段看是否=道具名（而不是0或空），EvType看是否∈{0,1}
3. 如果GS报`Invalid Data {RowId}`，检查该行的_EventType值是否异常

**验证写后读方法**：
```python
# 二进制读回新行验证
fp = row_start + 4  # 跳过RowId
# col0~4 都是int
fp += 5 * 4  # 跳过col0~4
ev_type = struct.unpack('<I', d[fp:fp+4])[0]  # col5 = EventType
fp += 4
# col6 = _Name (string)
slen = struct.unpack('<H', d[fp:fp+2])[0]
fp += 2
name = d[fp:fp+slen].decode('gbk', errors='replace') if slen > 0 else ''
```

### 导出TXT行为规范

1. **必须65列**（col0=_RowId + 64个CASH_SHOP字段）
2. TXT用`|`分隔，UTF-8编码
3. _RowId从当前CASH_SHOP最大RowId+1起，_PositionIndex从当前最大+1起
4. 价格统一240，_Buy_Disable=1, _Give_Disable=1
5. **被拒绝的格式**：64列无_RowId的txt、`.xlsx`、`.csv`
6. 生成后检查每行的_EventType ∈ {0,1} —— 如果出现>10的值说明列偏移

### EventType+_CategoryIndex3配对规则

| 类型 | _CategoryIndex3 | _EventType | _Limited_Time_Type |
|------|----------------|------------|-------------------|
| 永久 | 5 (发型) / 4 (衣服) … | 0 | 0 |
| 限时 | 0 (活动类) | 1 | 2 |

**注意**：_Limited_Time_Type的值只有0（永久）和2（限时）是合法的。值1会导致GS崩溃报 `CASH_PRICE_RATIO.LDT No Data`。

### 发型清单过滤规则

### 导出格式规范

- **必须65列**（第1列_RowId + 64个CASH_SHOP字段）
- TXT用`|`分隔，UTF-8编码
- _RowId从2400起，_PositionIndex从912008起
- 价格统一240，_Buy_Disable=1, _Give_Disable=1
- **被拒绝的格式**：64列无_RowId的txt、`.xlsx`、`.csv`

### 发型清单过滤规则

从xls→TXT时，过滤掉非发型条目。判断方法：
1. 耳环类：名称含"耳环""耳環""耳朵"
2. 指南针：名称含"指南针""指南針"
3. 上述名称关键词匹配不到的但ItemID在ITEM_2中PosID1≠3 → 跳过

### 耳环清单过滤规则

从全量xls/TXT提取耳环时，排除：
1. 名称含"不使用" "测试用"的条目（无用/测试道具，用户明确要求删除）
2. 分类范围：含"耳环""耳環""指南针""指南針""耳朵"关键字的行
3. _RowId从当前CASH_SHOP最大RowId+1起，_PositionIndex从当前最大+1起

耳环清单过滤后需要验证_EventType字段（见EventType列映射陷阱）。

### CASH_SHOP.LDT直接写入陷阱汇总

**核心失败模式**：直接二进制追加行到CASH_SHOP.LDT会导致GS启动闪退或彩虹岛编辑器报乱码。用户经过多次验证确认：**所有CASH_SHOP追加操作必须通过彩虹岛编辑器手动复制TXT完成。**

**触发条件**：任何自动二进制追加（build_ldt / struct.pack_into 逐行追加 / copy+append行数据）都会造成GS报`CASH_SHOP.LDT : Invalid Data {RowId}` 或编辑器显示乱码。

**已知原因**：
1. **列偏移陷阱（最高频）**：TXT有65列（col0=_RowId + 64字段），CASH_SHOP.LDT只有64列。写循环用`parts[ci]`会取到_RowId作为第0个字段，导致所有列向前偏移。必须用`parts[ci+1]`跳过第0列。
2. **CASH_PRICE_RATIO.LDT校验**：GS会校验CASH_SHOP中每行的_Limited_Time_Type值：
   - 永久类：`_Limited_Time_Type = 0`
   - 限时类：`_Limited_Time_Type = CASH_PRICE_RATIO的RowId`（不是简单的0/1/2！）
   - 当前CASH_PRICE_RATIO只有两行：RowId=1001（7天比例28）和RowId=1002（30天比例100）
   - 限时类的_Limited_Time_Type填写1001或1002，不是2！
   - 填1或2等值会导致GS报：`CASH_PRICE_RATIO.LDT No Data {RowId} {Name} {CashPrice} {PriceType} {WrongLimited}`
3. **_Limited_Time_Type非法值1/2**：这两个值（不是CASH_PRICE_RATIO的RowId）会导致GS崩溃。

**GS启动日志解读**（快速定位问题行）：
```
(CCashShopInfo::IsValid,103) : CASH_SHOP.LDT : CASH_PRICE_RATIO.LDT No Data {RowId} {Name} 240 1 {Limited}
(CCashShopInfoManager::SetData,143) : CASH_SHOP.LDT : Invalid Data {RowId} {Name} 240 1 {Limited} 1
......DATA/LDT/CASH_SHOP.LDT : FAILED !    iPackageID = [{RowId}]
GetCashShopInfoManager()::Init() : [FAILED]
```
- `240` = CashPrice，`1` = PriceType，最后那个数字是_Limited_Time_Type
- GS按RowId递增顺序加载，第一个失败的就是问题行
- 典型故障链：_EventType列偏移（值>1）→ GS报Invalid Data → 检查该行_EventType是否写成PositionIndex值

**用户明确的工作流（不可绕过）**：
1. 导出65列TXT到桌面（含_RowId）
2. 用户用彩虹岛编辑器手动逐行/批量复制
3. 用户自己打包SPF → 启动GS测试
4. 用户反馈OK后继续下一批

**当用户说"你先停让我来"时**：立刻停手，不要试第三次自动写入。把TXT生成好交给用户即可。

### 时装分类与PosID映射（2026-05-29 修正）

```
发型(PosID=3)  → cat=(1,1,2,5)  ci3=5
衣服(PosID=4)  → cat=(1,1,1,4)  ci3=4
裤子(PosID=5)  → cat=(1,1,1,2)  ci3=2
手套(PosID=7)  → cat=(1,1,4,10) ci3=10  ← 注意PosID1=7是手套不是鞋子！
鞋子(PosID=8)  → cat=(1,1,3,8)  ci3=8
披风(PosID=?)  → cat=(1,1,1,4)  ci3=4  （需进一步确认PosID1）

时限和永久同分类，只差：EventType=1, Limited_Time_Type=2。

### 陷阱合集

1. **xlrd列偏移**：xls有65列(col0=_RowId+64字段)，CASH_SHOP.LDT只有64列。必须从col1开始读跳过_RowId。
2. **ldt_writer自动加_RowId**：CASH_SHOP.LDT无_RowId列，ldt_writer加后整体偏移1列。
3. **用户容错低**：自动追加失败两次立即换手动方式（导出TXT让用户加）。
4. **TXT必须65列含_RowId**：用户明确纠正过。
5. **耳环混入发型清单**：按名称关键词（耳环/指南针/耳朵）过滤。
6. **不要用execute_code直接import xlrd**：沙箱Python无xlrd，需通过terminal()调用系统Python。
7. **xls列对应**：xls第0列=_RowId（手动追加用），CASH_SHOP.LDT无_RowId列。写入LDT时跳过xls的第0列。验证写入时检查_Name(ci=6)而不是col7。

详见 `references/session-20260529-txt-resort-and-banx-icon-mapping.md`。

### 跨版本ITEM表数据拷贝

当需要从S1端（彩虹岛S1）复制道具到怀旧端（他乡包衍生）时，注意列结构差异（109 vs 125列）和字段值类型差异（S1的type=3字段实际存int32）。详见 `references/cross-version-item-copy.md`。

**核心规则**：
1. **不可整行复制** — 列数不同会列偏移
2. **手动配对字段** — 前20列名一致可直接映射
3. **S1的_Name是索引ID** — 不是道具名，需查字符串表或编辑器确认
4. **怀旧端独有字段** — _Use_Type、_StatusType5~8等17个字段填默认值0
5. **ItemID必须唯一** — 不能照抄S1的_ID，要分配新ID
详见 `references/cashshop-fashion-append-technique.md`。
详见 `references/banx-iconfile-mapping-and-cross-server-method.md`。

### S1→怀旧S2跨版本道具复制

当需要从S1端（彩虹岛S1）复制道具到怀旧端时，注意列结构差异（109 vs 125列）、字段值类型差异（S1的type=3字段存int32）以及_Name存储方式不同（索引ID vs 中文名）。详见 `references/cross-version-item-copy-s1-to-s2.md`。

### EFFECT.LDT 结构（重要：70列全string变长）

详见 `references/effect-ldt-field-structure.md`。

**格式**：70列全部是 string（type=0），变长 `\x00` 分隔，行间用 `\x00\x00` 分隔。

**关键字段**：`_Name`（名字）、`_Description`（描述）、`_BuffID`（BUFF ID，区别于RowId）、`_Buff_Name`（BUFF显示名）、`_Buff_Description`（BUFF详细描述）、`_EffectValueType`（百分比数值）。

**二进制修改陷阱**：70列全string是变长结构，不等长替换会破坏文件 → GS在 GlobalSys::Init() 后闪退（不写任何ERROR日志）。必须确保修改前后字符串等长。

**安全修改方法**：
1. 优先用 `200%` → `20% `（末尾补空格）这类等长替换
2. 如果名字长度变了（如"爱丽丝的祝福"→"艾丽丝的祝福"），必须用彩虹岛编辑器改
3. 备份是先决条件

## 脚本索引

**⚠️ 列索引以0-based计（python脚本用），彩虹岛编辑器的 _Type/_SubType 不在 col9/col10！**

| 列索引(0-based) | 字段 | 说明 |
|:---:|:---|:---|
| 0 | _RowId | **=商店.txt的ItemID1（col16）**，做去重时用此列匹配 |
| 1 | _Category | 分类编号 |
| 2 | _Num | **物品ID（不是RowId！）** |
| 3 | _ColorID | 颜色ID |
| 4 | _Name | **道具名（中文）** |
| 5 | _Description | 道具描述 |
| 6 | _Icon | 图标文件ID |
| 7 | _IconIndex | 图标索引 |
| 8 | _GamePrice | 游戏币价格 |
| 9 | _CashPrice | 点券价格 |
| 10 | _CashCheck | 0=禁止商城里出售, 1=允许 |
| 11~13 | _Update_Date/null | 日期/占位 |
| **14** | **__Type** | **物品大类(1=结晶/强化, 4=徽章/饰品, 100=服装)** |
| **15** | **__SubType** | **子类(3=强化结晶, 11=徽章)** |
| 16~125 | 属性/状态/预留 | |

## 编辑器导出TXT列映射（2026-06-04 最终修正）

**⚠️ 列索引陷阱**：编辑器导出的TAB分隔TXT中，_Type和_SubType在0-based **col9**和**col10**。
之前脚本误用col14/col15（读到了_CashPrice/_CashCheck），验证后修复。

验证方法：取彩虹泡泡行，col9=4（Type）、col10=3（SubType）。

| 列索引(0-based) | 字段 | 说明 |
|:---:|:---|:---|
| 0 | _RowId | **=商店.txt的ItemID1（col16）**，去重用此列 |
| 1 | _Category | 分类编号 |
| 2 | _Num | 物品编号 |
| 3 | _ColorID | 颜色ID |
| 4 | _Name | **道具名（中文）** |
| 5 | _Description | 道具描述 |
| 6 | _Icon | 图标文件ID |
| 7 | _IconIndex | 图标索引 |
| 8 | _GamePrice | 游戏币价格 |
| **9** | **_Type** | **物品大类(1=结晶/强化, 4=徽章/饰品, 100=服装)** |
| **10** | **_SubType** | **子类(3=强化结晶, 11=徽章等)** |
| 11 | _CashCheck | 0=禁止上架, 1=允许 |

**常见过滤操作：**

```python
# 去重：排除商店已上架的(RowId匹配)
# 商店.txt col16(0-based) = ItemID1，对应item2的col0=RowId
shop_ids = set()
for parts in csv.reader(open('商店.txt'), delimiter='\t'):
    if len(parts) > 16 and parts[16].strip() != '0':
        shop_ids.add(parts[16].strip())

for parts in csv.reader(open('item2.txt'), delimiter='\t'):
    rowid = parts[0].strip()
    if rowid in shop_ids: continue  # 已上架跳过
```

```python
# 按Type/SubType过滤（col9=Type, col10=SubType）
# 常用：Type=1,SubType=0(强化结晶), Type=4,SubType=11(徽章/饰品)
#       Type=100,SubType=0(服装), Type=1000,SubType=0(配件)
for parts in csv.reader(open('item2.txt'), delimiter='\t'):
    typ = parts[9].strip()
    subtype = parts[10].strip()
    if typ == '4' and subtype == '11':  # 徽章类
        ...
```

```python
# 按名称+强化等级过滤（保持+15，去掉+0~+14）
import re
lvl = 0
m = re.search(r'\+(\d+)$', name)
if m: lvl = int(m.group(1))
if lvl > 0 and lvl < 15: continue  # 跳过低级强化
```

**常见过滤项：**
- `不使用` → 测试/废弃道具，跳过
- `定制` / `定制预留` → 预留空位道具，跳过
- `测试用` → 测试道具，跳过
- `【韩国专属合作道具，其他国家服无法使用】` → 仅韩国合作，按需处理
- 所有 `+N` 后缀的可强化装备类道具，按最大等级决定保留哪些

## ITEM_2 TXT 批量改名前缀（2026-06-04）

场景：编辑器导出的TXT中，道具名有不统一的前缀需要统一（如"活动用白熊手套"→"（活动）白熊手套"）。

**方法**：用 `scripts/rename_txt_prefix.py` 直接修改TXT文件：

```bash
# 将"活动用"改为"（活动）"
python scripts/rename_txt_prefix.py item2_clean.txt --old "活动用" --new "（活动）"
```

注意：这只改了桌面的TXT。如果要同步改ITEM_2.LDT，需：
- 先用TXT校对正确
- 再用彩虹岛编辑器从TXT写回LDT
- 或等用户手动改LDT

## 脚本索引

| 脚本 | 位置 | 用途 |
|------|------|------|
| `binary_replace.py` | scripts/ | 二进制等长替换一个关键词 |
| `enable_cashcheck_fashion.py` | scripts/ | ITEM_2时装_CashCheck 0→1 |
| `rename_txt_prefix.py` | scripts/ | 批量改ITEM_2 TXT中的道具名前缀（如"活动用"→"（活动）"） |
| `filter_item_txt.py` | scripts/ | 批量过滤编辑器导出的ITEM_2 txt（去重/去测试/按类型/按强化等级） |
| `gen_fashion_export.py` | scripts/ | 生成CASH_SHOP追加清单(txt+xls) |
| `ldt_python_writer.py` | scripts/ | Python LDT读写库 |
| `proxy_login.py` | scripts/ | 代理登录 |
| `scan_trad.py` | scripts/ | 搜索关键词在所有LDT文件中的分布 |

## ITEM_UPGRADE.LDT
- 编辑工具: `D:\\\\LaTale\\\\小九三合一\\\\彩虹岛编辑器.exe`
- Python写入工具: `C:\\\\Users\\\\Administrator\\\\Temp\\\\ldt_writer.py`
- 数据库: `127.0.0.1,59157` / sa / 123456

### CASH_SHOP.xls 第n行删除 + 重排_ID/_PositionIndex

**场景**：用户说删CASH_SHOP.xls第91行，但实际上编辑器显示和Python的`\n`分割索引**不一致**。
- 用户说的\"第91行\"不直接对应Python的lines[90]或lines[91]
- **安全做法**：不要猜行号。搜关键词定位目标行，打印_ID和_Name给用户确认后再删。

**安全删除流程**：
```python
with open(CASH_SHOP.xls, 'rb') as f:
    lines = f.read().split(b'\n')

# 1. 搜关键词定位
kw = '目标道具名'.encode('gbk')
target_idx = -1
for i, line in enumerate(lines):
    if kw in line:
        parts = line.split(b'\t')
        print(f'找到行{i+1}(1-based): ID={parts[0]}, Name={parts[7]}')
        target_idx = i
        break

# 2. 用户确认后删除
new_lines = lines[:target_idx] + lines[target_idx+1:]

# 3. 重排_ID(列0)和_PositionIndex(列5)
id_num = 1
pos_num = 1
for i in range(2, len(new_lines)):
    if not new_lines[i].strip(): continue
    p = new_lines[i].split(b'\t')
    if len(p) < 6: continue
    p[0] = str(id_num).encode('gbk')
    p[5] = str(pos_num).encode('gbk')
    new_lines[i] = b'\t'.join(p)
    id_num += 1
    pos_num += 1
```

**验证**：删除后检查_ID是否连续（1~N），_PositionIndex是否连续（1~N）。
