# rails_nav (Telescope extension)

A small Telescope extension for Rails-ish navigation:
- model (`app/models/**/*.rb`)
- view (`app/views/**/*`)
- controller (`app/controllers/**/*_controller.rb`)
- spec (`spec/**/*_spec.rb`)

## Install (lazy.nvim)

```lua
{
  "goronfreeman/rails_nav.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("telescope").load_extension("rails_nav")
    -- Optional override:
    -- require("telescope").setup({
    --   extensions = {
    --     rails_nav = {
    --       patterns = {
    --         model = "app/models/**/*.rb",
    --         view = "app/views/**/*",
    --         controller = "app/controllers/**/*_controller.rb",
    --         spec = "spec/**/*_spec.rb",
    --       },
    --       prompt_title = "Rails Nav",
    --     },
    --   },
    -- })
  end,
}
