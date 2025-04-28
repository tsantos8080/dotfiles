return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.5',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('telescope').setup({
      defaults = {
        file_ignore_patterns = { '.git/' },
      },
      pickers = {
        find_files = {
          hidden = true, -- shows all files, including those inside ./git/*
        },
      },
    })

    -- keymaps
    vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
    vim.keymap.set('n', '<leader>fo', function()
      require('telescope.builtin').oldfiles({ cwd_only = true })
    end, { desc = 'Oldfiles (relative)' })
    vim.keymap.set('n', '<leader>fg', '<cmd>Telescope git_status<cr>')
    vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
    vim.keymap.set('n', '<leader>sg', '<cmd>Telescope live_grep<cr>')

    vim.keymap.set('n', '<leader>ft', function()
      local builtin = require('telescope.builtin')

      local handle = io.popen('git diff --name-only --diff-filter=AM origin/main...HEAD')
      local result = handle:read('*a')
      handle:close()

      local files = {}
      for file in result:gmatch('[^\r\n]+') do
        table.insert(files, file)
      end

      require('telescope.builtin').grep_string({
	search = 'TODO|FIXME|BUG|HACK|XXX|OPTIMIZE|NOTE',
        search_dirs = files,
      })
    end, { desc = 'Find TODOs' })
  end,
}
