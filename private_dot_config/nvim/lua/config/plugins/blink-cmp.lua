-- Replaces nvim-cmp and its satellite plugins.
--
-- This collapses seven specs into two: nvim-cmp, cmp-buffer, cmp-path, cmp-nvim-lsp,
-- cmp_luasnip, LuaSnip and lspkind become blink.cmp plus friendly-snippets. blink has
-- buffer, path, snippet and LSP sources built in, draws its own kind icons, and uses
-- Neovim's native vim.snippet rather than LuaSnip.
--
-- No toolchain needed: prebuilt matcher binaries ship with each release and are
-- fetched automatically, with a pure-Lua fallback if that fails.
--
-- Pinned to 1.x deliberately. `main` is V2, has many breaking changes, and needs a
-- separate blink.lib install.
return {
	"saghen/blink.cmp",
	version = "1.*",
	event = "InsertEnter",
	dependencies = { "rafamadriz/friendly-snippets" },
	opts = {
		keymap = {
			preset = "default",

			-- Carried over from the nvim-cmp config so muscle memory survives.
			["<C-j>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
			["<C-e>"] = { "hide", "fallback" },
			["<CR>"] = { "accept", "fallback" },

			-- Snippet placeholder navigation, which was never mapped under nvim-cmp —
			-- snippets expanded and then you could not reach the next placeholder.
			-- Insert mode only, so <C-h> here does not touch the normal-mode
			-- vim-tmux-navigator binding.
			["<C-l>"] = { "snippet_forward", "fallback" },
			["<C-h>"] = { "snippet_backward", "fallback" },
		},

		appearance = {
			-- "mono" matches JetBrainsMono Nerd Font, which the terminal is set to.
			nerd_font_variant = "mono",
		},

		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 200 },
			-- Matches the old cmp behaviour: Enter only confirms an item you have
			-- explicitly selected, otherwise it inserts a newline.
			list = { selection = { preselect = false, auto_insert = true } },
			menu = { border = "rounded" },
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		fuzzy = {
			-- Downloads the prebuilt Rust matcher; warns and falls back to Lua if that
			-- is not possible.
			implementation = "prefer_rust_with_warning",
		},

		signature = { enabled = true },
	},
	opts_extend = { "sources.default" },
}
