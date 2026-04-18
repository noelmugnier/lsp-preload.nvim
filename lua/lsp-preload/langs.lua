-- Per-language preload strategy.
--
-- Two flavours:
--   strategy = "native"      : call vim.lsp.start() directly with the config
--                              registered under lsp/<name>.lua (nvim 0.11+).
--                              Use this for LSPs you declared yourself via
--                              vim.lsp.enable().
--   strategy = "trigger_file": the LSP is provided by a plugin that hooks
--                              FileType / BufReadPost (roslyn.nvim,
--                              rustaceanvim...). We can't start it manually,
--                              but loading the first matching file silently
--                              will trigger the plugin's normal attach path.
local M = {}

M.specs = {
	go = {
		strategy = "native",
		lsps = { "gopls" },
		-- Root dir for gopls follows the standard Go layout.
		root_markers = { "go.work", "go.mod" },
		filetype = "go",
	},
	python = {
		strategy = "native",
		lsps = { "pyright", "ruff" },
		root_markers = { "pyproject.toml", "setup.py", "setup.cfg" },
		filetype = "python",
	},
	php = {
		strategy = "native",
		lsps = { "phpactor" },
		root_markers = { "composer.json" },
		filetype = "php",
	},
	zig = {
		strategy = "native",
		lsps = { "zls" },
		root_markers = { "build.zig" },
		filetype = "zig",
	},
	csharp = {
		strategy = "trigger_file",
		-- Load the first .cs found; roslyn.nvim picks it up on FileType.
		trigger_glob = "**/*.cs",
	},
	rust = {
		strategy = "trigger_file",
		-- rustaceanvim attaches on FileType=rust.
		trigger_glob = "src/**/*.rs",
	},
}

return M
