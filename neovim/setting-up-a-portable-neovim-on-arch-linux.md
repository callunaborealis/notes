# Setting up a portable `neovim` on Arch Linux

This guide sets up Neovim as a portable IDE on Arch Linux. It is aimed at someone coming from Visual Studio Code or VSCodium who has passing familiarity with `vim`.

The idea you already know from VS Code, where your settings and extensions follow you when you sign in on a new machine, applies here too. It is just more explicit. Your whole configuration is a directory of Lua files. Put it in a git repo, and on a new machine you install Neovim, clone the config, and open it once. A plugin manager and a server installer rebuild the rest for you.

A note for the `vim`-curious. The modal editing you may have seen in `vim` is the same in Neovim. This guide uses Neovim because of its built-in LSP and the surrounding plugin ecosystem, which are what make the cross-machine reproducibility work.

This guide targets Neovim 0.12 or newer. Check with `nvim --version`. Two recent changes matter. LSP setup moved into core in 0.11, and `nvim-treesitter` was rewritten on a new `main` branch for 0.12. The config below uses both.

```sh
# Language toolchains
sudo pacman -S nodejs npm gcc go python

# Editor and supporting tools
sudo pacman -S neovim git ripgrep fd unzip tree-sitter-cli

# Rust
sudo pacman -S rustup
# Set a default toolchain
rustup default stable
# Install the analyser's source component and the standard library source
rustup component add rust-analyzer rust-src
```

## Pre-requisites

- `nodejs` and `npm`. Required by the TypeScript, ESLint, and Nx language servers. On Arch, `npm` is a separate package from `nodejs`, so install both. `npm` ships with Node directly. `corepack` is only relevant if you want `pnpm` or `yarn`.
- `python`. A Python interpreter. `pyright` resolves against your project's interpreter, ideally a virtual environment. `ruff` is a self-contained binary.
- `gcc`. A C compiler, used to compile Treesitter parsers locally.
- `go`. The Go toolchain. `gopls`, the Go language server, needs `go` on `PATH` to analyse code, resolve imports, and run tools like `go vet`.
- `rustup`. The Rust toolchain manager. `rust_analyzer` needs a real toolchain and the standard library source, not just the bare binary. The two `rustup` commands above set a default toolchain and add the analyser source.
- `neovim`. The editor, version 0.12 or newer.
- `git`. `lazy.nvim` uses it to clone plugins, and you will use it to version your config.
- `ripgrep` and `fd`. These power Telescope's project-wide search and file finding. Live grep does not work without `ripgrep`.
- `unzip`. `mason` needs it to unpack some server downloads.
- `tree-sitter-cli`. Required since 0.12. The rewritten `nvim-treesitter` compiles parsers locally instead of bundling them, and this CLI does the compilation. Install it from pacman rather than `npm`, because the `npm` build has caused version mismatches.

A clipboard provider is also worth having so `"+y` yanks to the system clipboard.

```sh
# Wayland
sudo pacman -S wl-clipboard
# or X11
sudo pacman -S xclip
```

## Initial config

The default config location is `~/.config/nvim`, since `XDG_CONFIG_HOME` defaults to `~/.config`.

```sh
# You do not need to change this. If you want to run a separate, named config, for testing or to keep more than one setup side by side, use `NVIM_APPNAME`. It changes only the folder name Neovim looks for, and keeps that config's data and state separate too.
# See https://neovim.io/doc/user/starting/#%24XDG_CONFIG_HOME
export XDG_CONFIG_HOME="$HOME/.config"
# Reads config from ~/.config/my_nvim instead of ~/.config/nvim
# See https://neovim.io/doc/user/starting/#%24NVIM_APPNAME
NVIM_APPNAME=my_nvim nvim
```

Create the directory structure. Use your app name in place of `nvim` below if you chose one.

```sh
mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins
```

```sh
~/.config/nvim
├── init.lua                  # Entry point
└── lua/
    ├── config/
    │   ├── options.lua       # Editor settings
    │   ├── keymaps.lua       # Global keymaps
    │   ├── lazy.lua          # Bootstraps the plugin manager
    │   └── cheatsheet.lua    # Live keymap cheatsheet generator
    └── plugins/
        ├── lsp.lua           # Language servers (TypeScript, ESLint, Nx, CSS, etc.)
        ├── completion.lua    # Autocomplete
        ├── treesitter.lua    # Syntax-aware highlighting
        ├── telescope.lua     # Fuzzy finder
        ├── neotree.lua       # File explorer sidebar
        └── formatting.lua    # Formatter on save
```

