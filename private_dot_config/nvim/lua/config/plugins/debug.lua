-- Debugging (DAP): breakpoints, step over/into/out, variables, call stack, REPL.
--
-- Keys follow VS Code's on purpose, so years of muscle memory carry over:
--   F5 start/continue · Shift+F5 stop · F9 breakpoint · F10 over · F11 into · Shift+F11 out
-- Rarer actions live under <leader>u ("debUg"); <leader>d is already the diagnostic
-- float, and making it a prefix too would stall every press for timeoutlen.
--
-- Python: the adapter is Mason's own debugpy (lsp/mason.lua installs it), so it exists on
-- Windows and WSL alike. The *program* runs with whichever venv is active when nvim
-- starts (nvim-dap-python resolves $VIRTUAL_ENV), i.e. the shared venv in Git Bash.
return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text", -- variable values inline, next to the code
			"mfussenegger/nvim-dap-python",
		},
		keys = {
			{ "<F5>", function() require("dap").continue() end, desc = "Debug: start / continue" },
			{ "<S-F5>", function() require("dap").terminate() end, desc = "Debug: stop" },
			{ "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
			{ "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
			{ "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
			{ "<S-F11>", function() require("dap").step_out() end, desc = "Debug: step out" },
			{ "<leader>u", nil, desc = "Debug" },
			{ "<leader>ub", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
			{
				"<leader>uB",
				function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end,
				desc = "Conditional breakpoint",
			},
			{ "<leader>uc", function() require("dap").continue() end, desc = "Start / continue" },
			{ "<leader>ur", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
			{ "<leader>ul", function() require("dap").run_last() end, desc = "Re-run last session" },
			{ "<leader>up", function() require("dap").pause() end, desc = "Pause" },
			{ "<leader>uq", function() require("dap").terminate() end, desc = "Stop" },
			{ "<leader>uu", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
			{ "<leader>ue", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Evaluate expression" },
			{ "<leader>ux", function() require("dap").clear_breakpoints() end, desc = "Clear all breakpoints" },
			{ "<leader>ut", function() require("dap-python").test_method() end, desc = "Debug test under cursor" },
		},
		config = function()
			local dap, dapui = require("dap"), require("dapui")
			dapui.setup()
			require("nvim-dap-virtual-text").setup({})

			-- Mason's debugpy lives in its own venv; the path differs per OS.
			local venv = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv"
			local adapter_python = vim.fn.has("win32") == 1 and (venv .. "/Scripts/python.exe")
				or (venv .. "/bin/python")
			if vim.fn.executable(adapter_python) == 0 then
				adapter_python = "python" -- fall back to any python with debugpy installed
			end
			require("dap-python").setup(adapter_python)

			-- The UI opens with a session and closes when it ends, like VS Code's debug view.
			dap.listeners.after.event_initialized.dapui = function() dapui.open() end
			dap.listeners.before.event_terminated.dapui = function() dapui.close() end
			dap.listeners.before.event_exited.dapui = function() dapui.close() end

			vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
			vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
		end,
	},
}
