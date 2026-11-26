# 网页搜索与获取

抓取网页正文、DuckDuckGo 关键词搜索。

Local-Harness（Godot 版）的独立插件。**不随主程序发布**，由主程序「设置 → 插件管理」从 GitHub 下载并自动部署到 `user://plugins/web/`。

## 工具

- `web_fetch` —— 抓取一个网页并返回纯文本（去掉标签），最多返回 6000 字。
  - `url`: string，完整网址
  - `max_chars`: int，可选，默认 6000
- `web_search` —— 用 DuckDuckGo 搜索关键词，返回标题 + 链接 + 摘要（前 8 条）。
  - `query`: string，搜索词
  - `limit`: int，可选，默认 8

## 安装

1. 打开 Local-Harness → 设置 → 插件管理 → 刷新列表
2. 找到「网页搜索与获取」点安装
3. 装完直接在对话里让模型调用即可（插件会出现在系统提示的工具清单里）

也可以手动：把本仓库下载解压到 `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\web\`。

## 结构

```
manifest.json   清单：id / 版本 / 工具定义
main.gd         extends Node，实现 run(tool, args) -> {ok, output}
```

## 许可

GPL-3.0（与主程序一致）。
