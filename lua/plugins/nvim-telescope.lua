return {
  'nvim-telescope/telescope.nvim', tag = '0.1.5',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    -- keymaps
    vim.keymap.set('n', '<leader>f', '<cmd>Telescope find_files<cr>')
    vim.keymap.set('n', '<leader>t', '<cmd>Telescope live_grep<cr>')
  end
}
