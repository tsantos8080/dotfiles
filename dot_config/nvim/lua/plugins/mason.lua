return {
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp',
    'SirVer/ultisnips',
    'quangnguyen30192/cmp-nvim-ultisnips',
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

    local on_attach = function()
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
    end
    
    local cmp = require('cmp')
    cmp.setup({
      snippet = {
        expand = function(args)
          vim.fn["UltiSnips#Anon"](args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
	['<tab>'] = cmp.mapping.select_next_item(),
	['<s-tab>'] = cmp.mapping.select_prev_item(),
      }),
      sources = cmp.config.sources({{ name = 'nvim_lsp' }}, {{ name = 'buffer' }}, {{ name = 'ultisnips' }}),
    })

    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    require('lspconfig').intelephense.setup({
      root_dir  = function() return vim.loop.cwd(); end,
      on_attach = on_attach,
      capabilities = capabilities,
    })

    require('lspconfig').quick_lint_js.setup({
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end,
  init = function()
    vim.cmd [[
      let g:UltiSnipsSnippetDirectories = ['~/.config/nvim/custom-snippets']
      let g:UltiSnipsJumpForwardTrigger="<tab>"  
    ]]
  end,
}
