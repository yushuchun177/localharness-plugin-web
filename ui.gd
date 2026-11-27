extends VBoxContainer
## 本插件的设置界面 —— 由插件自己提供，主程序只负责挂载。
## 想改这个插件在这里长什么样、有哪些开关，改这个文件即可。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(PluginUI.title("网页搜索与获取"))
	add_child(PluginUI.hint("抓网页正文、搜关键词。国内网络下会自动换 Bing 中国站。"))
	add_child(PluginUI.section("行为"))
	add_child(PluginUI.int_field(plugin_id, "max_chars", "抓取上限（字符）", 6000,
		"网页转成文本后最多返回多少字"))
	add_child(PluginUI.section("能力开关"))
	add_child(PluginUI.hint("每一项都能单独关掉；关掉后模型看不到这个能力，也调用不了。"))
	for t in Plugins.tools_of(plugin_id):
		var tname := str(t.get("name", ""))
		var human := tname
		var desc := str(t.get("description", ""))
		if tname == "web_fetch":
			human = "抓取网页"
			desc = "访问你给的网址并提取正文"
		if tname == "web_search":
			human = "搜索关键词"
			desc = "联网搜索，会暴露你的搜索词给搜索引擎"
		add_child(PluginUI.perm_row(tname, human, desc, bool(t.get("dangerous", false))))
	add_child(PluginUI.readme_box(plugin_id))
