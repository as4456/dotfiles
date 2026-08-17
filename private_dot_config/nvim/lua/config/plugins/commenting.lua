-- Replaces Comment.nvim, which was unmaintained from August 2024 and is now redundant:
-- Neovim 0.10+ provides `gc`, `gcc`, `gbc`, `gco`, `gcO` and `gcA` natively.
--
-- What core does NOT do is pick the right comment syntax for embedded languages — the
-- JSX case, where a comment inside a JSX expression needs {/* */} rather than //.
-- That is the only reason this plugin remains.
return {
	"JoosepAlviste/nvim-ts-context-commentstring",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		-- The plugin's legacy module hooked into Comment.nvim, which is gone.
		vim.g.skip_ts_context_commentstring_module = true

		require("ts_context_commentstring").setup({
			-- Core asks for 'commentstring' at the moment it comments, so computing it
			-- on every cursor move would be wasted work.
			enable_autocmd = false,
		})

		-- The documented native-commenting integration: core resolves 'commentstring'
		-- through vim.filetype.get_option, so wrapping that is what makes `gc`
		-- treesitter-aware without any plugin mappings.
		local get_option = vim.filetype.get_option
		vim.filetype.get_option = function(filetype, option)
			if option ~= "commentstring" then
				return get_option(filetype, option)
			end
			local ok, cs = pcall(require("ts_context_commentstring.internal").calculate_commentstring)
			if ok and cs then
				return cs
			end
			return get_option(filetype, option)
		end
	end,
}
