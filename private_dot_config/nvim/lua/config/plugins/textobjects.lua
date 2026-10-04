-- Syntax-aware text objects: select, delete, yank or send "the function I'm in".
--
--   af / if   around / inside function      vaf  selects the whole def
--   ac / ic   around / inside class         dac  deletes the class
--   aa / ia   around / inside argument      cia  changes one parameter
--   ]f / [f   next / previous function start
--
-- They compose with every operator, iron's included: <leader>rc + af sends the function
-- under the cursor to the REPL. nvim-treesitter is on its `main` branch, so this uses the
-- matching `main` branch here too.
local function sel(query)
	return function()
		require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
	end
end
local function move(fn, query)
	return function()
		require("nvim-treesitter-textobjects.move")[fn](query, "textobjects")
	end
end

return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = { "BufReadPost", "BufNewFile" },
	init = function()
		-- Filetype plugins ship their own ]] / [m style maps; stop them shadowing these.
		vim.g.no_plugin_maps = true
	end,
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true, -- `vaf` before a def jumps forward to it
				selection_modes = { ["@function.outer"] = "V", ["@class.outer"] = "V" },
			},
			move = { set_jumps = true }, -- Ctrl-o jumps back
		})
		local map = vim.keymap.set
		map({ "x", "o" }, "af", sel("@function.outer"), { desc = "around function" })
		map({ "x", "o" }, "if", sel("@function.inner"), { desc = "inside function" })
		map({ "x", "o" }, "ac", sel("@class.outer"), { desc = "around class" })
		map({ "x", "o" }, "ic", sel("@class.inner"), { desc = "inside class" })
		map({ "x", "o" }, "aa", sel("@parameter.outer"), { desc = "around argument" })
		map({ "x", "o" }, "ia", sel("@parameter.inner"), { desc = "inside argument" })
		map({ "n", "x", "o" }, "]f", move("goto_next_start", "@function.outer"), { desc = "Next function" })
		map({ "n", "x", "o" }, "[f", move("goto_previous_start", "@function.outer"), { desc = "Previous function" })
	end,
}
