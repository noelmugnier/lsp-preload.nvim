# lsp-preload.nvim

Start workspace-scoped language servers at `VimEnter` so you don't need
to open a file first before the LSP warms up.

## Supported languages

Detection relies on marker files at the workspace root:

| Language | Marker(s)                         | Strategy                                    |
| -------- | --------------------------------- | ------------------------------------------- |
| go       | `go.mod`, `go.work`               | `vim.lsp.start` gopls with root_dir         |
| python   | `pyproject.toml`                  | `vim.lsp.start` pyright + ruff              |
| php      | `composer.json`                   | `vim.lsp.start` phpactor                    |
| zig      | `build.zig`                       | `vim.lsp.start` zls                         |
| csharp   | `*.sln`, `*.slnx`, `*.csproj`     | silently `:edit` first `.cs` to trigger roslyn.nvim |
| rust     | `Cargo.toml`                      | silently `:edit` first `src/**/*.rs` to trigger rustaceanvim |

File-type-scoped LSPs (eslint, tailwindcss, html, etc.) are deliberately
excluded — they belong on the buffer they service, not on a workspace.

## Install (lazy.nvim)

```lua
{
  dir = "~/Projects/Perso/lsp-preload.nvim",
  dev = true,
  event = "VeryLazy",
  config = true,
}
```

## Toggling

`vim.g.lsp_preload_enabled = false` before `VimEnter` skips the preload.
`:LspPreloadToggle` flips the flag at runtime; `:LspPreloadRun` runs it
manually.
