# 繁简转换分批验证日志 (2026-05-27)

## 背景

彩虹岛S2怀旧端(D:\彩虹岛单机\)，LDT文件使用GBK编码存储繁体中文文本。需要将繁体转为简体。

## 关键发现

### 编码确认
- LDT字符串字段使用 **GBK编码**（非Big5），91.4%的2字节组合在GBK下有效
- Big5只有87.8%，确认不是Big5编码
- GBK原生支持繁体字，台服彩虹岛直接用GBK存繁体文本

### "设计"二字导致GS崩溃
- 改了"设"和"计"两个字后，GS直接无法启动
- 去掉这两个字后重试，GS正常启动
- 怀疑exe对LDT的某些字段有硬编码校验（不是CRC，可能是特定字段按偏移读取）

### EFFECT文件导致时尚商店故障
- 改了EFFECT.LDT/PVP_EFFECT.LDT等特效技能文件后
- 游戏中时尚商店报"关闭中，请稍后再使用"
- 不影响GS启动，不影响其他功能
- 怀疑时尚商店功能依赖EFFECT/PVP_EFFECT中的某些特效ID字符串匹配

### "艾丽丝"→"爱丽丝"文本错误
- 游戏中显示为"艾丽丝"（艾+丽+丝），不是繁体"愛麗絲"
- 属于台服翻译错误（"艾"应为"爱"）
- 561处分布在QUEST系列文件中
- 注意：只改"艾丽丝"完整词组，避免把NPC"艾咪""艾温"等也改了

## 分批验证策略

```
第1批: 纯描述文本 (12文件) ✅ 安全
  ACHIEVE, ACTION_INTERFACE, COLLECT_MOB, GIFT_INFO,
  ITEM_2, ITEM_3, NPCTALK, QUEST_1, QUEST_2,
  QUEST_INFO_1, QUEST_INFO_2, SAVEPOINT

第2批: 特效/技能类 (7文件) ⚠️ 时尚商店故障
  EFFECT, FX_GROUP, FX_UNIT, FX_UNIT_ROBOT,
  PVP_EFFECT, PVP_SKILL_USE, SKILL_USE

第3批: 数据表类 (9文件) ❌ 未测试
  ITEM_ENCHANT, ITEM_UPGRADE, ITEM_UPGRADE_P,
  GAMBLE_REWARD, MAPEVENT, NPC_EVENT,
  NPC_EVENT_DETAIL, CP_EVENT_MISSION, QUEST
```

## 推荐工作流

1. **用二进制替换**（不走LDT解析），直接在字节级别搜索GBK编码
2. **只替换等长GBK对**（1繁体字GBK字节数 == 1简体字GBK字节数）
3. **分批次改**，每批改完→打包SPF→验证GS启动→验证关键功能
4. **关键功能验证**：左下角不提示"无法连接" + 时尚商店能打开
5. **保留备份链**：*.bak_trad(原始繁体) → *.bak_v1(第一版简体)

## 危险字列表

| 字 | 状态 | 说明 |
|----|------|------|
| 设、计 | ❌ 危险 | 改了GS崩溃 |
| 佈濃雲當擾從災難 | ✅ 安全 | 第一批已过 |
| 後 | ⚠️ 歧义 | 皇后 vs 之後 都变"后" |
| 著 | ⚠️ 歧义 | 显著 vs 看着 冲突 |
| 權、徵、鬱、幹、裏 | ⚠️ 歧义 | 用户指出后才转 |
