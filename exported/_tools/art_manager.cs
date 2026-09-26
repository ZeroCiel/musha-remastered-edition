// Musha 美术开发工具（贴图管理 + scml 校验 + anim 自动打包）2026-09-25
//   用户需求：「美术开发工具（含自动打包）exe 部署到 D:\饥荒开发，仅支持本体 mod」
//             「官方打包老是出错，错乱的 scml 没打包好也不告知开发者」→ 本工具把每个 scml 的
//             校验错误、编译退出码、产物是否真的生成，全部明明白白列出来。
//
//   编译（系统自带 csc，离线，无第三方依赖；源码必须 UTF-8 带 BOM）：
//   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /nologo /target:winexe /optimize+
//     /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:art_manager.exe art_manager.cs
//
//   无界面入口（给 agent/脚本）：
//     art_manager.exe --dump  <输出文件>            列 images 贴图状态（OK/STALE/MISSING）
//     art_manager.exe --publish <png> <图名>        发布贴图（备份 → 拷入 → png.exe 转 tex）
//     art_manager.exe --check <输出文件>            校验 exported 全部 scml；退出码 1 = 有 ERROR
//     art_manager.exe --pack <出参目录> <报告文件>   校验 + scml.exe 逐个编译 + 产物复核；退出码 = 失败数
//
//   路径解析（exe 放哪都行）：art_manager.cfg（key=value，可选）→ exe 相对位（_tools 下）→ 硬编码本体 mod。
//   cfg 行格式：png=<png.exe 路径> / scml=<scml.exe 路径> / mod=<mod 根目录>（旧版"单行纯路径=png"仍兼容）。
//
//   打包底层（实测）：scml.exe <工程\x.scml> <出参目录> → <出参>\anim\<名>.zip；恰好 2 参，进度走 stderr。
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;
using System.Xml;

namespace MushaArt
{
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            ArtManager.ResolvePaths();

