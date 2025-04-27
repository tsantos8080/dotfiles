return {
  'stevearc/conform.nvim',
  opts = {},
  config = function()
    local conform = require('conform')

    conform.setup({
      formatters_by_ft = {
        lua = { 'stylua' },
        markdown = { 'markdownlint' },
      },
    })

    vim.keymap.set('n', '<leader>lf', function()
      conform.format({ async = true }, function(err)
        if err ~= nil then
          print(err)
        end
      end)
    end)
  end,
}
