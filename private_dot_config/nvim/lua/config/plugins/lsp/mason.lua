-- Repositories moved from `williamboman` to the `mason-org` organisation.
return {
	"mason-org/mason.nvim",
	dependencies = {
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		require("mason").setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		require("mason-lspconfig").setup({
			ensure_installed = {
				-- "efm" removed: it duplicated nvim-lint's linting and conform's
				-- formatting over the same filetypes, so diagnostics appeared twice.
				-- "tsserver" is now "ts_ls" upstream; the old name fails to install.
				-- "lua_ls" was listed twice.
				"lua_ls",
				"pyright",
				"jsonls",
				"clangd",
				"ts_ls",
				"html",
				"cssls",
				"tailwindcss",
				"svelte",
				"graphql",
				"emmet_ls",
				"prismals",
			},
			-- mason-lspconfig 2.x: installed servers are enabled automatically, which
			-- is what replaced the setup_handlers mechanism.
			automatic_enable = true,
		})

		require("mason-tool-installer").setup({
			ensure_installed = {
				"prettier",
				"stylua",
				-- isort, black and pylint were installed but never invoked: conform
				-- formats Python with ruff and nvim-lint lints it with ruff. Ruff
				-- covers all three.
				"ruff",
				"eslint_d",
			},
		})
	end,
}
