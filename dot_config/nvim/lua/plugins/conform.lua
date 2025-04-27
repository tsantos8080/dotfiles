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
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
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
