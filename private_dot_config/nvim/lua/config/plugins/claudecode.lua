-- Claude Code IDE integration: the same WebSocket protocol the VS Code and JetBrains
-- extensions use. Claude sees the current buffer and visual selection, and proposed
-- edits open as diffs here to accept (<leader>aa) or deny (<leader>ad).
--
-- The terminal opens through snacks.nvim, which is already loaded for input/indent;
-- snacks' terminal module does not need enabling in its opts to be called.

-- On Windows, Git Bash's .bashrc exports ANTHROPIC_API_KEY for project scripts and
-- relies on a shell alias to strip it before `claude` runs. Neovim never sees that
-- alias, so strip it here, or Claude would bill the API key instead of the Team seat.
-- `env` is Git for Windows' coreutils binary. The plugin's own `env` option can set
-- variables but not unset them, so it cannot do this.
local terminal_cmd = nil
if vim.fn.has("win32") == 1 and vim.fn.executable("env") == 1 then
	terminal_cmd = "env -u ANTHROPIC_API_KEY claude"
end

return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	-- Loaded at startup, not on first <leader>a key, so its WebSocket server and
	-- ~/.claude/ide/<port>.lock file exist from the moment nvim opens. That is what lets
	-- a Claude started in a *separate* herdr/tmux pane find this nvim with `/ide` (or
	-- `claude --ide`). Lazy-loaded, the server only appeared after a <leader>a press.
	lazy = false,
	opts = {
		terminal_cmd = terminal_cmd,
		terminal = {
			split_side = "right",
			split_width_percentage = 0.38,
		},
	},
	-- Command stubs so :ClaudeCode works before any <leader>a key has been pressed.
	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeSelectModel",
		"ClaudeCodeAdd",
		"ClaudeCodeSend",
		"ClaudeCodeTreeAdd",
		"ClaudeCodeStatus",
		"ClaudeCodeStart",
		"ClaudeCodeStop",
		"ClaudeCodeOpen",
		"ClaudeCodeClose",
		"ClaudeCodeDiffAccept",
		"ClaudeCodeDiffDeny",
		"ClaudeCodeCloseAllDiffs",
	},
	keys = {
		{ "<leader>a", nil, desc = "AI/Claude Code" },
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
		{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
		{ "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Add file", ft = { "NvimTree" } },
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
}
