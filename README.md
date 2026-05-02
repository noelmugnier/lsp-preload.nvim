# lsp-preload.nvim

Start workspace-scoped language servers at `VimEnter` so the LSP is already
warm by the time you open the first file. Useful for slow starters like
gopls on a large module, roslyn on a big solution, or rustaceanvim on a
multi-crate workspace.

## How it works

On startup (or via `:LspPreloadRun`) the plugin:

1. Looks at the current working directory.
2. Detects which languages are present from marker files at the workspace
   root (see table below).
3. For each detected language, starts the LSP using one of two strategies:
   - **native** — calls `vim.lsp.start()` directly with the config you
     registered under `lsp/<name>.lua` (Neovim 0.11+ native layout). The
     resulting client is auto-attached to future buffers of the matching
     filetype, so opening a file does not spawn a second server.
   - **trigger_file** — the LSP is owned by a plugin that hooks
     `FileType` / `BufReadPost` (roslyn.nvim, rustaceanvim...). The plugin
     silently `bufadd` + `bufload`s the first matching file in a hidden,
     unlisted buffer so the plugin's normal attach path runs.

File-type-scoped LSPs (eslint, tailwindcss, html, etc.) are deliberately
excluded — they belong on the buffer they service, not on a workspace.

## Supported languages

Detection relies on marker files at the workspace root:

| Language | Marker(s)                              | Strategy       | Server(s)                                      |
| -------- | -------------------------------------- | -------------- | ---------------------------------------------- |
| go       | `go.mod`, `go.work`                    | `native`       | `gopls`                                        |
| python   | `pyproject.toml`                       | `native`       | `pyright`, `ruff`                              |
| php      | `composer.json`                        | `native`       | `phpactor`                                     |
| zig      | `build.zig`                            | `native`       | `zls`                                          |
| csharp   | `*.sln`, `*.slnx`, `*.csproj`          | `trigger_file` | first `**/*.cs` triggers roslyn.nvim           |
| rust     | `Cargo.toml`                           | `trigger_file` | first `src/**/*.rs` triggers rustaceanvim      |

For native-strategy languages, you must already have a config file at
`<stdpath('config')>/lsp/<name>.lua` returning a `vim.lsp.Config` table
with at least a `cmd` field. The plugin only fires `vim.lsp.start` — it
does not install or configure servers for you.

## Requirements

- Neovim 0.11+ (native `vim.lsp.config` / `lsp/<name>.lua` layout).
- Server configs declared under `~/.config/nvim/lsp/<name>.lua` for the
  native strategy.
- The relevant plugin installed for trigger_file languages
  (`seblj/roslyn.nvim`, `mrcjkb/rustaceanvim`...).

## Install (lazy.nvim)

```lua
{
  "noelmugnier/lsp-preload.nvim",
  event = "VeryLazy",
  opts = {
    -- Allow-list of workspace roots. The plugin only runs when the
    -- current cwd is inside one of these directories (recursively).
    -- If empty or omitted, the plugin does nothing — opt-in by design.
    paths = { "~/projects", "~/Projects" },
  },
}
```

`VeryLazy` fires after `VimEnter`. The plugin detects this and runs the
preload immediately instead of registering a no-op autocmd.

## Configuration

```lua
require("lsp-preload").setup({
  paths = { "~/work", "~/oss" }, -- optional allow-list of workspace roots
})
```

| Option  | Type       | Default | Description                                                      |
| ------- | ---------- | ------- | ---------------------------------------------------------------- |
| `paths` | `string[]` | `{}`    | Allow-list of workspace roots (supports `~`). Preload only runs when cwd is inside one of them. Empty = plugin is a no-op. |

## Commands & toggles

| Command / variable               | Effect                                                            |
| -------------------------------- | ----------------------------------------------------------------- |
| `:LspPreloadRun`                 | Run preload manually for the current cwd.                         |
| `:LspPreloadToggle`              | Flip `vim.g.lsp_preload_enabled` for the current session.         |
| `vim.g.lsp_preload_enabled = false` | Set before `VimEnter` to skip the automatic preload entirely. |

## Notes

- For `trigger_file` languages, the dummy buffer occasionally produces
  `textDocument/diagnostic` errors while the server is still loading the
  solution/workspace. This is expected and disappears once the server is
  ready.
- The plugin attaches the started native client to future buffers of the
  matching filetype, so a single workspace will not end up with two
  competing LSP clients.
