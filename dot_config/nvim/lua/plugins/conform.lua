return {
  'stevearc/conform.nvim',
  opts = {},
  config = function()
    local conform = require('conform')

    conform.setup({
      formatters_by_ft = {
        lua = { 'stylua' },
        markdown = { 'markdownlint' },
        php = { 'pretty-php' },
        javascript = { 'prettierd' },
      },
    })

    vim.keymap.set('n', '<leader>lf', function()
      local lines = vim.fn.system('git diff --unified=0'):gmatch('[^\n\r]+')
      local ranges = {}
      for line in lines do
        if line:find('^@@') then
          local line_nums = line:match('%+.- ')
          if line_nums:find(',') then
            local _, _, first, second = line_nums:find('(%d+),(%d+)')
            table.insert(ranges, {
              start = { tonumber(first), 0 },
              ['end'] = { tonumber(first) + tonumber(second), 0 },
            })
          else
            local first = tonumber(line_nums:match('%d+'))
            table.insert(ranges, {
              start = { first, 0 },
              ['end'] = { first + 1, 0 },
            })
          end
        end
      end
      local format = require('conform').format
      for _, range in pairs(ranges) do
        format({
          range = range,
        })
      end
    end, { desc = 'Format changed lines' })

    vim.keymap.set('n', '<leader>lF', function()
      conform.format({ async = true }, function(err)
        if err ~= nil then
          print(err)
        end
      end)
    end, { desc = 'Format file' })
  end,
}
