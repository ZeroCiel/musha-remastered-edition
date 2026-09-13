#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
彩虹岛 Web 注册服务 - 监听 5888 端口
游戏内注册 / 网页注册
"""

import json
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
import pyodbc


DB_CONN_STR = (
    'DRIVER={SQL Server};SERVER=127.0.0.1,59157;'
    'Trusted_Connection=yes;DATABASE=dbLataleAccount'
)

HTML_PAGE = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>彩虹岛 - 账号注册</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body {
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
    font-family: 'Microsoft YaHei', sans-serif;
    min-height: 100vh;
    display: flex; align-items: center; justify-content: center;
}
.card {
    background: rgba(255,255,255,0.05);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 20px;
    padding: 40px;
    width: 380px;
    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
}
h1 {
    color: #e94560;
    text-align: center;
    font-size: 28px;
    margin-bottom: 8px;
    text-shadow: 0 0 20px rgba(233,69,96,0.3);
}
.subtitle {
    color: #888;
    text-align: center;
    font-size: 13px;
    margin-bottom: 30px;
}
label {
    display: block;
    color: #ccc;
    font-size: 13px;
    margin-bottom: 6px;
    margin-top: 16px;
}
input {
    width: 100%;
    padding: 12px 16px;
    border: 1px solid rgba(255,255,255,0.15);
    border-radius: 10px;
    background: rgba(255,255,255,0.08);
    color: #fff;
    font-size: 15px;
    outline: none;
    transition: border-color 0.3s;
}
input:focus {
    border-color: #e94560;
    box-shadow: 0 0 12px rgba(233,69,96,0.2);
}
button {
    width: 100%;
    margin-top: 24px;
    padding: 13px;
    border: none;
    border-radius: 10px;
    background: linear-gradient(135deg, #e94560, #c23152);
    color: #fff;
    font-size: 16px;
    font-weight: bold;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
}
button:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(233,69,96,0.4);
}
#msg {
    margin-top: 16px;
    padding: 10px;
    border-radius: 8px;
    text-align: center;
    font-size: 14px;
    display: none;
}
.success { background: rgba(0,255,0,0.1); color: #4ade80; border: 1px solid rgba(74,222,128,0.3); display:block !important; }
.error { background: rgba(255,0,0,0.1); color: #f87171; border: 1px solid rgba(248,113,113,0.3); display:block !important; }
.footer { text-align: center; margin-top: 20px; color: #555; font-size: 11px; }
</style>
</head>
<body>
<div class="card">
    <h1>🌈 彩虹岛</h1>
    <div class="subtitle">Latale 账号注册</div>
    <form id="regForm" onsubmit="return doRegister()">
        <label>账号</label>
        <input type="text" id="userid" placeholder="请输入账号" maxlength="20" required>
        <label>密码</label>
        <input type="password" id="password" placeholder="请输入密码" maxlength="20" required>
        <button type="submit">✨ 注册</button>
    </form>
    <div id="msg"></div>
    <div class="footer">www.aywd.vip</div>
</div>
<script>
async function doRegister() {
    const id = document.getElementById('userid').value.trim();
    const pw = document.getElementById('password').value.trim();
    const msg = document.getElementById('msg');
    if (!id || !pw) { msg.className='error'; msg.textContent='请填写账号和密码'; return false; }
    if (id.length < 2) { msg.className='error'; msg.textContent='账号至少2个字符'; return false; }
    if (pw.length < 4) { msg.className='error'; msg.textContent='密码至少4个字符'; return false; }
    try {
        const resp = await fetch('/register', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'id=' + encodeURIComponent(id) + '&pw=' + encodeURIComponent(pw)
        });
        const data = await resp.json();
        if (data.success) {
            msg.className = 'success';
            msg.innerHTML = '✅ ' + data.message + '<br>UID: ' + data.uid;
        } else {
            msg.className = 'error';
            msg.textContent = '❌ ' + data.message;
        }
    } catch(e) {
        msg.className = 'error';
        msg.textContent = '注册失败，请稍后再试';
    }
    return false;
}
</script>
</body>
</html>"""


def register_in_db(user_id: str, password: str):
    """在数据库中注册账号，返回 (success, uid, message)"""
    if not user_id or not password:
        return False, 0, "账号和密码不能为空"
    if len(user_id) > 20 or len(password) > 20:
        return False, 0, f"账号或密码过长（最多20字符）"

    conn = pyodbc.connect(DB_CONN_STR, timeout=5)
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM tbluAccount WHERE ID = ?", (user_id,))
    if cursor.fetchone()[0] > 0:
        conn.close()
        return False, 0, f"账号 '{user_id}' 已存在"

    cursor.execute(
        "INSERT INTO tbluAccount (ID, PW, Block, createdTime, Name, failedLoginTimes, IsOnlineStatus) "
        "VALUES (?, ?, 0, GETDATE(), ?, 0, 0)",
        (user_id, password, user_id))
    cursor.execute("SELECT ISNULL(MAX(UID), 0) FROM tbluAccount WHERE ID = ?", (user_id,))
    new_uid = cursor.fetchone()[0]
    conn.commit()
    conn.close()

    return True, new_uid, f"注册成功"


class RegisterHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def _send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', len(body))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)

    def _send_html(self, status=200):
        body = HTML_PAGE.encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', len(body))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)

        if parsed.path == '/register' and 'id' in params and 'pw' in params:
            uid_in = params['id'][0]
            pw_in = params['pw'][0]
            ok, uid, msg = register_in_db(uid_in, pw_in)
            self._send_json({'success': ok, 'uid': uid, 'message': msg})
            return

        self._send_html()

    def do_POST(self):
        content_len = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_len).decode('utf-8', errors='replace')
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path == '/register':
            params = urllib.parse.parse_qs(body)
            uid_in = params.get('id', [None])[0] or params.get('user', [None])[0]
            pw_in = params.get('pw', [None])[0] or params.get('pass', [None])[0] or params.get('password', [None])[0]

            if not uid_in:
                try:
                    data = json.loads(body)
                    uid_in = data.get('id') or data.get('user')
                    pw_in = data.get('pw') or data.get('pass') or data.get('password')
                except json.JSONDecodeError:
                    pass

            if not uid_in or not pw_in:
                self._send_json({'success': False, 'uid': 0, 'message': '缺少账号或密码'}, 400)
                return

            ok, uid, msg = register_in_db(uid_in, pw_in)
            self._send_json({'success': ok, 'uid': uid, 'message': msg})
            return

        self._send_json({'success': False, 'message': '未知请求'}, 404)


def main():
    port = 5888
    server = HTTPServer(('0.0.0.0', port), RegisterHandler)
    print(f"🌈 彩虹岛注册服务已启动 → http://0.0.0.0:{port}")
    print(f"   本地访问: http://127.0.0.1:{port}")
    print(f"   API 注册: http://127.0.0.1:{port}/register?id=账号&pw=密码")
    print("   按 Ctrl+C 停止服务")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n服务已停止")


if __name__ == '__main__':
    main()
