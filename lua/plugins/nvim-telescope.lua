return {
  'nvim-telescope/telescope.nvim', tag = '0.1.5',
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
    vim.keymap.set('n', '<leader>sf', '<cmd>Telescope find_files<cr>')
    vim.keymap.set('n', '<leader>sg', '<cmd>Telescope live_grep<cr>')
    vim.keymap.set('n', '<leader>sr', '<cmd>Telescope buffers<cr>')
  end
}
