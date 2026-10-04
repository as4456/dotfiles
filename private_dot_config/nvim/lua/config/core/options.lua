local opt = vim.opt -- for conciseness
-- line numbers
opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true
opt.autoindent = true

-- line wrapping
opt.wrap = false -- disable line wrapping

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- case sensistive, when using mixed case

-- cursorline
opt.cursorline = true

-- appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes" -- show sign column so that text dont shift

--backspace
opt.backspace = "indent,eol,start"

--clipboard
opt.clipboard:append("unnamedplus") -- system clipboard as register

-- split windows
opt.splitright = true -- split vertical window to right
opt.splitbelow = true -- split horiontal window to bottom

-- Folding by syntax tree. treesitter.lua sets foldexpr per window, but foldmethod was
-- still the default "manual", so zM / zR / za did nothing. Files open fully unfolded
-- (foldlevel 99); zM folds everything, zR opens everything, za toggles one fold.
opt.foldmethod = "expr"
opt.foldlevel = 99
opt.foldlevelstart = 99
