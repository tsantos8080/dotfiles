return {
  "nvim-tree/nvim-tree.lua",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    -- disable netrw at the very start of your init.lua
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- optionally enable 24-bit colour
    vim.opt.termguicolors = true
    
    -- empty setup using defaults
    require("nvim-tree").setup()
    
    -- OR setup with some options
    require("nvim-tree").setup({
      actions = {
        open_file = {
          quit_on_open = true,
        },
      },
      sort = {
        sorter = "case_sensitive",
      },
      view = {
        width = 30,
        side = 'right',
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
        git_ignored = false,
      },
    })

    -- set keymaps
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
    vim.keymap.set("n", "<leader>E", "<cmd>NvimTreeFindFile<CR>")
  end
}