### `init.lua`

```lua
-- Leader must be set BEFORE plugins load, or keymaps bind to the wrong key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.cheatsheet") -- registers the :Cheatsheet command
require("config.lazy")
```

### `config/options.lua`

```lua
local opt = vim.opt

opt.number = true             -- line numbers
opt.relativenumber = true     -- relative numbers for fast jumps (5j, 3k)
opt.expandtab = true          -- spaces, not tabs
opt.shiftwidth = 2            -- 2-space indents (TS/React convention)
opt.tabstop = 2
opt.smartindent = true
opt.wrap = false
opt.termguicolors = true      -- 24-bit colour for proper themes
opt.signcolumn = "yes"        -- stop the gutter from jumping around
opt.clipboard = "unnamedplus" -- yank to the system clipboard by default
opt.mouse = "a"
opt.ignorecase = true
opt.smartcase = true          -- case-sensitive only if you type a capital
opt.updatetime = 250          -- snappier diagnostics
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8             -- keep context above/below the cursor
```

### `config/keymaps.lua`

```lua
local map = vim.keymap.set

map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit window" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Move between splits with Ctrl + h/j/k/l
map("n", "<C-h>", "<C-w>h", { desc = "Go to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower split" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper split" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right split" })

-- Open the live keymap cheatsheet (defined in config/cheatsheet.lua)
map("n", "<leader>cs", "<cmd>Cheatsheet<cr>", { desc = "Open live cheatsheet" })
```

A short note on `desc`. The text you pass as `desc` is what `:map`, `:Telescope keymaps`, and which-key all display. Without it, Lua-backed mappings show an opaque `<Lua: ...>` reference instead of a readable label, so it is worth setting on every mapping.

### Lazy loading via `config/lazy.lua`

