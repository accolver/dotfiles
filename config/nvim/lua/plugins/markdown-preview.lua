return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = {
      "MarkdownPreviewToggle",
      "MarkdownPreview",
      "MarkdownPreviewStop",
    },
    ft = { "markdown" },
    build = function(plugin)
      vim.opt.rtp:append(plugin.dir)
      vim.fn["mkdp#util#install_sync"](true)
    end,
  },
}
