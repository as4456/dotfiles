return {
	"windwp/nvim-autopairs",
	event = { "InsertEnter" },
	config = function()
		require("nvim-autopairs").setup({
			check_ts = true,
			ts_config = {
				lua = { "string" },
			},
		})
		-- The nvim-cmp `confirm_done` hook that used to live here is gone with
		-- nvim-cmp. blink.cmp inserts brackets itself via completion.accept.auto_brackets,
		-- so no bridging plugin is needed.
	end,
}
