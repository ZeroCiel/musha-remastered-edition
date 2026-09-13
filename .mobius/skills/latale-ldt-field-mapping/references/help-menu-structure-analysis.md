# HELP_MENU / HELP_CONTENT / HELP.LDT 结构分析

**会话**: 2026-05-29，用户想用S1的HELP_MENU数据修复S2客户端帮助目录文字。

## HELP_MENU.LDT（帮助菜单按钮）

### 文件结构
- 列数: 70, 行数: 500（S1和S2一致）
- 所有列type=0（int32），但数据区实际上是**变长二进制块**，混合了：
  - UI坐标值（int32）
  - 颜色值（int32, RGB）
  - **内嵌字符串**（2字节GBK长度头 + GBK数据）

### 字符串分布
数据区前8716字节都是列名和类型区，之后的数据区以2字节长度头+GBK字符串方式嵌入文本：
- 每个菜单按钮的_Name文本存储在数据区的字符串块中
- 字符串之间混杂坐标和颜色数据
- 文本不可单独提取——它们是**和坐标/颜色数据交错存储的**

### S1 vs S2差异
| 项目 | S1 | S2 |
|------|----|----|
| 非空行 | 174行 | 211行 |
| 文本 | 简体中文（国服） | 繁体BIG5被当GBK解码的乱码 |
| 内容示例 | "基本操作方法" | "蛔昼 シ卫" |
| 图片引用 | `UI_Object_004.png` | 同 |

**S2 HELP_MENU的乱码原因**：繁体BIG5编码的数据被当作GBK读取。数据区的字符串以双字节编码存储，S2版本用BIG5写入但客户端以GBK解码，导致显示为日文+乱码的混合。

### 修复方案
1. **从解包目录复制完整繁体版**（如果存在备份）→ 替换
2. **手动用彩虹岛编辑器逐行改**（由于字符数据混乱，推荐）
3. **不推荐二进制替换**——数据区字符串/坐标/颜色混合，字节错位即崩

## HELP_CONTENT.LDT（帮助内容页面）

### 文件结构
- 列数: 20, 行数: 500
- 列: `_Test`, `_ID`, `_Image`, `_Left`, `_Top`, `_Right`, `_Bottom`, `_Image_PosX`, `_Image_PosY`, `_Width`, `_Height`, `_Text_PosX`, `_Text_PosY`, `_Red`, `_Green`, `_Blue`, `_Bold`, `_Horizontal_Align`, `_Vertical_Align`, `_Text`

### 关键发现：**文字在PNG上，不在LDT中**
- `_Image`列引用PNG路径（如 `DATA/INTERFACE/HELP/HELP_01-00_0.png`）
- `_Text`列虽然是type=0(int32)，但实际**指向的是数据区中的字符串ID**
- 这些PNG图片已经内嵌了帮助文字——每个帮助页面内容是一张PNG图片
- LDT只控制着：**哪张图片显示在哪个位置、文字在图片上的偏移和颜色**

### 尺寸参数含义
S1和S2的_Left/Top/Right/Bottom/Image_PosX/Image_PosY/Width/Height值基本一致，说明**两版帮助页面布局完全相同**。

## HELP.LDT（S2独有——帮助总索引）

### 文件结构
- 列数: 8, 行数: 185
- 列: `_Type`, `_Name`, `_CategoryPosition`, `_ConditionType`, `_ConditionID`, `_Image`, `_SystemLinkID`, `_HelpLinkID`
- 所有列type=0(int32)
- 数据区也是内嵌字符串+二进制混合

### 内容
存储每个帮助分类的标题（如"基本知识""上下左右移动、跑""弱攻击、强攻击"等），每个标题关联一个帮助页面PNG。

## HELP_UIBTN.LDT（S2独有——按钮提示文本）

### 文件结构
- 列数: 2, 行数: 25
- 列: `_HelpmenuID`, `_HelpmenuTxt`
- `_HelpmenuTxt`存的是**按钮悬停提示文本**（繁体）

## 数据流总结

```
HELP.LDT (_Name + _HelpLinkID)
    ↓
HELP_MENU.LDT (_Name + _Image坐标)  →  左侧菜单按钮（文字渲染）
    ↓
HELP_CONTENT.LDT (_Image + 文字坐标)  →  PNG图片（文字直接画在图上）
```

**重要推论**: 
- 帮助菜单按钮的**文字是LDT直接渲染的**（S1有简体、S2乱码）
- 帮助内容页面的**文字是PNG图片内嵌的**（改LDT没用，要改SPF里的PNG）
- 修复HELP_MENU的文本 → 改LDT的_Name字段
- 修复HELP_CONTENT的页面文字 → 改SPF里对应的PNG图片

## 本次会话确定的LDT-per-skill原则
每个LDT文件的列结构和功能高度特化，**一个LDT文件对应一类独立操作**。
不应混到通用"LDT操作"技能里。详见 `latale-dev` skill。
