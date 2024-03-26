-- Set leader key to Ctrl
vim.g.mapleader = " "

local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- split window opns
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Split window equally" })
keymap.set("n", "<leader>sx", "<C-w>q", { desc = "Close split window" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- Comments
keymap.set("n", "<C-_>", "gtc", { noremap = false })
keymap.set("v", "<C-_>", "goc", { noremap = false })

-- Window management
keymap.set("n", "<C-S-Up>", "resize +2")
keymap.set("n", "<C-Down>", "resize -2")
keymap.set("n", "<C-S-Left>", "vertical resize +2")
keymap.set("n", "<C-Right>", "vertical resize -2")

-- Buffer Navigation
keymap.set("n", "<leader>bn", "bnext") -- Next buffer
keymap.set("n", "<leader>bp", "bprevious") -- Prev buffer
