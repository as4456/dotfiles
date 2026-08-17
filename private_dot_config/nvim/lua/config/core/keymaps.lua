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

-- Keep the register when pasting over a selection.
keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without clobbering register" })
