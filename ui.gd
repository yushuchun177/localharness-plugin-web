extends VBoxContainer
## 本插件的设置界面 —— 由插件自己提供，主程序只负责挂载。
## 想加/改任何东西（多一个开关、换一段说明），改这个文件即可。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(PluginUI.plugin_header(plugin_id))
	add_child(PluginUI.overview(plugin_id))
	add_child(PluginUI.settings_section(plugin_id))
	add_child(PluginUI.permissions_section(plugin_id))
	add_child(PluginUI.doc_section(plugin_id))
