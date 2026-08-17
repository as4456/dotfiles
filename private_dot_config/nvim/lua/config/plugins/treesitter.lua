-- Migrated to the `main` branch.
--
-- The `master` branch this previously pinned is frozen, and its own README declares
-- Neovim 0.12 unsupported — which is what we run. `main` is a ground-up rewrite, and
-- the maintainers are explicit that nothing carries over: treat it as a new plugin.
--
-- What that means concretely, since none of these options exist any more:
--   * `highlight`, `indent` and `incremental_selection` config blocks are gone.
--     Features are no longer switched on automatically — you start them yourself.
--   * `ensure_installed` is replaced by require('nvim-treesitter').install{}.
--   * `incremental_selection` has a native replacement in 0.12: `an`/`in` in visual
--     mode grow and shrink the selection by node, plus `]n`/`[n`. The old
--     <C-space> / <BS> mappings are therefore deleted rather than ported.
--   * `main` does not support lazy-loading, hence lazy = false.
--
-- Parsers are compiled locally and still need a C compiler. There is no precompiled
-- distribution, and the WebAssembly route needs Neovim built with wasmtime, which the
-- release builds are not. `zig` from mise provides the compiler with no root.
local PARSERS = {
	"bash",
	"c",
	"cpp",
	"css",
	"dockerfile",
	"gitignore",
	"graphql",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"prisma",
	"python",
	"query",
	"rust",
	"sql",
	"svelte",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup()

			local has_cc = vim.fn.executable("cc") == 1
				or vim.fn.executable("gcc") == 1
				or vim.fn.executable("clang") == 1

			if has_cc then
				-- Async. Already-installed parsers are skipped, so this is cheap on
				-- every start after the first.
				require("nvim-treesitter").install(PARSERS)
			else
				vim.notify(
					"No C compiler, so Treesitter parsers cannot be built. No root needed "
						.. "to fix it: `mise use -g zig`, then put a `cc` wrapper on PATH "
						.. "that execs `zig cc`.",
					vim.log.levels.WARN
				)
			end

			-- On `main` nothing is enabled for you. Rather than maintaining a
			-- filetype-to-parser list that drifts, ask Neovim which language a
			-- filetype maps to and start only when a parser is actually present.
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
				callback = function(ev)
					local lang = vim.treesitter.language.get_lang(ev.match)
					if not lang then
						return
					end
					if not pcall(vim.treesitter.start, ev.buf, lang) then
						return
					end
					vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					if vim.api.nvim_get_current_buf() == ev.buf then
						vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
					end
				end,
			})
		end,
	},
	{
		-- Independent of the branch rewrite: it drives vim.treesitter directly rather
		-- than registering as a Treesitter module, which is why the old
		-- `autotag = { enable = true }` block inside setup() silently did nothing.
		"windwp/nvim-ts-autotag",
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
	},
}
