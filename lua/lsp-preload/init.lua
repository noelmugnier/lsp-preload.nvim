-- Preload LSP clients for the detected workspace languages at startup.
local M = {}

local detect = require("lsp-preload.detect")
local langs = require("lsp-preload.langs")

---Find the first file in the workspace matching a glob.
local function first_file(cwd, glob)
	local matches = vim.fn.glob(cwd .. "/" .. glob, false, true)
	return matches[1]
end

---Resolve the project root for a `native`-strategy LSP by walking up from
---cwd looking for one of the markers. Falls back to cwd.
local function project_root(cwd, markers)
	local found = vim.fs.find(markers, { path = cwd, upward = true, stop = vim.env.HOME })[1]
	return found and vim.fs.dirname(found) or cwd
end

---Load the config registered under `lsp/<name>.lua` in the user config.
---These files return a vim.lsp.Config table (nvim 0.11+ native layout).
local function load_lsp_config(name)
	local path = vim.fn.stdpath("config") .. "/lsp/" .. name .. ".lua"
	if vim.fn.filereadable(path) == 0 then
		return nil
	end
	local ok, cfg = pcall(dofile, path)
	if not ok or type(cfg) ~= "table" then
		return nil
	end
	return cfg
end

---Start a native LSP for a given language spec.
local function start_native(spec, cwd)
	local root = project_root(cwd, spec.root_markers or {})
	for _, name in ipairs(spec.lsps or {}) do
		local cfg = load_lsp_config(name)
		if cfg and cfg.cmd then
			local client_id = vim.lsp.start(
				vim.tbl_extend("force", cfg, {
					name = name,
					root_dir = root,
				}),
				{ attach = false }
			)
			if client_id and spec.filetype then
				-- Attach the running client to future buffers of the matching
				-- filetype so they don't spawn a second server.
				vim.api.nvim_create_autocmd("FileType", {
					pattern = spec.filetype,
					callback = function(ev)
						vim.lsp.buf_attach_client(ev.buf, client_id)
					end,
				})
			end
		end
	end
end

---Load the first matching file in a background buffer so a plugin-managed
---LSP (roslyn.nvim, rustaceanvim...) attaches on BufReadPost/FileType.
---The buffer is kept out of the user's way (not listed, not displayed).
---Occasional "textDocument/diagnostic" errors from servers that send
---requests against the dummy before solution load finishes are accepted
---as a price for the warm server.
local function start_via_trigger_file(spec, cwd)
	local path = first_file(cwd, spec.trigger_glob)
	if not path then
		return
	end
	local bufnr = vim.fn.bufadd(path)
	vim.fn.bufload(bufnr)
	vim.bo[bufnr].buflisted = false
	vim.bo[bufnr].bufhidden = "hide"
end

---Expand ~ and resolve to an absolute path.
local function normalize(path)
	return vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/$", "")
end

---Return true if `cwd` is inside any of the configured allow-list paths.
---No paths configured = no restriction (backward compat).
local function cwd_allowed(cwd, allowed)
	if not allowed or #allowed == 0 then
		return true
	end
	local abs_cwd = normalize(cwd) .. "/"
	for _, base in ipairs(allowed) do
		local abs_base = normalize(base) .. "/"
		if abs_cwd:sub(1, #abs_base) == abs_base then
			return true
		end
	end
	return false
end

---@param cwd? string override for auto-detect (tests)
function M.preload(cwd)
	cwd = cwd or vim.fn.getcwd()
	-- Never scan filesystem-root-like paths: the trigger_file strategy
	-- calls glob("/**/*.cs") which would walk the entire disk.
	if cwd == "/" or cwd == vim.env.HOME or cwd == "/Users" then
		return
	end
	if not cwd_allowed(cwd, M._opts.paths) then
		return
	end
	for _, lang in ipairs(detect.detect(cwd)) do
		local spec = langs.specs[lang]
		if spec then
			if spec.strategy == "native" then
				start_native(spec, cwd)
			elseif spec.strategy == "trigger_file" then
				start_via_trigger_file(spec, cwd)
			end
		end
	end
end

M._opts = { paths = {} }

---@class lsp_preload.Opts
---@field paths? string[] only preload when cwd is under one of these (supports ~)
function M.setup(opts)
	M._opts = vim.tbl_extend("force", M._opts, opts or {})
	local function run()
		if vim.g.lsp_preload_enabled == false then
			return
		end
		vim.schedule(function()
			M.preload()
		end)
	end

	-- Lazy may load us on VeryLazy, which fires *after* VimEnter has
	-- already completed. In that case register nothing and run now;
	-- otherwise wait for VimEnter so plugin configs have settled.
	if vim.v.vim_did_enter == 1 then
		run()
	else
		vim.api.nvim_create_autocmd("VimEnter", { callback = run, once = true })
	end
end

return M