`lazy.nvim` can import an entire folder of plugin specs at once. Every file in `lua/plugins` that returns a table is loaded automatically. Adding a plugin later means dropping in one new file, with nothing else to wire up.

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  checker = { enabled = true, notify = false }, -- check for plugin updates quietly
})
```

## Completion via `plugins/completion.lua`

This uses `blink.cmp`, which is fast, ships a sensible default keymap, and needs almost no config. Set it up before LSP so the language servers can advertise completion support to it.

```lua
return {
  "saghen/blink.cmp",
  version = "*", -- uses a prebuilt fuzzy matcher, so no Rust toolchain is needed
  opts = {
    keymap = { preset = "default" }, -- <C-y> to accept, <C-n>/<C-p> to cycle
    completion = {
      documentation = { auto_show = true },
    },
    sources = {
      default = { "lsp", "path", "buffer" },
    },
  },
}
```

## Language servers via `plugins/lsp.lua`

This file is what turns Neovim into an IDE.

- `mason` installs the server binaries.
- `nvim-lspconfig` provides the server definitions.

Each server is wired up explicitly rather than through automatic handlers, so the setup stays stable when `mason` or `lspconfig` change.

As of Neovim 0.11, LSP setup is built into core through `vim.lsp.config()` and `vim.lsp.enable()`. `nvim-lspconfig` now mainly ships the server definitions (command, filetypes, root markers) as data that core reads. The older `require('lspconfig').<server>.setup()` pattern still works but is deprecated and is slated for removal in `nvim-lspconfig` v3.0.0, so this config does not use it.

A breakdown of each server.

- React TypeScript is already handled. `vtsls` covers `.ts`, `.tsx`, `.js`, and `.jsx`, and `eslint` lints all of them. There is no separate React server, because JSX and TSX support is built into the TypeScript server. Nothing extra to add.
- Go uses `gopls`, the official server. It needs no config beyond having the `go` toolchain on `PATH`. It auto-organises imports and surfaces `go vet` diagnostics.
- Python uses a two-server split. `pyright` handles type-checking and hover. `ruff` handles fast linting and formatting. The `ruff` config below turns off ruff's hover so the two do not both answer. `pyright` resolves against your project's virtual environment, and a `.venv` in the project root is detected automatically.
- JSON (`jsonls`) and YAML (`yamlls`) become far more useful with `schemastore.nvim`, added to the dependencies below. You get validation and completion against the real schemas for `package.json`, `tsconfig.json`, GitHub Actions workflows, `docker-compose.yml`, and many more, with warnings on invalid keys. Note that `jsonls` and `nxls` both attach to JSON files. That is fine. They complement each other, one for schema validation and one for Nx-specific completion.
- Markdown uses `marksman`. It gives link and reference completion, cross-file navigation between notes, and rename-aware heading links. This is useful if you keep a notes vault. Prettier handles formatting, covered in the Formatting section.
- CSS, SCSS, and Sass use three pieces working together. `cssls` is the standard server and covers CSS, SCSS, and Less with completion, hover, and basic validation. `somesass_ls` adds richer SCSS support, including cross-file variable and mixin completion and the indented `.sass` syntax that `cssls` does not handle well. `stylelint_lsp` is the linter. It runs your project's stylelint config and reports problems, and it can fix them on save. `stylelint_lsp` only does useful work when the project actually has stylelint installed and configured, so it stays quiet in projects that do not use it. Prettier handles CSS and SCSS formatting (see the Formatting section), and the indented `.sass` syntax is left to stylelint, since Prettier does not support it.
- Rust runs `rust_analyzer` directly, which works well. A richer Rust experience comes from the `rustaceanvim` plugin, which adds debugging, macro expansion, runnables, and better cargo integration. There is one rule to remember. If you adopt `rustaceanvim`, it configures and starts `rust_analyzer` itself. You must then remove `rust_analyzer` from both the `ensure_installed` and `vim.lsp.enable` lists below, or you will get two analyser instances fighting over the same buffer. Pick one path. For now the plain `rust_analyzer` route keeps the config uniform. Switch to `rustaceanvim` when you move into bigger Rust projects.

```lua
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "williamboman/mason.nvim", opts = {} },
    "williamboman/mason-lspconfig.nvim",
    "b0o/schemastore.nvim", -- JSON/YAML schemas (see notes above)
    "saghen/blink.cmp",
  },
  config = function()
    -- Auto-install the servers we need
    require("mason-lspconfig").setup({
      ensure_installed = {
        "vtsls",         -- TypeScript / React (TSX)
        "eslint",        -- ESLint
        "gopls",         -- Go
        "rust_analyzer", -- Rust
        "pyright",       -- Python (types)
        "ruff",          -- Python (lint + format)
        "jsonls",        -- JSON
        "yamlls",        -- YAML
        "marksman",      -- Markdown
        "cssls",         -- CSS / SCSS / Less
        "somesass_ls",   -- richer SCSS and indented Sass
        "stylelint_lsp", -- CSS / SCSS / Sass linting and fix-on-save
        -- Mermaid has no language server. Treesitter only (see Syntax highlighting).
      },
    })

    -- Apply blink's completion capabilities to EVERY server via the "*" default
    vim.lsp.config("*", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    })

    -- JSON: feed it the SchemaStore catalogue so package.json, tsconfig.json,
    -- and similar files get validation and completion against their real schemas.
    vim.lsp.config("jsonls", {
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          validate = { enable = true },
        },
      },
    })

    -- YAML: same idea, plus disable the server's built-in store so it does not
    -- duplicate SchemaStore. Covers GitHub Actions, docker-compose, k8s, etc.
    vim.lsp.config("yamlls", {
      settings = {
        yaml = {
          schemaStore = { enable = false, url = "" },
          schemas = require("schemastore").yaml.schemas(),
        },
      },
    })

    -- Python: let pyright own hover and types and let ruff own lint and format,
    -- so the two do not both answer hover requests.
    vim.lsp.config("ruff", {
      on_attach = function(client)
        client.server_capabilities.hoverProvider = false
      end,
    })

    -- Stylelint: turn on fix-on-save for CSS, SCSS, and Sass. These settings
    -- live under the stylelintplus key, which is what this server expects.
    vim.lsp.config("stylelint_lsp", {
      settings = {
        stylelintplus = {
          autoFixOnSave = true,
          autoFixOnFormat = true,
        },
      },
    })

    -- Enable everything. Definitions for all of these ship with nvim-lspconfig.
    vim.lsp.enable({
      "vtsls", "eslint", "gopls", "rust_analyzer",
      "pyright", "ruff", "jsonls", "yamlls", "marksman",
      "cssls", "somesass_ls", "stylelint_lsp",
    })

    -- LSP behaviour, applied per-buffer when a server attaches
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        -- helper: buffer-local normal-mode map with a description.
        -- The desc is what :map, :Telescope keymaps, and which-key display.
        local function lspmap(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
        end

        lspmap("gd", vim.lsp.buf.definition, "Go to definition")
        lspmap("gr", vim.lsp.buf.references, "List references")
        lspmap("gi", vim.lsp.buf.implementation, "Go to implementation")
        lspmap("gy", vim.lsp.buf.type_definition, "Go to type definition")
        lspmap("K", vim.lsp.buf.hover, "Hover docs")
        lspmap("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        lspmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
        lspmap("[d", function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, "Previous diagnostic")
        lspmap("]d", function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, "Next diagnostic")

        -- ESLint: auto-fix on save. Gated by client name so we do not clobber
        -- nvim-lspconfig's own eslint on_attach, which creates EslintFixAll.
        if client and client.name == "eslint" then
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = ev.buf,
            command = "EslintFixAll",
          })
        end
      end,
    })
  end,
}
```

## Syntax highlighting via `plugins/treesitter.lua`

Since Neovim 0.12, `nvim-treesitter` was rewritten on a new `main` branch. The new version compiles parsers locally, which is why `tree-sitter-cli` and `gcc` are in the prerequisites, and it exposes highlighting and indentation through Neovim core rather than a plugin `setup()` call.

- Parser names and filetypes differ. You install parsers by parser name, like `tsx` and `bash`, but the FileType autocommand matches Neovim filetypes, like `typescriptreact` and `sh`. Mixing them up means highlighting silently does not fire.
- Parsers install asynchronously by default, and this config makes that step synchronous. On the `main` branch, `install()` compiles parsers in a background job and returns immediately. On a fresh machine this means the first file can open before its parser exists. The `install(...):wait(300000)` call below blocks startup until any missing parsers finish compiling, which removes the race. The cost is a one-time slow first launch on a new machine. Later launches are fast, because `install()` skips parsers that are already compiled. The `pcall` in the autocmd stays as a safety net for genuinely unsupported filetypes.
- Treesitter indentation is experimental. If you see odd auto-indent in TS or TSX, remove the `indentexpr` line and let the defaults handle it.
- CSS and SCSS have Treesitter parsers, so both highlight properly. There is no parser for the indented `.sass` syntax or for `.less`, so those filetypes fall back to Neovim's built-in syntax highlighting. The `pcall` in the autocmd makes that fallback silent.

```lua
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,    -- load at startup. This is a start plugin, not lazy loaded.
  priority = 1000, -- and load before other start plugins
  build = ":TSUpdate",
  config = function()
    -- Parser names. These differ from filetypes, e.g. tsx not typescriptreact.
    local parsers = {
      "typescript", "tsx", "javascript", "json", "jsonc",
      "lua", "markdown", "markdown_inline", "html", "css", "scss", "yaml", "bash",
      "go", "gomod", "gosum", "gowork", -- Go
      "rust",                           -- Rust
      "python",                         -- Python
      "mermaid",                        -- Mermaid (highlighting only, no LSP)
    }

    -- Block until any missing parsers are compiled. This removes the
    -- first-launch race. By the time the FileType autocmd below can fire, the
    -- parsers are present. install() only compiles what is missing, so on a
    -- machine where they already exist this returns almost immediately. Only
    -- the first launch pays the compile cost. summary = false keeps it quiet.
    require("nvim-treesitter").install(parsers, { summary = false }):wait(300000)

    -- Enable features per buffer, keyed by FILETYPE. These differ from parser
    -- names: typescriptreact not tsx, sh not bash.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "typescript", "typescriptreact", "javascript", "javascriptreact",
        "json", "jsonc", "lua", "markdown", "html", "css", "scss", "sass", "less", "yaml", "sh",
        "go", "gomod", "gosum", "gowork", "rust", "python", "mermaid",
      },
      callback = function(ev)
        -- pcall is belt and braces here. It protects genuinely unsupported
        -- filetypes even though :wait() above handles the install race.
        if pcall(vim.treesitter.start, ev.buf) then
          -- experimental treesitter indentation (drop this line if indent misbehaves)
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
```

## Fuzzy finder via `plugins/telescope.lua`

Telescope searches for files in the directory where Neovim is open, and a lot more. `ripgrep` is required for `live_grep`.

One thing to know if you followed the Treesitter section above. The `main`-branch rewrite removed the `ft_to_lang` and `get_buf_lang` helpers that Telescope's previewer relied on, so without a workaround every preview throws an error. Setting `preview = { treesitter = false }` sidesteps it. Previews fall back to regex syntax highlighting, which is still coloured. Files you actually open are unaffected and keep full Treesitter highlighting.

If you would rather keep Treesitter-accurate preview colours, the durable alternative is to swap Telescope for the actively maintained `fzf-lua`, which works with the rewrite and is faster, at the cost of redoing these four keymaps in its API.

```lua
return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    defaults = {
      -- See the note above. nvim-treesitter's main branch removed the helpers
      -- Telescope's previewer relied on, so disable Treesitter in the preview.
      preview = { treesitter = false },
    },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep project" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Open buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
  },
}
```

## File explorer via `plugins/neotree.lua`

Coming from VS Code, this is the sidebar tree you are used to on the left. `neo-tree.nvim` provides it. Press `<leader>e` to toggle it open and closed.

This setup uses plain text markers rather than icons, so it does not need a Nerd Font installed in your terminal. If you would rather have file-type glyphs, add `nvim-tree/nvim-web-devicons` to the dependencies, remove the `icon` and `indent` overrides below, and set a Nerd Font in your terminal emulator.

Inside the tree, the common keys are `Enter` to open a file, `a` to create, `d` to delete, `r` to rename, and `?` to show all of neo-tree's keymaps. `follow_current_file` keeps the tree in sync with the buffer you are editing, which matches the VS Code behaviour.

```lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim", -- already pulled in by Telescope
    "MunifTanjim/nui.nvim",
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
  },
  opts = {
    -- Plain text markers instead of Nerd Font glyphs. Removing the devicons
    -- dependency is not enough on its own, because neo-tree still tries its
    -- default glyphs. These overrides are what actually make it text-only.
    default_component_configs = {
      icon = {
        folder_closed = "+",
        folder_open = "-",
        folder_empty = ".",
        default = " ",
      },
      git_status = {
        symbols = {
          added = "A", modified = "M", deleted = "D", renamed = "R",
          untracked = "?", ignored = "I", unstaged = "U", staged = "S", conflict = "C",
        },
      },
      indent = {
        with_expanders = true,
        expander_collapsed = ">",
        expander_expanded = "v",
      },
    },
    filesystem = {
      follow_current_file = { enabled = true }, -- track the file you are editing
      use_libuv_file_watcher = true,            -- update on external changes
      filtered_items = { hide_dotfiles = false, hide_gitignored = true },
    },
    window = { width = 32 },
  },
}
```

## Formatting via `plugins/formatting.lua`

`conform.nvim` runs Prettier on save, and falls back to the LSP formatter if Prettier is not present.

- `conform` prefers your project-local Prettier from `node_modules`, so each repo's own config and version are respected.
- `goimports` is available through `mason` with `:MasonInstall goimports`. `gofmt` ships with the Go toolchain you already installed.
- `ruff` is already installed as your Python LSP, so `ruff_format` works for free.
- CSS, SCSS, and Less are formatted by Prettier. The indented `.sass` syntax is not in the list, because Prettier does not support it. `stylelint_lsp` handles fixing `.sass` on save instead, as set up in the Language servers section.
- Rust needs no entry. `format_on_save` uses `lsp_format = "fallback"`, so any filetype without an explicit formatter falls back to its language server, and `rust_analyzer`, like `gopls`, formats well that way.

```lua
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  opts = {
    formatters_by_ft = {
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      less = { "prettier" },
      html = { "prettier" },
      markdown = { "prettier" },
      go = { "goimports", "gofmt" }, -- organise imports, then format
      python = { "ruff_format" },    -- ruff handles Python formatting
    },
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "fallback",
    },
  },
}
```

## A live cheatsheet via `config/cheatsheet.lua`

Coming from VS Code you are used to a command palette that lists what you can do. The closest fit here is to generate a cheatsheet from the keymaps you have actually defined, so it can never drift out of date.

The module below reads the live keymaps at the moment you call it and shows them in a floating window. It only lists mappings that carry a `desc`, so the panel stays clean and reflects the labels you wrote.

Two built-in tools already do something similar. `:Telescope keymaps` gives a searchable list of every mapping. If you later add `which-key`, it pops up suggestions as you type a prefix like the leader key. The generator below is for a grouped, on-demand panel.

One behaviour to understand. Your LSP mappings, like `gd` and `gr`, are buffer-local, because they only exist once a language server has attached to a file. So if you run `:Cheatsheet` from a `.tsx` file with `vtsls` running, you will see them. Run it from an empty buffer and that section is empty. This is intentional. The panel shows what is available where you are.

This module is loaded by `init.lua` with `require("config.cheatsheet")`, and bound to `<leader>cs` in `keymaps.lua`. Both lines are already shown above.

```lua
-- ~/.config/nvim/lua/config/cheatsheet.lua
-- Generates a keybinding cheatsheet from the live config, so it cannot drift
-- out of sync with what is actually mapped. Run :Cheatsheet or press <leader>cs.
local M = {}

