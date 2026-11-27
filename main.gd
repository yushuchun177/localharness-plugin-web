extends Node
## 网页插件 · local-harness
## 工具：web_fetch(url, max_chars?) / web_search(query, limit?)
##
## 中文优先的两个点：
## 1. 抓取用 PowerShell + WebClient：按页面声明的编码解码（百度/新浪这类是 GBK/GB18030），
##    否则中文网页抓回来全是乱码；
## 2. 搜索先试 DuckDuckGo，不通就换 Bing 中国站（国内网络 DDG 经常被挡）。

const TIMEOUT := 25



func _pref(key: String, def_value):
	# 直接读设置文件：在后台线程里也能用（不能碰场景树）
	var f := FileAccess.open("user://plugin_settings.json", FileAccess.READ)
	if f == null:
		return def_value
	var obj = JSON.parse_string(f.get_as_text())
	if not (obj is Dictionary):
		return def_value
	var vals: Dictionary = obj.get("values", {})
	var mine: Dictionary = vals.get("web", {})
	return mine.get(key, def_value)

func run(tool: String, args: Dictionary) -> Dictionary:
	match tool:
		"web_fetch":
			return _fetch(args)
		"web_search":
			return _search(args)
	return {"ok": false, "output": "未知工具：%s" % tool}


# ---------------------------------------------------------------- 抓取
func _fetch_raw(url: String) -> String:
	var out_file := OS.get_temp_dir().path_join("lh_web_%d.txt" % randi())
	var ps_file := OS.get_temp_dir().path_join("lh_web_%d.ps1" % randi())
	var script := """
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $wc = New-Object System.Net.WebClient
  $wc.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) local-harness')
  $wc.Headers.Add('Accept-Language', 'zh-CN,zh;q=0.9')
  $bytes = $wc.DownloadData('URL')
  $probe = [Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(4096, $bytes.Length))
  if ($probe -match 'charset\\s*=\\s*["'']?(gb2312|gbk|gb18030)') {
    $enc = [Text.Encoding]::GetEncoding('GB18030')
  } elseif ($probe -match 'charset\\s*=\\s*["'']?(utf-8|utf8)') {
    $enc = [Text.Encoding]::UTF8
  } else {
    $enc = [Text.Encoding]::UTF8
  }
  $html = $enc.GetString($bytes)
  [IO.File]::WriteAllText('OUT', $html, [Text.Encoding]::UTF8)
  Write-Output 'ok'
} catch {
  [IO.File]::WriteAllText('OUT', '', [Text.Encoding]::UTF8)
  Write-Output ('ERR: ' + $_.Exception.Message)
}
""".replace("URL", url.replace("'", "''")).replace("OUT", out_file.replace("'", "''"))
	var f := FileAccess.open(ps_file, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_buffer(PackedByteArray([0xFF, 0xFE]))
	f.store_buffer(script.to_utf16_buffer())
	f.close()
	var out: Array = []
	OS.execute("powershell.exe", PackedStringArray([
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", ps_file]), out, true)
	DirAccess.remove_absolute(ps_file)
	var text := ""
	if FileAccess.file_exists(out_file):
		var rf := FileAccess.open(out_file, FileAccess.READ)
		if rf:
			text = rf.get_as_text()
		DirAccess.remove_absolute(out_file)
	return text


func _to_text(html: String) -> String:
	var s := html
	var re_script := RegEx.new()
	re_script.compile("(?is)<(script|style|noscript)[^>]*>.*?</\\1>")
	s = re_script.sub(s, " ", true)
	var re_br := RegEx.new()
	re_br.compile("(?i)<(br|/p|/div|/li|/tr|/h[1-6])[^>]*>")
	s = re_br.sub(s, "\n", true)
	var re_tag := RegEx.new()
	re_tag.compile("(?s)<[^>]+>")
	s = re_tag.sub(s, "", true)
	s = s.replace("&nbsp;", " ").replace("&amp;", "&").replace("&lt;", "<") \
		.replace("&gt;", ">").replace("&quot;", "\"").replace("&#39;", "'")
	var re_ws := RegEx.new()
	re_ws.compile("[ \\t]+")
	s = re_ws.sub(s, " ", true)
	var re_nl := RegEx.new()
	re_nl.compile("\\n{3,}")
	s = re_nl.sub(s, "\n\n", true)
	return s.strip_edges()


func _fetch(args: Dictionary) -> Dictionary:
	var url := str(args.get("url", "")).strip_edges()
	if url == "":
		return {"ok": false, "output": "url 不能为空"}
	if not (url.begins_with("http://") or url.begins_with("https://")):
		url = "https://" + url
	var limit := int(args.get("max_chars", int(_pref("max_chars", 6000))))
	var html := _fetch_raw(url)
	if html.strip_edges() == "":
		return {"ok": false, "output": "抓取失败或页面为空：%s" % url}
	var txt := _to_text(html)
	if txt.length() > limit:
		txt = txt.substr(0, limit) + "\n…（已截断）"
	return {"ok": true, "output": txt}


# ---------------------------------------------------------------- 搜索
func _search(args: Dictionary) -> Dictionary:
	var q := str(args.get("query", "")).strip_edges()
	if q == "":
		return {"ok": false, "output": "query 不能为空"}
	var limit := int(args.get("limit", 8))

	var ddg := _search_ddg(q, limit)
	if ddg != "":
		return {"ok": true, "output": ddg}
	var bing := _search_bing(q, limit)
	if bing != "":
		return {"ok": true, "output": bing}
	return {"ok": false, "output": "搜索失败：DuckDuckGo 和 Bing 都没能访问（检查网络/代理）"}


func _search_ddg(q: String, limit: int) -> String:
	var html := _fetch_raw("https://html.duckduckgo.com/html/?q=" + q.uri_encode())
	if html.strip_edges() == "":
		return ""
	var out: PackedStringArray = []
	var re := RegEx.new()
	re.compile("(?s)class=\"result__a\"[^>]*>(.*?)</a>.*?class=\"result__snippet\"[^>]*>(.*?)</a>")
	var strip := RegEx.new()
	strip.compile("(?s)<[^>]+>")
	for m in re.search_all(html):
		if out.size() >= limit:
			break
		out.append("%d. %s\n   %s" % [out.size() + 1,
			strip.sub(m.get_string(1), "", true).strip_edges(),
			strip.sub(m.get_string(2), "", true).strip_edges()])
	return "\n".join(out)


func _search_bing(q: String, limit: int) -> String:
	var html := _fetch_raw("https://cn.bing.com/search?q=" + q.uri_encode())
	if html.strip_edges() == "":
		return ""
	var out: PackedStringArray = []
	var re := RegEx.new()
	re.compile("(?s)<li class=\"b_algo\".*?<h2[^>]*>(.*?)</h2>.*?(?:<p[^>]*>(.*?)</p>)?")
	var strip := RegEx.new()
	strip.compile("(?s)<[^>]+>")
	for m in re.search_all(html):
		if out.size() >= limit:
			break
		var title := strip.sub(m.get_string(1), "", true).strip_edges()
		var snip := ""
		if m.get_string(2) != "":
			snip = strip.sub(m.get_string(2), "", true).strip_edges()
		if title == "":
			continue
		out.append("%d. %s\n   %s" % [out.size() + 1, title, snip])
	return "\n".join(out)

