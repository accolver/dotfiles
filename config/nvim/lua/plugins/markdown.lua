return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        -- Distinguish heading levels without requiring special font glyphs.
        icons = { "◉ ", "○ ", "◆ ", "◇ ", "▸ ", "▹ " },
        position = "inline",
      },
      checkbox = { enabled = true },
      code = {
        border = "thin",
        left_pad = 2,
        right_pad = 2,
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      -- Prose and scratch notes should not require Markdown style compliance.
      opts.linters_by_ft.markdown = {}
      opts.linters_by_ft["markdown.mdx"] = {}
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      -- Keep formatting, but do not rewrite prose to satisfy markdownlint.
      opts.formatters_by_ft.markdown = { "prettier", "markdown-toc" }
      opts.formatters_by_ft["markdown.mdx"] = { "prettier", "markdown-toc" }
    end,
  },
}
