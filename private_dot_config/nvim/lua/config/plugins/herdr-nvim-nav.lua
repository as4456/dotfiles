-- Ctrl-h/j/k/l across nvim splits AND herdr panes: the vim-tmux-navigator experience,
-- for herdr. When the cursor reaches the edge of nvim's splits, the same chord moves
-- herdr's focus to the neighbouring pane (e.g. a Claude Code pane). Under tmux it
-- hands off to vim-tmux-navigator instead, so tmux keeps working unchanged.
--
-- WSL/Linux only: the plugin talks to herdr over a Unix socket and checks the nvim PID
-- with kill(pid, 0). On native Windows herdr uses named pipes, so there herdr's own
-- prefix+h/j/k/l moves between panes and Ctrl-h/j/k/l stays inside nvim.
--
-- The herdr half is a separate install (`herdr plugin install aimdevlee/herdr-nvim-nav`)
-- plus four [[keys.command]] bindings in herdr's config.toml, both managed alongside
-- this file.
return {
	"aimdevlee/herdr-nvim-nav",
	cond = vim.fn.has("win32") == 0,
	dependencies = { "christoomey/vim-tmux-navigator" },
	lazy = false,
	config = function()
		require("herdr-nvim-nav").setup({
			-- Its defaults also claim Ctrl+arrows, which core/keymaps.lua uses to resize
			-- splits. Keep only the hjkl chords.
			keymaps = {
				left = { "<C-h>" },
				down = { "<C-j>" },
				up = { "<C-k>" },
				right = { "<C-l>" },
			},
		})
	end,
}
