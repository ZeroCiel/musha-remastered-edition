// Musha 贴图管理窗口（2026-09-25 用户：「那个工具，请加个 exe 做成管理窗口，我随时来看」）
//   编译（系统自带 csc，离线，无第三方依赖）：
//   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /nologo /target:winexe /optimize+
//     /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:art_manager.exe art_manager.cs
//   源码必须存成 UTF-8 带 BOM（否则 csc 按本地码页读中文字符串会乱码）。
//
//   无界面自检入口（给 agent/脚本用）：
//     art_manager.exe --dump <输出文件>          列全部贴图状态
//     art_manager.exe --publish <png> <图名>     发布（旧图备份 → 拷入 → png.exe 转 tex）
//
//   逻辑与 exported/_tools/art_update.py 一致：MISSING=缺 tex/xml，STALE=png 比 tex 新。
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;

namespace MushaArt
{
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            if (args.Length >= 2 && args[0] == "--dump")
            {
                try
                {
                    File.WriteAllText(args[1], ArtManager.BuildStatusText(), new UTF8Encoding(false));
                    return 0;
                }
                catch (Exception e)
                {
                    try { File.WriteAllText(args[1], "ERROR: " + e.Message, new UTF8Encoding(false)); }
                    catch { }
                    return 1;
                }
            }
            if (args.Length >= 3 && args[0] == "--publish")
            {
                try
                {
                    ArtManager.Publish(args[1], args[2], null);
                    return 0;
                }
                catch (Exception e)
                {
                    return 1;
                }
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new ArtManager());
            return 0;
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

    class ArtManager : Form
    {
        public static readonly string ToolDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
        public static readonly string ModDir = Path.GetFullPath(Path.Combine(ToolDir, "..", ".."));
        public static readonly string ImgDir = Path.Combine(ModDir, "images");
        public static readonly string BackupDir = Path.Combine(ToolDir, "_art_backup");
        public static string PngExe = @"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\png.exe";

        private static Action<string> LogSink;   // GUI=写日志框；CLI=null

        private ListView lv;
        private TextBox logBox;
        private Label summary;

        public ArtManager()
        {
            LoadConfig();
            LogSink = AppendLog;

            Text = "Musha 贴图管理 — images\\ 状态 / 发布 / 备份";
            Width = 900;
            Height = 580;
            StartPosition = FormStartPosition.CenterScreen;
            Font = new Font("Microsoft YaHei UI", 9F);

            var toolbar = new FlowLayoutPanel();
            toolbar.Dock = DockStyle.Top;
            toolbar.Height = 42;
            toolbar.Padding = new Padding(6, 7, 6, 0);
            toolbar.WrapContents = false;

            var btnRefresh = new Button();
            btnRefresh.Text = "刷新";
            btnRefresh.AutoSize = true;
            btnRefresh.Click += delegate { RefreshList(); };

            var btnPublish = new Button();
            btnPublish.Text = "发布 PNG…";
            btnPublish.AutoSize = true;
            btnPublish.Click += delegate { PublishInteractive(); };

            var btnImg = new Button();
            btnImg.Text = "打开 images";
            btnImg.AutoSize = true;
            btnImg.Click += delegate { OpenDir(ImgDir); };

            var btnBak = new Button();
            btnBak.Text = "打开备份";
            btnBak.AutoSize = true;
            btnBak.Click += delegate { OpenDir(BackupDir); };

            var btnTool = new Button();
            btnTool.Text = "打开工具目录";
            btnTool.AutoSize = true;
            btnTool.Click += delegate { OpenDir(ToolDir); };

            toolbar.Controls.Add(btnRefresh);
            toolbar.Controls.Add(btnPublish);
            toolbar.Controls.Add(btnImg);
            toolbar.Controls.Add(btnBak);
            toolbar.Controls.Add(btnTool);

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
            logBox.Height = 116;
            logBox.Multiline = true;
            logBox.ScrollBars = ScrollBars.Vertical;
            logBox.ReadOnly = true;
            logBox.Font = new Font("Consolas", 9F);

            // 停靠顺序（WinForms 按 z 序反向停靠）：Fill 最先入列 → 最后吃剩余空间
            Controls.Add(lv);
            Controls.Add(summary);
            Controls.Add(logBox);
            Controls.Add(toolbar);

            Shown += delegate { RefreshList(); };
            AppendLog("工具目录: " + ToolDir);
            AppendLog("images:   " + ImgDir);
            AppendLog("png.exe:  " + PngExe + (File.Exists(PngExe) ? "" : "   ← 不存在，发布会失败！"));
        }

        private void LoadConfig()
        {
            try
            {
                string cfg = Path.Combine(ToolDir, "art_manager.cfg");
                if (File.Exists(cfg))
                {
                    string first = File.ReadAllLines(cfg).Length > 0 ? File.ReadAllLines(cfg)[0].Trim() : "";
                    if (first.Length > 0) PngExe = first;
                }
            }
            catch { }
        }

        // ---------------- 状态逻辑（与 art_update.py 同口径） ----------------

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

            // 1) 旧图备份（png+tex+xml，同 art_update.py）
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

            // 2) 拷入 images
            string dstPng = Path.Combine(ImgDir, name + ".png");
            File.Copy(pngPath, dstPng, true);
            logFn("copied " + pngPath + " -> " + dstPng);

            // 3) png.exe <in.png> <out.tex>（同名 xml 自动生成；必须恰好两个参数）
            if (!File.Exists(PngExe)) throw new FileNotFoundException("png.exe not found: " + PngExe);
            string dstTex = Path.Combine(ImgDir, name + ".tex");
            string dstXml = Path.Combine(ImgDir, name + ".xml");
            if (File.Exists(dstTex)) File.Delete(dstTex);   // 陈旧产物别混淆结果
            if (File.Exists(dstXml)) File.Delete(dstXml);

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = PngExe;
            psi.Arguments = "\"" + dstPng + "\" \"" + dstTex + "\"";
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
            psi.CreateNoWindow = true;

            string so, se;
            using (Process p = Process.Start(psi))
            {
                so = p.StandardOutput.ReadToEnd();
                se = p.StandardError.ReadToEnd();
                p.WaitForExit();
                if (p.ExitCode != 0)
                    throw new Exception("png.exe exit " + p.ExitCode + "\n" + se + so);
            }
            if (!File.Exists(dstTex)) throw new Exception("png.exe 没产出 tex\n" + se + so);
            if (so.Trim().Length > 0) logFn(so.Trim());
            logFn("OK   " + name + " : tex=" + new FileInfo(dstTex).Length + " bytes, xml=" +
                  (File.Exists(dstXml) ? new FileInfo(dstXml).Length + " bytes" : "MISSING"));
            logFn("done. FULL restart DST to see the change in game.");
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
                summary.Text = "共 " + lv.Items.Count + " 张：OK " + ok + " · STALE " + stale + " · MISSING " + missing +
                               (stale + missing > 0 ? "   ← STALE/MISSING 用「发布 PNG…」补" : "   ✓ 全绿");
            }
            catch (Exception e)
            {
                summary.Text = "读取失败: " + e.Message;
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
                    try
                    {
                        Publish(f, name, logBox);
                    }
                    catch (Exception e)
                    {
                        AppendLog("FAIL " + name + " : " + e.Message);
                        MessageBox.Show(this, "发布 " + name + " 失败：" + e.Message, "错误",
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
            catch (Exception e)
            {
                AppendLog("打开目录失败: " + e.Message);
            }
        }
    }
}
