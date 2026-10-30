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
            -- Wired: kanagawa-dragon recolored with the Serial Experiments Lain
            -- palette (black, pink, beige), matching kitty and tmux.
            colors = {
                theme = {
                    dragon = {
                        ui = {
                            fg = "#e6d6c8",
                            fg_dim = "#c9bcb4",
                            bg_m3 = "#060405",
                            bg_m2 = "#0b0809",
                            bg_m1 = "#110c0e",
                            bg = "#0b0809",
                            bg_p1 = "#1a1214",
                            bg_p2 = "#241a1d",
                            bg_gutter = "none",
                            special = "#8c7a72",
                            whitespace = "#3d2a30",
                            nontext = "#3d2a30",
                            bg_visual = "#5a2a35",
                            bg_search = "#8c3f52",
                            pmenu = {
                                fg = "#e6d6c8",
                                bg = "#1a1214",
                                bg_sel = "#5a2a35",
                                bg_sbar = "#1a1214",
                                bg_thumb = "#8c3f52",
                            },
                            float = {
                                fg = "#e6d6c8",
                                bg = "#0b0809",
                                fg_border = "#d4687f",
                                bg_border = "#0b0809",
                            },
                        },
                        syn = {
                            string = "#c9b48c",
                            number = "#ea8ea2",
                            constant = "#e2d1aa",
                            identifier = "#e6d6c8",
                            parameter = "#c9bcb4",
                            fun = "#d4687f",
                            statement = "#b05a8a",
                            keyword = "#b05a8a",
                            operator = "#a2a6cc",
                            preproc = "#d27fab",
                            type = "#7ea6a3",
                            regex = "#ea8ea2",
                            punct = "#8c7a72",
                            comment = "#6b5a5f",
                            special1 = "#a0c4c1",
                            special2 = "#d4687f",
                            special3 = "#d4687f",
                        },
                    },
                },
            },
            overrides = function()
                return {
                    StatusLine = { fg = "#0b0809", bg = "#d4687f", bold = true },
                    StatusLineNC = { fg = "#8c7a72", bg = "#1a1214" },
                    CursorLineNr = { fg = "#d4687f", bold = true },
                    WinSeparator = { fg = "#3d2a30" },
                }
            end,
        })
        vim.cmd("colorscheme kanagawa-dragon")
    end
}
