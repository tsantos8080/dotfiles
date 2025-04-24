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
    vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
    vim.keymap.set("n", "<leader>fo", function()
      require("telescope.builtin").oldfiles({ cwd_only = true })
    end, { desc = "Oldfiles (relative)" })
    vim.keymap.set('n', '<leader>fg', '<cmd>Telescope git_status<cr>')
    vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
    vim.keymap.set('n', '<leader>sg', '<cmd>Telescope live_grep<cr>')
  end
}
