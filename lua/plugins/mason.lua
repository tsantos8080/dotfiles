return {
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
  },
  lazy = false,
  config = function()
    require('mason').setup()
    
    require('mason-lspconfig').setup({
      ensure_installed = {
	'intelephense',
	'quick_lint_js',
      },
    })

    require('lspconfig').intelephense.setup({
      root_dir  = function() return vim.loop.cwd(); end,
    })

    require('lspconfig').quick_lint_js.setup({
      on_attach = function() end,
    })
  end
}
