if vim.g.loaded_lsp_preload then
	return
end
vim.g.loaded_lsp_preload = true

vim.api.nvim_create_user_command("LspPreloadToggle", function()
	vim.g.lsp_preload_enabled = vim.g.lsp_preload_enabled == false
	vim.notify(
		"lsp-preload: " .. (vim.g.lsp_preload_enabled and "enabled" or "disabled"),
		vim.log.levels.INFO
	)
end, { desc = "Toggle lsp-preload for the current session" })

vim.api.nvim_create_user_command("LspPreloadRun", function()
	require("lsp-preload").preload()
end, { desc = "Manually run lsp-preload for the current workspace" })
