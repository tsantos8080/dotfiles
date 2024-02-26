return {
  'RaafatTurki/corn.nvim',
  lazy = false,
  config = function()
    -- hide errors
    vim.diagnostic.config { virtual_text = false }

    require('corn').setup({
      on_toggle = function(is_hidden)
        vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })
      end,
      item_preprocess_func = function(item)
        return item
      end,
    })
  end,
}
