-- Markdown rendered in place (headings, tables, code blocks, checkboxes) instead of a
-- browser preview: nothing to build, works the same over SSH, in WSL and in herdr.
-- Rendering switches off on the line under the cursor so editing stays raw.
return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {},
	keys = {
		{ "<leader>mv", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle markdown view" },
	},
}
