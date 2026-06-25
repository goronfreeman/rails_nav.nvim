local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  return
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local defaults = {
  patterns = {
    model = "app/models/**/*.rb",
    view = "app/views/**/*",
    controller = "app/controllers/**/*_controller.rb",
    spec = "spec/**/*_spec.rb",
  },
  prompt_title = "Rails Nav",
}

M.opts = vim.deepcopy(defaults)

local function tbl_keys(tbl)
  local keys = {}
  for k, _ in pairs(tbl) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  return keys
end

local function glob_files(glob)
  -- Use Neovim's native globbing.
  -- 0 = don't return list as string
  -- 1 = return list
  local files = vim.fn.glob(glob, false, true)
  if type(files) ~= "table" then
    return {}
  end
  return files
end

local function build_entries()
  local entries = {}
  for _, kind in ipairs(tbl_keys(M.opts.patterns)) do
    local glob = M.opts.patterns[kind]
    for _, path in ipairs(glob_files(glob)) do
      entries[#entries + 1] = {
        value = path,
        display = string.format("[%s] %s", kind, path),
        ordinal = kind .. " " .. path,
        kind = kind,
        path = path,
      }
    end
  end
  return entries
end

function M.rails_nav()
  local entries = build_entries()

  pickers.new({}, {
    prompt_title = M.opts.prompt_title,
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return entry
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      local function open_selection()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.path then
          vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
        end
      end

      map("i", "<CR>", open_selection)
      map("n", "<CR>", open_selection)
      return true
    end,
  }):find()
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return telescope.register_extension({
  setup = function(ext_opts)
    M.setup(ext_opts)
  end,
  exports = {
    rails_nav = M.rails_nav,
  },
})
