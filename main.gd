extends Node
## 网页插件 · local-harness
## 工具：web_fetch(url, max_chars?) / web_search(query, limit?)
##
## 用系统自带的 curl.exe 抓取（Windows 10+ 内置），避免在 GDScript 里处理压缩和超时。
## 国内网络访问 DuckDuckGo 可能不通，失败时给出明确提示，不要假装搜到了。

const TIMEOUT := 25


func run(tool: String, args: Dictionary) -> Dictionary:
	match tool:
		"web_fetch":
			return _fetch(args)
		"web_search":
			return _search(args)
	return {"ok": false, "output": "未知工具：%s" % tool}


func _curl(url: String) -> String:
	var tmp := OS.get_temp_dir().path_join("lh_web_%d.html" % randi())
	var pid := OS.create_process("curl.exe", PackedStringArray([
		"-sL", "--max-time", str(TIMEOUT), "--compressed",
		"-A", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) local-harness",
		"-o", tmp, url,
	]), false)
	if pid <= 0:
		return ""
	var t0 := Time.get_ticks_msec()
	while OS.is_process_running(pid):
		if (Time.get_ticks_msec() - t0) / 1000.0 > TIMEOUT + 5:
			OS.kill(pid)
			break
		OS.delay_msec(40)
	var text := ""
	if FileAccess.file_exists(tmp):
		var f := FileAccess.open(tmp, FileAccess.READ)
		if f:
			text = f.get_as_text()
		DirAccess.remove_absolute(tmp)
	return text


func _to_text(html: String) -> String:
	var s := html
	var re_script := RegEx.new()
	re_script.compile("(?is)<(script|style)[^>]*>.*?</\\1>")
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
	var limit := int(args.get("max_chars", 6000))
	var html := _curl(url)
	if html.strip_edges() == "":
		return {"ok": false, "output": "抓取失败或页面为空：%s" % url}
	var txt := _to_text(html)
	if txt.length() > limit:
		txt = txt.substr(0, limit) + "\n…（已截断）"
	return {"ok": true, "output": txt}


func _search(args: Dictionary) -> Dictionary:
	var q := str(args.get("query", "")).strip_edges()
	if q == "":
		return {"ok": false, "output": "query 不能为空"}
	var limit := int(args.get("limit", 8))
	var url := "https://html.duckduckgo.com/html/?q=" + q.uri_encode()
	var html := _curl(url)
	if html.strip_edges() == "":
		return {"ok": false, "output": "搜索请求失败（这个网络环境可能访问不到 DuckDuckGo）"}
	var out: PackedStringArray = []
	var re := RegEx.new()
	re.compile("(?s)class=\"result__a\"[^>]*>(.*?)</a>.*?class=\"result__snippet\"[^>]*>(.*?)</a>")
	var title_re := RegEx.new()
	title_re.compile("(?s)<[^>]+>")
	for m in re.search_all(html):
		if out.size() >= limit:
			break
		var title := title_re.sub(m.get_string(1), "").strip_edges()
		var snippet := title_re.sub(m.get_string(2), "").strip_edges()
		out.append("%d. %s\n   %s" % [out.size() + 1, title, snippet])
	if out.is_empty():
		return {"ok": false, "output": "没有解析到结果（页面结构可能变了）"}
	return {"ok": true, "output": "\n".join(out)}
