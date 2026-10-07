-- iron.nvim: send lines / selections / motions from the editor to an ipython REPL.
--
-- Two Windows-specific problems are handled below, both verified by driving this
-- config through a real ConPTY:
--
--   * Extra empty `In [n]:` prompts. On Windows, iron's core.send appends its own
--     delayed Enter keypresses (one for a string, two for a table of lines) on top of
--     whatever the format function adds, so every send produced 2-4 blank prompts.
--     The Windows formatter here therefore adds no CR at all, and the send wrapper
--     picks how many of iron's Enters a block needs: two only when the block ends
--     inside an indented body (a def or for loop needs the blank line to close it),
--     otherwise one.
--
--   * A REPL that did not fill the height. `iron.view.right` opens a *floating*
--     window, sized once at open, which also covered the right edge of the code. A
--     real split resizes with the terminal instead: a vertical split at the far right,
--     full height, 40% wide. With the Claude split open as well, the two sit side by
--     side on the right.
local windows = vim.fn.has("win32") == 1
local OPEN, CLOSE = "\27[200~", "\27[201~" -- bracketed paste markers

local function trim_trailing_blanks(lines)
	local out = vim.list_slice(lines, 1, #lines)
	while #out > 0 and not out[#out]:match("%S") do
		table.remove(out)
	end
	return out
end

-- Multi-line sends become one bracketed paste, so ipython runs them as a single cell
-- rather than line by line.
local function windows_ipython_format(lines)
	-- iron's delayed Enter arrives through here too, as the single line "\r".
	if #lines <= 1 then
		return lines
	end
	local out = trim_trailing_blanks(lines)
	if #out <= 1 then
		return out
	end
	out[1] = OPEN .. out[1]
	out[#out] = out[#out] .. CLOSE
	return out
end

return {
	"hkupty/iron.nvim", -- now Vigemus/iron.nvim; GitHub redirects the old name
	config = function()
		local iron = require("iron.core")
		local common = require("iron.fts.common")

		iron.setup({
			config = {
				-- Whether a repl should be discarded or not
				scratch_repl = true,
				repl_definition = {
					python = {
						-- ipython from whichever venv is active when nvim starts. On
						-- Windows that is the shared venv Git Bash activates.
						command = { "ipython", "--no-autoindent" },
						format = windows and windows_ipython_format or common.bracketed_paste_python,
					},
					sh = {
						-- zsh exists only inside WSL; Git Bash is the Windows shell.
						command = { windows and "bash" or "zsh" },
					},
				},
				repl_open_cmd = require("iron.view").split.vertical.botright("40%"),
			},
			-- Iron doesn't set keymaps by default anymore.
			keymaps = {
				send_motion = "<space>rc",
				visual_send = "<space>rc",
				send_file = "<space>rF",
				send_line = "<space>rl",
				send_mark = "<space>rm",
				mark_motion = "<space>mc",
				mark_visual = "<space>mc",
				remove_mark = "<space>md",
				cr = "<space>s<cr>",
				interrupt = "<space>s<space>",
				exit = "<space>sq",
				clear = "<space>cl",
			},
			highlight = {
				italic = true,
			},
			ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
		})

		if windows then
			-- Every send path (line, motion, selection, file, mark) goes through
			-- core.send, so wrapping it here covers all of them.
			local send = iron.send
			iron.send = function(ft, data)
				if type(data) == "table" then
					data = trim_trailing_blanks(data)
					-- A string gets one delayed Enter from iron, a table two. Only a
					-- block ending in an indented line needs the second.
					if #data > 0 and not data[#data]:match("^%s") then
						data = table.concat(data, "\n")
					end
				end
				return send(ft, data)
			end
		end

		-- iron also has a list of commands, see :h iron-commands for all available commands
		vim.keymap.set("n", "<space>ri", "<cmd>IronRepl<cr>", { desc = "Open REPL" })
		vim.keymap.set("n", "<space>rr", "<cmd>IronRestart<cr>", { desc = "Restart REPL" })
		vim.keymap.set("n", "<space>rf", "<cmd>IronFocus<cr>", { desc = "Focus REPL" })
		vim.keymap.set("n", "<space>rh", "<cmd>IronHide<cr>", { desc = "Hide REPL (keeps it running)" })
	end,
}
