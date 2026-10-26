return {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("kanagawa").setup({
            -- Let kitty's background opacity show through.
            transparent = true,
            theme = "dragon",
            background = { dark = "dragon" },
        })
        vim.cmd("colorscheme kanagawa-dragon")
    end
}
