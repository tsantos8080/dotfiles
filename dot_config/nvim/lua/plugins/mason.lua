return {
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
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
        'phpactor',
        'quick_lint_js',
      },
    })

    require('mason-tool-installer').setup({
      ensure_installed = {
        'stylua',
        'markdownlint',
        'pretty-php',
      },
    })

    local cmp = require('cmp')
    cmp.setup({
      snippet = {
        expand = function(args)
          vim.fn['UltiSnips#Anon'](args.body)
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
      sources = cmp.config.sources({ { name = 'nvim_lsp' } }, { { name = 'buffer' } }, { { name = 'ultisnips' } }),
    })

    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    local on_attach = function()
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})

      vim.keymap.set('n', 'gr', function()
        local clients = vim.lsp.get_active_clients()
        local current_buf = vim.api.nvim_get_current_buf()

        if vim.tbl_isempty(clients) then
          print('LSP is not active.')
          return
        end

        local references = vim.lsp.buf.definition({
          on_list = function(opts)
            local current_line = vim.api.nvim_win_get_cursor(0)[1]
            local current_filename = vim.api.nvim_buf_get_name(0)
            local item = opts.items[1]

            if current_line == item.lnum and current_filename == item.filename then
              vim.lsp.buf.references()
              return
            end

            vim.lsp.buf.definition()
          end,
        })
      end, {})

      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', 'r', vim.lsp.buf.rename, {})
    end

    require('lspconfig').phpactor.setup({
      root_dir = function()
        return vim.loop.cwd()
      end,
      on_attach = on_attach,
      capabilities = capabilities,
    })

    require('lspconfig').quick_lint_js.setup({
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end,
  init = function()
    vim.cmd([[
      let g:UltiSnipsSnippetDirectories = ['~/.config/nvim/custom-snippets']
      let g:UltiSnipsJumpForwardTrigger="<tab>"  
    ]])
  end,
}
