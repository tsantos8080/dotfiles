-- GitHub PR review inside nvim. gh-dash opens a PR here with O
-- (nvim octo://owner/repo/pull/N). <localleader> is space, like <leader>:
-- <space>ve starts or resumes the review, <space>ca comments, <space>sa
-- suggests a change, <space>vs submits, ]q / [q change file.
return {
    "pwntester/octo.nvim",
    -- Not lazy: octo:// buffers must be handled from the first file opened.
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("octo").setup({ picker = "telescope" })
    end
}
