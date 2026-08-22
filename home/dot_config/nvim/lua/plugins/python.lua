-- Point pyright at the project's local virtualenv.
--
-- uv (`uv venv` / `uv sync`) always creates `.venv` in the project root, but
-- pyright doesn't look for it: with no venv configured it falls back to the
-- `python` on $PATH, so every third-party import resolves to nothing and
-- completion dies. Resolve it per-root instead of per-project.
--
-- This has to happen in `on_init` rather than `before_init`: the client copies
-- `config.settings` at construction time, and it's that copy which answers
-- pyright's `workspace/configuration` requests.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          on_init = function(client)
            local root = client.root_dir or vim.fn.getcwd()
            local python = root .. "/.venv/bin/python"
            if vim.uv.fs_stat(python) then
              client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
                python = { pythonPath = python },
              })
            end
          end,
        },
      },
    },
  },
}
