# 2026-05-29 会话：去重、BANX差异规划、文本替换

## 轮次总结
1. 发型追加（55件纯发型到莉莉安）→ 生成TXT
2. 耳环追加（166件，过滤"不使用""测试用"）→ 直接写入CASH_SHOP → 踩坑_Limited_Time_Type
3. 修复_Limited_Time_Type（1001/1002代替2）
4. 鞋子追加（155件，去掉"未命名"）→ 写入GS报Invalid Data（CashCheck=0）
5. 修复155个道具CashCheck：0→1
6. GS启动成功
7. 检查重复：发现2637~2729（93行）跟2543~2636完全重复 → 删除
8. BANX差异清单生成
9. 繁转简测试：超级玛璃→超级玛丽

## CASH_SHOP重复检测方法

```python
pos = 8716
items = []
for ri in range(rc):
    rid = struct.unpack('<I', d[pos:pos+4])[0]
    pos += 4
    # 读ItemID1(col15)
    # ...
    itemid = ...
    items.append((rid, itemid, name))

from collections import Counter
itemid_counts = Counter(itemid for _, itemid, _ in items)
for itemid, count in itemid_counts.most_common():
    if count > 1:
        rows = [(rid, name) for rid, iid, name in items if iid == itemid]
        # 真正重复的（同名+同ItemID+RowId不同）= 二次写入导致
```

注意：有的是"正常重复"（不同性别套装、x1/x10不同档位、不同性别的同名装备），这些要跟真正的写入重复区分开。Rid范围连续+ItemID相同+Name相同 = 重复写入。

## BANX贴图搬运计划（搁置）
- 需要搞懂SPF打包格式
- 他乡端GLOBALRES已解包PNG，怀旧端BANX.SPF未解包
- 直接从国服/S3拷贝可能图索引对不上
- 等他乡端的人问到了打包工具再继续

## 后续上架计划
- 翅膀类（PosID1=9，排除丝袜/+N翅膀）→ 暂缓，与时装冲突
- 衣服(507件)、裤子(85)、手套(70)、披风(181) 未上架的时装待处理

## "现在无法连接"问题
单机版客户端报此错不影响功能。可能原因：
- 缺少后端验证接口
- 客户端死代码残留
- 不影响后续联机