-- Neovim stores the leader expanded to its actual key, which is a space by
-- default. Turn it back into a readable "<leader>" token for display.
local function leader_token(lhs)
  local leader = vim.g.mapleader or "\\"
  if leader == " " then
    return (lhs:gsub(" ", "<leader>"))
  end
  return (lhs:gsub(vim.pesc(leader), "<leader>"))
end

-- Keep only mappings that carry a description, which are the ones you
-- intentionally documented. This filters out plugins' internal, unlabelled maps.
local function described(maps, out)
  for _, m in ipairs(maps) do
    if m.desc and m.desc ~= "" then
      out[#out + 1] = { lhs = leader_token(m.lhs), desc = m.desc }
    end
  end
  table.sort(out, function(a, b) return a.lhs < b.lhs end)
end

local function section(title, items, lines)
  if #items == 0 then return end
  lines[#lines + 1] = "## " .. title
  lines[#lines + 1] = ""
  local w = 0
  for _, it in ipairs(items) do w = math.max(w, #it.lhs) end
  for _, it in ipairs(items) do
    lines[#lines + 1] = ("  `%s`%s  %s")
      :format(it.lhs, string.rep(" ", w - #it.lhs), it.desc)
  end
  lines[#lines + 1] = ""
end

function M.open()
  local global, buffer = {}, {}
  described(vim.api.nvim_get_keymap("n"), global)
  described(vim.api.nvim_buf_get_keymap(0, "n"), buffer) -- current buffer (LSP, etc.)

  local lines = { "# Live keymap cheatsheet (normal mode)", "" }
  -- Buffer-local maps come first. These are the context-specific binds such as
  -- LSP go-to-definition, rename, and code action. They exist only because a
  -- server is attached to this buffer.
  section("Buffer-local (LSP and filetype, active in this buffer)", buffer, lines)
  section("Global", global, lines)
  lines[#lines + 1] = "Generated live from the running config. Press q to close."

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown" -- picks up your Treesitter highlighting
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = math.min(84, math.floor(vim.o.columns * 0.7))
  local height = math.min(#lines + 1, math.floor(vim.o.lines * 0.8))
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Cheatsheet ",
    style = "minimal",
  })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
end

vim.api.nvim_create_user_command("Cheatsheet", M.open, {})
return M
```

## Launching

```sh
nvim path/to/file.tsx
```

When Neovim starts for the first time, `lazy.nvim` clones itself and installs every plugin, then `mason` pulls the language-server binaries, and Treesitter compiles your parsers. The first launch is slower for this reason, and later launches are fast.

- `:Lazy` shows the plugin status dashboard.
- `:Mason` shows installed servers and tools.
- `:checkhealth` diagnoses missing dependencies, such as the clipboard provider, Node, ripgrep, and the compiler.
- `:checkhealth nvim-treesitter` confirms parsers compiled and the CLI was found.
- `:LspInfo`, which is an alias for `:checkhealth vim.lsp`, confirms which servers attached to the current buffer.
- `:Cheatsheet` opens the live keymap panel.
- `:restart`, introduced in 0.12, reloads Neovim core so you can iterate on config without a full quit.

Open a `.tsx` file in a real project and hover over a symbol with `K`. If you get docs and structural highlighting, the IDE is live.

## Making it portable

Turn the config into a git repo.

```sh
cd ~/.config/nvim
git init
git add .
git commit -m "Initial Neovim IDE config"
git remote add origin <your-repo-url>
git push -u origin main
```

On a new machine, install Neovim, Node, and the build tools, plus whichever language toolchains you use there, such as `go`, `rustup`, and `python`. Clone the repo to `~/.config/nvim`, then open `nvim` once. `lazy`, `mason`, and Treesitter rebuild everything and pull the correct binaries for that operating system. The same config produces the same setup on Arch, macOS, and Windows. On Windows the config path is `~/AppData/Local/nvim` instead.

If you prefer to keep the config inside a wider dotfiles repo, clone that repo wherever you like and symlink it into place with `ln -s ~/dotfiles/nvim ~/.config/nvim`, so Neovim still finds it at the default path.