-- Rewritten for mason-lspconfig 2.x and Neovim 0.11+.
--
-- What changed and why:
--   * mason-lspconfig 2.0 removed `setup_handlers`, which the previous version was
--     built on. It failed with "attempt to call field 'setup_handlers' (a nil value)".
--     Servers are now configured with vim.lsp.config() and enabled automatically.
--   * `tsserver` was renamed `ts_ls` upstream.
--   * efm-langserver is gone. It was configured to run ruff and eslint over the same
--     filetypes that nvim-lint already lints and conform already formats, so every
--     violation was reported twice and up to three formatters competed on save.
--     nvim-lint owns linting; conform owns formatting.
--   * neodev.nvim is deprecated; lua_ls gets its library paths directly instead.
return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"saghen/blink.cmp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		"mason-org/mason.nvim",
		"mason-org/mason-lspconfig.nvim",
		"ibhagwan/fzf-lua",
	},
	config = function()
		local keymap = vim.keymap

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, noremap = true, silent = true }

				keymap.set("n", "gR", "<cmd>FzfLua lsp_references<CR>", opts)
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", opts)
				keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<CR>", opts)
				keymap.set("n", "gt", "<cmd>FzfLua lsp_typedefs<CR>", opts)
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				keymap.set("n", "<leader>D", "<cmd>FzfLua diagnostics_document<CR>", opts)
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				-- vim.diagnostic.goto_prev/goto_next were deprecated in 0.11 in favour
				-- of vim.diagnostic.jump.
				keymap.set("n", "[d", function()
					vim.diagnostic.jump({ count = -1, float = true })
				end, opts)
				keymap.set("n", "]d", function()
					vim.diagnostic.jump({ count = 1, float = true })
				end, opts)

				keymap.set("n", "K", vim.lsp.buf.hover, opts)
				keymap.set("n", "<leader>rs", "<cmd>LspRestart<CR>", opts)

				opts.desc = "Format current buffer"
				keymap.set("n", "<leader>bf", function()
					vim.lsp.buf.format({ async = true })
				end, opts)

				local client = vim.lsp.get_client_by_id(ev.data.client_id)
				if client and client.name == "pyright" then
					opts.desc = "Organize Imports"
					keymap.set("n", "<leader>oi", "<cmd>PyrightOrganizeImports<CR>", opts)
				end
			end,
		})

		-- Diagnostic presentation. vim.diagnostic.config is the supported route in
		-- 0.10+; the old sign_define loop is no longer the recommended way.
		vim.diagnostic.config({
			virtual_text = true,
			severity_sort = true,
			float = { border = "rounded", source = true },
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
		})

		local capabilities = require("blink.cmp").get_lsp_capabilities()

		-- Applies to every server, including ones installed later.
		vim.lsp.config("*", { capabilities = capabilities })

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = {
						library = {
							vim.fn.expand("$VIMRUNTIME/lua"),
							vim.fn.stdpath("config") .. "/lua",
						},
						checkThirdParty = false,
					},
					completion = { callSnippet = "Replace" },
				},
			},
		})

		vim.lsp.config("pyright", {
			settings = {
				python = {
					analysis = {
						-- Previously "off", justified with "we'll use Ruff for this".
						-- Ruff is a linter and formatter and does not type check, so
						-- that left the setup with no type checking at all while
						-- looking configured. "basic" restores it; ruff still owns
						-- lint and format.
						typeCheckingMode = "basic",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
					},
				},
			},
		})

		vim.lsp.config("clangd", {
			cmd = { "clangd", "--offset-encoding=utf-16" },
		})

		vim.lsp.config("ts_ls", {
			filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		})

		vim.lsp.config("cssls", {
			filetypes = { "css", "scss", "less" },
		})

		vim.lsp.config("graphql", {
			filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
		})

		vim.lsp.config("emmet_ls", {
			filetypes = {
				"html",
				"typescriptreact",
				"javascriptreact",
				"css",
				"sass",
				"scss",
				"less",
				"svelte",
			},
		})

		vim.lsp.config("svelte", {
			on_attach = function(client)
				vim.api.nvim_create_autocmd("BufWritePost", {
					pattern = { "*.js", "*.ts" },
					callback = function(ctx)
						client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
					end,
				})
			end,
		})
	end,
}
