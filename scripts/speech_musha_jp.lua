--==============================================================================
-- speech_musha_jp.lua  -  ムシャ 日本語セリフ v1 (2026-09-13)
-- 日本語台詞 v1 / 角色台词日语版 v1
--------------------------------------------------------------------------------
-- 【本批已完成 / 本次已翻译】
--   * ANNOUNCE_*                （アナウンス系セリフ + サブテーブル）
--   * PLAYER                    （DESCRIBE.PLAYER プレイヤー呼びかけ）
--   * MUSHA_* / SHADOWMUSHA     （ムシャ専用アイテム・ヤムチェ関連）
--   * QUAGMIRE_ANNOUNCE_*       （アナウンス系のためあわせて翻訳）
-- 【待第二批 / 未翻译，保留英文原值】
--   * DESCRIBE 内のその他のキー（バニラアイテム・モブ説明など）
--   * ACTIONFAIL / BATTLECRY / COMBAT_QUIT / EAT_FOOD / DESCRIBE_TOODARK など
--------------------------------------------------------------------------------
-- 構成・キー名・インデントは speech_musha_en.lua と完全一致。
-- 結構、鍵名、縮排與 en 母本 100% 一致；未翻訳分は英語のまま。
-- 自称は「ムシャ」。明るい子ども口調（〜だよ！／〜なの！／えっ？／うわっ）。
--==============================================================================
--Created: Luka  --correction: Alucard Elric
return {
    --adds action start
    ACTIONFAIL = {
        REPAIR = {
            WRONGPIECE = "え〜、なんかちがうみたいなの。"
        },
        BUILD = {
            MOUNTED = "こんな高いところからは置けないよ〜！",
            HASPET = "ムシャ、もうペットがいるもん！"
        },
        SHAVE = {
            AWAKEBEEFALO = "起きてるビーファローを刈っちゃだめなの！あぶないもん！",
            GENERIC = "それ、刈れないの！",
            NOBITS = "う〜ん、もう毛が残ってないみたいなの。"
        },
        STORE = {
            GENERIC = "いっぱいいっぱいだよ！",
            NOTALLOWED = "それはそこに入らないの！",
            INUSE = "ムシャの順番、まだかな〜？"
        },
        RUMMAGE = {
            GENERIC = "ムシャにはできないの。",
            INUSE = "なにか探してるみたいなの。"
        },
        USEKLAUSSACKKEY = {
            WRONGKEY = "あれっ？ちがうみたい！",
            KLAUS = "ムシャ、いま忙しいの！！",
            QUAGMIRE_WRONGKEY = "べつの鍵をさがさないとね。"
        },
        ACTIVATE = {
            LOCKED_GATE = "門に鍵がかかってるの。"
        },
        COOK = {
            GENERIC = "いまはごはんを作れないの。",
            INUSE = "あれ？ムシャと同じこと考えたんだね！",
            TOOFAR = "遠すぎてムシャの手がとどかないの！"
        },
        GIVE = {
            GENERIC = "それはそこには置けないの。",
            DEAD = "じゃあムシャがもらっておくね。",
            SLEEPING = "ぐっすり眠ってるの。",
            BUSY = "ちょっと待ってね、すぐもう一度やってみるの。",
            ABIGAILHEART = "だめでも、ためしてみたかったの。",
            GHOSTHEART = "ムシャ、それはやめたほうがいいと思うの。",
            NOTGEM = "そんなの入れちゃだめなの！",
            WRONGGEM = "この宝石はここじゃだめみたいなの。",
            NOTSTAFF = "かたちがちがうみたいなの。",
            MUSHROOMFARM_needSHROOM = "キノコのほうがいいと思うの！",
            MUSHROOMFARM_needLOG = "いきてる木のほうがいいと思うの！",
            SLOTFULL = "ムシャ、もうここに入れちゃったの。",
            FOODFULL = "もうごはんが入ってるの。",
            NOTDISH = "それ、食べたくないみたいなの。",
            DUPLICATE = "それはもう知ってるの！",
            NOTSCULPTABLE = "科学でもそれは彫刻にできないの。",
            NOTATRIUMKEY = "かたちがちがうみたいなの。",
            CANTSHADOWREVIVE = "生きかえらないの。",
            WRONGSHADOWFORM = "組み立てかたがちがうの。"
        },
        GIVETOPLAYER = {
            FULL = "あっ！ポケットがもうパンパンなの！",
            DEAD = "じゃあムシャが預かっておくね。",
            SLEEPING = "ぐったりしてて、もうどうでもいいみたいなの。",
            BUSY = "すぐにもう一回やるの。"
        },
        GIVEALLTOPLAYER = {
            FULL = "ポケットがパンパンで入らないの！",
            DEAD = "じゃあムシャが持ってるの。",
            SLEEPING = "ぐっすり眠ってるの。",
            BUSY = "ちょっと待ってね、すぐやってみるの。"
        },
        WRITE = {
            GENERIC = "ムシャはへいきだと思うの。",
            INUSE = "らくがきできるのは一人だけなの。"
        },
        DRAW = {
            NOIMAGE = "目の前にそれがあると、もっと簡単なのにな〜。"
        },
        CHANGEIN = {
            GENERIC = "いまは着がえたくないの。",
            BURNING = "いまはあぶなすぎるの！",
            INUSE = "いちどに一つしか変えられないの。"
        },
        ATTUNE = {
            NOHEALTH = "ムシャ、ちょっと具合がよくないの。"
        },
        MOUNT = {
            TARGETINCOMBAT = "怒ってるビーファローにさわるのはやめたほうがいいの！",
            INUSE = "サドルは、ほかの人に先に取られちゃったの！"
        },
        SADDLE = {
            TARGETINCOMBAT = "怒ってるときは、させてくれないの。"
        },
        TEACH = {
            --Recipes/Teacher
            KNOWN = "それはもう知ってるの！",
            CANTLEARN = "それは覚えられないの。",
            --MapRecorder/MapExplorer
            WRONGWORLD = "この地図はべつの場所のものみたいなの。"
        },
        WRAPBUNDLE = {
            EMPTY = "包むものをなにか持ってこないとね。"
        },
        PICKUP = {
            RESTRICTION = "ムシャ、まだうまく使えないの。",
            INUSE = "科学がいうには、ムシャの順番を待たないとだめなの。"
        },
        SLAUGHTER = {
            TOOFAR = "にげられちゃったの。"
        },
        REPLATE = {
            MISMATCH = "ここにはちがう料理を入れるみたいなの。",
            SAMEDISH = "お皿は一つだけでよかったの。"
        }
    },
    ACTIONFAIL_GENERIC = "ムシャにはできないの。",
    ANNOUNCE_DIG_DISEASE_WARNING = "もう元気になったみたいだよ！",
    ANNOUNCE_PICK_DISEASE_WARNING = "うーん、ムシャこのにおい苦手なの！",
    --adds action end

    ANNOUNCE_HATEFOOD = "うえっ！",
    ANNOUNCE_ADVENTUREFAIL = "ムシャ、腕がもう動かないよ〜！",
    ANNOUNCE_BOOMERANG = "木がムシャに当たった！わるい木は遠くにポイしちゃうよ！",
    ANNOUNCE_CHARLIE = "ムシャの後ろに何かいるの！",
    ANNOUNCE_CHARLIE_ATTACK = "ムシャの頭をかまないでよ！やっつけちゃうからね！",
    ANNOUNCE_COLD = "さむいさむい！ムシャの耳がとれちゃうよ！",
    ANNOUNCE_HOT = "ムシャの足の裏が焼けちゃうよ！",
    ANNOUNCE_DUSK = "太陽がいなくなっちゃった！\nムシャ、明かりを用意しないと！",
    ANNOUNCE_EAT = {
        GENERIC = "すっごくおいしいの！",
        PAINFUL = "うえっ！",
        SPOILED = "これ食べものじゃないよ！べー！",
        STALE = "べー！",
        YUCKY = "べー！"
    },
    ANNOUNCE_NOSLEEPONFIRE = "こんなとこで寝られないよ！\n背中が冷たくなっちゃうの！",
    ANNOUNCE_NODANGERSIESTA = "ムシャ、何か聞こえたの。見に行かないと！",
    ANNOUNCE_NONIGHTSIESTA = "ここは寒すぎて休めないよ！",
    ANNOUNCE_NONIGHTSIESTA_CAVE = "ここは本当に寒いの！",
    ANNOUNCE_NOHUNGERSIESTA = "ムシャおなかすいたの！ごはんがほしいよ！",
    ANNOUNCE_SHELTER = "ここはムシャにちょうどいいの！",
    ANNOUNCE_BURNT = "こげちゃったね。",
    ANNOUNCE_TOOL_SLIP = "えっ？うわっ、すべるよ！",
    ANNOUNCE_DAMP = "ムシャ、ちょっとしめってるの。",
    ANNOUNCE_WET = "ムシャの服、乾かすの大変そうだよ。",
    ANNOUNCE_WETTER = "ムシャ、びしょぬれなの。",
    ANNOUNCE_SOAKED = "ムシャ、下着を着替えたいよ…",
    ANNOUNCE_HOUNDS = "今の聞こえた？犬さんたちが来るよ！",
    --ANNOUNCE_HUNGRY = "Musha need meat. Anyone?",
    ANNOUNCE_HUNGRY = "おなかすいたよ…",
    ANNOUNCE_HUNT_BEAST_NEARBY = "ムシャ見えたよ！すっごく大きいの！",
    ANNOUNCE_HUNT_LOST_TRAIL = "足あとを見失っちゃった。何だったのかな？",
    ANNOUNCE_HUNT_LOST_TRAIL_SPRING = "泥が足あとを隠しちゃったの！ムシャ、泥はきらいだよ。",
    ANNOUNCE_ACCOMPLISHMENT = "こんなの楽勝だよ！",
	ANNOUNCE_ARROW_BATTLE = "戦うよ！",
    ANNOUNCE_ACCOMPLISHMENT_DONE = "ムシャ、やったよ！",
    ANNOUNCE_LIGHTFIRE = {
        [1] = "明かりだよ！",
        [2] = "火だよ！",
        [3] = "火はいいものなの！",
        [4] = "ふりふり、赤い明かり！",
        [5] = "料理には使えないけど、あったかいの！",
        [6] = "やったね！"
    },
    ANNOUNCE_PECKED = "わるい鳥さん！",
    ANNOUNCE_TORCH_OUT = "次の明かりはどこかな？",
    ANNOUNCE_WORMHOLE = "ムシャ、こういう移動はあんまり好きじゃないの…",
    ANNOUNCE_TRAP_WENT_OFF = "うわあっ！",
    ANNOUNCE_CRAFTING_FAIL = "ええ？うまくいかないよ〜。",
    ANNOUNCE_QUAKE = "おなかが痛いみたいな音だよ！洞窟くん、痛いのかな？",
    ANNOUNCE_NODANGERSLEEP = "ムシャ、何か聞こえたの。\n見に行かないと！",
    ANNOUNCE_NOHUNGERSLEEP = "ムシャおなかすいたの！\nこんなんじゃ眠れないよ！",
    ANNOUNCE_FREEDOM = "ムシャは自由だよ！誰にも縛れないの！",
    ANNOUNCE_RESEARCH = "それ知ってるよ！ムシャ、使えるの！",
    ANNOUNCE_NO_TRAP = "ムシャには簡単すぎるよ！",
    ANNOUNCE_HIGHRESEARCH = "やったあ！ムシャ、できちゃったよ！",
    ANNOUNCE_THORNS = "いたっ！失礼な植物さんだね！",
    ANNOUNCE_NODAYSLEEP_CAVE = "ムシャ、遊びたいの！\n眠くないよ。",
    ANNOUNCE_BEES = "ハチさんがムシャの耳の周りでブンブンしてるの！",
    ANNOUNCE_KNOCKEDOUT = "あれ…星がくるくる回ってるよ…",
    ANNOUNCE_LOWRESEARCH = "ムシャ、作りすぎちゃったの。",
    ANNOUNCE_DEERCLOPS = "一番強い一つ目はオーディンだけだよ！きみじゃないの！",
    ANNOUNCE_MOSQUITOS = "ムシャもかみつき返すよ、虫さん！",
    ANNOUNCE_NODAYSLEEP = "お昼寝？ムシャは走り回りたいの！",
    ANNOUNCE_INSUFFICIENTFERTILIZER = "これ、植物さんにはよくないみたい…",
    ANNOUNCE_CANFIX = "\nムシャ、直せるよ！",
    ANNOUNCE_LIGHTNING_DAMAGE_AVOIDED = "ムシャは光よりも速いの！",
    BATTLECRY = {
        GENERIC = "ムシャのほうが強いもん！",
        PIG = "このブタさん、わるいブタさんなの！",
        PREY = "ムシャのこと、きらいなの？\nじゃあムシャもきらいでいいもん！",
        SPIDER = "ムシャの経験値になりなさいなの！",
        SPIDER_WARRIOR = "かかってきなさいなの！"
    },
    COMBAT_QUIT = {
        GENERIC = "だから言ったとおりなの！",
        PIG = "つよいブタさんだったの。\nつぎはムシャのベーコンにしてやるの！",
        PREY = "つぎはまけないの！",
        SPIDER = "ムシャのうでがもっと長かったら、\nこんな虫ぜんぶたたきつぶせるのにな。",
        SPIDER_WARRIOR = "とぶクモ！あれ、いちばんきらいなの！"
    },
    --adds 4 start
    --ANNOUNCE_TOOL_SLIP = "Whoa! It's slippery!",
    --ANNOUNCE_LIGHTNING_DAMAGE_AVOIDED = "Musha is safe from that scary lightning!",
    ANNOUNCE_TOADESCAPING = "ヒキガエルさん、飽きちゃったみたい。",
    ANNOUNCE_TOADESCAPED = "ヒキガエルさん、逃げられちゃった。",
    ANNOUNCE_BECOMEGHOST = "お〜お〜お〜！！",
    ANNOUNCE_GHOSTDRAIN = "ムシャ、人間じゃなくなっちゃいそう…",
    ANNOUNCE_PETRIFED_TREES = "今、木さんたちの悲鳴が聞こえたの？",
    ANNOUNCE_KLAUS_ENRAGE = "もう勝てっこないよ！！",
    ANNOUNCE_KLAUS_UNCHAINED = "鎖が外れちゃったの！",
    ANNOUNCE_KLAUS_CALLFORHELP = "助けを呼んでるよ！",
    --lavaarena event
    ANNOUNCE_REVIVING_CORPSE = "ムシャが助けてあげるよ！",
    ANNOUNCE_REVIVED_OTHER_CORPSE = "もうぴんぴんしてるよ！",
    ANNOUNCE_REVIVED_FROM_CORPSE = "すっかり元気になったよ。ありがとう！",
    --quagmire event
    QUAGMIRE_ANNOUNCE_NOTRECIPE = "その材料じゃ何もできなかったよ。",
    QUAGMIRE_ANNOUNCE_MEALBURNT = "ムシャ、火にかけすぎちゃったの。",
    QUAGMIRE_ANNOUNCE_LOSE = "なんだか嫌な予感がするよ。",
    QUAGMIRE_ANNOUNCE_WIN = "行く時間だよ！",
    ANNOUNCE_ROYALTY = {
        "陛下！",
        "殿下！",
        "ムシャの主さま！"
    },
    --adds 4 end

    DESCRIBE = {
        --adds 5 start (DESCRIBE)
        --MULTIPLAYER_PORTAL = "This ought to be a scientific impossibility.",
        ANTLION = {
            GENERIC = "ムシャから何かほしがってるみたいなの。",
            VERYHAPPY = "なかよしさんになれたみたいなの！",
            UNHAPPY = "こわい顔してるの！ムシャ、こわいの！"
        },
        ANTLIONTRINKET = "だれかさん、これに興味あるかもなの。",
        SANDSPIKE = "あやうく串刺しにされるところだったの！",
        SANDBLOCK = "じゃりじゃりしてるの！",
        GLASSSPIKE = "串刺しになりかけた思い出…ムシャ、わすれないの！",
        GLASSBLOCK = "これが科学ってやつなの。",
        ABIGAIL_FLOWER = {
            GENERIC = "ぞくっとするくらいきれいなの。",
            LONG = "それを見ると、ムシャの魂がいたいの。",
            MEDIUM = "見てるとぞわぞわしてくるの。",
            SOON = "あの花、なんだかへんなの！",
            HAUNTED_POCKET = "これは持っておかないほうがいいと思うの。",
            HAUNTED_GROUND = "なにがおきるのか、知りたくてたまらないの！"
        },
        BALLOONS_EMPTY = "ピエロのおかねみたいなの。",
        BALLOON = "どうやって浮いてるの？",
        BERNIE_INACTIVE = {
            BROKEN = "とうとうこわれちゃったの。",
            GENERIC = "まっ黒こげなの。"
        },
        BERNIE_ACTIVE = "あのテディベア、うごいてるの。おもしろいの！",
        PLAYER = {
            GENERIC = "わあ！やっほー、%s！",
            ATTACKER = "%s、なんだか怪しいよ…",
            MURDERER = "人殺しなの！",
            REVIVER = "%s、おばけの友だちなの。",
            GHOST = "%sはハートが必要なんだね。",
            FIRESTARTER = "%s、火をつけるのは科学的じゃないよ。"
        },
        WILSON = {
            GENERIC = "うわっ！%s、もしかしてムシャのコピーなの？",
            ATTACKER = "うえ〜、ムシャっていつもそんなこわい顔なの？",
            MURDERER = "%s、あなたの存在は科学に反してるの！",
            REVIVER = "%sは理論をちゃんと実践してるの、すごいの！",
            GHOST = "復活の装置を作らないとね。だれかをふわふわのままにはできないの。",
            FIRESTARTER = "それ、燃やしちゃうのは科学的じゃないの、%s。"
        },
        WOLFGANG = {
            GENERIC = "%s、こんにちはなの！",
            ATTACKER = "力もちさんとけんかしちゃだめなの…",
            MURDERER = "ひとごろし！ムシャがやっつけてあげるの！",
            REVIVER = "%sは大きなテディベアさんなの。",
            GHOST = "だから言ったの、その岩は持てないって、%s。計算がまちがってるの！",
            FIRESTARTER = '%s、火と「戦う」なんてできないの！'
        },
        WAXWELL = {
            GENERIC = "%s、いい日に会えてうれしいの！",
            ATTACKER = 'あなた、「ダンディ」から「パンチ」になっちゃったの。',
            MURDERER = "ムシャが理論と理性ってやつを見せてあげるの…これがムシャの拳なの！",
            REVIVER = "%sは力をいいほうに使ってるの。",
            GHOST = "%s、そんな目で見ちゃいやなの！ムシャ、がんばってるの！",
            FIRESTARTER = "%sは焼かれたいみたいなの。"
        },
        WX78 = {
            GENERIC = "%s、いい日に会えてうれしいの！",
            ATTACKER = "ムシャが%sのプログラムを直さないといけないみたいなの…",
            MURDERER = "%s！第一法則を破ったの！",
            REVIVER = "%s、その共感のモジュール、ちゃんと動いたみたいなの！",
            GHOST = "ムシャ、%sには心がいると思ってたの。やっぱりね！",
            FIRESTARTER = "%s、とけちゃいそうな顔してるの。どうしたの？"
        },
        WILLOW = {
            GENERIC = "%s、こんにちはなの！",
            ATTACKER = "%s、ライター握りしめてるの…こわいの。",
            MURDERER = "ひとごろし！放火だめなの！",
            REVIVER = "%sはゴーストのおともだちなの。",
            GHOST = "%s、心がほしくて燃えてるんでしょ。ムシャにはわかるの。",
            FIRESTARTER = "またなの？"
        },
        WENDY = {
            GENERIC = "%s、やっほーなの！",
            ATTACKER = "%s、あぶないもの持ってないよね…？",
            MURDERER = "ひとごろし！",
            REVIVER = "%sはゴーストを家族みたいに大切にしてるの。",
            GHOST = "ムシャ、二重に見えるの！%sに心を作ってあげないとね。",
            FIRESTARTER = "%sが火をつけたの、ムシャは知ってるの。"
        },
        WOODIE = {
            GENERIC = "%s、やっほーなの！",
            ATTACKER = "%s、最近ちょっととろとろしてるの…",
            MURDERER = "ひとごろし！斧を持ってきてくれたら、ちゃんとやるの！",
            REVIVER = "%sがみんなを助けたの！",
            GHOST = '%s、「全対応」に虚無も入ってるの？',
            BEAVER = "%s、木をかじりまくってるの！",
            BEAVERGHOST = "%s、復活させなかったら、ビーバーみたいに怒るの？",
            FIRESTARTER = "%s、燃えつきちゃだめなの。"
        },
        WICKERBOTTOM = {
            GENERIC = "%s、こんにちはなの！",
            ATTACKER = "%s、なにかムシャに本を投げつけようとしてるの…？",
            MURDERER = "査読の時間なの！",
            REVIVER = "%sの実用的な定理、ムシャは尊敬してるの。",
            GHOST = "%s、これってあんまり科学的じゃないの…？",
            FIRESTARTER = "%s、その火にはきっとりっぱな理由があるの。たぶん。"
        },
        WES = {
            GENERIC = "%s、やっほーなの！",
            ATTACKER = "%sは無口だけど、あぶないの…",
            MURDERER = "ムシャにその手は通じないの！",
            REVIVER = "%sは見えない箱のそとを考えられるの、えらいの。",
            GHOST = '「復活装置を作ります」って、パントマイムでどう言うの、%s？',
            FIRESTARTER = "あ、言わなくていいの。火をつけたのね。"
        },
        WEBBER = {
            GENERIC = "%s、こんにちはなの！",
            ATTACKER = "ムシャ、新聞をつくるくる丸めておくの。念のためなの。",
            MURDERER = "ひとごろし！%s、ムシャがぺしゃんこにしてあげるの！",
            REVIVER = "%s、みんなと仲良くできてるの！",
            GHOST = "%s、ムシャに心をねだってるの。うるさいの！",
            FIRESTARTER = "火の用心について、みんなで話し合わないとね。"
        },
        WATHGRITHR = {
            GENERIC = "%s、いい日だね！",
            ATTACKER = "%sに殴られるのはいやなの。できれば。",
            MURDERER = "%sが暴れてるの！",
            REVIVER = "%sは精霊をちゃんと使いこなしてるの。",
            GHOST = "残念だったね。%sはまだヴァルハラに行けないの。",
            FIRESTARTER = "%s、今日はやけに熱いの。"
        },
        WINONA = {
            GENERIC = "%s、こんにちはなの！",
            ATTACKER = "%sはあぶないの。",
            MURDERER = "%s、ここで終わりなの！",
            REVIVER = "%s、いてくれると助かるの！",
            GHOST = "計画がめちゃくちゃになっちゃったみたいなの。",
            FIRESTARTER = "工場が燃えてるの。"
        },
        MIGRATION_PORTAL = {
            GENERIC = "ムシャに友だちがいたら、ここから会いに行けるのにな。",
            OPEN = "ここを通ったら、ムシャはまだムシャなのかな？",
            FULL = "あっちでは人気みたいなの。"
        },
        --adds 5 end (DESCRIBE)

        MUSHA_EGG = "ちっちゃな花のつぼみだよ。",
        MUSHA_EGGS1 = "ヤムチェが冒険のじゅんびをしてるの！",
        MUSHA_EGGS2 = "ヤムチェのつぼみがどんどん大きくなってるよ！",
        MUSHA_EGGS3 = "もうこんなに大きくなったの！",
        MUSHA_EGG1 = "ヤムチェはもう戦えるくらい強くなったよ！",
        MUSHA_EGG2 = "もうこんなに大きいの！",
        MUSHA_EGG3 = "わあ、ヤムチェはぐっすり眠れたみたい！",
        MUSHA_EGG8 = "誰にもムシャたちを止められないよ！",
        MUSHA_EGG_CRACKED = "ちっちゃな花のつぼみだよ。",
        MUSHA_EGG_CRACKEDS1 = "ムシャ、ヤムチェを待ってるの！",
        MUSHA_EGG_CRACKEDS2 = "すっごく大きいつぼみでしょ？",
        MUSHA_EGG_CRACKEDS3 = "もうこんなに大きくなったの！",
        MUSHA_EGG_CRACKED1 = "はやくはやく！",
        MUSHA_EGG_CRACKED2 = "とっても大きいつぼみだよ。",
        MUSHA_EGG_CRACKED3 = "わあ、ヤムチェが目を覚まし始めたよ！",
        MUSHA_EGG_CRACKED8 = "ムシャ、ヤムチェを待ってるの！",
        MUSHA_SMALL = "わあ、かわいい！\n命令キー：（Z,V,B）",
        MUSHA_TEEN = "ヤムチェはちっちゃいけど勇敢な鳥なの！\n命令キー：（Z,V,B）",
        MUSHA_TEENR1 = "ヤムチェはちっちゃいけど勇敢な鳥なの！\n命令キー：（Z,V,B）",
        MUSHA_TEENR2 = "ヤムチェはちっちゃいけど勇敢な鳥なの！\n命令キー：（Z,V,B）",
        MUSHA_TEENR3 = "ヤムチェはちっちゃいけど勇敢な鳥なの！\n命令キー：（Z,V,B）",
        MUSHA_TEENR4 = "ヤムチェはちっちゃいけど勇敢な鳥なの！\n命令キー：（Z,V,B）",
        MUSHA_TEENICE = "ヤムチェはちっちゃいけど勇敢な鳥なの！\n命令キー：（Z,V,B）",
        MUSHA_TALL = "ヤムチェはクモをやっつけられる力を持ってるよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLR1 = "ヤムチェはクモをやっつけられる力を持ってるよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLR2 = "ヤムチェはクモをやっつけられる力を持ってるよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLR3 = "ヤムチェはクモをやっつけられる力を持ってるよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLR4 = "ヤムチェはクモをやっつけられる力を持ってるよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRICE = "ヤムチェはクモをやっつけられる力を持ってるよ！\n命令キー：（Z,V,B）",
        MUSHA_TALL2 = "どっちが強いと思う？ヤムチェか、それとも牛さんかな？\n命令キー：（Z,V,B）",
        MUSHA_TALLRR1 = "どっちが強いと思う？ヤムチェか、それとも牛さんかな？\n命令キー：（Z,V,B）",
        MUSHA_TALLRR2 = "どっちが強いと思う？ヤムチェか、それとも牛さんかな？\n命令キー：（Z,V,B）",
        MUSHA_TALLRR3 = "どっちが強いと思う？ヤムチェか、それとも牛さんかな？\n命令キー：（Z,V,B）",
        MUSHA_TALLRR4 = "どっちが強いと思う？ヤムチェか、それとも牛さんかな？\n命令キー：（Z,V,B）",
        MUSHA_TALLRR5 = "どっちが強いと思う？ヤムチェか、それとも牛さんかな？\n命令キー：（Z,V,B）",
        MUSHA_TALLRRICE = "どっちが強いと思う？ヤムチェか、それとも牛さんかな？\n命令キー：（Z,V,B）",
        MUSHA_TALL3 = "ヤムチェはムシャの頼もしい相棒なの！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRR1 = "ヤムチェはムシャの頼もしい相棒なの！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRR2 = "ヤムチェはムシャの頼もしい相棒なの！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRR3 = "ヤムチェはムシャの頼もしい相棒なの！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRR4 = "ヤムチェはムシャの頼もしい相棒なの！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRR5 = "ヤムチェはムシャの頼もしい相棒なの！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRICE = "ヤムチェはムシャの頼もしい相棒なの！\n命令キー：（Z,V,B）",
        MUSHA_TALL4 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRR1 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRR2 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRR3 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRR4 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRR5 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRR6 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRRICE = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALL5 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRRR1 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRRR2 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRRR3 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRRR4 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRRR5 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRRR6 = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_TALLRRRRRICE = "ヤムチェがすごいパワーを手に入れたよ！\n命令キー：（Z,V,B）",
        MUSHA_RP1 = "誰にもムシャたちを止められないよ！\n命令キー：（Z,V,B）",
        MUSHA_RP2 = "誰にもムシャたちを止められないよ！\n命令キー：（Z,V,B）",
        MUSHA_RP3 = "誰にもムシャたちを止められないよ！\n命令キー：（Z,V,B）",
        MUSHA_RP4 = "誰にもムシャたちを止められないよ！\n命令キー：（Z,V,B）",
        MUSHA_RP5 = "誰にもムシャたちを止められないよ！\n命令キー：（Z,V,B）",
        MUSHA_RP6 = "誰にもムシャたちを止められないよ！\n命令キー：（Z,V,B）",
        MUSHA_RP7 = "誰にもムシャたちを止められないよ！\n命令キー：（Z,V,B）",
        MUSHA_RPICE = "誰にもムシャたちを止められないよ！\n命令キー：（Z,V,B）",
        GHOSTHOUND = "行くの、ゴーストのおともだち！",
        GHOSTHOUND2 = "あっ、ムシャは呼ぶつもりなかったの。",
        SHADOWMUSHA = "わあ、ムシャの影が目を覚ましたの！",
        --item
        MUSHA_FLUTE = "ヤムチェはムシャのメロディが大好きなの！",
        MUSHA_WEAPON_SWORD = "これはムシャの剣だよ！",
        -- MUSHASWORD = "Fire! Heed Musha's call!", -- War3 Pandaren Brewmaster
        -- MUSHASWORD_FROST = "Storm! Heed Musha's call!", -- War3 Pandaren Brewmaster
        MUSHA_WEAPON_FROSTHAMMER = "大地よ！ムシャの呼び声に応えて！", -- War3 Pandaren Brewmaster
        MUSHA_ARMOR_FROST = "ムシャ、このひんやりした鎧が大好きなの！", -- this is frost armor, grow up : frost armor II
        MUSHA_HAT_PHOENIX = "武将のかぶとだよ！ムシャ、ずっと欲しかったの！",
        MUSHA_HAT_PRINCESS = "ムシャの王冠が戻ってきたよ！", --grow up : Queen crown
        MUSHA_HAT_RABBIT = "そろそろお仕置きの時間だよ！", -- Lol Caitlyn
        MUSHA_ARMOR_PROTOTYPE = "この鎧、見たことある？\nそう、これがムシャの基本の鎧なの！",
        MUSHA_ARMOR_PRINCESS = "これはムシャの最高傑作なの！",
        --WIP
        GLOWDUST = "砂糖みたいな味なの。",
        CRISTAL = "きらきらのキャンディなの！",
        EXP = "これがエッセンスなの！",
        --EXP1000CHEAT = "Show me the money!", -- Starcraft

        BOOK_BIRDS = "これ、鳥の言葉で書いてあるの？",
        BOOK_TENTACLES = "大きなミミズの育てかたが書いてあるの。",
        BOOK_GARDENING = "植物はこの本が大好きなの。",
        BOOK_SLEEP = "すっごく退屈な本なの。ムシャ眠くなっちゃう…",
        BOOK_BRIMSTONE = "あんまりいい本じゃないの…",
        GLOMMER = "あのネコさん、羽があるの！飛べるの！",
        GLOMMERFLOWER = {
            GENERIC = "大きな花なの！どうやって咲いたの？",
            DEAD = "花が灰色なの？前は赤かったのに！"
        },
        GLOMMERWINGS = "ちっちゃいの！",
        GLOMMERFUEL = "ムシャ、これ食べられるの？だめなの？どうして？",
        BELL = "これはごはんのベルなの？ムシャのごはんをくれるのはだれなの？",
        STATUEGLOMMER = {
            GENERIC = "ムシャ、知ってるの！えっと…なんだっけ？",
            EMPTY = "ムシャ、何週間か前に花を見たの。"
        },
        WEBBERSKULL = "この頭の骨、なにか物語がありそうなの。",
        MOLE = {
            HELD = "見て見て！おかしな鼻がついてるの！",
            UNDERGROUND = "この下に何か隠れてるの。\nムシャが追い出すの！",
            ABOVEGROUND = "ムシャのアイテムを持ってったの！"
        },
        MOLEHILL = "中に何かいるの。ムシャは知ってるの。",
        MOLEHAT = "なにか匂いをかぎまわってるの…",
        NIGHTSTICK = "これ、役に立つの？",
        --adds 6 start
        MUSHROOMHAT = "これをかぶると、たのしいキノコに見えるの。",
        MUSHROOM_LIGHT2 = {
            ON = "青はもちろん、いちばん科学的な色なの。",
            OFF = "三原色があれば、いい明かりが作れるの。",
            BURNT = "ムシャ、カビはやったんじゃないの。誓うの！"
        },
        MUSHROOM_LIGHT = {
            ON = "科学で光るの。",
            OFF = "大きくて科学的なキノコなの。",
            BURNT = "こんがりこげこげなの。"
        },
        SLEEPBOMB = "投げると、すやすやの輪っかが出るの。",
        MUSHROOMBOMB = "キノコ雲になりそうなの！",
        SHROOM_SKIN = "いぼいぼもついてるの！",
        TOADSTOOL_CAP = {
            EMPTY = "ただの地面の穴なの。",
            INGROUND = "なにか顔を出してるの。",
            GENERIC = "あのキノコ、切ってほしそうなの。"
        },
        TOADSTOOL = {
            GENERIC = "うえ〜！ムシャ、そんなのキスしないの！",
            RAGE = "ぴょんぴょん怒ってるの！"
        },
        MUSHROOMSPROUT = {
            GENERIC = "なんて科学的なの！",
            BURNT = "キノコらしくないの！"
        },
        MUSHTREE_TALL = {
            GENERIC = "あのキノコ、大きくなりすぎたの。",
            BLOOM = "遠くからはわからないけど、けっこうくさいの。"
        },
        MUSHTREE_MEDIUM = {
            GENERIC = "これ、昔はムシャのお風呂場に生えてたの。",
            BLOOM = "ムシャ、ちょっと気分を害したの。"
        },
        MUSHTREE_SMALL = {
            GENERIC = "魔法のキノコなの？",
            BLOOM = "増えようとしてるの。"
        },
        MUSHTREE_TALL_WEBBED = "クモたちはこれを大事だと思ってたの。",
        SPORE_TALL = {
            GENERIC = "ただぷかぷか漂ってるの。",
            HELD = "ムシャは小さな明かりをポケットに入れておくの。"
        },
        SPORE_MEDIUM = {
            GENERIC = "なんの心配もなさそうなの。",
            HELD = "ムシャは小さな明かりをポケットに入れておくの。"
        },
        SPORE_SMALL = {
            GENERIC = "胞子の目にはたまらない景色なの。",
            HELD = "ムシャは小さな明かりをポケットに入れておくの。"
        },
        BEEQUEEN = "その針をムシャに近づけないでなの！",
        BEEQUEENHIVE = {
            GENERIC = "べたべたで歩けないの。",
            GROWING = "これ、前からあったっけ？"
        },
        BEEQUEENHIVEGROWN = "どうやってこんな大きくなったの？！",
        BEEGUARD = "女王さまを守ってるの。",
        HIVEHAT = "これをかぶってると、世界がちょっとだけ落ち着いて見えるの。",
        MINISIGN = {
            GENERIC = "ムシャ、もっと上手に描けるの！",
            UNDRAWN = "ここに何か描いたらいいの。"
        },
        MINISIGN_ITEM = "これじゃ使えないの。置いてあげるの。",
        BERRYBUSH_JUICY = {
            BARREN = "こんな状態じゃ実がならないの。",
            WITHERED = "暑さで、みずみずしい実まで干からびちゃったの！",
            GENERIC = "食べる時まで、そのままにしておくの。",
            PICKED = "この木、次の分をせっせと作ってるの。",
            DISEASED = "かなり具合が悪そうなの。",
            DISEASING = "う〜ん、なにかおかしいの。",
            BURNING = "すっかり燃えてるの。"
        },
        CANARY = {
            GENERIC = "科学でできた、黄色い生きものなの。",
            HELD = "ムシャ、つぶしてないの…よね？"
        },
        CANARY_POISONED = "たぶん大丈夫なの。",
        CRITTERLAB = "この中に何かいるの？",
        CRITTER_GLOMLING = "なんて流線形な生きものなの！",
        CRITTER_DRAGONLING = "ムシャの心に、にゅるっと入ってきたの。",
        CRITTER_LAMB = "お母さんより、ずっとぬめぬめしてないの。",
        CRITTER_PUPPY = "小さなモンスターにしては、けっこうかわいいの！",
        CRITTER_KITTEN = "あなた、ムシャの実験助手に向いてるの。",
        CRITTER_PERDLING = "羽のおともだちなの。",
        LAVA_POND = "マグマみたいに、まぶしいの！",
        LAVAE = "熱すぎて触れないの。",
        LAVAE_COCOON = "すっかり冷めて落ち着いたの。",
        LAVAE_PET = {
            STARVING = "かわいそうに、おなかペコペコなの。",
            HUNGRY = "ちっちゃいお腹が鳴ってるの、聞こえるの。",
            CONTENT = "うれしそうなの。",
            GENERIC = "よしよし。いいモンスターはだあれなの？"
        },
        LAVAE_EGG = {
            GENERIC = "中から、ほんのりあったかいの。"
        },
        LAVAE_EGG_CRACKED = {
            COLD = "あの卵、あったかさが足りないと思うの。",
            COMFY = "うれしそうな卵なんて、はじめて見たの。"
        },
        LAVAE_TOOTH = "卵の歯なの！",
        ENDTABLE = {
            BURNT = "こげた机の上に、こげた花びんがあるの。",
            GENERIC = "机の上の花びんに、花が入ってるの。",
            EMPTY = "ここに何か入れないとね。",
            WILTED = "あんまり元気そうじゃないの。",
            FRESHLIGHT = "小さな明かりがあると、いいの。",
            OLDLIGHT = "新しい電球、取ってくるの忘れてない？" -- will be wilted soon, light radius will be very small at this point
        },
        TWIGGYTREE = {
            BURNING = "木がもったいないの。",
            BURNT = "ムシャが止められた気がするの…",
            CHOPPED = "どうだ、自然め！",
            GENERIC = "とげとげなの。",
            DISEASED = "具合が悪そうなの。いつもよりずっと。"
        },
        TWIGGY_NUT_SAPLING = "自分で育つの。手伝いいらないの。",
        TWIGGY_OLD = "あの木、ひょろひょろなの。",
        TWIGGY_NUT = "中から出たがってる木の芽が入ってるの。",
        FLOWER_WITHERED = "お日さまが足りなかったんだと思うの。",
        FOSSIL_PIECE = "科学の骨なの！組み立て直すの！",
        FOSSIL_STALKER = {
            GENERIC = "まだ足りない部分があるの。",
            FUNNY = "ムシャの科学のカンが、なにかちがうって言ってるの。",
            COMPLETE = "生きてるの！…あ、ちがった、動いてないの。"
        },
        STALKER = "骸骨が影とくっついたの！",
        STALKER_ATRIUM = "どうしてこんなに大きいの…？",
        STALKER_MINION = "足首をかじるやつらなの！",
        THURIBLE = "薬品のにおいがするの。",
        ATRIUM_OVERGROWTH = "この記号、ムシャにはどれも読めないの。",
        LUCY = "ムシャが見慣れてる斧より、ずっとかわいいの。",
        MINIFAN = "なぜか後ろから、2倍の速さで風が出てくるの。",
        OASISLAKE = "あれって、蜃気楼なの？",
        PINECONE_SAPLING = "もうすぐ木になるの！",
        LUMPY_SAPLING = "この木、どうやって増えたの…？",
        --adds 6 end

        RABBITHOUSE = {
            GENERIC = "ウサギが住んでるの。",
            BURNT = "もうだれも住んでないの。\nでもムシャ、だれか見つけられるの。"
        },
        TURF_DECIDUOUS = "腐った葉っぱがいっぱいなの。",
        TURF_SANDY = "砂は隠れるのに便利なの！",
        TURF_BADLANDS = "かたすぎるの！",
        BEARGER = "どうやったらあなたみたいに大きくなれるの？",
        BEARGERVEST = "もふもふのおドレスなの！",
        ICEPACK = "もふもふリュックなの！",
        BEARGER_FUR = "ただの毛皮だけど、ムシャ、いいこと思いついたの。",
        FURTUFT = "げほっ…ムシャ、毛を食べちゃったの！",
        BIGFOOT = "すっごく大きな足あとなの！",
        BONESHARD = "骨のかけらなの。",
        BUZZARD = "空から来たの！",
        CACTUS = {
            GENERIC = "この植物、トゲトゲしてるの！\nだれも食べないと思うの。",
            PICKED = "いたっ！しまいにくいの！"
        },
        CACTUS_MEAT_COOKED = "ムシャ、これ食べられるの…たぶん。",
        CACTUS_MEAT = "うわ、においがすごいの！",
        CACTUS_FLOWER = "サボテンの頭の花なの。ムシャは食べたくないの。",
        COLDFIRE = {
            EMBERS = "あっ、たいへん！燃料はどこなの？",
            GENERIC = "青い火なの。でも料理はできないの。",
            HIGH = "この火、ムシャを涼しくしてくれるの！",
            LOW = "もっと大きくするにはどうするの？",
            NORMAL = "ファファは青い火はすごく熱いって言ってたのに、これはちがうの。",
            OUT = "あ〜あ、もう終わっちゃったの。"
        },
        CATCOON = "このネコさん、ムシャが食べないもの食べてくれるの！",
        CATCOONDEN = {
            GENERIC = "ネコのおうちなの！ネコの足あとがついてるの。",
            EMPTY = "もうだれも住んでないの。\nムシャ、もう興味ないの。"
        },
        CATCOONHAT = "う〜ん…ないよりはいいの。",
        COONTAIL = "ムシャ、これをネコから切り取った理由がわからないの。",
        COOKPOT = {
            COOKING_LONG = "料理に時間がかかるの。",
            COOKING_SHORT = "すぐにできあがるの！",
            DONE = "ムシャ、これ好きなの！あなたは？",
            EMPTY = "だれも使ってないの。じゃあムシャの番なの。",
            BURNT = "なんでこの石、燃えちゃったの？"
        },
        EYEBRELLAHAT = "雨も暑さも雪もへいきなの！でも重いの。",
        ARMORDRAGONFLY = "これ着てたら、さわった人がこんがり焼けちゃうの！",
        DRAGON_SCALES = "かっこいいの！あ、熱いの！",
        DRAGONFLYCHEST = "このチェストは火を吸っちゃうの。灰にならないの！",
        DECIDUOUSTREE = {
            BURNING = "わああ！",
            BURNT = "細くて黒い木なの。",
            CHOPPED = "ここで休んでいいの？",
            GENERIC = "木なの。",
            POISON = "ガウガウ！"
        },
        ACORN_COOKED = "いいにおいなの！",
        BIRCHNUTDRAKE = "ヤリじゃだめなの！斧を持ってくるの！切るの！",
        FARMPLOT = {
            GENERIC = "タネをまく土なの。",
            GROWING = "はやくはやく！ムシャ、待ってるの。",
            needFERTILIZER = "うんちがいるの。",
            BURNT = "こげたものは食べないの。"
        },
        COLDFIREPIT = {
            EMBERS = "あっ、たいへん！燃料はどこなの？",
            GENERIC = "青い火なの。でも料理ができないの。",
            HIGH = "この火、ムシャを涼しくしてくれるの！",
            LOW = "もっと大きくするにはどうするの？",
            NORMAL = "ファファは青い火はすごく熱いって言ってたのに、これはちがうの。",
            OUT = "あ〜あ、もう終わっちゃったの。"
        },
        FIRESUPPRESSOR = {
            ON = "燃料がたくさん必要なの。ときどき見てあげてね。",
            OFF = "夏だったら、\n燃料を入れておかないとだめなの。",
            LOWFUEL = "燃料が少なくなってるの。ムシャ、見てきたの。"
        },
        ICEHAT = "問題は、ムシャの足のうらがまだ熱いことなの。",
        LIGHTNINGGOAT = {
            GENERIC = "ふしぎなツノのヤギさんなの。",
            CHARGED = "電気ヤギなの！でもムシャ、痛いのはいやなの。"
        },
        LIGHTNINGGOATHORN = "ギガドリルブレイカー！！\nえっ？なんでだめなの？おもしろいのに！",
        GOATMILK = "いたっ！ミルクがはじけてるの！",
        MEATRACK = {
            DONE = "いつ取るの？もう完全にできてるの！",
            DRYING = "いつできるのかはわからないの。",
            DRYINGINRAIN = "かさがいるみたいなの。",
            GENERIC = "これでお肉を干せるの。\nジャーキーはおいしいの！",
            BURNT = "干し網に焼いたお肉をのせると、いちばん早くジャーキーになるの。"
        },
        MERMHEAD = {
            GENERIC = "うう。ムシャはあいつがきらいで、あいつもムシャがきらいなの。",
            BURNT = "二回も死んでるの！"
        },
        MERMHOUSE = {
            GENERIC = "沼のモンスターが住んでるの。",
            BURNT = "え〜、なにがあったのかわからないの。"
        },
        FLOWERSALAD = "花をそのまま食べるよりいいの。",
        ICECREAM = "めったにないごちそうなの！ありがとうなの！",
        WATERMELONICLE = "この凍った果物で、ムシャは涼しくなれるの！",
        TRAILMIX = "ポリポリポリ！",
        HOTCHILI = "これ、辛いにおいがするの。",
        GUACAMOLE = "好きな人もいるの。",
        MOOSE = "お肉をいっぱい取るの！ただのガチョウなの。",
        MOOSEEGG = "わあ、すっごく大きいの！",
        MOSSLING = "はやくはやく！カミナリと雨を呼んじゃうの！",
        FEATHERFAN = "なんでこんなに大きいのか、ムシャにはわからないの。",
        GOOSE_FEATHER = "扇風機には使えるけど、ペンにはならないの。",
        STAFF_TORNADO = "ぶわぁ〜！風を呼ぶの！",
        PIGHEAD = {
            GENERIC = "暗いメッセージを送ってるの。",
            BURNT = "ブタさんがきらいな人がいるの。だから燃やされたの。"
        },
        PIGHOUSE = {
            FULL = "すみません、ムシャを助けてくれないの？困ってるの。",
            GENERIC = "ブタさんたちはいつもムシャを助けてくれるの…たまにだけど。",
            LIGHTSOUT = "ふーん、ムシャは気にしないの。",
            BURNT = "なにがあったの？"
        },
        FERTILIZER = "うんちがいっぱいのバケツなの。",
        RAINOMETER = {
            GENERIC = "もうすぐ雨がふるっていう合図なの。",
            BURNT = "看板、読めないの。"
        },
        RAINCOAT = "小さすぎて、リュックと一緒には着られないの。",
        RAINHAT = "水を飲むのは好きなの。でも髪を濡らすのはいやなの。",
        RESEARCHLAB = {
            GENERIC = "生きのびるための始まりなの。",
            BURNT = "あ〜…ムシャの実験室がなくなっちゃったの。"
        },
        RESEARCHLAB2 = {
            GENERIC = "ムシャはなんでも作れるの！…作れないのもあるの。",
            BURNT = "まだそれが必要だったの！"
        },
        RESEARCHLAB3 = {
            GENERIC = "おお〜！これで魔法が使えるの！",
            BURNT = "火の力はだれにも止められないの…"
        },
        RESEARCHLAB4 = {
            GENERIC = "なんでシルクハットがいるの？科学のためなの？ほんとに？",
            BURNT = "魔法でも火は消せないの。"
        },
        RESURRECTIONSTATUE = {
            GENERIC = "…ウィルソンみたいなの？",
            BURNT = "悲鳴が聞こえた気がしたの。"
        },
        --adds 1 start
        CAVEIN_BOULDER = {
            GENERIC = "これはムシャでも持ち上げられるの。",
            RAISED = "ムシャの手がとどかないの！"
        },
        ROCK = "ムシャのポケットには入らないの。",
        PETRIFIED_TREE = "こわくなって固まっちゃったの。",
        ROCK_PETRIFIED_TREE = "こわくなって固まっちゃったの。",
        ROCK_PETRIFIED_TREE_OLD = "こわくなって固まっちゃったの。",
        --adds 1 end
        ROCK_ICE = {
            GENERIC = "凍ままでいたいなら、そこでじっとしてればいいの。",
            MELTED = "また凍るまで少し待たないとね。"
        },
        ROCK_ICE_MELTED = "また凍るまで、すごく時間がかかるの。",
        ICE = "ひえひえなの。",
        REFLECTIVEVEST = "地面では泳げないの。",
        HAWAIIANSHIRT = "このシャツは「夏だぞ〜」って叫んでるの！",
        TENT = {
            GENERIC = "ここで長く休めるの。",
            BURNT = "ムシャのベッドが灰になっちゃったの！"
        },
        SIESTAHUT = {
            GENERIC = "少なくとも、かさがなくても濡れずにすむの。",
            BURNT = "ムシャの乾いた場所が燃えちゃったの。"
        },
        TRANSISTOR = "どうやって動くのか、ムシャにはわからないの。",
        TREASURECHEST = {
            GENERIC = "ムシャはたくさん物がいるの。だから箱もたくさん作るの。",
            BURNT = "おしまいなの！ぜんぶ！ムシャの持ち物が全部消えたの！"
        },
        TUMBLEWEED = "止まって！ムシャ、止まれって言ってるの！",
        GRASS_UMBRELLA = "見た目もかわいくて、水もよく防ぐの。",
        UNIMPLEMENTED = "まだうまく動かないの。",
        WALL_HAY = {
            GENERIC = "少しは防げるけど、火には弱いの…",
            BURNT = "だから言ったの！燃えやすいって！"
        },
        WALL_WOOD = {
            GENERIC = "けっこう丈夫なの。でも火には負けちゃうの。",
            BURNT = "はぁ…ムシャ、がんばったの。"
        },
        WARG = "見て！ハウンドのボスなの！",
        WATERMELON = "大きいけど、お腹はいっぱいになるの。",
        WATERMELON_COOKED = "いま食べたいの！",
        WATERMELONHAT = "おもしろいの！ちょっとべたべたするの！",
        WINTEROMETER = {
            GENERIC = "どんどん熱く、どんどん高くなるの。",
            BURNT = "火は測れなかったの。"
        },
        HOMESIGN = {
            GENERIC = "これでなにか書けるの。",
            BURNT = "ムシャ、これリサイクルできるの。"
        },
        BEEBOX = {
            READY = "見た？ハチミツの箱なの！",
            FULLHONEY = "箱がハチミツでいっぱいなの！",
            GENERIC = "ハチと花が入って、ハチミツが出てくるの！",
            NOHONEY = "液体の黄金、待たないといけないの。",
            SOMEHONEY = "あっ、ハチさんたち、まだ働いてるの。",
            BURNT = "ムシャ、こげたハチミツはすきじゃないの…"
        },
        LIVINGTREE = "あの木、顔があるから生きてるみたいに見えるの。",
        ICESTAFF = "これでムシャは安心なの。",
        WORMLIGHT = "まぜても使えるけど、ムシャは光の粉のほうが好きなの。",
        WORM = {
            PLANT = "いい光なの。でも植物みたいなの。",
            DIRT = "地面の下でなにか動いてるの！",
            WORM = "いたっ！今のなんなの！？"
        },
        EEL = "長くて、へんで、緑の魚なの。",
        EEL_COOKED = "へんなにおいがするの…",
        UNAGI = "ムシャ、そんなに何もしてないのに、ウナギができたの！",
        EYETURRET = "背の高い骨の目玉なの。なんでもやっつけてくれるの。",
        EYETURRET_ITEM = "今は小さなおもちゃだけど、地面に置くと大きくなって動き出すの。",
        MINOTAURHORN = "影の洞くつの奥にいる、征服者のしるしなの。",
        MINOTAURCHEST = "大きなチェストなの！ムシャより背が高いの！",
        THULECITE_PIECES = "もっとあれば、\nムシャはルーン素材のものを作れるの。",
        POND = "釣りに行くの！",
        POND_ALGAE = "暗くて湿ったところで育つの。",
        GREENSTAFF = "建物と道具の時間をもどして、\n作るのに使ったものを返してくれるの。",
        POTTEDFERN = "なにもしないけど、かわいいの。",
        THULECITE = "古いやつなの。",
        ARMORRUINS = "重いけど、安心なの。",
        RUINS_BAT = "ムシャが知ってる中で、いちばん強い石のバットなの。",
        RUINSHAT = "簡単に作れる王冠なの。",
        NIGHTMARE_TIMEPIECE = {
            --Keeps track of the nightmare cycle
            CALM = "なにも起きてないの。ここは問題なしなの。", --Calm phase
            WARN = "ムシャへの警告なの。", --Before nightmare
            WAXING = "あっ…ここはあぶないって、ムシャのカンが言ってるの。", --Nightmare Phase first 33%
            STEADY = "ムシャの状況、どんどん悪くなってるの！", --Nightmare 33% - 66%
            WANING = "あと少しなの。ムシャ、もう少しだけがんばるの。", --Nightmare 66% +
            DAWN = "もうすぐ終わると思うの。", --After nightmare
            NOMAGIC = "ここは魔法もなし、あぶなさもなしなの。" --Place with no nightmare cycle.
        },
        BISHOP_NIGHTMARE = "どうしてまだいるの？",
        ROOK_NIGHTMARE = "壊れた頭、足、目。それでもまだ動いてるの。",
        KNIGHT_NIGHTMARE = "置きざりにされた兵隊なの。",
        MINOTAUR = "あぶないけど、ムシャはちゃんとわかってるの。", --Monster in labyrinth
        SPIDER_DROPPER = "白いクモなの。巣は洞くつの天井にあるの。", --White spider that comes from the roof
        NIGHTMARELIGHT = "この光、ムシャの頭が痛くなるの。", --Lights that activate during nightmare.
        GREENGEM = "ムシャにとっていちばん大事な宝石なの！",
        RELIC = "だれかがこれを直したの。", --Fixed relic
        RUINS_RUBBLE = "まだなにか足りないの。", --Broken relic
        MULTITOOL_AXE_PICKAXE = "すてきなの！石も木も壊せるの！", --Works as axe and pickaxe
        ORANGESTAFF = "これがなにか、ムシャは知ってるの。これでワープできるの。", --Teleports player.
        YELLOWAMULET = "むげんの力なの！", --Emits light, player walks faster.
        GREENAMULET = "半分おトクなの！", --Reduce cost of crafting
        SLURPER = "大きなふわふわボールなの！",
        SLURPER_PELT = "見える？まだ生きてるみたいなの！",
        ARMORSLURPER = "きついの！でもこれでムシャはお腹がすきにくいの…",
        ORANGEAMULET = "アイテムを勝手に拾ってくれるの！",
        YELLOWSTAFF = "ムシャも同じこと知ってるの！",
        YELLOWGEM = "ぴかぴかの黄色い石なの。",
        ORANGEGEM = "ムシャ、へんな気配を感じるの。",
        TELEBASE = {
            VALID = "わ…どうすればいいの？",
            GEMS = "ムシャはなにをすればいいの？"
        },
        GEMSOCKET = {
            VALID = "紫の宝石から、魔法の力を感じるの。",
            GEMS = "もっと魔法が必要なの！"
        },
        STAFFLIGHT = "す…すごいの！",
        LIGHTER = "小さな火おこしなの。",
        ANCIENT_ALTAR = {
            WORKING = "ムシャの頭に、直接話しかけてきたの。",
            BROKEN = "動いてるけど、全力にはまだ何か足りないの。"
        },
        ANCIENT_ALTAR_BROKEN = "動いてるけど、全力にはまだ何か足りないの。",
        ANCIENT_STATUE = "へんな見た目の古代のものなの。",
        LICHEN = "石みたいに見えるの。",
        CUTLICHEN = "傷んでるみたいなの。",
        CAVE_BANANA = "これ、洞くつで見つけたの。",
        CAVE_BANANA_COOKED = "バナナなの！",
        CAVE_BANANA_TREE = "暗いところでどうやって育つの？",
        ROCKY = "すっごく大きいの。",
        BLUEAMULET = "このお守り、冷たいの！",
        PURPLEAMULET = "ムシャには死んだ人が見えるの…",
        TELESTAFF = "ポン！ポン！ポン！なの！",
        MINERHAT = "ムシャは炭鉱夫じゃないけど、これで洞くつでも見えるの。",
        MONKEY = "追いかけるの！ムシャのもの取ったの！",
        MONKEYBARREL = "サルたちが、自分の顔みたいな家を作ったの。",
        HOUNDSTOOTH = "するどいの。ムシャの遠距離も近距離も武器にできるの！",
        ARMORSNURTLESHELL = "王冠のほうがいいけど、これはかわいいの！",
        BAT = "怒ったコウモリなの！",
        BATBAT = "これでムシャの敵をたたけるの。",
        BATWING = "どうやって使うの？料理できるの？",
        BATWING_COOKED = "ちぢんじゃったの。",
        BEDROLL_FURRY = "これで眠れるの。",
        BUNNYMAN = "気をつけて。お肉がきらいなの。",
        FLOWER_CAVE = "いい明かりになるの。",
        FLOWER_CAVE_DOUBLE = "いい明かりになるの。",
        FLOWER_CAVE_TRIPLE = "いい明かりになるの。",
        GUANO = "かわいた白いうんちなの。",
        LANTERN = "ランタンは明かりだけなの。これでは戦えないの。",
        LIGHTBULB = "光る野菜なの！",
        MANRABBIT_TAIL = "小さな白いしっぽなの！",
        MUSHTREE_TALL = "青い常緑樹なの。",
        MUSHTREE_MEDIUM = "頭がふたつのキノコなの！",
        MUSHTREE_SMALL = "気持ちわるい、頭でっかちの緑キノコなの。",
        SLURTLE = "これ、ムシャの頭にちょうどよさそうなの。",
        SLURTLE_SHELLPIECES = "こわれてるの、ムシャは知ってるの。",
        SLURTLEHAT = "見てなの！かたいヘルメットなの！",
        SLURTLEHOLE = "大きなサボテンみたいなの。",
        SLURTLESLIME = "爆発するの！",
        SNURTLE = "これは体にちょうどよさそうなの。",
        SPIDER_HIDER = "あのクモ、へんな帽子をかぶってるの！",
        SPIDER_SPITTER = "あのクモたち、巣を飛ばしてくるの！",
        SPIDERHOLE = "クモの巣なの。",
        STALAGMITE = "下から生えてる古い岩なの。",
        STALAGMITE_FULL = "あの古い岩、すごく大きいの！\n中に宝石が見えた気がするの。",
        STALAGMITE_LOW = "つるつるした小さな岩があるの。",
        STALAGMITE_MED = "つるつるした大きな岩があるの。育ってるみたいなの。",
        STALAGMITE_TALL = "背が高くてするどい岩なの。",
        STALAGMITE_TALL_FULL = "大きなするどい岩なの！\n中に宝石が見えた気がするの。",
        STALAGMITE_TALL_LOW = "するどい小さな岩があるの。",
        STALAGMITE_TALL_MED = "するどい大きな岩があるの。上に育ってるみたいなの。",
        TURF_CARPETFLOOR = "ふわふわなの！",
        TURF_CHECKERFLOOR = "この床は人工的なの。",
        TURF_DIRT = "土には植物が育つの。",
        TURF_FOREST = "コケがいっぱいなの。",
        TURF_GRASS = "うすい緑の草の床なの。",
        TURF_MARSH = "葉っぱだらけなの！",
        TURF_ROAD = "この床だとムシャは速く走れるの！",
        TURF_ROCKY = "岩はすごく大事な資源なの。",
        TURF_SAVANNA = "ウサギもビーファローも、この床が好きなの。",
        TURF_WOODFLOOR = "木の床は気持ちいいの。",
        TURF_CAVE = "白いしましまの床なの。",
        TURF_FUNGUS = "場所によって見た目がちがうの。",
        TURF_SINKHOLE = "緑のしましまの床なの。",
        TURF_UNDERROCK = "岩が分かれてるの。",
        TURF_MUD = "ぬちゃぬちゃなの。",
        TURKEYDINNER = "ターキー、ターキー、ターキーなの！",
        TWIGS = "小枝が足りないの！",
        POWCAKE = "うまみがたっぷりなの。",
        CAVE_ENTRANCE = {
            GENERIC = "だれかが何か詰まらせたの。\n下に何かいるのかな？",
            OPEN = "ムシャはロープを持ってるの。あなたは？"
        },
        CAVE_EXIT = "ロープなの？",
        MAXWELLPHONOGRAPH = "もっと音楽をかけてほしいの！",
        PIGGUARD = "この農場の持ち主なの！",
        BOOMERANG = "曲がった木が敵に当たって、ムシャのところに戻ってくるの。",
        ADVENTURE_PORTAL = "門なの？どこにつながってるの？",
        AMULET = "ムシャは無敵なの！…たぶんちがうの。\nでも気分はいいの。",
        ANIMAL_TRACK = "いい狩りになりそうなの。",
        ARMORGRASS = "安い鎧なの。あんまり守ってくれないの。",
        ARMORMARBLE = "悪くないの。ただ重いの。",
        ARMORWOOD = "この世界の標準的な鎧なの。",
        ARMOR_SANITY = "これ、ムシャを守ってくれるの？",
        ASH = {
            GENERIC = "なんだったかわからないけど、今は灰なの。",
            REMAINS_GLOMMERFLOWER = "ああ…古いベルがなくなっちゃったの。",
            REMAINS_EYE_BONE = "別の目玉骨、どうやって見つけるの？",
            REMAINS_THINGIE = "なくてさみしいの。"
        },
        AXE = "切るの！",
        BABYBEEFALO = {
            GENERIC = "傷つけちゃだめなの。まだ。",
            SLEEPING = "まだだめなの。まだ赤ちゃんなの！"
        },
        BACKPACK = "守ってはくれないけど、たくさん運べるの。",
        BACONEGGS = "ムシャこれ大好きなの。ベーコンとたまごなの！",
        BANDAGE = "その調子なの！",
        BASALT = "わあ！すごくかたいの。ムシャには壊せないの！",
        BEARDHAIR = "ウィルソンの髪から、ウィルソン像になったの。",
        BEDROLL_STRAW = "これで眠れるの。",
        BEE = {
            GENERIC = "動いてるの。",
            HELD = "ぶーん ぶーん ぶーん…"
        },
        BEEFALO = {
            FOLLOWER = "ムシャを追いかけてるの！",
            GENERIC = "重くて、きたなくて、のろそうなの。",
            NAKED = "ムシャじゃないの。なにがあったのか知らないの。",
            SLEEPING = "おうちはどこなの？"
        },
        BEEFALOHAT = "すごいにおいなの…ビーファローみたいなの。",
        BEEFALOWOOL = "冬のために取っておくの。",
        BEEHIVE = "中にハチミツなの。どうやって取るの？",
        BEEMINE = "今はハチが入ってるの…",
        BEEMINE_MAXWELL = "ハチのかわりに、蚊が入ってるの！",
        BEEHAT = "これでムシャの顔を刺されから守れるの！",
        BERRIES = "おいしい赤い実なの！",
        BERRIES_COOKED = "焼いた実のほうがおいしいの。",
        BERRYBUSH = {
            BARREN = "ただの茂みなの。赤い実はあるの？",
            WITHERED = "腐ったものか肥料はどこなの？",
            GENERIC = "実がなるまで時間がかかるの！",
            PICKED = "いつ実がとれるの？"
        },
        BIRDCAGE = {
            GENERIC = "ここに鳥が住めるの。",
            OCCUPIED = "中に鳥がいるの。エサをあげないとね！",
            SLEEPING = "鳥が眠っちゃったの。"
        },
        BIRDTRAP = "ムシャがどうやって鳥を捕まえるか、知りたいの？",
        BIRD_EGG = "卵はいくつ産まれるの？",
        BIRD_EGG_COOKED = "朝ごはんにいいの。",
        BISHOP = "あの敵はあぶないの！ムシャを撃ってくるの！",
        BLOWDART_FIRE = "このダーツには火のエッセンスがこもってるの！",
        BLOWDART_SLEEP = "このダーツで敵を寝かせて、ムシャの的になるの。",
        BLOWDART_PIPE = "こういうダーツはセイウチから出るの。",
        BLUEGEM = "ひえひえなの。",
        BLUEPRINT = "ふむふむ…そうなの？",
        BELL_BLUEPRINT = "空から来たの。",
        BLUE_CAP = "においは…しないの。",
        BLUE_CAP_COOKED = "火で焼いたの！",
        BLUE_MUSHROOM = {
            GENERIC = "青いキノコなの。",
            INGROUND = "青いキノコなの。",
            PICKED = "青いキノコだったの。"
        },
        BOARDS = "木が平らな板になったの。これでいろいろ作れるの。",
        BONESTEW = "ムシャが作れる中でいちばんの肉シチューなの。",
        BUGNET = "虫をつかまえるの！",
        BUSHHAT = "これをかぶってたら、だれにも見つからないの！",
        BUTTER = "チョウチョウが持ってたバターなの。",
        BUTTERFLY = {
            GENERIC = "チョウチョウ、だからバターなの！",
            HELD = "どうすればいいの？バターがいるの？" --☺
        },
        BUTTERFLYMUFFIN = "バターのマフィンに、チョウがのってるの。",
        BUTTERFLYWINGS = "うすくて、きれいな羽なの。",
        CAMPFIRE = {
            EMBERS = "火の穴に燃料を入れないとね。",
            GENERIC = "やわらかい明かりと、あたたかさなの。",
            HIGH = "火が高くのぼってるの！",
            LOW = "夜明けが来るの。",
            NORMAL = "明るい火なの。",
            OUT = "ムシャが火をおこすの？"
        },
        CANE = "ムシャ、もっと速く動けるの！",
        CARROT = "うん、ムシャはニンジン食べられるの。",
        CARROT_COOKED = "焼いたニンジンのにおい、知ってる？",
        CARROT_PLANTED = "だれがニンジンを植えたの？ウサギがいるの？",
        CARROT_SEEDS = "へんなオレンジの野菜のタネなの。",
        CAVE_FERN = "洞くつでしか育たない紫の花なの。",
        CHARCOAL = "木は二回燃やせるの。",
        CHESSJUNK1 = "壊れたものがいっぱいなの。",
        CHESSJUNK2 = "壊れたものがいっぱいなの。",
        CHESSJUNK3 = "壊れたものがいっぱいなの。",
        CHESTER = "すごくもふもふなの！",
        CHESTER_EYEBONE = {
            GENERIC = "骨に目玉なの？どうやって生きてるの？",
            WAITING = "安らかに眠ってなの。いい子だったの、チェスター…"
        },
        COOKEDMEAT = "生より焼いたほうがおいしいの。",
        COOKEDMONSTERMEAT = "それでもムシャは食べたくないの…できればね。",
        COOKEDSMALLMEAT = "小さいお肉だけど、生よりずっといいの。",
        CORN = "ムシャにスープ作ってくれるの？",
        CORN_COOKED = "いいにおいなの！",
        CORN_SEEDS = "これでケーキが作れるの。パウダーケーキなの！",
        CROW = {
            GENERIC = "鳥はタネと卵をムシャにくれるの。",
            HELD = "ムシャの勝ちなの！鳥をつかまえたの。"
        },
        CUTGRASS = "草がもっと必要なの！",
        CUTREEDS = "パピルスなの！",
        CUTSTONE = "石で装備を直せるって、知ってた？",
        DEADLYFEAST = "それは食べちゃだめなの！",
        DEERCLOPS = "あの大きな鹿、目がひとつなの…ムシャ、ちゃんと見てないとね！",
        DEERCLOPS_EYEBALL = "目玉かさ、鎧、ハンマー、剣！\nもっといるの！",
        DIRTPILE = "足あとを見つけたの！",
        DIVININGROD = {
            COLD = "この音なに？ハチなの？",
            GENERIC = "これ、なんのためのもの？\n出口を見つけられるの？",
            HOT = "なにか見つけたの！ムシャに見えるの！",
            WARM = "なにかを感じてるの。",
            WARMER = "動き出したの…なんのためかはわからないの。"
        },
        DIVININGRODBASE = {
            GENERIC = "鍵かけなの！",
            READY = "ムシャ、拾う準備できたの！",
            UNLOCKED = "またロッドを使えるの？"
        },
        DIVININGRODSTART = "ムシャ、なにか探しに行くの。\nそれが助けになるといいの。",
        DRAGONFLY = "ドラゴンフライを見つけたの！すっごく強いの！",
        LAVASPIT = {
            HOT = "あつい！あつい！",
            COOL = "もう冷めたの。"
        },
        DRAGONFRUIT = "ああ、これおいしいの！",
        DRAGONFRUIT_COOKED = "ああ、これおいしいの！",
        DRAGONFRUIT_SEEDS = "ドラゴンフルーツ！ムシャ好きなの！",
        DRAGONPIE = "ムシャを元気にしてくれるの！",
        DRUMSTICK = "ムシャはゴブラーを全部やっつけるの！",
        DRUMSTICK_COOKED = "わるいゴブラー、いいドラムスティックなの！",
        DURIAN = "中身は食べられるの！",
        DURIAN_COOKED = "おいしいの。においなんて気にしないの。",
        DURIAN_SEEDS = "ドリアンを植えるの！",
        EARMUFFSHAT = "小さなウサギが、あったかい耳あてになるの！",
        EGGPLANT = "焼くとやわらかくなるの。",
        EGGPLANT_COOKED = "ナスがやわらかくなったの。でも好きじゃない人もいるの。",
        EGGPLANT_SEEDS = "ナス一本だけで足りる人なんているの？",
        STUFFEDEGGPLANT = "ムシャ、全部食べられるの！",
        DUG_BERRYBUSH = "これ、おうちに持って帰るの！",
        DUG_GRASS = "これ、おうちに持って帰るの！",
        DUG_MARSH_BUSH = "これ、おうちに持って帰るの！",
        DUG_SAPLING = "これ、おうちに持って帰るの！",
        EARMUFFS = "小さな耳あてなの。",
        DECIDUOUSTREE = {
            BURNING = "あっ！あつい！あつい！火なの！木に水を急がないと！",
            BURNT = "細い炭の木なの。",
            CHOPPED = "木を切ったの。また生えてくるまで時間がかかるの。",
            GENERIC = "木は大事だけど、木そのもののほうがもっといいの。"
        },
        ACORN = {
            GENERIC = "バーチナッツのタネなの。",
            PLANTED = "もうすぐ大きな木になるの。"
        },
        EVERGREEN = {
            BURNING = "あっ！あつい！あつい！火なの！木に水を急がないと！",
            BURNT = "細い炭の木なの。",
            CHOPPED = "木を切ったの。また生えてくるまで時間がかかるの。",
            GENERIC = "木は大事だけど、木そのもののほうがもっといいの。"
        },
        EVERGREEN_SPARSE = {
            BURNING = "あっ！あつい！あつい！火なの！木に水を急がないと！",
            BURNT = "細い炭の木なの。",
            CHOPPED = "木を切ったの。また生えてくるまで時間がかかるの。",
            GENERIC = "木は大事だけど、木そのもののほうがもっといいの。"
        },
        EYEPLANT = "近くのアイテムを集めて、\nぜんぶ食べちゃうの。ムシャには永遠にあげないの！",
        FEATHERHAT = "羽の王冠をつけて、踊って遊ぶの！",
        FEATHER_CROW = "黒い羽は、眠りのダーツに使えるの！",
        FEATHER_ROBIN = "赤い羽は、火のダーツに使えるの！",
        FEATHER_ROBIN_WINTER = "白い羽は、吹き矢に使えるの！",
        FEM_PUPPET = "えっ…だれが、なんのために作ったの？", --what was that?
        FIREFLIES = {
            GENERIC = "ムシャ、このきれいな明かりが好きなの！",
            HELD = "ふむ…なんだか…へんなの。"
        },
        FIREHOUND = "ムシャの大事なものに近づけちゃだめなの！燃え出す前に倒すの！",
        FIREPIT = {
            EMBERS = "火の穴に燃料を入れないとね。",
            GENERIC = "やわらかい明かりと、あたたかさなの。",
            HIGH = "火が高くのぼってるの！",
            LOW = "夜明けが来るの。",
            NORMAL = "明るい火なの。",
            OUT = "ムシャが火をおこすの？"
        },
        FIRESTAFF = "あぶない魔法の杖なの。",
        FISH = "池でとったの…それとも人魚さんかな？",
        FISHINGROD = "生きのびるために魚を釣るの。",
        FISHSTICKS = "魚の串なの！作りやすくて、食べやすいの！",
        FISHTACOS = "タコス知ってる？これがタコスなの…魚入りなの！",
        FISH_COOKED = "ムシャ、スモークサーモンが食べたいの。",
        FLINT = "ムシャが作る道具の、ほとんどのはじまりなの。",
        FLOWER = "いっぱい集めたら、なにかできそうなの。",
        FLOWERHAT = "花の冠なの。つけると気分がよくなるの。",
        FLOWER_EVIL = "うえっ、この花すごいくさいの。他の花とちがうの。",
        FOLIAGE = "これ、洞くつでとったの。",
        FOOTBALLHAT = "ムシャの頭を守ってくれるの！",
        FROG = {
            DEAD = "いいカエルは、死んだカエルなの。",
            GENERIC = "ムシャ、カエルに舐められるのいやなの…",
            SLEEPING = "寝てるカエルなの。そっと近づいてみるの？"
        },
        FROGGLEBUNWICH = "サンドイッチの中にカエルがいるの。",
        FROGLEGS = "ムシャはカエルの足だけ食べるの。",
        FROGLEGS_COOKED = "おいしいの！",
        FRUITMEDLEY = "おいしい、果物なの！",
        GEARS = "金属の歯車なの。",
        GHOST = "アンデッド退治？ゴーストは剣で叩けばいいの！",
        GOLDENAXE = "金色に光る斧なの！",
        GOLDENPICKAXE = "金色に光るツルハシなの！",
        GOLDENPITCHFORK = "金色に光るクマデなの！",
        GOLDENSHOVEL = "金色に光るシャベルなの！",
        GOLDNUGGET = "ムシャは全部集めないといけないの！",
        GRASS = {
            BARREN = "うんちがいるの。",
            WITHERED = "からからに乾いてるの。",
            BURNING = "火なの！火！ムシャ、水が必要なの！",
            GENERIC = "草は生きのびる基本なの。",
            PICKED = "草はいつでも生えてくるの。"
        },
        GREEN_CAP = "うん。生で食べちゃだめなの。幻が見えるの。",
        GREEN_CAP_COOKED = "心の元気を助けてくれるの。",
        GREEN_MUSHROOM = {
            GENERIC = "眠り薬に使えるの。",
            INGROUND = "夕方にもう一度来ないとね。",
            PICKED = "だれかがもう摘んじゃったの。ムシャかな？"
        },
        GUNPOWDER = "ドラゴンフライと戦うときのために、取っておくの！",
        HAMBAT = "はじめまして、お肉さんなの！",
        HAMMER = "ハンマー兄弟なの！",
        HEALINGSALVE = "これに何度も助けられたの。",
        HEATROCK = {
            FROZEN = "こおりこおりなの！",
            COLD = "石みたいに冷たいの。",
            GENERIC = "夏は冷たく、冬はあったかくしておくの。",
            WARM = "あったかい黄色い石なの。",
            HOT = "赤くて熱い石なの！"
        },
        HONEY = "やった！ハチミツなの！",
        HONEYCOMB = "ハチはこれをムシャにあげたくなさそうなの。",
        HONEYHAM = "お肉もいっぱい、ハチミツもいっぱいなの。",
        HONEYNUGGETS = "ムシャはお肉が好き。ハチミツも好き。両方あるの！",
        HORN = "大きな低い音が出るの。",
        HOUND = "昔は友だちだったのに。今はムシャを強くしてくれるの。",
        HOUNDMOUND = "ハウンドってどこから来るの？地下なの？",
        HOUNDBONE = "これはハウンドだったの。今はもう骨だけなの。",
        ICEBOX = "これで食べものを長く保存できるの！",
        ICEHOUND = "毛が真っ白なの！",
        INSANITYROCK = {
            ACTIVE = "正気が低いと起きるの。",
            INACTIVE = "開いてるの。"
        },
        JAMMYPRESERVES = "ゆっくり食べるの！",
        KABOBS = "串に刺したお肉なの！",
        KILLERBEE = {
            GENERIC = "ハチミツバチじゃないの！\nどうしてハチとアシナガバチが一緒にいるの？",
            HELD = "赤い悪魔なの！"
        },
        KNIGHT = "ムシャのポニーじゃないの！",
        KOALEFANT_SUMMER = "ゾウさ…なんだっけ？",
        KOALEFANT_WINTER = "ゾウさ…なんだっけ？",
        KRAMPUS = "悪魔なの！",
        KRAMPUS_SACK = "ムシャより大きいの！",
        LAVAE = "火をつけるのが好きなの…ムシャ、あれきらいなの…",
        LEIF = "歩く木なの！",
        LEIF_SPARSE = "歩く木なの！",
        LIGHTNING_ROD = {
            CHARGED = "わっ、帯電した鉄なの！触っちゃだめなの！",
            GENERIC = "これで周りはカミナリから安全なの。"
        },
        LITTLE_WALRUS = "武器を持ってない赤ちゃんが、お父さんについてくるの！",
        LIVINGLOG = "これは古い木からなの。",
        LOCKEDWES = "捕まっちゃってるの！",
        LOG = {
            BURNING = "火なの！燃えてるの！",
            GENERIC = "木はすごく便利なの！何を作ろうかな？"
        },
        LUREPLANT = "この植物、お腹がすごく大きいの。",
        LUREPLANTBULB = "これでムシャのものなの。",
        MALE_PUPPET = "…ウィルソンみたいなの？",
        MANDRAKE = {
            DEAD = "人のような顔に、葉っぱの髪なの。",
            GENERIC = "これはニンジンとはちょっとちがうの。",
            PICKED = "人のような顔に、葉っぱの髪なの。"
        },
        COOKEDMANDRAKE = "今度はマンドレイクを焼いたの。\nでもムシャはマンドレイクスープのほうが好きなの。",
        MANDRAKESOUP = "マンドレイクスープ！かんぺきなの！",
        MARBLE = "うっ…重いの！",
        MARBLEPILLAR = "いい感じなの。",
        MARBLETREE = "だれが、なんのために作ったの？",
        MARSH_BUSH = {
            BURNING = "火なの！火！ねえ、ムシャ、水がいるの！",
            GENERIC = "トゲが多すぎるの！",
            PICKED = "ムシャ、これに興味ないの。"
        },
        MARSH_PLANT = "このあたりはトゲトゲの植物ができるの。",
        MARSH_TREE = {
            BURNING = "あっ、これはムシャのせいじゃないの。",
            BURNT = "燃えた木は、みんな炭になるの。",
            CHOPPED = "切り株だけ残ったの。",
            GENERIC = "あの木、具合が悪そうなの。"
        },
        MAXWELL = "背が高いの。",
        MAXWELLHEAD = "べらべらべらなの。",
        MAXWELLLIGHT = "ひとりでに光ったの！",
        MAXWELLLOCK = "ふむ、鍵がいるの。",
        MAXWELLTHRONE = "あぶなそうなの…",
        MEAT = "今でも食べられるけど、ジャーキーのほうがよくて、焼いたのがいちばんなの。",
        MEATBALLS = "ミートボールなの！",
        MEAT_DRIED = "ムシャ、これ好きなの！",
        MERM = "あっ、ムシャのこときらいみたいなの。",
        MONSTERLASAGNA = "食べものだけど、ムシャには体に悪いの。\nだれか他の人が食べたらいいの。",
        MONSTERMEAT = "だれがこんなの食べるの？うえっ。",
        MONSTERMEAT_DRIED = "いやなにおいは消えたの。\nでもまだ…「よくはない」の。",
        MOSQUITO = {
            GENERIC = "ムシャの血はおいしくないの！",
            HELD = "これでムシャのものなの。もう刺されないの！"
        },
        MOSQUITOSACK = "ふわふわなの！",
        MOUND = {
            DUG = "だれも安らかに眠れないの。\nだれか死んだら、何度でもやり直すの…",
            GENERIC = "だれのお墓なの？"
        },
        MULTIPLAYER_PORTAL = "これははじまりであり終わりなの。\nアルファでありオメガなの。",
        NIGHTLIGHT = "燃料は、人の悪夢なの。",
        NIGHTMAREFUEL = "小さな恐怖が、まだ生きてるの！",
        NIGHTSWORD = "ムシャの悪夢の剣で、本物の悪夢を倒せるの！",
        NITRE = "他の人は火薬にするけど、\nムシャは装備の修理に使えるの。",
        ONEMANBAND = "さぁ、おどってあそぶの！",
        PANDORASCHEST = "古い時代のチェストなの？どうしてここに？",
        PANFLUTE = "眠れ、けものさんなの。",
        PAPYRUS = "便利な植物なの！ムシャは紙を作れるの！",
        PENGUIN = "陸でも滑ってるの！信じられる？",
        PERD = "だれかベリーかキノコ持ってないの？\nそれであの鳥をおびき寄せられるの。",
        PEROGIES = "占いクッキーなの！…あ、中にお肉が入ってるの？",
        PETALS = "いいにおいなの。でもお腹はふくれないの。",
        PETALS_EVIL = "うえっ、この花すごいくさいの。まわりのとちがうの。",
        PHLEGM = "なにこれ…どうすればいいの？",
        PICKAXE = "石を掘って、家を建てるの！",
        PIGGYBACK = "大きくて、火にも水にも強いリュックなの！",
        PIGKING = "この人、金をいっぱい持ってるの！物々交換するの！",
        PIGMAN = {
            DEAD = "死んだブタ男は、ただのブタなの。",
            FOLLOWER = "行くの！木を切って、クモを倒すの！",
            GENERIC = "ムシャには親切なの。",
            GUARD = "もう、やめてなの！",
            WEREPIG = "もうブタ男じゃないの！モンスターなの！"
        },
        PIGSKIN = "ブタの皮なの！",
        PIGTORCH = "たいまつを飾るのが好きみたいなの。",
        PINECONE = {
            GENERIC = "常緑樹のタネなの。",
            PLANTED = "もうすぐ大きな木になるの。"
        },
        PITCHFORK = "ムシャは芝生をはがせるの。",
        PLANTMEAT = "うえっ、溶けはじめてるの。",
        PLANTMEAT_COOKED = "あっ、お肉のにおいがするの！",
        PLANT_NORMAL = {
            GENERIC = "野菜…野菜なの。",
            GROWING = "育て〜育て〜なの。",
            READY = "できたの！摘まないとね！",
            WITHERED = "からからなの…抜いてあげないとね。"
        },
        POMEGRANATE = "リンゴじゃないの！ザクロなの！",
        POMEGRANATE_COOKED = "体にいいの。\nじゃあ、もう食べていいの？",
        POMEGRANATE_SEEDS = "小さなルビー色のタネなの。",
        POOP = "うっ…使うと汚れるし、すごいくさいの…でも便利なの。",
        PUMPKIN = "カボチャなの！ムシャはジャック・オー・ランタンが好きなの！",
        PUMPKINCOOKIE = "カボチャのクッキーなの！",
        PUMPKIN_COOKED = "やさしく焼けたの。",
        PUMPKIN_LANTERN = "ハウンドの顔みたいなの。でしょ？",
        PUMPKIN_SEEDS = "カボチャがもっと必要なの？",
        PURPLEGEM = "紫の宝石は、世界を狂わせるの。",
        RABBIT = {
            GENERIC = "速いの！でもムシャ、いいこと思いついたの！",
            HELD = "どうするの？殺すの？育てるの？"
        },
        RABBITHOLE = {
            GENERIC = "聞こえた？まだ中にウサギがいるの。",
            SPRING = "この穴は雪でいっぱいだったの。でもウサギはまだ中にいるの。"
        },
        RATATOUILLE = "お肉はどこなの？ないの？あ〜…",
        RAZOR = "ムシャが髪を剃ってあげるの！",
        REDGEM = "赤い宝石は、命と火のしるしなの。",
        RED_CAP = "あざやかな色のキノコは、ふつう毒なの。",
        RED_CAP_COOKED = "役に立たないの。でしょ？",
        RED_MUSHROOM = {
            GENERIC = "あざやかな色のキノコには、ふつう毒があるの。",
            INGROUND = "昼だけ地面から出てくるの。",
            PICKED = "だれかがキノコを摘んだの。"
        },
        REEDS = {
            BURNING = "火なの！だれかムシャを助けてなの！",
            GENERIC = "葦は主に、ダーツと包帯の材料なの。",
            PICKED = "もっと手に入ればいいのにな。"
        },
        RELIC = {
            GENERIC = "ふむ。ムシャ、持っていけるの？",
            BROKEN = "修理が必要なの。"
        },
        RUBBLE = "時間が飛ぶように過ぎるの。",
        RESURRECTIONSTONE = "復活じゃないの。\nムシャをもう一度死なせるだけなの。",
        ROBIN = {
            GENERIC = "赤い鳥なの。火の色で、ヤムチェみたいなの。",
            HELD = "どうするの？入れるカゴはどこなの？"
        },
        ROBIN_WINTER = {
            GENERIC = "あの青い鳥は体があったかいの。ヤムチェはちがうの。ふしぎなの。",
            HELD = "どうするの？入れるカゴはどこなの？"
        },
        ROBOT_PUPPET = "だれも死から逃げられないの。",
        ROCK_LIGHT = {
            -- what the flame blast?
            GENERIC = "どうしてこうなったのか、ムシャにはわからないの。",
            OUT = "明かりが消えたの。",
            LOW = "溶岩が冷えてるの。",
            NORMAL = "うん、すごくすごく熱いの。"
        },
        ROCKS = "これでいろんなものが作れるの。",
        ROOK = "鋼鉄のサイなの！",
        ROPE = "これで結べるの！",
        ROTTENEGG = "腐った卵はくさいけど使えるの。\nとくに火薬を作るのに。",
        SANITYROCK = {
            ACTIVE = "正気が高いと起きるの。",
            INACTIVE = "開いてるの。"
        },
        --adds 2 start
        SCARECROW = {
            GENERIC = "おめかししたけど、鳴くところがないの。",
            BURNING = "だれかがあのかかしに一杯くわせたの。",
            BURNT = "だれかがあのかかしを殺したの！"
        },
        SCULPTINGTABLE = {
            EMPTY = "これで石の彫刻が作れるの。",
            BLOCK = "彫る準備できたの。",
            SCULPTURE = "傑作なの！",
            BURNT = "すっかり燃えたの。"
        },
        SCULPTURE_KNIGHTHEAD = "残りはどこなの？",
        SCULPTURE_KNIGHTBODY = {
            COVERED = "へんな大理石の像なの。",
            UNCOVERED = "プレッシャーでひび割れたみたいなの。",
            FINISHED = "少なくとも、元に戻ったの。",
            READY = "中でなにか動いてるの。"
        },
        SCULPTURE_BISHOPHEAD = "これ、頭なの？",
        SCULPTURE_BISHOPBODY = {
            COVERED = "古く見えるけど、新しい感じなの。",
            UNCOVERED = "大きな部分が足りないの。",
            FINISHED = "で、どうするの？",
            READY = "中でなにか動いてるの。"
        },
        SCULPTURE_ROOKNOSE = "これ、どこから来たの？",
        SCULPTURE_ROOKBODY = {
            COVERED = "大理石の像みたいなの。",
            UNCOVERED = "状態はあんまりよくないの。",
            FINISHED = "直ったの。",
            READY = "中でなにか動いてるの。"
        },
        GARGOYLE_HOUND = "ムシャを見る目がいやなの。",
        GARGOYLE_WEREPIG = "すごく生きてるみたいなの。",
        --adds 2 end

        SAPLING = {
            BURNING = "ウィロー！？また火をつけてるの！？",
            WITHERED = "水がいるの。それかうんちなの。",
            GENERIC = "これは必需品なの。",
            PICKED = "ムシャのために、いつでも生えてくるの。"
        },
        SEEDS = "お肉か、野菜か。それが問題なの。",
        SEEDS_COOKED = "お腹をふくらませられるの。見つけやすいの。",
        SEWING_KIT = "ムシャは服を縫えるの！",
        SHOVEL = "ムシャは掘り出せるの！",
        SILK = "ムシャはいつもクモと戦ってるから、\n糸が山ほどあるの。",
        SKELETON = "魂は別の世界で苦しんでるの。",
        --SKELETON_PLAYER = "That gives me the willies.",

        SKELETON_PLAYER = {
            MALE = "%sの亡骸なの。原因は%sなの。",
            FEMALE = "%sの骨なの。原因は%sなの。",
            ROBOT = "%sの残骸なの。原因は%sなの。",
            DEFAULT = "%sの亡骸なの。原因は%sなの。"
        },
        SKULLCHEST = "なんのためなの？このデザイン、悪い予感がするの！", --what was that?
        SMALLBIRD = {
            GENERIC = "ヤムチェにちょっと似てるの。",
            HUNGRY = "お腹すいたの？",
            STARVING = "待って待って。ムシャは知ってるの、お腹ペコペコなの。"
        },
        SMALLMEAT = "脚か、体か、頭か、羽みたいなの。",
        SMALLMEAT_DRIED = "いいにおいなの！",
        SPAT = "ヒツジ？ちがうの…サイ？ううん…",
        SPEAR = "ムシャ、戦うの！",
        SPIDER = {
            DEAD = "強くなるには、もっとクモがいるの。",
            GENERIC = "倒しやすくて、練習にちょうどいいの！",
            SLEEPING = "クモが寝てるの。そっと近づくの？それとも放っておくの？"
        },
        SPIDERDEN = "ムシャ、あれこわくないの！",
        SPIDEREGGSACK = "ムシャの庭に持って行けるの。",
        SPIDERGLAND = "これでムシャは治るの！\nそれに回復薬も作れるの！",
        SPIDERHAT = "ムシャがお母さんなの！",
        SPIDERQUEEN = "大きなお母さんグモなの。ムシャには経験値の山なの！",
        SPIDER_WARRIOR = {
            DEAD = "がんばったけど、ムシャが強すぎたの！",
            GENERIC = "遠くから飛びかかって噛んでくるの。気をつけないとね。",
            SLEEPING = "戦士が寝てるの。今度はムシャが飛びかかる番なの？"
        },
        SPOILED_FOOD = "ムシャ、まずいって言ったの。",
        STATUEHARP = "ハープなの？ムシャ、はじめて見たの。",
        STATUEMAXWELL = "この人がムシャをここに閉じこめたの…きらいなの。",
        STEELWOOL = "セーターでも編むの？…え、冗談なの！",
        STINGER = "小さなハチの針なの。",
        STRAWHAT = "わらでできてるのに、濡れないし涼しいの。",
        SUNKBOAT = "この船、どうなったの？",
        SWEATERVEST = "おしゃれなベストなの！",
        TAFFY = "ムシャにお菓子が増えたの！",
        TALLBIRD = "すごく背の高い黒い鳥なの。ときどき凶暴なの！",
        TALLBIRDEGG = "大きな青い卵なの。",
        TALLBIRDEGG_COOKED = "ひとりで食べるには大きすぎるの。でもムシャはお腹ペコペコだから食べられちゃうの。",
        TALLBIRDEGG_CRACKED = {
            COLD = "卵はもっとあったかいほうがいいの！",
            GENERIC = "ヤムチェと同じように育つの！",
            HOT = "熱すぎて孵らないの！",
            LONG = "どれくらいかかるの？",
            SHORT = "なにか聞こえるの。もうすぐ孵りそうなの！"
        },
        TALLBIRDNEST = {
            GENERIC = "見た？大きな卵なの！",
            PICKED = "怒った鳥の卵がなくなったの。"
        },
        TEENBIRD = {
            GENERIC = "あの鳥、なにかほしがってるみたいなの…",
            HUNGRY = "あの鳥はいつもお腹をすかせてるの。",
            STARVING = "ムシャをつつかないでなの！\nごはんあげたのに！"
        },
        TELEPORTATO_BASE = {
            ACTIVE = "ムシャは画面ごしに会いたかっただけなの。",
            GENERIC = "ワープゲートなの？",
            LOCKED = "使う前に何かがいるの。",
            PARTIAL = "次の世界へなの！"
        },
        TELEPORTATO_BOX = "びっくり箱なの！",
        TELEPORTATO_CRANK = "これ、どこにつながるの？",
        TELEPORTATO_POTATO = "ただの金属なの。",
        TELEPORTATO_RING = "大きな輪っかなの。",
        TENTACLE = "イカの脚みたいなの。",
        TENTACLESPOTS = "中に何かいるの！ムシャ、持ってないとだめなの？",
        TENTACLESPIKE = "あっ、トゲがついてるの。なんていい感じなの！",
        TENTACLE_PILLAR = "あれ、生きてるの！",
        TENTACLE_PILLAR_ARM = "ムシャをさわらないでなの！",
        TENTACLE_GARDEN = "なにか掘ってる音がしたの。",
        TOPHAT = "紳士の帽子なの。",
        TORCH = "暗くなければ、こわくないの！",
        TRAP = "ウサギとカエルとクモ用なの。",
        TRAP_TEETH = "ハウンドとペンギルとモスリングを倒す用なの。",
        TRAP_TEETH_MAXWELL = "なにこれ？地雷なの？\nムシャがあぶないの？",
        TRINKET_1 = "モンスターにはあまり効かないの。\nだれか興味あるかな？",
        -- Melty Marbles
        TRINKET_10 = "歯なの？噛むには弱すぎるの。",
        -- Second-hand Dentures
        TRINKET_11 = "おもちゃなの！",
        -- Lying Robot
        TRINKET_12 = "その触手はかたくて食べられないの。",
        --Dessicated Tentacle
        TRINKET_13 = "好きな人もいるけど、ムシャはちがうの。",
        TRINKET_2 = "風のオカリナ…えっ？ムシャ、吹けないの。",
        --Fake Kazoo
        TRINKET_3 = "結び目がほどけないなら、切ればいいの。",
        --Gord's Knot
        TRINKET_4 = "ノーム ノーム ノーム〜 小さなノーム〜なの。",
        --Gnome
        TRINKET_5 = "核のお昼ごはん？どういう意味なの？", --starcraft
        TRINKET_6 = "暗殺？ワイヤーで？これワイヤーなの？\nムシャ、興味ないの。",
        --Frazzled Wires
        TRINKET_7 = "カップにボールを入れられる？",
        -- Ball and Cup
        TRINKET_8 = "これ知ってるの…えっと、小さなフレイルの部品なの。",
        -- Hardened Rubber Bung
        TRINKET_9 = "このボタンで像を飾るの！",
        --Mismatched Buttons
        --adds 3 start
        TRINKET_10 = "ウェスのお気に入りの小道具になったの。", --Dentures
        TRINKET_11 = "ハルはムシャに、きれいな嘘をささやくの。", --Lying Robot
        TRINKET_12 = "実験してって言ってるみたいなの。", --Dessicated Tentacle
        TRINKET_13 = "宗教的なものにちがいないの。", --Gnomette
        TRINKET_14 = "お茶があればなあ…なの。", --Leaky Teacup
        TRINKET_15 = "…またマクスウェルが置きっぱなしにしてるの。", --Pawn
        TRINKET_16 = "…またマクスウェルが置きっぱなしにしてるの。", --Pawn
        TRINKET_17 = "恐ろしい道具の合体なの。科学も行きすぎることがあるのね。", --Bent Spork
        TRINKET_18 = "なにを隠してるのかな？", --Trojan Horse
        TRINKET_19 = "あんまりうまく回らないの。", --Unbalanced Top
        TRINKET_20 = "ウィグフリッドがいつも飛び出して、これでムシャを叩くの！？", --Backscratcher
        TRINKET_21 = "この卵まぜ、ぜんぶ曲がっちゃってるの。", --Egg Beater
        TRINKET_22 = "このひもには、いくつか説があるの。", --Frayed Yarn
        TRINKET_23 = "ムシャ、ひとりで靴を履けるの。ありがとね。", --Shoehorn
        TRINKET_24 = "ウィッカーボトムはネコを飼ってたんだと思うの。", --Lucky Cat Jar
        TRINKET_25 = "なんだか古いにおいがするの。", --Air Unfreshener
        TRINKET_26 = "食べものとカップ！究極のサバイバル容器なの。", --Potato Cup
        TRINKET_27 = "ほどいたら、すごく遠くから誰かをつつけるの。", --Coat Hanger
        TRINKET_28 = "なんてマキャベリ的（ずる賢い）なの。", --Rook
        TRINKET_29 = "なんてマキャベリ的（ずる賢い）なの。", --Rook
        TRINKET_30 = "ほんとに、そこらへんに置きっぱなしなの。", --Knight
        TRINKET_31 = "ほんとに、そこらへんに置きっぱなしなの。", --Knight
        TRINKET_32 = "これで夢中になる人を、ムシャは知ってるの！", --Cubic Zirconia Ball
        TRINKET_33 = "これでクモが寄ってこないといいの。", --Spider Ring
        TRINKET_34 = "お願いしよう。科学のために。", --Monkey Paw
        TRINKET_35 = "いいフラスコは、なかなか見つからないの。", --Empty Elixir
        TRINKET_36 = "あんなにキャンディを食べたから、これがいるの。", --Faux fangs
        TRINKET_37 = "ムシャは超常現象なんて信じないの。", --Broken Stake
        TRINKET_38 = "別の世界から来たんだと思うの。インチキのある世界の。", -- Binoculars Griftlands trinket
        TRINKET_39 = "もう片方はどこなの？", -- Lone Glove Griftlands trinket
        TRINKET_40 = "持ってると、物々交換したくなるの。", -- Snail Scale Griftlands trinket
        TRINKET_41 = "触ると、ちょっとあたたかいの。", -- Goop Canister Hot Lava trinket
        TRINKET_42 = "だれかの子どもの頃の思い出でいっぱいなの。", -- Toy Cobra Hot Lava trinket
        TRINKET_43 = "あんまりうまく跳べないの。", -- Crocodile Toy Hot Lava trinket
        TRINKET_44 = "植物の標本みたいなの。", -- Broken Terrarium ONI trinket
        TRINKET_45 = "別の世界の電波を受けてるの。", -- Odd Radio ONI trinket
        TRINKET_46 = "空気力学を試す道具なのかな？", -- Hairdryer ONI trinket
        HALLOWEENCANDY_1 = "虫歯になっても、その価値はあるの…よね？",
        HALLOWEENCANDY_2 = "科学のどんな歪みが、これを育てたの？",
        HALLOWEENCANDY_3 = "これは…トウモロコシなの。",
        HALLOWEENCANDY_4 = "飲みこむ途中で動くの。",
        HALLOWEENCANDY_5 = "明日、ムシャの歯が文句を言うの。",
        HALLOWEENCANDY_6 = "ムシャ…これは食べないと思うの。",
        HALLOWEENCANDY_7 = "みんながこれで騒ぐの。",
        HALLOWEENCANDY_8 = "これがきらいなのは、すっぱいのだけなの。",
        HALLOWEENCANDY_9 = "歯にくっつくの。",
        HALLOWEENCANDY_10 = "これがきらいなのは、すっぱいのだけなの。",
        HALLOWEENCANDY_11 = "本物よりずっとおいしいの。",
        HALLOWEENCANDY_12 = "今、あのキャンディ動いた？", --ONI meal lice candy
        HALLOWEENCANDY_13 = "ああ、ムシャのかわいそうなアゴなの。", --Griftlands themed candy
        HALLOWEENCANDY_14 = "ムシャは辛いの苦手なの。", --Hot Lava pepper candy
        CANDYBAG = "甘いお菓子のための、おいしいポケット次元なの。",
        DRAGONHEADHAT = "で、頭になるのはだれなの？",
        DRAGONBODYHAT = "ムシャはこの真ん中のパーツ、まあまあなの。",
        DRAGONTAILHAT = "だれかがしんがりをやらないとね。",
        PERDSHRINE = {
            GENERIC = "なにかほしがってるみたいなの。",
            EMPTY = "ここに何か植えないとね。",
            BURNT = "これじゃだめなの。"
        },
        REDLANTERN = "このランタン、他より特別な感じがするの。",
        LUCKY_GOLDNUGGET = "なんてラッキーな発見なの！",
        FIRECRACKERS = "爆発の科学がつまってるの！",
        PERDFAN = "めちゃくちゃ大きいの。",
        REDPOUCH = "中に何か入ってるの？",
        WARGSHRINE = {
            GENERIC = "なにか楽しいものを作るの。",
            EMPTY = "たいまつを入れないとね。",
            BURNT = "燃えちゃったの。"
        },
        CLAYWARG = {
            GENERIC = "テラコッタの怪物なの！",
            STATUE = "今、動いた？"
        },
        CLAYHOUND = {
            GENERIC = "解き放たれたの！",
            STATUE = "すごく本物みたいなの。"
        },
        HOUNDWHISTLE = "これで犬も足を止めるの。",
        CHESSPIECE_CLAYHOUND = "あれの心配は、まだマシなほうなの。",
        CHESSPIECE_CLAYWARG = "それにムシャ、食べられなかったの！",
        BISHOP_CHARGE_HIT = "いたっ！",
        --adds 3 end
        TRUNKVEST_SUMMER = "あたたかくて水を防ぐベストなの！",
        TRUNKVEST_WINTER = "ベストの中身は手に入りにくいって言うけど、\nムシャ、できたの。",
        TRUNK_COOKED = "これ食べるの？どうして？",
        TRUNK_SUMMER = "長い鼻なの！",
        TRUNK_WINTER = "長い鼻なの！",
        UMBRELLA = "ムシャ、この色が好きなの！",
        WAFFLES = "やあ、ワッフルさん！食べる時間なの！",
        WALL_HAY_ITEM = "ふむ。燃えやすくないか心配なの。",
        WALL_STONE = "これなら安全なの…",
        --0
        WALL_STONE_ITEM = "重そうだけど、ムシャは気にしないの。",
        WALL_RUINS = "黄色い石の壁なの！",
        --0
        WALL_RUINS_ITEM = "重そうだけど、ムシャは気にしないの。",
        WALL_WOOD_ITEM = "木の壁なの。わらよりいいの。",
        WALRUS = "近くにいてなの！あの人、ダーツしか持ってないの！",
        WALRUSHAT = "かんぺきなの。",
        WALRUS_CAMP = {
            EMPTY = "だれかがここに住んでたの。",
            GENERIC = "ムシャ、あんな家に住みたいの！"
        },
        WALRUS_TUSK = "大きくて、つるつるなの。",
        WARG = "兄弟を連れてきなさいなの。",
        WASPHIVE = "とてもあぶなそうなの。",
        WETGOOP = "ムシャは悪くないの。",
        WINTERHAT = "冬の基本装備なの。",
        WORMHOLE = {
            GENERIC = "そっちはしっぽなの？それとも頭なの？",
            OPEN = "あれが安全かどうか、ムシャにはわからないの。"
        },
        ACCOMPLISHMENT_SHRINE = "ムシャ、あの矢がいやなの！"
    },
    DESCRIBE_TOODARK = "光の粉はどこなの？\nムシャ、もっと明かりがいるの！",
    DESCRIBE_SMOLDERING = "おおおおお！",
    EAT_FOOD = {
        TALLBIRDEGG_CRACKED = "これもおいしいけど、お肉のほうがいいの。"
    }
}
