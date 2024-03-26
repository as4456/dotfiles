return{
	"bluz71/vim-nightfly-colors",
	priority=1000, -- to ensure it loads before evry other plugin
	config=function()
		-- load the colorscheme here
		vim.cmd([[colorscheme nightfly]])
	end,
}
