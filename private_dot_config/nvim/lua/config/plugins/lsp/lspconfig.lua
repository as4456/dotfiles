return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
		"williamboman/mason.nvim",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-buffer",
		"windwp/nvim-autopairs",
		"creativenull/efmls-configs-nvim",
	},
	config = function()
		local lspconfig = require("lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local mason_lspconfig = require("mason-lspconfig")
		local keymap = vim.keymap

		-- Keybindings setup
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, noremap = true, silent = true }

				-- Set keybinds
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
				keymap.set("n", "K", vim.lsp.buf.hover, opts)
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

				-- Add format keybind
				opts.desc = "Format current buffer"
				keymap.set("n", "<leader>bf", function()
					vim.lsp.buf.format({ async = true })
				end, opts)

				-- Add Pyright-specific keybind
				if vim.lsp.get_client_by_id(ev.data.client_id).name == "pyright" then
					opts.desc = "Organize Imports"
					keymap.set("n", "<leader>oi", "<cmd>PyrightOrganizeImports<CR>", opts)
				end
			end,
		})

		-- Capabilities for autocompletion
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Diagnostic signs
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		-- Default handler for installed servers
		local function default_handler(server_name)
			lspconfig[server_name].setup({
				capabilities = capabilities,
			})
		end

		-- Server-specific setups
		local server_setups = {
			lua_ls = function()
				lspconfig.lua_ls.setup({
					capabilities = capabilities,
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = {
								library = {
									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
									[vim.fn.stdpath("config") .. "/lua"] = true,
								},
							},
							completion = { callSnippet = "Replace" },
						},
					},
				})
			end,
			pyright = function()
				lspconfig.pyright.setup({
					capabilities = capabilities,
					settings = {
						python = {
							analysis = {
								typeCheckingMode = "off", -- Disable type checking as we'll use Ruff for this
							},
						},
					},
				})
			end,
			clangd = function()
				lspconfig.clangd.setup({
					capabilities = capabilities,
					cmd = { "clangd", "--offset-encoding=utf-16" },
				})
			end,
			svelte = function()
				lspconfig.svelte.setup({
					capabilities = capabilities,
					on_attach = function(client, bufnr)
						vim.api.nvim_create_autocmd("BufWritePost", {
							pattern = { "*.js", "*.ts" },
							callback = function(ctx)
								client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
							end,
						})
					end,
				})
			end,
			graphql = function()
				lspconfig.graphql.setup({
					capabilities = capabilities,
					filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
				})
			end,
			emmet_ls = function()
				lspconfig.emmet_ls.setup({
					capabilities = capabilities,
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
			end,
			-- TypeScript and JavaScript
			tsserver = function()
				lspconfig.tsserver.setup({
					capabilities = capabilities,
					filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
					root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
				})
			end,

			-- CSS
			cssls = function()
				lspconfig.cssls.setup({
					capabilities = capabilities,
					filetypes = { "css", "scss", "less" },
				})
			end,
		}

		-- Set up mason-lspconfig
		mason_lspconfig.setup_handlers({
			function(server_name)
				if server_setups[server_name] then
					server_setups[server_name]()
				else
					default_handler(server_name)
				end
			end,
		})
		local eslint = require("efmls-configs.linters.eslint")
		local prettier = require("efmls-configs.formatters.prettier")
		local stylelint = require("efmls-configs.linters.stylelint")
		-- Set up EFM language server
		local efmls_config = {
			filetypes = {
				"lua",
				"python",
				"markdown",
				"docker",
				"c",
				"cpp",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"css",
				"scss",
				"less",
				"html",
			},
			init_options = {
				documentFormatting = true,
				documentRangeFormatting = true,
				hover = true,
				documentSymbol = true,
				codeAction = true,
				completion = true,
			},
			settings = {
				languages = {
					lua = { require("efmls-configs.linters.luacheck"), require("efmls-configs.formatters.stylua") },
					python = { require("efmls-configs.linters.ruff"), require("efmls-configs.formatters.ruff") },
					markdown = { require("efmls-configs.formatters.prettier_d") },
					docker = {
						require("efmls-configs.linters.hadolint"),
						require("efmls-configs.formatters.prettier_d"),
					},
					c = { require("efmls-configs.formatters.clang_format"), require("efmls-configs.linters.cpplint") },
					cpp = { require("efmls-configs.formatters.clang_format"), require("efmls-configs.linters.cpplint") },
					yaml = { prettier },
					json = { prettier },
					javascript = { eslint, prettier },
					javascriptreact = { eslint, prettier },
					typescript = { eslint, prettier },
					typescriptreact = { eslint, prettier },
					css = { stylelint, prettier },
					scss = { stylelint, prettier },
					less = { stylelint, prettier },
					html = { prettier },
				},
			},
		}
		lspconfig.efm.setup(efmls_config)
	end,
}
