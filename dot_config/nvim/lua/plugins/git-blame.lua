return {
  'f-person/git-blame.nvim',
  lazy = false,
  config = function()
    require('gitblame').setup({
      enabled = true,
    })

    vim.keymap.set('n', '<leader>gb', '<cmd>GitBlameToggle<cr>')
  end
}
