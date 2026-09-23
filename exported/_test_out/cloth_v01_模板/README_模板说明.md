# musha_cloth_v01 模板说明（整理自 musha_cloth_v01_SCML_ready.zip）

来源：D:\Backup\Downloads\musha_cloth_v01_SCML_ready.zip
（158 个条目 = build.xml + animation.xml + 156 张符号 PNG，build 名写的是 musha.scml）

## 一、做了什么
用 `exported/_tools/buildxml_to_scml.py` 把 Mod Tool 的 build 源转成 musha 那套 Spriter 工程：

    cd exported/_tools
    python buildxml_to_scml.py <解包目录> <输出目录>/musha_cloth_v01

产物：`musha_cloth_v01/musha_cloth_v01.scml` + 19 个符号子文件夹 + 156 张 PNG（2.3 MB）
→ 19 符号 / 98 时间轴 / 39 帧

## 二、和现役 musha.scml 对不对得上（校验过）
拿 `exported/musha/musha.scml` 逐文件比（尺寸 + pivot）：

    156 vs 156，文件名一一对应，没有多也没有少
    135 个"完全一致"
     21 个不一致，但全是同一回事：现役把透明边裁掉了
        例：torso_pelvis-0  现役 80x68 pivot(0.500,0.409) / 模板 80x90 pivot(0.500,0.309)
            —— pivot 距底边都是 27.8px，只差顶部 22px 透明边
        例：hand-4          现役 57x57 / 模板 75x75，pivot 距右下角都是 29.2px

结论：**这套源就是真 musha build 源**（或等价物），21 处差异只是"有没有裁透明边"，
不影响对位。可以放心当模板用。

## 三、19 个部件规格表（朝向数 / 画布 / pivot）

部件             朝向  画布               pivot_x   pivot_y
arm_lower         7   宽50~80 高50~80    0.516     0.8330
arm_upper         7   宽60~80 高80       0.5125    0.7325
arm_upper_skin    3   宽40    高40~80    0.5362    0.7413
cheeks            2   64x60              0.5086    0.4996
face             33   宽50~150 高75~150  0.5570    0.6410
foot              8   50x50              0.8000    0.8000
hair              4   宽75    高75~100   0.6967   -0.6330  ← pivot 在画布外，正常（DST 发片这样）
hair_hat          4   400x400            0.5056    0.3813  ← 空占位，见第四节
hairfront         2   400x400            0.5056    0.3813  ← 空占位
hairpigtails      5   宽93~156 高187~225 0.6826    0.6607
hand             20   宽50~75 高50~100   0.4855    0.7425
headbase          5   宽206~225 高187~263 0.5300   0.1643
headbase_hat      5   宽206~225 高187~263 0.5300   0.1643
leg              11   宽60    高60~80    0.5621    0.7513
skirt             5   160x120            0.5022    0.5619  ← 空占位
swap_icon         1   201x244            0.5025    0.5000  ← zip 里没这张图
tail             12   250x100            0.6280    0.5000  ← 空占位
torso            11   宽80~160 高120     0.5000    0.2319
torso_pelvis     11   宽80~120 高90      0.5000    0.3092

（pivot 换算口径：pivot_x = 0.5 - x/w，pivot_y = 0.5 + y/h，x/y 取 build.xml 的 Frame 值。
 headbase-0 用这个换算出来 = (0.529998, 0.164336)，和现役 musha.scml 一模一样 ✓）

## 四、缺图清单（画图时要补的）
这 5 个是空的，zip 里给的是 100x100 全透明占位 / 没有：

    skirt-0..4        声明 160x120   实际 100x100 全透明
    tail-0..11        声明 250x100   实际 100x100 全透明
    hairfront-0..1    声明 400x400   实际 100x100 全透明
    hair_hat-0..3     声明 400x400   实际 100x100 全透明
    swap_icon         声明 201x244   完全没有

转身后处理：这 5 个部件共 23 张，工具已经按声明尺寸生成了同尺寸的空图占位，
画好真图直接盖同名文件即可。

## 五、皮肤能换的件（做"天使皮肤"只动这些）
    headbase / headbase_hat        头（含脸）—— 见 headbase 尺寸基准
    hair / hairfront / hair_hat    头发（含帽子版）
    hairpigtails                   双马尾
    face（33 张表情）              换表情才动，换皮肤一般不动
    torso / torso_pelvis / skirt   上衣 / 下摆 / 裙子
    arm_upper / arm_lower / hand   手臂手（换肤色才动）
    leg / foot                     腿脚（换肤色才动）
    cheeks / tail / swap_icon      腮红 / 尾巴 / 人物选择图标

## 六、headbase 尺寸基准（2026-09-19 实测）
老版（现役、好用）`exported/musha/headbase/headbase-0.png`：

    画布        225 x 225
    实心内容    210 x 199   bbox x[13..222] y[16..214]
    脸(皮肤块)  105 x 85    bbox x[66..170] y[108..192]
                脸中心 x = 118.5    下巴底 y = 192
    pivot       (0.53000, 0.16434) → 像素 (119.25, 从顶算 188.02)
    即：pivot 在下巴底往上 4px，横向在脸中心

其余 4 个朝向：-1 206x187 pivot(0.61432, 0.08864)
                -2 206x187 pivot(0.48665, 0.09613)
                -3 225x263 pivot(0.53000, 0.14059)
                -4 同 -0

## 七、给 ChatGPT 的出图需求单（可直接粘）
    我要一张饥荒(DST)角色头部贴图，透明背景 PNG。
    画布 225 x 225。里面画：一个正面朝前的头，只画头（下巴以下不要身体）。
    脸（肤色区域）宽 105px、高 85px，脸的水平中心在 x=118，
    下巴最底边落在 y=192（从图片顶部往下数）。
    头顶发际线从 y=16 附近开始。脖子不要。整张图除了头都是透明。
