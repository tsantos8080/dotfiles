local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Settings
vim.g.mapleader = " "
vim.wo.relativenumber = true
vim.wo.number = true
vim.opt.shiftwidth = 4

-- Remap '<' and '>' in visual mode to reselect the last visual selection after indenting
vim.api.nvim_set_keymap('v', '<', '<gv', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '>', '>gv', { noremap = true, silent = true })

-- Switch to the most recent buffer
vim.api.nvim_set_keymap('n', '<tab>', ':buffer #<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>r', ':lua require("scripts").run_test()<cr>', {})

-- Save file
vim.api.nvim_set_keymap('n', '<leader>w', ':w<cr>', {})

require("lazy").setup("plugins")
