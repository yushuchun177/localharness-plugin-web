extends VBoxContainer
## 网页搜索与获取 —— 这个页面是插件自己提供的界面。
## 界面全部由插件自己拼，主程序只提供积木。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_child(PluginUI.section("抓多少"))
	add_child(PluginUI.slider_row(plugin_id, "max_chars", "一次最多返回多少字", 1000, 20000, 1000, "字", 6000,
		"太长会占满上下文，6000 左右够用"))
	add_child(PluginUI.action_row("测试一下抓网页", "抓 example.com 验证网络是否通", "测试",
		func(): return Plugins.invoke("web_fetch", {"url": "https://example.com", "max_chars": 600})))
	add_child(PluginUI.overview(plugin_id))
	add_child(PluginUI.permissions_section(plugin_id))
	add_child(PluginUI.doc_section(plugin_id))
