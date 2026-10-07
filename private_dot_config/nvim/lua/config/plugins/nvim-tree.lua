return {
	"nvim-tree/nvim-tree.lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local nvimtree = require("nvim-tree")

		-- recommended settings from nvim-tree documentation
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		-- change color for arrows in tree to light blue
		vim.cmd([[ highlight NvimTreeFolderArrowClosed guifg=#3FC5FF ]])
		vim.cmd([[ highlight NvimTreeFolderArrowOpen guifg=#3FC5FF ]])

		-- Sort order, toggled with <leader>es. Default is VS Code's "sort by modified":
		-- most recently modified file first, folders still on top. Note it is
		-- *modification* time: running a script doesn't move it, saving it does.
		vim.g.nvim_tree_sorter = vim.g.nvim_tree_sorter or "modification_time"

		-- configure nvim-tree
		nvimtree.setup({
			sort = {
				-- A function so the toggle below can change the order without re-running setup.
				sorter = function()
					return vim.g.nvim_tree_sorter
				end,
				folders_first = true,
			},
			view = {
				width = 35,
				relativenumber = true,
			},
			-- change folder arrow icons
			renderer = {
				indent_markers = {
					enable = true,
				},
				icons = {
					glyphs = {
						folder = {
							arrow_closed = "", -- arrow when folder is closed
							arrow_open = "", -- arrow when folder is open
						},
					},
				},
			},
			-- disable window_picker for
			-- explorer to work well with
			-- window splits
			actions = {
				open_file = {
					window_picker = {
						enable = false,
					},
				},
			},
			-- filters = {
			-- 	custom = { ".DS_Store" },
			-- },
			git = {
				ignore = false,
			},
		})

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set(
			"n",
			"<leader>em",
			"<cmd>NvimTreeFocus<CR>",
			{ desc = "Focus on the current file in file explorer", noremap = true, silent = true }
		)
		keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
		keymap.set(
			"n",
			"<leader>ef",
			"<cmd>NvimTreeFindFileToggle<CR>",
			{ desc = "Toggle file explorer on current file" }
		) -- toggle file explorer on current file
		keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }) -- collapse file explorer
		keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" }) -- refresh file explorer
		keymap.set("n", "<leader>es", function()
			vim.g.nvim_tree_sorter = vim.g.nvim_tree_sorter == "modification_time" and "name" or "modification_time"
			require("nvim-tree.api").tree.reload()
			vim.notify(
				"File explorer sorted by "
					.. (vim.g.nvim_tree_sorter == "name" and "name (A–Z)" or "last modified (newest first)")
			)
		end, { desc = "Toggle explorer sort: modified / name" })
	end,
}
