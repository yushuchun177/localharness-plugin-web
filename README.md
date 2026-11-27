# 网页搜索与获取 / Web search & fetch

抓取网页正文（curl 转纯文本）和 DuckDuckGo 关键词搜索，把结果喂给模型。

Fetch page text and search DuckDuckGo.

> Local-Harness（Godot 版）的独立插件。不随主程序发布，由主程序
> 「设置 → 插件管理」从 GitHub 下载并自动部署到 `user://plugins/web/`。

## 安装

1. 打开 Local-Harness → 设置 → 插件管理 → 刷新列表
2. 找到「网页搜索与获取」点「安装」
3. 装好后在侧栏底部点同名按钮，里面是这个插件自己的设置页

手动安装：把本仓库下载解压到 `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\web\`

## 工具

- `web_fetch` —— 抓取一个网页并返回纯文本（去掉标签），最多返回 6000 字。（只读）
  - `url`: string，完整网址
  - `max_chars`: int，可选，默认 6000
- `web_search` —— 用 DuckDuckGo 搜索关键词，返回标题 + 链接 + 摘要（前 8 条）。（只读）
  - `query`: string，搜索词
  - `limit`: int，可选，默认 8

## 命令

（没有命令）

## 设置项

- **抓取上限（字符）**（`max_chars`，默认 `6000`）网页转文本后最多返回多少字

## 权限

每个工具都能在插件设置页里单独开关。关掉之后它不会出现在模型的工具清单里，
就算模型硬要调用也会被主程序拒绝。协议里用 `level` 标了风险等级：

- `read` 只读：不会改动任何东西
- `act` 会产生操作：会读写文件、联网或占用设备
- `danger` 高危：会操作你的系统

## 怎么用

装好后直接在对话里提需求，例如：“抓取一个网页并返回纯文本（去掉标签），最多返回 6000 字。”

模型会输出一行 ```tool 协议块，宿主解析后执行，再把结果喂回模型。
也可以直接用斜杠命令，不经过模型。

## 许可

GPL-3.0（与主程序一致）。完整协议文本见仓库根目录的 [LICENSE](LICENSE)。

---

# Web search & fetch

Fetch page text and search DuckDuckGo.

> An independent plugin for **Local-Harness (Godot edition)**. It is not bundled with the
> app; the app downloads it from this repository into `user://plugins/web/` and hot-loads it.

## Install

1. Local-Harness → Settings → Plugins → Refresh
2. Find "Web search & fetch" and click Install
3. Open it from the button at the bottom of the sidebar for its own settings page

Manual: unzip this repo into `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\web\`

## Tools

- `web_fetch` — 抓取一个网页并返回纯文本（去掉标签），最多返回 6000 字。 (read-only)
  - `url`: string，完整网址
  - `max_chars`: int，可选，默认 6000
- `web_search` — 用 DuckDuckGo 搜索关键词，返回标题 + 链接 + 摘要（前 8 条）。 (read-only)
  - `query`: string，搜索词
  - `limit`: int，可选，默认 8

## Commands

(no commands)

## Settings

- **抓取上限（字符）** (`max_chars`, default `6000`) 网页转文本后最多返回多少字

## Permissions

Every tool can be toggled individually on the plugin settings page. A disabled tool is
removed from the model's tool list and rejected by the host even if the model still calls it.
`level` in the manifest marks the risk:

- `read` — no side effects
- `act` — reads/writes, network or devices
- `danger` — controls your system

## Usage

Just ask in the chat, e.g. “抓取一个网页并返回纯文本（去掉标签），最多返回 6000 字。”

The model emits a ```tool block, the host executes it and feeds the result back.
You can also use the slash commands above, which skip the model entirely.

## License

GPL-3.0 (same as the host app). Full text: [LICENSE](LICENSE).
