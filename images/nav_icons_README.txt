Musha 导航图标 —— 打包说明（2026-09-13 更新）
================================================

七张图都画好了（底板统一：蜡黄圆角方块 + 深棕描边）：

  images/nav_home.png    主页    —— 你给的原图（房子）
  images/nav_skill.png   技能    —— 你给的枝干线稿（抠白底 + 缩 80% + 加粗 + 染深棕）
  images/nav_equip.png   装备    —— 胸甲（扁护肩 + 领口 + 中缝 + 铆钉）
  images/nav_mail.png    信箱    —— 信封 + 火漆印
  images/nav_set.png     设置    —— 原齿轮保留，底板薄荷绿换蜡黄
  images/nav_gift.png    礼包    —— 圣诞礼物盒
  images/nav_dex.png     图鉴    —— 放大镜（新画）

看效果（双击就能开）：
  images/_nav_all7.png     七张总览（2 倍放大）
  images/_nav_real28.png   导航里实际大小（28x28）长这样

现在只差打包这一步
--------------------------------------
已经打包好的：nav_home / nav_mail / nav_set（你上次那批转的，我把 nav_setting 那对改名成 nav_set 了）
还差的：      nav_skill / nav_equip / nav_gift / nav_dex

做法：拿你的贴图工具把 images 里 nav_ 开头的 png 转成同名 .tex + .xml（整批转一遍最省事）。
  ⚠️ png 名必须是 ASCII：中文名（主页.png 之类）转出来的 xml 是空的（15 字节），没用，别管它。
  ⚠️ 转完必须重启游戏 —— assets 只在开游戏时加载一次。

打包好就自动生效，不用改代码
--------------------------------------
代码已经不靠开关了：清单在 scripts/musha_nav_icons.lua（唯一真源），
modmain 按它注册 assets，面板按它画图标。
哪张 tex 没打包，哪一行的图标就自动跳过（只显示文字，不会报错），日志里会打一行
  [Musha] 导航图标没加载上（tex 打包了吗？）: xxx

进游戏后：开面板 → 点右上角 ">" 展开导航 → 七行左边各有一个 28x28 小图标。
位置不对（压字 / 跑出横条 / 偏上偏下）告诉我偏多少像素，当前参数：图标 28x28 放在 x=-41、文字右移 8。
