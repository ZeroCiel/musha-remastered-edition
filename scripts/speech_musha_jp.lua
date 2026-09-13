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
            FIRESTARTER = 'You can\'t actually "fight" fire, %s!'
        },
        WAXWELL = {
            GENERIC = "%s、いい日に会えてうれしいの！",
            ATTACKER = 'Seems you\'ve gone from "dapper" to "slapper".',
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
            GHOST = 'Does "universal" coverage include the void, %s?',
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
            GHOST = 'How do you say "I\'ll concoct a revival device" in mime?',
            FIRESTARTER = "あ、言わなくていいの。火をつけたのね。"
        },
        WEBBER = {
            GENERIC = "%s、こんにちはなの！",
            ATTACKER = "ムシャ、新聞をつくるくる丸めておくの。念のためなの。",
            MURDERER = "ひとごろし！%s、ムシャがぺしゃんこにしてあげるの！",
            REVIVER = "%s、みんなと仲良くできてるの！",
            GHOST = "%s is really buggin' me for a heart.",
            FIRESTARTER = "We need to have a group meeting about fire safety."
        },
        WATHGRITHR = {
            GENERIC = "Good day, %s!",
            ATTACKER = "Musha doesn't want a punch from %s, if possible.",
            MURDERER = "%s's gone berserk!",
            REVIVER = "%s has full command of spirits.",
            GHOST = "Nice try. You're not escaping to Valhalla yet, %s.",
            FIRESTARTER = "%s is really heating things up today."
        },
        WINONA = {
            GENERIC = "Good day to you, %s!",
            ATTACKER = "%s is a safety hazard.",
            MURDERER = "It ends here, %s!",
            REVIVER = "You're pretty handy to have around, %s.",
            GHOST = "Looks like someone threw a wrench into your plans.",
            FIRESTARTER = "Things are burning up at the factory."
        },
        MIGRATION_PORTAL = {
            GENERIC = "If Musha had any friends, this could take me to them.",
            OPEN = "If Musha would step through, will Musha still be Musha?",
            FULL = "It seems to be popular over there."
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
        GHOSTHOUND = "Let's go, ghost buddy!",
        GHOSTHOUND2 = "Oh, Musha didn't mean to call it.",
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
        GLOWDUST = "Tastes like sugar.",
        CRISTAL = "Twinkle candy!",
        EXP = "This is essence!",
        --EXP1000CHEAT = "Show me the money!", -- Starcraft

        BOOK_BIRDS = "Is this written in the language of birds?",
        BOOK_TENTACLES = "It tells Musha how to grow a big earthworm.",
        BOOK_GARDENING = "Plants love this book.",
        BOOK_SLEEP = "A really boring book, it makes Musha sleepy",
        BOOK_BRIMSTONE = "Not a good book..",
        GLOMMER = "That kitty has wings! It can fly!",
        GLOMMERFLOWER = {
            GENERIC = "Huge flower! How did it bloom?",
            DEAD = "The flower is grey? But it was red before!"
        },
        GLOMMERWINGS = "They're so small!",
        GLOMMERFUEL = "Can Musha eat this? No? Why?",
        BELL = "Is this a dinner bell? Who is the one who gives Musha's food?",
        STATUEGLOMMER = {
            GENERIC = "Musha knows that! Um... What was it again?",
            EMPTY = "Musha saw flower a few weeks ago."
        },
        WEBBERSKULL = "This skull seems to have a story.",
        MOLE = {
            HELD = "Look at this! It has a funny nose! ",
            UNDERGROUND = "Something is hiding under here.\nMusha will chase it.",
            ABOVEGROUND = "It got Musha's item!"
        },
        MOLEHILL = "Something is in there. Musha knows that.",
        MOLEHAT = "It smells something...",
        NIGHTSTICK = "Is it useful?",
        --adds 6 start
        MUSHROOMHAT = "Makes the wearer look like a fun guy.",
        MUSHROOM_LIGHT2 = {
            ON = "Blue is obviously the most scientific color.",
            OFF = "We could make a prime light source with some primary colors.",
            BURNT = "Musha didn't mildew it, Musha swears."
        },
        MUSHROOM_LIGHT = {
            ON = "Science makes it light up.",
            OFF = "It's a big, science-y 'shroom.",
            BURNT = "Comboletely burnt."
        },
        SLEEPBOMB = "It makes snooze circles when Musha throws it.",
        MUSHROOMBOMB = "A mushroom cloud in the making!",
        SHROOM_SKIN = "Warts and all!",
        TOADSTOOL_CAP = {
            EMPTY = "Just a hole in the ground.",
            INGROUND = "There's something poking out.",
            GENERIC = "That toadstool's just asking to be cut down."
        },
        TOADSTOOL = {
            GENERIC = "Yeesh! Musha is not kissing that!",
            RAGE = "He's hopping mad now!"
        },
        MUSHROOMSPROUT = {
            GENERIC = "How scientific!",
            BURNT = "How im-morel!"
        },
        MUSHTREE_TALL = {
            GENERIC = "That mushroom got too big for its own good.",
            BLOOM = "You can't tell from far away, but it's quite smelly."
        },
        MUSHTREE_MEDIUM = {
            GENERIC = "These used to grow in Musha's bathroom.",
            BLOOM = "Musha is mildly offended by this."
        },
        MUSHTREE_SMALL = {
            GENERIC = "A magic mushroom?",
            BLOOM = "It's trying to reproduce."
        },
        MUSHTREE_TALL_WEBBED = "The spiders thought this one was important.",
        SPORE_TALL = {
            GENERIC = "It's just drifting around.",
            HELD = "Musha will keep a little light in Musha's pocket."
        },
        SPORE_MEDIUM = {
            GENERIC = "Hasn't a care in the world.",
            HELD = "Musha will keep a little light in Musha's pocket."
        },
        SPORE_SMALL = {
            GENERIC = "That's a sight for spore eyes.",
            HELD = "Musha will keep a little light in Musha's pocket."
        },
        BEEQUEEN = "Keep that stinger away from Musha!",
        BEEQUEENHIVE = {
            GENERIC = "It's too sticky to walk on.",
            GROWING = "Was that there before?"
        },
        BEEQUEENHIVEGROWN = "How in science did it get so big?!",
        BEEGUARD = "It's guarding the queen.",
        HIVEHAT = "The world seems less a little crazy when Musha wears it.",
        MINISIGN = {
            GENERIC = "Musha could draw better than that!",
            UNDRAWN = "We should draw something on there."
        },
        MINISIGN_ITEM = "It's not much use like this. We should place it.",
        BERRYBUSH_JUICY = {
            BARREN = "It won't make any berries in this state.",
            WITHERED = "The heat even dehydrated the juicy berries!",
            GENERIC = "Musha should leave them there until it's time to eat.",
            PICKED = "The bush is working hard on the next batch.",
            DISEASED = "It looks pretty sick.",
            DISEASING = "Err, something's not right.",
            BURNING = "It's very much on fire."
        },
        CANARY = {
            GENERIC = "Some sort of yellow creature made of science.",
            HELD = "Musha is not squishing you... Right?"
        },
        CANARY_POISONED = "It's probably fine.",
        CRITTERLAB = "Is there something in there?",
        CRITTER_GLOMLING = "What an aerodynamical creature!",
        CRITTER_DRAGONLING = "It's wyrmed its way into Musha's heart.",
        CRITTER_LAMB = "Much less mucusy than its momma.",
        CRITTER_PUPPY = "Pretty cute for a lil monster!",
        CRITTER_KITTEN = "You'd make a good lab assistant for Musha.",
        CRITTER_PERDLING = "My feathered friend.",
        LAVA_POND = "Magmificent!",
        LAVAE = "Too hot to handle.",
        LAVAE_COCOON = "Cooled off and chilled out.",
        LAVAE_PET = {
            STARVING = "Poor thing must be starving.",
            HUNGRY = "Musha hears a tiny stomach grumbling.",
            CONTENT = "It seems happy.",
            GENERIC = "Aww. Who's a good monster?"
        },
        LAVAE_EGG = {
            GENERIC = "There's a faint warmth coming from inside."
        },
        LAVAE_EGG_CRACKED = {
            COLD = "Musha doesn't think that egg is warm enough.",
            COMFY = "Musha never thought Musha would see a happy egg."
        },
        LAVAE_TOOTH = "It's an egg tooth!",
        ENDTABLE = {
            BURNT = "A burnt vase on a burnt table.",
            GENERIC = "A flower in a vase on a table.",
            EMPTY = "Musha should put something in there.",
            WILTED = "Not looking too fresh.",
            FRESHLIGHT = "It's nice to have a little light.",
            OLDLIGHT = "Did we remember to pick up new bulbs?" -- will be wilted soon, light radius will be very small at this point
        },
        TWIGGYTREE = {
            BURNING = "What a waste of wood.",
            BURNT = "Musha feel like Musha could have prevented that.",
            CHOPPED = "Take that, nature!",
            GENERIC = "It's all stick-y.",
            DISEASED = "It looks sick. More so than usual."
        },
        TWIGGY_NUT_SAPLING = "It doesn't need any help to grow.",
        TWIGGY_OLD = "That tree looks pretty wimpy.",
        TWIGGY_NUT = "There's a stick-y tree inside it that wants to get out.",
        FLOWER_WITHERED = "Musha doesn't think it got enough sun.",
        FOSSIL_PIECE = "Science bones! We should put them back together.",
        FOSSIL_STALKER = {
            GENERIC = "Still missing some pieces.",
            FUNNY = "My scientific instincts say this isn't quite right.",
            COMPLETE = "It's alive! Oh wait, no, it's not."
        },
        STALKER = "The skeleton fused with the shadows!",
        STALKER_ATRIUM = "Why'd it have to be so big?",
        STALKER_MINION = "Anklebiters!",
        THURIBLE = "It smells like chemicals.",
        ATRIUM_OVERGROWTH = "Musha don't recognize any of these symbols.",
        LUCY = "That's a prettier axe than Musha is used to.",
        MINIFAN = "Somehow the breeze comes out the back twice as fast.",
        OASISLAKE = "Is that a mirage?",
        PINECONE_SAPLING = "It'll be a tree soon!",
        LUMPY_SAPLING = "How did this tree even reproduce?",
        --adds 6 end

        RABBITHOUSE = {
            GENERIC = "Rabbits live in there.",
            BURNT = "No one lives in there.\nBut Musha can find someone."
        },
        TURF_DECIDUOUS = "Many rotten leaves.",
        TURF_SANDY = "Sand is useful for hiding!",
        TURF_BADLANDS = "Too hard!",
        BEARGER = "How can Musha grow big like you?",
        BEARGERVEST = "Fuzzy dress!.",
        ICEPACK = "Fuzzy backpack!",
        BEARGER_FUR = "Just fur, but Musha has an idea.",
        FURTUFT = "*cough* Musha ate the fur!",
        BIGFOOT = "That's a huge footstep!",
        BONESHARD = "It is piece of bone.",
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
            NOHONEY = "Musha has to wait for the liquid gold.",
            SOMEHONEY = "Oh, the bees are still working.",
            BURNT = "Musha doesn't like burnt honey..."
        },
        LIVINGTREE = "The face on that tree makes it seem alive to Musha.",
        ICESTAFF = "It makes Musha safe.",
        WORMLIGHT = "Musha can mix it with things, but Musha likes glow dust better.",
        WORM = {
            PLANT = "Cool light. But it looks like a plant.",
            DIRT = "Something is moving underground!",
            WORM = "Ow! What was that!?"
        },
        EEL = "Long, strange, and green fish.",
        EEL_COOKED = "It has an odd smell...",
        UNAGI = "Musha didn't do much, but unagi is done already!",
        EYETURRET = "Tall eyebone, He can beat everything.",
        EYETURRET_ITEM = "It's just tiny toy, but grow bigger and activate when it set on ground.",
        MINOTAURHORN = "It is symbol of a conqueror deep in the shadowy cave.",
        MINOTAURCHEST = "A huge chest! It is taller than Musha!",
        THULECITE_PIECES = "If Musha has some more of that,\n Musha can build thulecite items.",
        POND = "Let's go fishing!",
        POND_ALGAE = "It lives and grows in dark and humid places.",
        GREENSTAFF = "It rewinds time of structures and items\n returning to Musha what was used to build it.",
        POTTEDFERN = "It doesn't do anything, but it looks pretty.",
        THULECITE = "It is old one.",
        ARMORRUINS = "It is heavy, but safe.",
        RUINS_BAT = "Strongest stone bat Musha knows.",
        RUINSHAT = "It is crown that easy to make.",
        NIGHTMARE_TIMEPIECE = {
            --Keeps track of the nightmare cycle
            CALM = "Nothing is going on, there is no problem here.", --Calm phase
            WARN = "It's a warning to Musha.", --Before nightmare
            WAXING = "Uh oh... something tells Musha this place isn't safe.", --Nightmare Phase first 33%
            STEADY = "Things just keep getting worse for Musha!", --Nightmare 33% - 66%
            WANING = "Just few more minutes. Musha must last a little more.", --Nightmare 66% +
            DAWN = "Musha thinks it's nearly over.", --After nightmare
            NOMAGIC = "No magic here, no danger here." --Place with no nightmare cycle.
        },
        BISHOP_NIGHTMARE = "Why are you still here?",
        ROOK_NIGHTMARE = "Broken head, legs, eyes. But you're still moving.",
        KNIGHT_NIGHTMARE = "Abandoned soldiers.",
        MINOTAUR = "It is dangerous, but Musha knows better.", --Monster in labyrinth
        SPIDER_DROPPER = "White spiders. Their nest is on the ceiling of the cave.", --White spider that comes from the roof
        NIGHTMARELIGHT = "This light makes Musha head ache.", --Lights that activate during nightmare.
        GREENGEM = "Most important gem to Musha!",
        RELIC = "Someone fixed this.", --Fixed relic
        RUINS_RUBBLE = "Something is still missing.", --Broken relic
        MULTITOOL_AXE_PICKAXE = "How nice! Musha can break rocks and wood!", --Works as axe and pickaxe
        ORANGESTAFF = "Musha knows what this is, Musha can teleport with this", --Teleports player.
        YELLOWAMULET = "UNLIMITED POWER!", --Emits light, player walks faster.
        GREENAMULET = "50% off!", --Reduce cost of crafting
        SLURPER = "Large fluff ball!",
        SLURPER_PELT = "Do you see it? It's still looks alive!",
        ARMORSLURPER = "Too tight! This makes Musha not as hungry...",
        ORANGEAMULET = "It picks up item automatically!",
        YELLOWSTAFF = "Musha knows same things!",
        YELLOWGEM = "Shiny yellow stone.",
        ORANGEGEM = "Musha feels a strange aura.",
        TELEBASE = {
            VALID = "Wa... How can Musha do?",
            GEMS = "What does Musha have to do?"
        },
        GEMSOCKET = {
            VALID = "Musha feels a magical force from the purple gem.",
            GEMS = "Musha need more magic!"
        },
        STAFFLIGHT = "A... awesome!",
        LIGHTER = "A tiny fire starter.",
        ANCIENT_ALTAR = {
            WORKING = "It spoke directly in Musha's head.",
            BROKEN = "It is working, but need something else to be at full power."
        },
        ANCIENT_ALTAR_BROKEN = "It is working, but need something else to be at full power.",
        ANCIENT_STATUE = "Antiquity of strange looks.",
        LICHEN = "It looks like stone.",
        CUTLICHEN = "It looks spoiled.",
        CAVE_BANANA = "Musha got this in a cave.",
        CAVE_BANANA_COOKED = "BANANA!",
        CAVE_BANANA_TREE = "How can it grow in the dark?",
        ROCKY = "So huge.",
        BLUEAMULET = "This amulet feels cold!",
        PURPLEAMULET = "Musha can see dead people...",
        TELESTAFF = "Pop! Pop! Pop!",
        MINERHAT = "Musha is not miner, but it is helps Musha see in the cave.",
        MONKEY = "Chase him! He stole Musha's stuff!",
        MONKEYBARREL = "Monkeys made a house that looks like their face.",
        HOUNDSTOOTH = "It's sharp. Can make good long or short range weapons for Musha!",
        ARMORSNURTLESHELL = "Crown is better, but this is cute!",
        BAT = "Angry bat!",
        BATBAT = "Musha can hit Musha's enemies with it.",
        BATWING = "How can Musha use this? Can Musha cook it?",
        BATWING_COOKED = "It shrunk.",
        BEDROLL_FURRY = "Musha can sleep on this.",
        BUNNYMAN = "Careful, they don't like meat.",
        FLOWER_CAVE = "It is good source of light.",
        FLOWER_CAVE_DOUBLE = "It is good source of light.",
        FLOWER_CAVE_TRIPLE = "It is good source of light.",
        GUANO = "Dry white manure.",
        LANTERN = "Lantern only gives off light. Musha can't fight with it.",
        LIGHTBULB = "Bright vegetable!",
        MANRABBIT_TAIL = "small white tail!",
        MUSHTREE_TALL = "Blue evergreen.",
        MUSHTREE_MEDIUM = "Twin headed mushroom!",
        MUSHTREE_SMALL = "Gross, big headed, green mushroom.",
        SLURTLE = "These could be made to fit on Musha's head.",
        SLURTLE_SHELLPIECES = "Musha knows it is broken.",
        SLURTLEHAT = "Look at Musha! It is a stiff helmet!",
        SLURTLEHOLE = "Looks like a huge cactus.",
        SLURTLESLIME = "It is explosive!",
        SNURTLE = "It could be made to fit on Musha's body.",
        SPIDER_HIDER = "That spider has strange hat!",
        SPIDER_SPITTER = "Those spiders shoot webs!",
        SPIDERHOLE = "That is a spider nest.",
        STALAGMITE = "Old rocks that grow upwards.",
        STALAGMITE_FULL = "That old rock is so big!,\n Musha thinks she saw some jewels in there.",
        STALAGMITE_LOW = "There is a small slippery rock.",
        STALAGMITE_MED = "There is big slippery rock, it seems to be growing",
        STALAGMITE_TALL = "Tall sharp rocks.",
        STALAGMITE_TALL_FULL = "A huge sharp rock!\n Musha thinks she saw some jewels in there.",
        STALAGMITE_TALL_LOW = "There is a small sharp rock.",
        STALAGMITE_TALL_MED = "There is big sharp rock, it seems to be growing upward",
        TURF_CARPETFLOOR = "Puff puff!",
        TURF_CHECKERFLOOR = "This turf is artificial.",
        TURF_DIRT = "Plants grow on dirt.",
        TURF_FOREST = "There is a lot of moss.",
        TURF_GRASS = "Light green grass turf.",
        TURF_MARSH = "Tons of leaves!",
        TURF_ROAD = "Musha can run fast on this turf!",
        TURF_ROCKY = "Rocks are very important resources.",
        TURF_SAVANNA = "Rabbits and Beefaloes like live on this turf.",
        TURF_WOODFLOOR = "Floor made Musha feel comfortable.",
        TURF_CAVE = "White Striped Turf.",
        TURF_FUNGUS = "Looks like different depending on the area.",
        TURF_SINKHOLE = "Green Striped Turf.",
        TURF_UNDERROCK = "Rocks are separated.",
        TURF_MUD = "It is sloppy.",
        TURKEYDINNER = "Turkey, Turkey, Turkey!",
        TWIGS = "Not enough twigs!",
        POWCAKE = "Tons of MSG.",
        CAVE_ENTRANCE = {
            GENERIC = "Someone plugged something up, \n is there something down there?.",
            OPEN = "Musha has a rope. How about you?"
        },
        CAVE_EXIT = "Ropes?",
        MAXWELLPHONOGRAPH = "Play more music!",
        PIGGUARD = "He is the farm owner!",
        BOOMERANG = "Curved wood hits enemy then comes back to Musha.",
        ADVENTURE_PORTAL = "Gate? Where does this connect?",
        AMULET = "I'm invincible! Well, maybe not.\n But it feels good.",
        ANIMAL_TRACK = "Good hunting.",
        ARMORGRASS = "Cheap armor, doesn't protect Musha from much.",
        ARMORMARBLE = "Well, it's not bad.just heavy.",
        ARMORWOOD = "Standard armor for this world.",
        ARMOR_SANITY = "Does this protect Musha?",
        ASH = {
            GENERIC = "Musha doesn't know what it was, but now it is ash.",
            REMAINS_GLOMMERFLOWER = "Oh god. Old bell is gone.",
            REMAINS_EYE_BONE = "How can Musha find another eyebone?",
            REMAINS_THINGIE = "Musha misses it."
        },
        AXE = "Let's cut!",
        BABYBEEFALO = {
            GENERIC = "Don't hurt it, not yet.",
            SLEEPING = "Not yet.It's ust baby!"
        },
        BACKPACK = "It wont protect Musha, but Musha can carry more in it.",
        BACONEGGS = "Musha loves this, it's bacon AND eggs!",
        BANDAGE = "Keep it up!",
        BASALT = "Wow! It is realy hard, no way Musha can break it!",
        BEARDHAIR = "From Winson's hair, to Wilson statue.",
        BEDROLL_STRAW = "Musha can sleep on this.",
        BEE = {
            GENERIC = "It is working.",
            HELD = "Buzzz buzzzzz buzzzzz."
        },
        BEEFALO = {
            FOLLOWER = "It is chasing Musha!",
            GENERIC = "Looks heavy, dirty and slow.",
            NAKED = "Musha didn't do it. Musha doesn't know what happened.",
            SLEEPING = "where is their home?"
        },
        BEEFALOHAT = "It smells something fierce... like Beefaloes",
        BEEFALOWOOL = "Musha should keep it for winter.",
        BEEHIVE = "Honey in there. How can Musha get it?",
        BEEMINE = "Bees are inside... for now",
        BEEMINE_MAXWELL = "Instead of bees there are mosquitoes in here!",
        BEEHAT = "It will keep Musha's face safe from stings!",
        BERRIES = "Delicious red berries!",
        BERRIES_COOKED = "Cooked berries are better.",
        BERRYBUSH = {
            BARREN = "Only a bush, are there red berries in there?",
            WITHERED = "Where is rot or manure?",
            GENERIC = "It takes time to make berries!",
            PICKED = "When can Musha get berries?"
        },
        BIRDCAGE = {
            GENERIC = "Birds can live in here.",
            OCCUPIED = "There is a bird in here, Musha must feed it!",
            SLEEPING = "The bird has fallen asleep."
        },
        BIRDTRAP = "Do you want to know how Musha can get a bird?",
        BIRD_EGG = "How many eggs will be laid?",
        BIRD_EGG_COOKED = "It is good for breakfast.",
        BISHOP = "That enemy is dangerous! It can shoot at Musha!",
        BLOWDART_FIRE = "These darts are empowered with the essence fire!",
        BLOWDART_SLEEP = "This dart can make enemies easy targets for Musha.",
        BLOWDART_PIPE = "Many these darts come from walruses.",
        BLUEGEM = "Frosty.",
        BLUEPRINT = "Hmm... Is that so?",
        BELL_BLUEPRINT = "It came from the sky.",
        BLUE_CAP = "Is smells like... nothing.",
        BLUE_CAP_COOKED = "Musha cooked it with fire!",
        BLUE_MUSHROOM = {
            GENERIC = "It is a blue mushroom.",
            INGROUND = "It is a blue mushroom.",
            PICKED = "It was a blue mushroom."
        },
        BOARDS = "Wood turned into flat boards. Musha can make many things now.",
        BONESTEW = "It is the best meat stew Musha can make.",
        BUGNET = "Let's catch some bugs!",
        BUSHHAT = "No one can find Musha if Musha wears it!",
        BUTTER = "Butterfly had this butter.",
        BUTTERFLY = {
            GENERIC = "Butter fly, so butterfly!",
            HELD = "How can Musha does? Do you need butter?" --☺
        },
        BUTTERFLYMUFFIN = "This butter muffin is decorated with a butterfly.",
        BUTTERFLYWINGS = "Thin, pretty, wings.",
        CAMPFIRE = {
            EMBERS = "Musha need to put fuel in the pit.",
            GENERIC = "It gives of a soft light and warmth.",
            HIGH = "Fire flies high!",
            LOW = "Dawn will come.",
            NORMAL = "Bright fire.",
            OUT = "Musha has to turn it on?"
        },
        CANE = "Musha can move FASTER now!",
        CARROT = "Yes, Musha can eat carrots.",
        CARROT_COOKED = "Do you know the smell of cooked carrots?",
        CARROT_PLANTED = "Who planted a carrot? is there a rabbit here?",
        CARROT_SEEDS = "Seeds for a yucky orange vegetable.",
        CAVE_FERN = "Purple flowers that grow only in caves",
        CHARCOAL = "Trees can be burnt twice.",
        CHESSJUNK1 = "There are many broken things.",
        CHESSJUNK2 = "There are many broken things.",
        CHESSJUNK3 = "There are many broken things.",
        CHESTER = "He's so fuzzy!",
        CHESTER_EYEBONE = {
            GENERIC = "Eye on on bone? How can it be alive?",
            WAITING = "Rest in peace. You were good Chester..."
        },
        COOKEDMEAT = "It tastes better cooked then when it's raw.",
        COOKEDMONSTERMEAT = "Musha still doesn't want to eat it... if Musha can help it",
        COOKEDSMALLMEAT = "This meat is small but it's still better then raw meat.",
        CORN = "Would you like to make soup for Musha?",
        CORN_COOKED = "Smells good!",
        CORN_SEEDS = "Musha can make cake with these, powder cake!",
        CROW = {
            GENERIC = "Birds give seeds and eggs to Musha.",
            HELD = "Musha won! Musha caught the bird."
        },
        CUTGRASS = "We need more grass!",
        CUTREEDS = "Papyrus!",
        CUTSTONE = "Do you know Musha can fix Musha's gear with stones?",
        DEADLYFEAST = "Do not eat that!",
        DEERCLOPS = "That giant deer has one eye... Musha better keep an EYE on it!",
        DEERCLOPS_EYEBALL = "Eyebrella, Armor, Hammer, Sword!\n Musha need more!",
        DIRTPILE = "Musha found footprints!",
        DIVININGROD = {
            COLD = "What is this noise? Bees?",
            GENERIC = "What is this thing for? \n  Can it find an exit?",
            HOT = "It found some thing! Musha can see it!",
            WARM = "It senses something.",
            WARMER = "It started working... Musha doesn't know what for."
        },
        DIVININGRODBASE = {
            GENERIC = "Key holder!",
            READY = "Musha is ready to pick up!",
            UNLOCKED = "Can Musha use the rod again?"
        },
        DIVININGRODSTART = "Musha is going to look for someting,\n Maybe it will help Musha.",
        DRAGONFLY = "Musha found the Dragonfly! It's super strong!",
        LAVASPIT = {
            HOT = "hot! hot!",
            COOL = "It's cool now"
        },
        DRAGONFRUIT = "Oh, this is delicious!",
        DRAGONFRUIT_COOKED = "Oh, this is delicious!",
        DRAGONFRUIT_SEEDS = "Dragonfruit! Musha likes it!",
        DRAGONPIE = "It give encouragement to Musha!",
        DRUMSTICK = "Musha will kill EVERY Gobbler!",
        DRUMSTICK_COOKED = "Bad gobbler, good drumstick!",
        DURIAN = "Musha can eat the inside!",
        DURIAN_COOKED = "Yum, Musha doesn't care what it smells like.",
        DURIAN_SEEDS = "Let's plant a durian!",
        EARMUFFSHAT = "Small rabbits make warm earmuffs!",
        EGGPLANT = "It will be tender if cooked.",
        EGGPLANT_COOKED = "The eggplant is tender now, but some people don't like that.",
        EGGPLANT_SEEDS = "Who can eat only one eggplant?",
        STUFFEDEGGPLANT = "I can eat all of that!",
        DUG_BERRYBUSH = "Let's this get home!",
        DUG_GRASS = "Let's this get home!",
        DUG_MARSH_BUSH = "Let's this get home!",
        DUG_SAPLING = "Let's this get home!",
        EARMUFFS = "Small earmuffs.",
        DECIDUOUSTREE = {
            BURNING = "Ah! Hot! Hot! Fire! Fire! The tree need water quick!",
            BURNT = "Thin charcoal tree.",
            CHOPPED = "The tree was chopped down, it'll take a while to grow back.",
            GENERIC = "Wood is important, but trees are better."
        },
        ACORN = {
            GENERIC = "It is Birchnut's seed.",
            PLANTED = "It will be huge tree soon."
        },
        EVERGREEN = {
            BURNING = "Ah! Hot! Hot! Fire! Fire! The tree need water quick!",
            BURNT = "Thin charcoal tree.",
            CHOPPED = "The tree was chopped down, it'll take a while to grow back.",
            GENERIC = "Wood is important, but trees are better."
        },
        EVERGREEN_SPARSE = {
            BURNING = "Ah! Hot! Hot! Fire! Fire! The tree need water quick!",
            BURNT = "Thin charcoal tree.",
            CHOPPED = "The tree was chopped down, it'll take a while to grow back.",
            GENERIC = "Wood is important, but trees are better."
        },
        EYEPLANT = "It collects items near by items.\n It then devours them, keeping them away from Musha for ever!",
        FEATHERHAT = "Let's play and dance with the feather crown!",
        FEATHER_CROW = "Black feathers can be used to make sleep darts!",
        FEATHER_ROBIN = "Red feathers can be used to make fire darts!",
        FEATHER_ROBIN_WINTER = "White feathers can be used used to make blow darts!",
        FEM_PUPPET = "Uh... Who made that, and what for?", --what was that?
        FIREFLIES = {
            GENERIC = "Musha like their pretty light!",
            HELD = "Hmm... It looks so... strange."
        },
        FIREHOUND = "Don't let them near Musha's valuables! Take them out safely the burst into flames!",
        FIREPIT = {
            EMBERS = "Musha need to put fuel in the pit.",
            GENERIC = "It gives of a soft light and warmth.",
            HIGH = "Fire flies high!",
            LOW = "Dawn will come.",
            NORMAL = "Bright fire.",
            OUT = "Musha has to turn it on?"
        },
        FIRESTAFF = "It is dangerous magical staff.",
        FISH = "Musha got this from a pond... or maybe a merman?",
        FISHINGROD = "Fishing for fish so Musha can survive.",
        FISHSTICKS = "Sticks of fish! Easy to make, simple to eat!",
        FISHTACOS = " You know about tacos? These are tacos, with 'fish!' ",
        FISH_COOKED = "Musha wants to eat smoked salmon.",
        FLINT = "The edge to most of the tools Musha can make.",
        FLOWER = "Musha might be able to do something with a lot of these",
        FLOWERHAT = "A halo of flowers. It makes Musha feel so good.",
        FLOWER_EVIL = "Ew, this flower smells really bad, not like the other flowers",
        FOLIAGE = "Musha got this in the cave.",
        FOOTBALLHAT = "It keeps Musha's head safe!",
        FROG = {
            DEAD = "A good frog is a dead frog.",
            GENERIC = "Musha doesn't like when frogs lick Musha...",
            SLEEPING = "Sleeping frogs, should Musha sneak up on them?"
        },
        FROGGLEBUNWICH = "A frog inside of sandwich.",
        FROGLEGS = "Musha only eats the legs from the frogs.",
        FROGLEGS_COOKED = "It's yummy!",
        FRUITMEDLEY = "Yummy, fruit!",
        GEARS = "Metal gear Musha.",
        GHOST = "Turn undead? Just beat the ghost with a sword!!",
        GOLDENAXE = "Golden shiny axe!",
        GOLDENPICKAXE = "Golden shiny pickaxe!",
        GOLDENPITCHFORK = "Golden shiny pitchfork!",
        GOLDENSHOVEL = "Golden shiny shovel!",
        GOLDNUGGET = "Musha has to collect them!",
        GRASS = {
            BARREN = "It need poop.",
            WITHERED = "It is bone dry.",
            BURNING = "Fire! Fire! Musha need water!",
            GENERIC = "Grass is base of survival.",
            PICKED = "Grass will always grow."
        },
        GREEN_CAP = "Yes. Don't eat raw. Will see hallucination.",
        GREEN_CAP_COOKED = "It can help your mental health.",
        GREEN_MUSHROOM = {
            GENERIC = "It can be used as a sedative.",
            INGROUND = "Musha has to come back in the evening.",
            PICKED = "Someone picked it already, maybe it was Musha."
        },
        GUNPOWDER = "Maybe Musha should keep this incase Musha has to fight a dragonfly!",
        HAMBAT = "Nice to 'meat' you!",
        HAMMER = "Hammer bros!",
        HEALINGSALVE = "It saved Musha several times.",
        HEATROCK = {
            FROZEN = "Freezing!",
            COLD = "It's stone cold.",
            GENERIC = "Musha need to keep it Cooler in summer, and hotter in winter.",
            WARM = "Warm yellow stone.",
            HOT = "Red hot stone!"
        },
        HONEY = "Yeah! Honey!",
        HONEYCOMB = "Bees probably don't want Musha to have this.",
        HONEYHAM = "Lots of meat, and lots of honey.",
        HONEYNUGGETS = "Musha loves meat. Musha loves honey. Musha has both!",
        HORN = "It makes a loud and low sound.",
        HOUND = "They were friends, but now they make Musha stronger.",
        HOUNDMOUND = "Where are hounds coming from? Underground?",
        HOUNDBONE = "This was a hound at one point, now it's just bones ",
        ICEBOX = "Allows Musha to store food for a long time!",
        ICEHOUND = "Its fur is snow white!",
        INSANITYROCK = {
            ACTIVE = "It rises at low sainty.",
            INACTIVE = "It's open."
        },
        JAMMYPRESERVES = "Eat slowly!",
        KABOBS = "Meat chunks speared by a stick!",
        KILLERBEE = {
            GENERIC = "It is not honeybee!\n Why do wasps and bees live together?",
            HELD = "Red devils!"
        },
        KNIGHT = "Not Musha's little pony!",
        KOALEFANT_SUMMER = "Elepha... What was that?",
        KOALEFANT_WINTER = "Elepha... What was that?",
        KRAMPUS = "Demon!",
        KRAMPUS_SACK = "It is bigger than Musha!",
        LAVAE = "It likes to set things on fire... Musha hate's them...",
        LEIF = "Walking Tree!",
        LEIF_SPARSE = "Walking Tree!",
        LIGHTNING_ROD = {
            CHARGED = "Oh, Charged steel! Don't touch it!",
            GENERIC = "It makes the area safe from lightning."
        },
        LITTLE_WALRUS = "Unarmed baby follows father!",
        LIVINGLOG = "That is from an old tree",
        LOCKEDWES = "He's trapped!",
        LOG = {
            BURNING = "Fire! It is on fire!",
            GENERIC = "Wood is so useful! What should Musha do with it?"
        },
        LUREPLANT = "This plant has huge stomach.",
        LUREPLANTBULB = "It is mine now.",
        MALE_PUPPET = "It looks like... Wilson?",
        MANDRAKE = {
            DEAD = "It has a human like face & leafy hair.",
            GENERIC = "It isn't exactly a carrot.",
            PICKED = "It has a human like face & leafy hair."
        },
        COOKEDMANDRAKE = "This time Musha cooked mandrake,\n but Musha likes mandrake soup more.",
        MANDRAKESOUP = "Mandrake soup! Totally perfect!",
        MARBLE = "Oof... It's heavy!",
        MARBLEPILLAR = "It looks nice.",
        MARBLETREE = "Who made this, and what for?",
        MARSH_BUSH = {
            BURNING = "Fire! Fire! Hey, Musha need water!",
            GENERIC = "Too many spines!",
            PICKED = "Musha has no interest in it."
        },
        MARSH_PLANT = "This area makes spiky plants.",
        MARSH_TREE = {
            BURNING = "Oh, It is not Musha's fault.",
            BURNT = "All burned wood becomes charcoal.",
            CHOPPED = "A stump is all that is left.",
            GENERIC = "That tree seems to be sick."
        },
        MAXWELL = "He's so tall.",
        MAXWELLHEAD = "Bla bla bla.",
        MAXWELLLIGHT = "It lit on its own!.",
        MAXWELLLOCK = "Hmm, Musha need a key.",
        MAXWELLTHRONE = "Looks dangerous...",
        MEAT = "Musha can eat this now, but it's better if it's jerky, but it's best when cooked.",
        MEATBALLS = "Meatballs!",
        MEAT_DRIED = "Musha likes that!",
        MERM = "Oh, They seem to dislike Musha.",
        MONSTERLASAGNA = "It is food, but it's not healthy for Musha. \n Maybe someone else can eat it",
        MONSTERMEAT = "Who would eat this? Eww.",
        MONSTERMEAT_DRIED = "Disgusting smell is disappeared.\n But it is still... 'not good'.",
        MOSQUITO = {
            GENERIC = "Musha's blood is not delicious!",
            HELD = "Now, it is mine, no more itchy bites!"
        },
        MOSQUITOSACK = "It is fluffy!",
        MOUND = {
            DUG = "No one will rest in peace.\n If anyones dies we just try and try again...",
            GENERIC = "Whose mound?"
        },
        MULTIPLAYER_PORTAL = "It is alpha and omega\n the beginning and the end.",
        NIGHTLIGHT = "Its fuel is man's nightmares.",
        NIGHTMAREFUEL = "The little fear is still alive!",
        NIGHTSWORD = "Musha's nightmare blade can vanquish real nightmares!",
        NITRE = "Others use this for making gunpowder,\n Musha can use this for gear repair.",
        ONEMANBAND = "LeT's DaNcE aNd PlAy!",
        PANDORASCHEST = "A chest from the old age? How'd it get here?",
        PANFLUTE = "Sleeping Beasty.",
        PAPYRUS = "Useful plant! Musha can make papyrus!",
        PENGUIN = "They slide on land! Can you believe it?",
        PERD = "Does anyone have berries or mushrooms? \n Musha can lure that bird with them.",
        PEROGIES = "Fortune cookies! Oh, wait, there is meat inside?",
        PETALS = "Smells good. But not enough to fill Musha's belly.",
        PETALS_EVIL = "Ew, These flowers smell really bad, not like the others ones around here.",
        PHLEGM = "What the... What can Musha do?",
        PICKAXE = "Cut stone, and then build a house!",
        PIGGYBACK = "Big, Fire and water proof backpack!",
        PIGKING = "He has a tons of gold! Musha need's to barter with him!",
        PIGMAN = {
            DEAD = "Dead pigman is just a pig.",
            FOLLOWER = "Let's go! Let's cut trees and kill spiders!",
            GENERIC = "They are friendly to Musha.",
            GUARD = "Oh, come on!",
            WEREPIG = "You are not a pigman anymore! You're a monster!"
        },
        PIGSKIN = "A pig's skin!",
        PIGTORCH = "They seem to like decorating their torches.",
        PINECONE = {
            GENERIC = "It is an Evergreen's seed.",
            PLANTED = "It will be huge tree soon."
        },
        PITCHFORK = "Musha can pull up turf.",
        PLANTMEAT = "Eww, it started melting.",
        PLANTMEAT_COOKED = "Oh, it smells like a meat!",
        PLANT_NORMAL = {
            GENERIC = "Vegetables... Vegetables.",
            GROWING = "Let it grow~ Let it grow~",
            READY = "It's finished! Musha should pick it!",
            WITHERED = "It id totally dry... Musha has to get that out of there."
        },
        POMEGRANATE = "It is not an apple! It's Pomegranate!",
        POMEGRANATE_COOKED = "It makes Musha feel healthy.\n So, can Musha eat this now?",
        POMEGRANATE_SEEDS = "A tiny ruby red seed.",
        POOP = "Ick... It is messy to use and it smells horid... But it's useful.",
        PUMPKIN = "Pumpkin! Musha loves Jack-O-lanterns!",
        PUMPKINCOOKIE = "Pumpkin cookies!",
        PUMPKIN_COOKED = "It was gently cooked.",
        PUMPKIN_LANTERN = "It looks like hound's face, doesn't it?",
        PUMPKIN_SEEDS = "Do you need more pumpkins?",
        PURPLEGEM = "Purple gem makes the world crazy.",
        RABBIT = {
            GENERIC = "It's fast! But Musha has an idea!",
            HELD = "What does Musha do? Kill it? Nourish it?"
        },
        RABBITHOLE = {
            GENERIC = "Did you hear that? There are still bunnies in there.",
            SPRING = "This hole was filled with snow. But rabbits are still inside."
        },
        RATATOUILLE = "Where is the meat? There is none? Oh...",
        RAZOR = "Musha will shave your hair!",
        REDGEM = "Red gem is symbol of life and fire.",
        RED_CAP = "Mushrooms of brilliant colors are posionus, usually.",
        RED_CAP_COOKED = "Useless, isn't it?",
        RED_MUSHROOM = {
            GENERIC = "Mushroom of brilliant colors has poison, usually.",
            INGROUND = "It only comes above gound in the day",
            PICKED = "Someone picked the mushroom."
        },
        REEDS = {
            BURNING = "FIRE! Somebody help Musha!",
            GENERIC = "Mostly, reeds are materials for darts and bandages.",
            PICKED = "Musha hoped that Musha could get some more."
        },
        RELIC = {
            GENERIC = "Hm. Can Musha take it?",
            BROKEN = "need to repair."
        },
        RUBBLE = "Time flies.",
        RESURRECTIONSTONE = "It is not resurrection.\n It forces Musha die again.",
        ROBIN = {
            GENERIC = "A red bird. The color of fire, like Yamche.",
            HELD = "What does Musha do? Where is a cage Musha can put it in?"
        },
        ROBIN_WINTER = {
            GENERIC = "That blue bird has a warm body. Yamche doesn't. Strange.",
            HELD = "What does Musha do? Where is a cage Musha can put it in?"
        },
        ROBOT_PUPPET = "No one can escape from death.",
        ROCK_LIGHT = {
            -- what the flame blast?
            GENERIC = "Musha doesn't understand how this happened.",
            OUT = "Lights out.",
            LOW = "The lava is cooling.",
            NORMAL = "Yes, it's very very hot."
        },
        ROCKS = "Musha can do many things using these.",
        ROOK = "Steel rhinoceros!",
        ROPE = "Musha can use this as bindings!",
        ROTTENEGG = "Rotten egg smells bad but is still useful.\n Especially to make gunpowder.",
        SANITYROCK = {
            ACTIVE = "It rises if Musha has high sainty.",
            INACTIVE = "It's open.'"
        },
        --adds 2 start
        SCARECROW = {
            GENERIC = "All dressed up and no where to crow.",
            BURNING = "Someone made that strawman eat crow.",
            BURNT = "Someone MURDERed that scarecrow!"
        },
        SCULPTINGTABLE = {
            EMPTY = "We can make stone sculptures with this.",
            BLOCK = "Ready for sculpting.",
            SCULPTURE = "A masterpiece!",
            BURNT = "Burnt right down."
        },
        SCULPTURE_KNIGHTHEAD = "Where's the rest of it?",
        SCULPTURE_KNIGHTBODY = {
            COVERED = "It's an odd marble statue.",
            UNCOVERED = "Musha guesses he cracked under the pressure.",
            FINISHED = "At least it's back in one piece now.",
            READY = "Something's moving inside."
        },
        SCULPTURE_BISHOPHEAD = "Is that a head?",
        SCULPTURE_BISHOPBODY = {
            COVERED = "It looks old, but it feels new.",
            UNCOVERED = "There's a big piece missing.",
            FINISHED = "Now what?",
            READY = "Something's moving inside."
        },
        SCULPTURE_ROOKNOSE = "Where did this come from?",
        SCULPTURE_ROOKBODY = {
            COVERED = "It's some sort of marble statue.",
            UNCOVERED = "It's not in the best shape.",
            FINISHED = "All patched up.",
            READY = "Something's moving inside."
        },
        GARGOYLE_HOUND = "Musha doesn't like how it's looking at Musha.",
        GARGOYLE_WEREPIG = "It looks very lifelike.",
        --adds 2 end

        SAPLING = {
            BURNING = "WILLOW!? IS SHE AGAIN BURNING THINGS AGAIN!?",
            WITHERED = "It need water. Or poop.",
            GENERIC = "This is essential.",
            PICKED = "It will always grow back for Musha"
        },
        SEEDS = "Meats or vegetables. That is the question.",
        SEEDS_COOKED = "Musha can eat to fill hunger. They are easy to find.",
        SEWING_KIT = "Musha can sew clothes!",
        SHOVEL = "Musha can dig up items!",
        SILK = "Musha always hunting spiders,\n so Musha has tons of web.",
        SKELETON = "Its soul suffers in another world.",
        --SKELETON_PLAYER = "That gives me the willies.",

        SKELETON_PLAYER = {
            MALE = "Here is %s's corpse, cause is %s.",
            FEMALE = "Here is %s's bone, cause is %s.",
            ROBOT = "Here is %s's wreck, cause is %s.",
            DEFAULT = "Here is %s's corpse, cause is %s."
        },
        SKULLCHEST = "What's for? This design feels like an bad omen!", --what was that?
        SMALLBIRD = {
            GENERIC = "It is similar to yamche, kinda.",
            HUNGRY = "Are you hungry?",
            STARVING = "Wait, wait. Musha knows, you are starving."
        },
        SMALLMEAT = "Looks like a leg, body, head or wing.",
        SMALLMEAT_DRIED = "Smells good!",
        SPAT = "Sheep? Nope... Rhino? Nah...",
        SPEAR = "Musha will FIGHT!",
        SPIDER = {
            DEAD = "Musha need more spiders to become stronger.",
            GENERIC = "Easy to beat, easy training!.",
            SLEEPING = "The spider is sleeping, should Musha sneak up on it or leave it be?"
        },
        SPIDERDEN = "Musha isn't scared of that!",
        SPIDEREGGSACK = "Musha can take it to Musha's backyard.",
        SPIDERGLAND = "This can heal Musha!, \n also it can make healing slave!",
        SPIDERHAT = "Musha is your mother!",
        SPIDERQUEEN = "Big mother spider, and big mother load of EXP for Musha!",
        SPIDER_WARRIOR = {
            DEAD = "You did your best, but Musha is too strong!",
            GENERIC = "It can lunge and bite from a distance. Musha need to be careful.",
            SLEEPING = "The warrior is sleeping, should Musha lunge at it this time?"
        },
        SPOILED_FOOD = "Musha said that it was yucky.",
        STATUEHARP = "Is that a harp? Musha's never seen it before.",
        STATUEMAXWELL = "He trapped me here... Musha hates him.",
        STEELWOOL = "Should Musha make a jumper? What? it's a joke!",
        STINGER = "The stinger of a little bee.",
        STRAWHAT = "Made by straw, but it keeps Musha dry and cool.",
        SUNKBOAT = "What's happen to it?",
        SWEATERVEST = "It is a fashionable vest!",
        TAFFY = "More candy for Musha!",
        TALLBIRD = "Really tall black bird. Sometimes it's vicious!",
        TALLBIRDEGG = "A big blue egg.",
        TALLBIRDEGG_COOKED = "It is too large to eat alone, But Musha can because Musha's very hungry.",
        TALLBIRDEGG_CRACKED = {
            COLD = "The egg need to be warmer!",
            GENERIC = "It is raised  the same as Yamche!",
            HOT = "It is too hot to hatch!",
            LONG = "How long is this going to take?",
            SHORT = "Musha hears something it might hatch soon!"
        },
        TALLBIRDNEST = {
            GENERIC = "Did you see that? It is a big egg!",
            PICKED = "Angry bird's egg is gone."
        },
        TEENBIRD = {
            GENERIC = "It seems to that bird wants something...",
            HUNGRY = "That bird is always hungry.",
            STARVING = "Do not peck Musha!\n Musha gave your foods!"
        },
        TELEPORTATO_BASE = {
            ACTIVE = "Musha just wanted to meet you over the monitor.",
            GENERIC = "Is it a warp gate?",
            LOCKED = "need something before Musha can use it.",
            PARTIAL = "To the next world!"
        },
        TELEPORTATO_BOX = "Surprise box!",
        TELEPORTATO_CRANK = "What does this go to?",
        TELEPORTATO_POTATO = "Just a metal thing.",
        TELEPORTATO_RING = "Some large ring.",
        TENTACLE = "Looks like a squid's leg.",
        TENTACLESPOTS = "Something is in here! Does Musha have to keep it?",
        TENTACLESPIKE = "Oh, It has spikes on it. How nice!",
        TENTACLE_PILLAR = "That's alive!",
        TENTACLE_PILLAR_ARM = "Do not grope Musha!",
        TENTACLE_GARDEN = "Musha heard something digging.",
        TOPHAT = "Gentlemanly hat.",
        TORCH = "No darkness, no fear!",
        TRAP = "For rabbits, frogs and spiders.",
        TRAP_TEETH = "For killing hounds, pengull and mosling.",
        TRAP_TEETH_MAXWELL = "What was that? a Landmine?\n Is that a danger to Musha?",
        TRINKET_1 = "It doesn't deal much damage to monsters.\n Is there anyone interested it?",
        -- Melty Marbles
        TRINKET_10 = "Teeth? It is not strong enough to bite.",
        -- Second-hand Dentures
        TRINKET_11 = "Toy!",
        -- Lying Robot
        TRINKET_12 = "It is too hard to eat that tentacle.",
        --Dessicated Tentacle
        TRINKET_13 = "Some people like this, but Musha doesn't.",
        TRINKET_2 = "Ocarina of Wind... Wha? Musha can't play it",
        --Fake Kazoo
        TRINKET_3 = "If it's to difficult to untie the knot, just cut it.",
        --Gord's Knot
        TRINKET_4 = "Gnome gnome gnome~ Little little gnome~",
        --Gnome
        TRINKET_5 = "Nuclear lunch detected? What does that mean?", --starcraft
        TRINKET_6 = "Assassination? With wires? are these wires?\n Musha's not interested.",
        --Frazzled Wires
        TRINKET_7 = "Try to catch the ball in the cup!",
        -- Ball and Cup
        TRINKET_8 = "Musha knows what this is... uh, it's parts to a mini flail.",
        -- Hardened Rubber Bung
        TRINKET_9 = "Musha will decorate a statue with these buttons!",
        --Mismatched Buttons
        --adds 3 start
        TRINKET_10 = "They've quickly become Wes' favorite prop.", --Dentures
        TRINKET_11 = "Hal whispers beautiful lies to Musha.", --Lying Robot
        TRINKET_12 = "That's just asking to be experimented on.", --Dessicated Tentacle
        TRINKET_13 = "It must be some kind of religious artifact.", --Gnomette
        TRINKET_14 = "Now if Musha only had some tea...", --Leaky Teacup
        TRINKET_15 = "...Maxwell left his stuff out again.", --Pawn
        TRINKET_16 = "...Maxwell left his stuff out again.", --Pawn
        TRINKET_17 = "A horrifying utensil fusion. Maybe science *can* go too far.", --Bent Spork
        TRINKET_18 = "Musha wonders what it's hiding?", --Trojan Horse
        TRINKET_19 = "It doesn't spin very well.", --Unbalanced Top
        TRINKET_20 = "Wigfrid keeps jumping out and hitting Musha with it?!", --Backscratcher
        TRINKET_21 = "This egg beater is all bent out of shape.", --Egg Beater
        TRINKET_22 = "Musha has a few theories about this string.", --Frayed Yarn
        TRINKET_23 = "Musha can put Musha's shoes on without help, thanks.", --Shoehorn
        TRINKET_24 = "Musha thinks Wickerbottom had a cat.", --Lucky Cat Jar
        TRINKET_25 = "It smells kind of stale.", --Air Unfreshener
        TRINKET_26 = "Food and a cup! The ultimate survival container.", --Potato Cup
        TRINKET_27 = "If you unwound it you could poke someone from really far away.", --Coat Hanger
        TRINKET_28 = "How Machiavellian.", --Rook
        TRINKET_29 = "How Machiavellian.", --Rook
        TRINKET_30 = "Honestly, he just leaves them out wherever.", --Knight
        TRINKET_31 = "Honestly, he just leaves them out wherever.", --Knight
        TRINKET_32 = "Musha knows someone who'd have a ball with this!", --Cubic Zirconia Ball
        TRINKET_33 = "Musha hopes this doesn't attract spiders.", --Spider Ring
        TRINKET_34 = "Let's make a wish. For science.", --Monkey Paw
        TRINKET_35 = "Hard to find a good flask around here.", --Empty Elixir
        TRINKET_36 = "Musha might need these after all that candy.", --Faux fangs
        TRINKET_37 = "Musha doesn't believe in the supernatural.", --Broken Stake
        TRINKET_38 = "Musha thinks it came from another world. One with grifts.", -- Binoculars Griftlands trinket
        TRINKET_39 = "Musha wonders where the other one is?", -- Lone Glove Griftlands trinket
        TRINKET_40 = "Holding it makes me feel like bartering.", -- Snail Scale Griftlands trinket
        TRINKET_41 = "It's a little warm to the touch.", -- Goop Canister Hot Lava trinket
        TRINKET_42 = "It's full of someone's childhood memories.", -- Toy Cobra Hot Lava trinket
        TRINKET_43 = "It's not very good at jumping.", -- Crocodile Toy Hot Lava trinket
        TRINKET_44 = "It's some sort of plant specimen.", -- Broken Terrarium ONI trinket
        TRINKET_45 = "It's picking up frequencies from another world.", -- Odd Radio ONI trinket
        TRINKET_46 = "Maybe a tool for testing aerodynamics?", -- Hairdryer ONI trinket
        HALLOWEENCANDY_1 = "The cavities are probably worth it, right?",
        HALLOWEENCANDY_2 = "What corruption of science grew these?",
        HALLOWEENCANDY_3 = "It's... corn.",
        HALLOWEENCANDY_4 = "They wriggle on the way down.",
        HALLOWEENCANDY_5 = "Musha's teeth are going to have something to say about this tomorrow.",
        HALLOWEENCANDY_6 = "Musha... doesn't think Musha will be eating those.",
        HALLOWEENCANDY_7 = "Everyone'll be raisin' a fuss over these.",
        HALLOWEENCANDY_8 = "Only a sucker wouldn't love this.",
        HALLOWEENCANDY_9 = "Sticks to Musha's teeth.",
        HALLOWEENCANDY_10 = "Only a sucker wouldn't love this.",
        HALLOWEENCANDY_11 = "Much better tasting than the real thing.",
        HALLOWEENCANDY_12 = "Did that candy just move?", --ONI meal lice candy
        HALLOWEENCANDY_13 = "Oh, Musha's poor jaw.", --Griftlands themed candy
        HALLOWEENCANDY_14 = "Musha doesn't do well with spice.", --Hot Lava pepper candy
        CANDYBAG = "It's some sort of delicious pocket dimension for sugary treats.",
        DRAGONHEADHAT = "So who gets to be the head?",
        DRAGONBODYHAT = "Musha is middling on this middle piece.",
        DRAGONTAILHAT = "Someone has to bring up the rear.",
        PERDSHRINE = {
            GENERIC = "Musha feels like it wants something.",
            EMPTY = "Musha need to plant something there.",
            BURNT = "That won't do at all."
        },
        REDLANTERN = "This lantern feels more special than the others.",
        LUCKY_GOLDNUGGET = "What a lucky find!",
        FIRECRACKERS = "Filled with explosion science!",
        PERDFAN = "It's inordinately large.",
        REDPOUCH = "Is there something inside?",
        WARGSHRINE = {
            GENERIC = "Musha should make something fun.",
            EMPTY = "Musha need to put a torch in it.",
            BURNT = "It burned down."
        },
        CLAYWARG = {
            GENERIC = "A terror cotta monster!",
            STATUE = "Did it just move?"
        },
        CLAYHOUND = {
            GENERIC = "It's been unleashed!",
            STATUE = "It looks so real."
        },
        HOUNDWHISTLE = "This'd stop a dog in its tracks.",
        CHESSPIECE_CLAYHOUND = "That thing's the leashed of my worries.",
        CHESSPIECE_CLAYWARG = "And Musha didn't even get eaten!",
        BISHOP_CHARGE_HIT = "Ow!",
        --adds 3 end
        TRUNKVEST_SUMMER = "It is a warm waterproof vest!",
        TRUNKVEST_WINTER = "Someone said the padding for the vest is hard to get,\n but Musha did it.",
        TRUNK_COOKED = "Would you eat this? Why?",
        TRUNK_SUMMER = "A long nose!",
        TRUNK_WINTER = "A long nose!",
        UMBRELLA = "Musha loves the colour!",
        WAFFLES = "Hi, waffles! It is time to eat you!",
        WALL_HAY_ITEM = "Hmmm. I worry about how easily it can burn.",
        WALL_STONE = "It would be safe..",
        --0
        WALL_STONE_ITEM = "It looks heavy, but Musha doesn't mind.",
        WALL_RUINS = "Wellow stone wall!",
        --0
        WALL_RUINS_ITEM = "It looks heavy, but Musha doesn't mind.",
        WALL_WOOD_ITEM = "Wooden walls. Better than hay.",
        WALRUS = "Stay close! He only has darts!",
        WALRUSHAT = "PERFECT.",
        WALRUS_CAMP = {
            EMPTY = "Someone lived here.",
            GENERIC = "Musha wants to live in a house like that!"
        },
        WALRUS_TUSK = "It is large and sleek.",
        WARG = "Bring your brothers kid.",
        WASPHIVE = "Looks very dangerous.",
        WETGOOP = "Musha did nothing wrong.",
        WINTERHAT = "Basic equipment for the winter.",
        WORMHOLE = {
            GENERIC = "Is that the tail end or the head?",
            OPEN = "Musha can't be sure that thing is safe."
        },
        ACCOMPLISHMENT_SHRINE = "Musha hates that arrow!"
    },
    DESCRIBE_TOODARK = "Where is glow dust?\n Musha need more light now!",
    DESCRIBE_SMOLDERING = "Oooooooooh!",
    EAT_FOOD = {
        TALLBIRDEGG_CRACKED = "This is yummy, but meat is better."
    }
}
