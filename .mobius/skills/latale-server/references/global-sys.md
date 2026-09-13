# GLOBAL_SYS.LDT — 游戏平衡参数表

## 加载链路

```
MgmtServer::OnStartup()
  → LoadGlobalSysLDT("DATA/LDT/GLOBAL_SYS.LDT")
  → LDT 解析 → SET_GLOBAL_VALUE(id, value)
  → g_GlobalLogicValue[id] = value

GameServer::OnStartup()
  → LoadGlobalSysLDT(...)  // 同上
GameServer 运行时:
  → Thread_DynamicLoading → ProcReLoadCashShop(RES_FNAME_LDT_GLOBAL_SYS)
  → Thread_DynamicLoading → ProcReLoadHotCashShop(RES_FNAME_LDT_GLOBAL_SYS)
  → PCMain_DynamicThread → ReLoadCashShopVersion(...)
```

## 加载逻辑 (GlobalSys.cpp)

```cpp
bool LoadGlobalSysLDT(TCHAR* pszDescriptor) {
    pLDTManager->LoadLDTFileFromFile(pszDescriptor, &pLDTFile);
    if(pLDTFile == NULL) return false;  // 返回 false 但调用方 non-fatal

    for(record in LDT) {
        iKeyID = pLDTFile->GetPrimaryKey(record);      // 主键 = 参数 ID
        pLDTFile->GetFieldFromLable(iKeyID, "_Check", ldtField);
        SET_GLOBAL_VALUE(iKeyID, ldtField[0].uData.lValue);  // 存整数值
    }
    return true;
}
```

## LOGIC_VALUE 枚举 (完整)

```cpp
enum LOGIC_VALUE {
    LOGIC_VALUE_NULL,
    LOGIC_VALUE_DEATH_PENALTY_NO_ITEM = 1,    // 死亡不掉装备等级阈值
    LOGIC_VALUE_DEATH_PENALTY_EXP = 2,        // 死亡掉经验系数
    LOGIC_VALUE_DEATH_PENALTY_ELY = 3,        // 死亡掉金币
    LOGIC_VALUE_DEATH_PENALTY_FAME = 4,       // 死亡掉声望
    LOGIC_VALUE_CHAT_WORLD_ITEM = 5,          // 世界频道消耗道具ID
    LOGIC_VALUE_CHAT_CHANNEL_ITEM = 6,        // 频道聊天消耗道具ID
    LOGIC_VALUE_MAIL_STAMP_ITEM = 11,         // 邮件邮票道具
    LOGIC_VALUE_MAIL_SEND_FEE = 12,            // 发邮件手续费
    LOGIC_VALUE_MAIL_MAX_LIST = 17,            // 邮件列表最大数
    LOGIC_VALUE_CASHSHOP_MAJOR = 21,          // 商城主版本号
    LOGIC_VALUE_CASHSHOP_MINOR = 22,          // 商城次版本号
    LOGIC_VALUE_CASHSHOP_HOT = 23,            // 热卖版本号
    LOGIC_VALUE_LOTTERY_RANK1-9 = 31-39,      // 淘淘乐各等级概率/阈值
    LOGIC_VALUE_LOTTERY_ITEM = 41,            // 抽奖道具
    LOGIC_VALUE_LOTTERY_ELY = 42,             // 抽奖金币消耗
    LOGIC_VALUE_LOTTERY_COUNT = 43,           // 抽奖次数
    LOGIC_VALUE_LOTTERY_RESTART = 44,         // 重置时间
    LOGIC_VALUE_LOTTERY_FREQ = 45,            // 频率
    LOGIC_VALUE_MAX_HITCOUNT = 51,            // 最大连击
    LOGIC_VALUE_PVP_ESCAPE = 61,              // PVP 逃跑
    LOGIC_VALUE_PVP_REVIVAL = 62,             // PVP 复活
    LOGIC_VALUE_CHATROOM_ADVERT_ITEM = 70,    // 聊天室广告道具
    LOGIC_VALUE_CHATROOM_MAXNUM_INROOM = 71,  // 聊天室最大人数
    LOGIC_VALUE_CHATROOM_MAXNUM_INTYPESEARCH = 72,
    LOGIC_VALUE_CHATROOM_ADVERT_MAXTIME = 73,
    LOGIC_VALUE_AUCTION_STARTPRICE_FACTOR = 91,   // 拍卖起拍价系数
    LOGIC_VALUE_AUCTION_GAMEPRICE_FACTOR = 92,    // 拍卖成交价系数
    LOGIC_VALUE_AUCTION_STANDARD_FACTOR = 93,     // 拍卖标准价系数
    LOGIC_VALUE_CH_BEGIN = 500,
    LOGIC_VALUE_GAME_PRICER = 594,
    LOGIC_VALUE_GAMBLE_PERSONAL_POINT = 595,
    LOGIC_VALUE_GAMBLE_SERVER_POINT = 596,
    LOGIC_VALUE_MAX,
};
```

## 加载失败的后果

所有参数默认 0:
- ✅ 服务正常启动
- ❌ 商城版本号=0 → 商城可能无商品或异常
- ❌ 死亡不掉装备 → 死亡无惩罚
- ❌ 邮件/聊天免费
- ❌ 淘淘乐概率异常
- ❌ 拍卖价格异常

## 原始 SPF 中是否存在？

实测原始 SPF 也报 `GLOBAL_SYS.LDT : FAILED ! (Not Exist)` 但随后 `GlobalSys::Init() : [OK]` 恢复。说明：
- GLOBAL_SYS.LDT **可能不在原始 SPF 中**
- 服务端以默认值运行（参数全 0）
- 基础功能可用，高级功能（商城/抽奖）可能受影响

## 关键误解纠正

| 误解 | 事实 |
|---|---|
| "AS 控制台报 GLOBAL_SYS 失败" | AS 不加载它。输出来自 MgmtServer 或 GameServer |
| "这个错误是红鲱鱼可以忽略" | 启动不会被阻塞，但游戏平衡参数全部归零 |
| "需要重编译樱花网关" | 网关是 OSP 代理，不碰 LDT。要排查需编译 MgmtServer/GameServer |
| "GLOBAL_SYS 和 Press any Key 有关" | 完全无关。卡住是因为 Division/Guild 失败触发 getchar() |
