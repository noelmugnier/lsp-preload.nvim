-- Detect workspace languages via marker files at the project root.
local M = {}

-- Entries are { lang, markers }. Each marker is a glob pattern evaluated
-- against the workspace root. First matching marker wins per language.
local MARKERS = {
	{ "go", { "go.mod", "go.work" } },
	{ "rust", { "Cargo.toml" } },
	{ "csharp", { "*.sln", "*.slnx", "*.csproj", "*.fsproj" } },
	{ "python", { "pyproject.toml" } },
	{ "php", { "composer.json" } },
	{ "zig", { "build.zig" } },
}

---@param cwd string
---@return string[] detected language keys
function M.detect(cwd)
	local found, seen = {}, {}
	for _, entry in ipairs(MARKERS) do
		local lang, markers = entry[1], entry[2]
		for _, pattern in ipairs(markers) do
			if #vim.fn.glob(cwd .. "/" .. pattern, false, true) > 0 and not seen[lang] then
				seen[lang] = true
				table.insert(found, lang)
				break
			end
		end
	end
	return found
end

return M