            if (args.Length >= 2 && args[0] == "--dump")
            {
                try { File.WriteAllText(args[1], ArtManager.BuildStatusText(), new UTF8Encoding(false)); return 0; }
                catch (Exception e) { SafeWrite(args[1], "ERROR: " + e.Message); return 1; }
            }
            if (args.Length >= 3 && args[0] == "--publish")
            {
                try { ArtManager.Publish(args[1], args[2], null); return 0; }
                catch (Exception) { return 1; }
            }
            if (args.Length >= 2 && args[0] == "--check")
            {
                try
                {
                    string txt = ArtManager.CheckText();
                    File.WriteAllText(args[1], txt, new UTF8Encoding(false));
                    return ArtManager.HasErrors() ? 1 : 0;
                }
                catch (Exception e) { SafeWrite(args[1], "ERROR: " + e.Message); return 1; }
            }
            if (args.Length >= 3 && args[0] == "--pack")
            {
                try
                {
                    StringBuilder sb = new StringBuilder();
                    int fails = ArtManager.PackAll(args[1], delegate(string s) { sb.AppendLine(s); });
                    File.WriteAllText(args[2], sb.ToString(), new UTF8Encoding(false));
                    return fails;
                }
                catch (Exception e) { SafeWrite(args[2], "ERROR: " + e.Message); return 1; }
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new ArtManager());
            return 0;
        }

        static void SafeWrite(string path, string text)
        {
            try { File.WriteAllText(path, text, new UTF8Encoding(false)); }
            catch { }
        }
    }

    class Row
    {
        public string Name;
        public string State;     // OK / STALE / MISSING
        public string PngTime;
        public string TexTime;
        public string Note;
    }

    class Issue
    {
        public string Scml;      // 相对路径
        public string Level;     // ERROR / WARN
        public string Msg;
    }

    class ArtManager : Form
    {
        // ---- 路径（ResolvePaths 统一定）----
        public static string ToolDir;                 // exe 所在目录
        public static string ModDir;                  // 本体 mod 根（含 modinfo.lua）
        public static string ImgDir;
        public static string BackupDir;
        public static string PngExe;
        public static string ScmlExe;

        public const string DEFAULT_MOD = @"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha";
        public const string DEFAULT_TOOLS = @"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools";

        private static Action<string> LogSink;         // GUI=写日志框；CLI=null

        private ListView lv;
        private TextBox logBox;
        private Label summary;
        private bool busy;

        public ArtManager()
        {
            LogSink = AppendLog;

            Text = "Musha 美术开发工具 — 贴图状态 / 发布 / scml 校验 / 打包";
            Width = 940;
            Height = 580;
            StartPosition = FormStartPosition.CenterScreen;
            Font = new Font("Microsoft YaHei UI", 9F);

            var toolbar = new FlowLayoutPanel();
            toolbar.Dock = DockStyle.Top;
            toolbar.Height = 42;
            toolbar.Padding = new Padding(6, 7, 6, 0);
            toolbar.WrapContents = false;

            toolbar.Controls.Add(MkBtn("刷新", delegate { RefreshList(); }));
            toolbar.Controls.Add(MkBtn("发布 PNG…", delegate { PublishInteractive(); }));
            toolbar.Controls.Add(MkBtn("校验 scml", delegate { RunValidate(); }));
            toolbar.Controls.Add(MkBtn("打包 anim（校验+编译）", delegate { RunPack(); }));
            toolbar.Controls.Add(MkBtn("打开 images", delegate { OpenDir(ImgDir); }));
            toolbar.Controls.Add(MkBtn("打开备份", delegate { OpenDir(BackupDir); }));
            toolbar.Controls.Add(MkBtn("打开 mod 目录", delegate { OpenDir(ModDir); }));

            summary = new Label();
            summary.Dock = DockStyle.Top;
            summary.Height = 26;
            summary.TextAlign = ContentAlignment.MiddleLeft;
            summary.Padding = new Padding(8, 0, 0, 0);

            lv = new ListView();
            lv.Dock = DockStyle.Fill;
            lv.View = View.Details;
            lv.FullRowSelect = true;
            lv.GridLines = true;
            lv.Columns.Add("图名", 250);
            lv.Columns.Add("状态", 86);
            lv.Columns.Add("PNG 修改时间", 150);
            lv.Columns.Add("TEX 修改时间", 150);
            lv.Columns.Add("备注", 170);

            logBox = new TextBox();
            logBox.Dock = DockStyle.Bottom;
            logBox.Height = 140;
            logBox.Multiline = true;
            logBox.ScrollBars = ScrollBars.Vertical;
            logBox.ReadOnly = true;
            logBox.Font = new Font("Consolas", 9F);

            Controls.Add(lv);
            Controls.Add(summary);
            Controls.Add(logBox);
            Controls.Add(toolbar);

            Shown += delegate { RefreshList(); };
            AppendLog("mod:     " + ModDir + (File.Exists(Path.Combine(ModDir, "modinfo.lua")) ? "" : "   ← 找不到 modinfo.lua！"));
            AppendLog("images:  " + ImgDir);
            AppendLog("png.exe: " + PngExe + (File.Exists(PngExe) ? "" : "   ← 不存在，发布会失败！"));
            AppendLog("scml.exe:" + ScmlExe + (File.Exists(ScmlExe) ? "" : "   ← 不存在，打包会失败！"));
        }

        private Button MkBtn(string text, EventHandler onClick)
        {
            var b = new Button();
            b.Text = text;
            b.AutoSize = true;
            b.Click += onClick;
            return b;
        }

        // ---------------- 路径解析 ----------------

        public static void ResolvePaths()
        {
            ToolDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
            PngExe = Path.Combine(DEFAULT_TOOLS, "png.exe");
            ScmlExe = Path.Combine(DEFAULT_TOOLS, "scml.exe");
            string mod = null;

            try
            {
                string cfg = Path.Combine(ToolDir, "art_manager.cfg");
                if (File.Exists(cfg))
                {
                    foreach (string raw in File.ReadAllLines(cfg))
                    {
                        string line = raw == null ? "" : raw.Trim();
                        if (line.Length == 0 || line.StartsWith("#")) continue;
                        int eq = line.IndexOf('=');
                        if (eq > 0)
                        {
                            string k = line.Substring(0, eq).Trim().ToLowerInvariant();
                            string v = line.Substring(eq + 1).Trim();
                            if (k == "png" && v.Length > 0) PngExe = v;
                            else if (k == "scml" && v.Length > 0) ScmlExe = v;
                            else if (k == "mod" && v.Length > 0) mod = v;
                        }
                        else
                        {
                            PngExe = line;   // 旧版：单行纯路径 = png.exe
                        }
                    }
                }
            }
            catch { }

            if (mod != null && Directory.Exists(mod))
            {
                ModDir = mod;
            }
            else
            {
                try
                {
                    string rel = Path.GetFullPath(Path.Combine(ToolDir, "..", ".."));
                    ModDir = File.Exists(Path.Combine(rel, "modinfo.lua")) ? rel : DEFAULT_MOD;
                }
                catch { ModDir = DEFAULT_MOD; }
            }

            ImgDir = Path.Combine(ModDir, "images");
            BackupDir = Path.Combine(ModDir, "exported", "_tools", "_art_backup");
        }

        // ---------------- 贴图状态（与 art_update.py 同口径） ----------------

        public static List<Row> BuildRows()
        {
            var rows = new List<Row>();
            if (!Directory.Exists(ImgDir)) return rows;

            foreach (string png in Directory.GetFiles(ImgDir, "*.png"))
            {
                string name = Path.GetFileNameWithoutExtension(png);
                string tex = Path.Combine(ImgDir, name + ".tex");
                string xml = Path.Combine(ImgDir, name + ".xml");

                Row r = new Row();
                r.Name = name;
                r.PngTime = File.GetLastWriteTime(png).ToString("yyyy-MM-dd HH:mm");

                bool hasTex = File.Exists(tex);
                bool hasXml = File.Exists(xml);
                r.TexTime = hasTex ? File.GetLastWriteTime(tex).ToString("yyyy-MM-dd HH:mm") : "—";

                if (!hasTex || !hasXml)
                {
                    r.State = "MISSING";
                    r.Note = (!hasTex ? "缺 tex" : "") + (!hasTex && !hasXml ? " + " : "") + (!hasXml ? "缺 xml" : "");
                }
                else if (File.GetLastWriteTime(png) > File.GetLastWriteTime(tex))
                {
                    r.State = "STALE";
                    r.Note = "png 比 tex 新 → 需转换";
                }
                else
                {
                    r.State = "OK";
                    r.Note = "";
                }
                rows.Add(r);
            }
            rows.Sort(delegate(Row a, Row b) { return string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase); });
            return rows;
        }

        public static string BuildStatusText()
        {
            var sb = new StringBuilder();
            List<Row> rows = BuildRows();
            int ok = 0, stale = 0, missing = 0;
            foreach (Row r in rows)
            {
                if (r.State == "OK") ok++;
                else if (r.State == "STALE") stale++;
                else missing++;
                sb.Append(r.State.PadRight(8));
                sb.Append(r.Name);
                if (r.Note.Length > 0) sb.Append("  [" + r.Note + "]");
                sb.AppendLine();
            }
            sb.AppendLine("----");
            sb.AppendLine("total=" + rows.Count + " OK=" + ok + " STALE=" + stale + " MISSING=" + missing);
            return sb.ToString();
        }

        // ---------------- 发布（备份 → 拷入 → png.exe 转换） ----------------

        public static void Publish(string pngPath, string name, TextBox log)
        {
            Action<string> logFn = delegate(string s)
            {
                if (log != null) log.AppendText(s + Environment.NewLine);
                else if (LogSink != null) LogSink(s);
            };

            if (!File.Exists(pngPath)) throw new FileNotFoundException("png not found: " + pngPath);
            if (name == null || name.Length == 0) name = Path.GetFileNameWithoutExtension(pngPath);
            if (!Directory.Exists(ImgDir)) Directory.CreateDirectory(ImgDir);
            if (!Directory.Exists(BackupDir)) Directory.CreateDirectory(BackupDir);

            string ts = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string bak = Path.Combine(BackupDir, name + "_" + ts);
            bool any = false;
            string[] olds = {
                Path.Combine(ImgDir, name + ".png"),
                Path.Combine(ImgDir, name + ".tex"),
                Path.Combine(ImgDir, name + ".xml"),
            };
            foreach (string f in olds)
            {
                if (File.Exists(f))
                {
                    if (!any) Directory.CreateDirectory(bak);
                    File.Copy(f, Path.Combine(bak, Path.GetFileName(f)), true);
                    any = true;
                }
            }
            if (any) logFn("backed up -> " + bak);

            string dstPng = Path.Combine(ImgDir, name + ".png");
            File.Copy(pngPath, dstPng, true);
            logFn("copied " + pngPath + " -> " + dstPng);

            if (!File.Exists(PngExe)) throw new FileNotFoundException("png.exe not found: " + PngExe);
            string dstTex = Path.Combine(ImgDir, name + ".tex");
            string dstXml = Path.Combine(ImgDir, name + ".xml");
            if (File.Exists(dstTex)) File.Delete(dstTex);
            if (File.Exists(dstXml)) File.Delete(dstXml);

            StringBuilder sb = new StringBuilder();
            int code = RunExe(PngExe, "\"" + dstPng + "\" \"" + dstTex + "\"", 120, sb);
            if (code != 0) throw new Exception("png.exe exit " + code + "\n" + sb.ToString());
            if (!File.Exists(dstTex)) throw new Exception("png.exe 没产出 tex\n" + sb.ToString());
            logFn("OK   " + name + " : tex=" + new FileInfo(dstTex).Length + " bytes, xml=" +
                  (File.Exists(dstXml) ? new FileInfo(dstXml).Length + " bytes" : "MISSING"));
            logFn("done. FULL restart DST to see the change in game.");
        }

        // ---------------- scml 校验（官方编译器不报的，我们报） ----------------

        // 收集待编 scml：exported\<非_开头工程>\**\*.scml，跳过工程内 _bak/_ 开头子目录
        public static List<string> ListScmlFiles()
        {
            var list = new List<string>();
            string ex = Path.Combine(ModDir, "exported");
            if (!Directory.Exists(ex)) return list;

            foreach (string proj in Directory.GetDirectories(ex))
            {
                string pname = Path.GetFileName(proj);
                if (pname.StartsWith("_")) continue;
                foreach (string f in Directory.GetFiles(proj, "*.scml", SearchOption.AllDirectories))
                {
                    string rel = f.Substring(proj.Length).TrimStart(Path.DirectorySeparatorChar);
                    if (rel.StartsWith("_") || rel.Contains("\\" + "_")) continue;  // _bak 子目录不算
                    list.Add(f);
                }
            }
            list.Sort(StringComparer.OrdinalIgnoreCase);
            return list;
        }

        public static List<Issue> ValidateAll()
        {
            var issues = new List<Issue>();
            var zipNames = new Dictionary<string, string>();   // zip 基名 -> 首个 scml

            foreach (string scml in ListScmlFiles())
            {
                string rel = scml.Substring(ModDir.Length).TrimStart(Path.DirectorySeparatorChar);
                string baseName = Path.GetFileNameWithoutExtension(scml);

                string firstZip;
                if (zipNames.TryGetValue(baseName, out firstZip))
                    issues.Add(Mk(rel, "WARN", "与 " + firstZip + " 同名 → 打包产物 anim\\" + baseName + ".zip 会互相覆盖"));
                else
                    zipNames[baseName] = rel;

                ValidateOne(scml, rel, issues);
            }
            if (issues.Count == 0) issues.Add(Mk("(全部)", "OK", "无问题"));
            return issues;
        }

        static Issue Mk(string scml, string level, string msg)
        {
            Issue i = new Issue();
            i.Scml = scml; i.Level = level; i.Msg = msg;
            return i;
        }

        static void ValidateOne(string scmlPath, string rel, List<Issue> issues)
        {
            string projDir = Path.GetDirectoryName(scmlPath);

            XmlDocument doc = new XmlDocument();
            try
            {
                doc.XmlResolver = null;
                doc.Load(scmlPath);
            }
            catch (XmlException xe)
            {
                issues.Add(Mk(rel, "ERROR", "XML 解析失败（行 " + xe.LineNumber + " 列 " + xe.LinePosition + "）：" + xe.Message));
                return;
            }
            catch (Exception e)
            {
                issues.Add(Mk(rel, "ERROR", "读取失败：" + e.Message));
                return;
            }

            if (doc.DocumentElement == null || doc.DocumentElement.Name != "spriter_data")
            {
                issues.Add(Mk(rel, "ERROR", "根节点是 <" + (doc.DocumentElement == null ? "?" : doc.DocumentElement.Name) +
                    ">，不是 <spriter_data> → 编译器不认"));
                return;
            }

            // 1) folder/file id 表 + 贴图文件存在性
            var folders = new Dictionary<int, Dictionary<int, string>>();
            foreach (XmlNode folder in doc.SelectNodes("//folder[@id]"))
            {
                int fid;
                if (!int.TryParse(GA(folder, "id"), out fid)) continue;
                var files = new Dictionary<int, string>();
                foreach (XmlNode file in folder.SelectNodes("./file[@id][@name]"))
                {
                    int fileid;
                    if (!int.TryParse(GA(file, "id"), out fileid)) continue;
                    string name = GA(file, "name");
                    files[fileid] = name;
                    try
                    {
                        string p = Path.GetFullPath(Path.Combine(projDir, name.Replace('/', Path.DirectorySeparatorChar)));
                        if (!File.Exists(p))
                            issues.Add(Mk(rel, "ERROR", "贴图缺失：" + name + "（工程目录下找不到该文件 → 编译会静默跳过/出空帧）"));
                    }
                    catch (Exception)
                    {
                        issues.Add(Mk(rel, "ERROR", "贴图路径非法：" + name));
                    }
                }
                folders[fid] = files;
            }
            if (folders.Count == 0)
                issues.Add(Mk(rel, "ERROR", "没有任何 <folder> 图层定义 → 空工程"));

            // 2) 动画段（timeline id 按 <animation> 作用域从 0 重编，必须分段校验；同文去重防刷屏）
            var seen = new HashSet<string>();
            XmlNodeList anims = doc.SelectNodes("//animation|//anim");
            if (anims.Count == 0)
                Add(issues, seen, rel, "ERROR", "没有任何 <animation> 动画段 → 编译出来是空包");

            foreach (XmlNode anim in anims)
            {
                string aname = GA(anim, "name");
                string where = "动画[" + (aname.Length > 0 ? aname : GA(anim, "id")) + "]";

                var tlKeys = new Dictionary<int, int>();
                foreach (XmlNode tl in anim.SelectNodes("./timeline[@id]"))
                {
                    int tid;
                    if (!int.TryParse(GA(tl, "id"), out tid)) continue;
                    int kc = tl.SelectNodes("./key").Count;
                    tlKeys[tid] = kc;
                    if (kc == 0)
                        Add(issues, seen, rel, "ERROR", where + " 时间线 id=" + tid + "（" + GA(tl, "name") + "）没有关键帧 → 空轨道");
                }

                foreach (XmlNode r in anim.SelectNodes(".//bone_ref[@timeline]"))
                    CheckTl(r, tlKeys, rel, where + " bone_ref", issues, seen);

                foreach (XmlNode r in anim.SelectNodes(".//object_ref[@timeline]"))
                {
                    CheckTl(r, tlKeys, rel, where + " object_ref", issues, seen);
                    int fid, fileid;
                    if (int.TryParse(GA(r, "folder"), out fid) && int.TryParse(GA(r, "file"), out fileid))
                    {
                        Dictionary<int, string> files;
                        string nm;
                        if (!folders.TryGetValue(fid, out files) || !files.TryGetValue(fileid, out nm))
                            Add(issues, seen, rel, "ERROR", "object_ref 指向不存在的图层 folder=" + fid + " file=" + fileid +
                                " → 编译后该物件丢失/错位");
                    }
                }
            }
        }

        static void Add(List<Issue> issues, HashSet<string> seen, string scml, string level, string msg)
        {
            if (!seen.Add(level + "\n" + scml + "\n" + msg)) return;
            issues.Add(Mk(scml, level, msg));
        }

        static void CheckTl(XmlNode r, Dictionary<int, int> tlKeys, string rel, string where,
                            List<Issue> issues, HashSet<string> seen)
        {
            int tid;
            if (!int.TryParse(GA(r, "timeline"), out tid)) return;
            if (!tlKeys.ContainsKey(tid))
            {
                Add(issues, seen, rel, "ERROR", where + " 引用了不存在的时间线 id=" + tid + " → 编译报错或丢帧");
                return;
            }
            int key;
            if (int.TryParse(GA(r, "key"), out key) && key >= tlKeys[tid])
                Add(issues, seen, rel, "WARN", where + " 引用时间线 id=" + tid + " key=" + key + "，但它只有 " +
                    tlKeys[tid] + " 帧 → 编译器钳到末帧（错乱嫌疑）");
        }

        static string GA(XmlNode n, string attr)
        {
            XmlAttribute a = n.Attributes != null ? n.Attributes[attr] : null;
            return a == null ? "" : a.Value;
        }

        static bool CachedHasErrors;
        public static bool HasErrors() { return CachedHasErrors; }

        public static string CheckText()
        {
            List<Issue> issues = ValidateAll();
            var sb = new StringBuilder();
            int errs = 0, warns = 0;
            foreach (Issue i in issues)
            {
                if (i.Level == "ERROR") errs++;
                else if (i.Level == "WARN") warns++;
                if (i.Level == "OK") continue;
                sb.Append(i.Level == "ERROR" ? "ERROR " : "WARN  ");
                sb.Append(i.Scml);
                sb.Append("  ");
                sb.AppendLine(i.Msg);
            }
            sb.AppendLine("----");
            sb.AppendLine("scml=" + ListScmlFiles().Count + " ERROR=" + errs + " WARN=" + warns);
            CachedHasErrors = errs > 0;
            return sb.ToString();
        }

        // ---------------- 打包：校验 → scml.exe 逐个编译 → 产物复核 ----------------

        // 返回失败数（校验 ERROR 跳过数 + 编译失败数）；0 = 全绿
        public static int PackAll(string outDir, Action<string> log)
        {
            if (log == null) log = delegate { };
            if (!File.Exists(ScmlExe)) { log("FAIL scml.exe 不存在：" + ScmlExe); return 1; }

            List<Issue> issues = ValidateAll();
            int e = 0, w = 0;
            foreach (Issue i in issues)
            {
                if (i.Level == "ERROR") e++;
                else if (i.Level == "WARN") w++;
                if (i.Level == "OK") continue;
                log((i.Level == "ERROR" ? "[ERROR] " : "[WARN ] ") + i.Scml + "  " + i.Msg);
            }
            log("校验: " + ListScmlFiles().Count + " 个 scml, ERROR " + e + ", WARN " + w);

            var bad = new HashSet<string>();
            foreach (Issue i in issues) if (i.Level == "ERROR") bad.Add(i.Scml);

            List<string> all = ListScmlFiles();
            int ok = 0, fail = 0, skipped = 0;
            DateTime stamp = DateTime.Now.AddSeconds(-15);
            string animDir = Path.Combine(outDir, "anim");

            int n = 0;
            foreach (string scml in all)
            {
                n++;
                string rel = scml.Substring(ModDir.Length).TrimStart(Path.DirectorySeparatorChar);
                string baseName = Path.GetFileNameWithoutExtension(scml);

                if (bad.Contains(rel))
                {
                    skipped++;
                    log("SKIP  " + rel + "（校验有 ERROR，不编译 —— 官方会静默产出坏/旧包，这里明确跳过）");
                    continue;
                }

                string zip = Path.Combine(animDir, baseName + ".zip");
                try { if (File.Exists(zip)) File.Delete(zip); } catch { }   // 逼出真产物，防旧包冒充

                StringBuilder sb = new StringBuilder();
                int code = RunExe(ScmlExe, "\"" + scml + "\" \"" + outDir + "\"", 300, sb);

                bool produced = File.Exists(zip)
                                && File.GetLastWriteTime(zip) >= stamp
                                && new FileInfo(zip).Length > 0;
                if (code == 0 && produced)
                {
                    ok++;
                    log("OK    anim\\" + baseName + ".zip  (" + new FileInfo(zip).Length + " bytes)");
                }
                else
                {
                    fail++;
                    string why = code != 0 ? "退出码 " + code : "没产出 anim\\" + baseName + ".zip（官方静默失败就是这种）";
                    log("FAIL  " + rel + "  → " + why);
                    string tail = Tail(sb.ToString(), 600);
                    if (tail.Length > 0) log("      " + tail.Replace("\r\n", " | ").Replace("\n", " | "));
                }
            }

            log("打包完成: 成功 " + ok + " / 失败 " + fail + " / 校验错误跳过 " + skipped + "  →  " + outDir);
            log(fail + skipped == 0 ? "全绿。改过 Lua/贴图仍需完全重启游戏。" : "有失败项 —— 上面每一条都写明了原因，别当没看见。");
            return fail + skipped;
        }

        static string Tail(string s, int max)
        {
            if (s == null) return "";
            s = s.Trim();
            return s.Length <= max ? s : s.Substring(s.Length - max);
        }

        // 运行外部程序，异步收双流（防 stderr 缓冲区堵死），带超时；返回退出码（超时 = -1）
        static int RunExe(string exe, string args, int timeoutSec, StringBuilder output)
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = exe;
            psi.Arguments = args;
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
            psi.CreateNoWindow = true;

            object sync = new object();
            using (Process p = new Process())
            {
                p.StartInfo = psi;
                p.OutputDataReceived += delegate(object s, DataReceivedEventArgs ev)
                { if (ev.Data != null) { lock (sync) output.AppendLine(ev.Data); } };
                p.ErrorDataReceived += delegate(object s, DataReceivedEventArgs ev)
                { if (ev.Data != null) { lock (sync) output.AppendLine(ev.Data); } };
                p.Start();
                p.BeginOutputReadLine();
                p.BeginErrorReadLine();
                if (!p.WaitForExit(timeoutSec * 1000))
                {
                    try { p.Kill(); } catch { }
                    lock (sync) output.AppendLine("[超时 " + timeoutSec + "s 已强杀]");
                    return -1;
                }
                p.WaitForExit();   // 等异步流收完
                return p.ExitCode;
            }
        }

        // ---------------- UI ----------------

        private void RefreshList()
        {
            lv.Items.Clear();
            int ok = 0, stale = 0, missing = 0;
            try
            {
                foreach (Row r in BuildRows())
                {
                    var it = new ListViewItem(new string[] { r.Name, r.State, r.PngTime, r.TexTime, r.Note });
                    if (r.State == "OK") { it.ForeColor = Color.FromArgb(0, 120, 0); ok++; }
                    else if (r.State == "STALE") { it.ForeColor = Color.FromArgb(190, 90, 0); it.Font = new Font(lv.Font, FontStyle.Bold); stale++; }
                    else { it.ForeColor = Color.FromArgb(190, 0, 0); it.Font = new Font(lv.Font, FontStyle.Bold); missing++; }
                    lv.Items.Add(it);
                }
                summary.Text = "贴图 " + lv.Items.Count + " 张：OK " + ok + " · STALE " + stale + " · MISSING " + missing +
                               (stale + missing > 0 ? "   ← STALE/MISSING 用「发布 PNG…」补" : "   ✓");
            }
            catch (Exception ex)
            {
                summary.Text = "读取失败: " + ex.Message;
            }
        }

        private void RunValidate()
        {
            if (busy) return;
            busy = true;
            try
            {
                AppendLog("---- 校验 scml ----");
                int errs = 0, warns = 0;
                foreach (Issue i in ValidateAll())
                {
                    if (i.Level == "ERROR") errs++;
                    else if (i.Level == "WARN") warns++;
                    if (i.Level == "OK") continue;
                    AppendLog((i.Level == "ERROR" ? "[ERROR] " : "[WARN ] ") + i.Scml + "  " + i.Msg);
                }
                AppendLog("校验结果: ERROR " + errs + " · WARN " + warns + (errs + warns == 0 ? "   ✓ 全部干净" : ""));
            }
            catch (Exception ex)
            {
                AppendLog("校验异常: " + ex.Message);
            }
            finally { busy = false; }
        }

        private void RunPack()
        {
            if (busy) return;
            if (MessageBox.Show(this,
                    "校验 + 重编 exported 全部 scml → " + ModDir + @"\anim\（仅本体 mod）。\n\n" +
                    "带 ERROR 的 scml 会被跳过并在日志里写明原因。\n继续？",
                    "自动打包", MessageBoxButtons.OKCancel, MessageBoxIcon.Question) != DialogResult.OK)
                return;

            busy = true;
            string oldTitle = Text;
            try
            {
                AppendLog("---- 打包 anim ----");
                int i = 0;
                int total = ListScmlFiles().Count;
                Action<string> logFn = delegate(string s)
                {
                    AppendLog(s);
                    i++;
                    Text = "打包中… " + Math.Min(i, total) + "/" + total + "   （窗口短暂无响应属正常）";
                    Application.DoEvents();
                };
                int fails = PackAll(ModDir, logFn);
                summary.Text = fails == 0 ? "打包完成 ✓ 全部 scml 编译成功" : "打包有 " + fails + " 项失败/跳过 → 看日志";
            }
            catch (Exception ex)
            {
                AppendLog("打包异常: " + ex.Message);
            }
            finally
            {
                Text = oldTitle;
                busy = false;
            }
        }

        private void PublishInteractive()
        {
            using (var dlg = new OpenFileDialog())
            {
                dlg.Filter = "PNG 图片 (*.png)|*.png";
                dlg.Multiselect = true;
                dlg.Title = "选择要发布的 PNG（图名 = 文件名，不含扩展名）";
                if (dlg.ShowDialog(this) != DialogResult.OK) return;

                string names = "";
                foreach (string f in dlg.FileNames)
                    names += "  " + Path.GetFileName(f) + Environment.NewLine;
                if (MessageBox.Show(this,
                        "发布以下 PNG 到 images\\（旧图先备份到 _art_backup）：" + Environment.NewLine + names +
                        Environment.NewLine + Environment.NewLine + "发布后需完全重启游戏才生效。",
                        "确认发布", MessageBoxButtons.OKCancel, MessageBoxIcon.Question) != DialogResult.OK)
                    return;

                foreach (string f in dlg.FileNames)
                {
                    string name = Path.GetFileNameWithoutExtension(f);
                    try { Publish(f, name, logBox); }
                    catch (Exception ex)
                    {
                        AppendLog("FAIL " + name + " : " + ex.Message);
                        MessageBox.Show(this, "发布 " + name + " 失败：" + ex.Message, "错误",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
                RefreshList();
            }
        }

        private void AppendLog(string s)
        {
            if (logBox == null) return;
            logBox.AppendText("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + s + Environment.NewLine);
        }

        private void OpenDir(string dir)
        {
            try
            {
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                Process.Start("explorer.exe", "\"" + dir + "\"");
            }
            catch (Exception ex)
            {
                AppendLog("打开目录失败: " + ex.Message);
            }
        }
    }
}
