-- Replaces dressing.nvim, which its author archived in February 2025 pointing readers
-- here. Only the modules that earn their place are enabled — snacks bundles about 35,
-- and turning them all on would be adopting a whole UI framework to replace one plugin.
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		-- What dressing actually provided: a decent floating vim.ui.input.
		input = { enabled = true },

		-- Adds scope highlighting over indent-blankline's plain guides. Both are
		-- loaded; indent-blankline draws the guides, snacks highlights the active
		-- scope. Disable one if they visually fight.
		indent = { enabled = true, scope = { enabled = true } },

		-- Skips syntax, treesitter and LSP on very large files so they open instantly
		-- instead of hanging the editor.
		bigfile = { enabled = true },

		-- Everything else stays off deliberately: picker (fzf-lua does that),
		-- explorer (nvim-tree), notifier (noice), lazygit (lazygit.nvim), dashboard,
		-- zen, terminal, scratch.
	},
}
