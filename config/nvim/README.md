# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Markdown editing

Markdown and MDX do not run automatic `markdownlint-cli2` checks or fixes.
Markdown spellcheck is off by default so names and technical terms are not
underlined. Other filetypes keep their normal linting and spellcheck.
Use `:setlocal spell` to enable spellcheck in the current window.

The existing `render-markdown.nvim` plugin renders headings with level-specific
icons and colored backgrounds, task checkboxes, padded code blocks with thin
borders, tables, and links inside Neovim. Rendering is enabled by default in
normal mode; the cursor line reveals its source for editing, and insert mode
shows the source. This is a rendered source editor, not a full Typora-style
WYSIWYG editor.

- `<leader>um` toggles in-editor Markdown rendering.
- `<leader>cp` toggles the browser preview for Markdown.
- `<leader>cf` formats using available formatters. Prettier still requires a
  project Prettier config, and `markdown-toc` only acts on its TOC markers.

Restart Neovim after updating this config. No additional plugins are needed.

## Regression check

With this config active and its LazyVim plugins installed, run from the repo root:

```sh
nvim --headless -u config/nvim/init.lua '+lua dofile("tests/nvim_markdown_test.lua")'
```
