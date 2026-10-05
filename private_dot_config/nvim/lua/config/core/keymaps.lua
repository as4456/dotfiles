-- Leader is Space. (The previous comment here said "Ctrl", which it never was.)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>nh", "<cmd>nohl<CR>", { desc = "Clear search highlights" })

-- split window opns
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Split window equally" })
keymap.set("n", "<leader>sx", "<C-w>q", { desc = "Close split window" })

-- Replaces vim-maximizer, unmaintained since 2022. A toggle rather than `:only`,
-- because `:only` closes the other splits outright and loses the layout.
local maximized = false
keymap.set("n", "<leader>sm", function()
	if maximized then
		vim.cmd("wincmd =")
	else
		vim.cmd("wincmd _")
		vim.cmd("wincmd |")
	end
	maximized = not maximized
end, { desc = "Maximise / restore split" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })
-- A shell in a split along the bottom; the same key hides it again and the shell keeps
-- running. snacks.nvim's terminal is already loaded (claudecode uses it). Normal mode
-- only: a Space-prefixed map in terminal mode would stall every space typed in a shell.
-- From inside the terminal: Ctrl-k back to the code, then <leader>tt to hide it.
keymap.set("n", "<leader>tt", function()
	Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 0.3 } })
end, { desc = "Toggle terminal" })

-- Comments.
-- Ctrl+/ was previously mapped to "gtc" and "goc", which are not commenting mappings
-- in any plugin: gt jumps to the next tab and the trailing c left a pending change
-- operator. The real mappings are gcc for a line and gc for a selection, and Neovim
-- 0.10+ provides both natively. remap = true is required so these resolve to the
-- mapping rather than being taken literally.
--
-- <C-_> is what most terminals historically send for Ctrl+/; modern ones send <C-/>.
-- Both are bound so the key works regardless of emulator.
keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment on line" })
keymap.set("x", "<C-_>", "gc", { remap = true, desc = "Toggle comment on selection" })
keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment on line" })
keymap.set("x", "<C-/>", "gc", { remap = true, desc = "Toggle comment on selection" })

-- Window resizing.
-- These four were previously bare strings ("resize +2"), with no <cmd> and no <CR>,
-- so Vim replayed them as normal-mode keystrokes and edited the buffer instead of
-- resizing the window. The modifier set is now symmetric too: grow and shrink used to
-- disagree about whether Shift was involved.
keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Terminal windows (the iron REPL, the Claude Code split).
-- In terminal mode every key goes to the program inside, so leaving needed
-- Ctrl-\ Ctrl-n and then a window motion. These make Ctrl-h/j/k/l work straight from
-- a terminal, exactly as they do from a normal buffer: drop to normal mode, then replay
-- the key so whichever navigator owns <C-h> handles it (vim-tmux-navigator, or
-- herdr-nvim-nav under herdr), which means the chord also crosses tmux/herdr panes.
-- Cost: the program inside never sees these four keys. ipython's Ctrl-L clear is
-- <leader>cl instead; Claude Code's Ctrl-J newline is Shift+Enter instead.
for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
	keymap.set("t", key, "<C-\\><C-n>" .. key, { remap = true, desc = "Leave terminal and move window" })
end

-- Coming back to a terminal window should mean typing into it, not landing in normal
-- mode over its scrollback. snacks.nvim already does this for the Claude split; this
-- covers every other terminal, the iron REPL included.
-- Scheduled and re-checked: iron enters the new REPL window and then jumps back to the
-- code, and an immediate startinsert would land in the code buffer instead.
vim.api.nvim_create_autocmd("WinEnter", {
	group = vim.api.nvim_create_augroup("TerminalAutoInsert", { clear = true }),
	callback = function()
		vim.schedule(function()
			if vim.bo.buftype == "terminal" and vim.fn.mode() ~= "t" then
				vim.cmd.startinsert()
			end
		end)
	end,
})

-- Buffer navigation.
-- Same missing-<cmd> defect as the resize mappings above: "bnext" was replayed as the
-- keystrokes b, n, e, x, t.
keymap.set("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Keep the cursor centred when jumping by half-pages or through search results.
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down, centred" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up, centred" })
keymap.set("n", "n", "nzzzv", { desc = "Next search result, centred" })
keymap.set("n", "N", "Nzzzv", { desc = "Previous search result, centred" })

-- Move the selection up and down, reindenting as it goes.
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- VS Code's Alt+Up/Down "move line", as Alt+j/k in every mode. herdr deliberately takes
-- no Alt+letter, so these reach nvim inside herdr too. Copy a line down/up: yyp / yyP.
keymap.set("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
keymap.set("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
keymap.set("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
keymap.set("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move line up" })
keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Alacritty sends Shift+Enter as ESC+CR so Claude Code gets a newline. Unmapped, nvim
-- reads that as <M-CR> = Esc then Enter, which drops out of insert mode. Mapping it back
-- to Enter keeps Shift+Enter in nvim exactly as before. Insert mode only: terminal
-- windows (the Claude split) still pass ESC+CR through to Claude.
keymap.set("i", "<M-CR>", "<CR>", { desc = "Shift+Enter = newline (Alacritty sends ESC+CR)" })

-- Keep the register when pasting over a selection.
keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without clobbering register" })
