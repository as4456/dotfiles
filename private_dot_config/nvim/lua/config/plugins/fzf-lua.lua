-- Replaces telescope.nvim.
--
-- The deciding factor is that fzf-lua needs no build step at all: it drives the `fzf`
-- binary, which is already installed via mise, so matching and grepping happen in a
-- compiled Go process rather than on Neovim's event loop. telescope's fast sorter
-- (telescope-fzf-native) is a C library that has to be compiled locally.
--
-- The "telescope" profile keeps the layout and keybinds close to what was here before,
-- so the migration costs no muscle memory.
return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = "FzfLua",
	keys = {
		{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files in cwd" },
		{ "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Find recent files" },
		{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Find string in cwd" },
		{ "<leader>fc", "<cmd>FzfLua grep_cword<cr>", desc = "Find string under cursor" },
		{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Show buffers" },
		{ "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Search help tags" },
		{ "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Search keymaps" },
		{ "<leader>fs", "<cmd>FzfLua resume<cr>", desc = "Resume last picker" },
		{ "<leader>ft", "<cmd>TodoFzfLua<cr>", desc = "Find todos" },
	},
	opts = {
		{ "telescope" },
		winopts = { preview = { default = "bat" } },
		keymap = {
			builtin = {
				["<C-d>"] = "preview-page-down",
				["<C-u>"] = "preview-page-up",
			},
			fzf = {
				-- Matches the old telescope insert-mode bindings.
				["ctrl-j"] = "down",
				["ctrl-k"] = "up",
				["ctrl-q"] = "select-all+accept",
			},
		},
	},
}
