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

vim.api.nvim_set_keymap('n', '<leader>r', ':lua require("scripts").run_test()<cr>', {})

require("lazy").setup("plugins")
