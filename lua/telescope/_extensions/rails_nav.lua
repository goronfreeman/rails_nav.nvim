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
  category_title = "Rails Nav Category",
  root_markers = { "config/application.rb", "Gemfile", "app" },
}

M.opts = vim.deepcopy(defaults)

local function category_list()
  return {
    { key = "model", label = "Model" },
    { key = "view", label = "View" },
    { key = "controller", label = "Controller" },
    { key = "spec", label = "Spec" },
  }
end

local function path_join(...)
  return table.concat({ ... }, "/")
end

local function is_dir(path)
  return vim.fn.isdirectory(path) == 1
end

local function is_file(path)
  return vim.fn.filereadable(path) == 1
end

local function marker_exists(dir, marker)
  local candidate = path_join(dir, marker)
  return is_dir(candidate) or is_file(candidate)
end

local function find_rails_root()
  local cwd = vim.fn.getcwd()
  local markers = M.opts.root_markers or {}

  if vim.fs and vim.fs.find and vim.fs.dirname then
    local best_root = nil
    local best_len = -1

    for _, marker in ipairs(markers) do
      local found = vim.fs.find(marker, {
        path = cwd,
        upward = true,
        stop = vim.loop.os_homedir(),
      })[1]

      if found then
        local marker_segments = vim.split(marker, "/", { plain = true })
        local root = found
        for _ = 1, #marker_segments do
          root = vim.fs.dirname(root)
        end

        if root and #root > best_len then
          best_root = root
          best_len = #root
        end
      end
    end

    if best_root then
      return best_root
    end
  end

  local function parent_dir(dir)
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      return nil
    end
    return parent
  end

  local dir = cwd
  while dir do
    for _, marker in ipairs(markers) do
      if marker_exists(dir, marker) then
        return dir
      end
    end
    dir = parent_dir(dir)
  end

  return cwd
end

local function glob_files_from_root(root, glob_pattern)
  local absolute_glob = path_join(root, glob_pattern)
  local files = vim.fn.glob(absolute_glob, false, true)
  if type(files) ~= "table" then
    return {}
  end

  local readable = {}
  for _, path in ipairs(files) do
    if vim.fn.filereadable(path) == 1 then
      readable[#readable + 1] = path
    end
  end
  return readable
end

local function open_file(path)
  if not path or path == "" then
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function display_path(path, root)
  if path:sub(1, #root) == root then
    local rel = path:sub(#root + 2)
    if rel ~= "" then
      return rel
    end
  end
  return path
end

local function notify_no_files(category_key, root, glob)
  vim.notify(
    string.format(
      "rails_nav: no %s files found in %s (pattern: %s)",
      category_key,
      root,
      glob
    ),
    vim.log.levels.INFO
  )
end

local function open_file_picker_for_category(category_key)
  local glob = M.opts.patterns[category_key]
  if not glob then
    vim.notify("rails_nav: unknown category " .. tostring(category_key), vim.log.levels.WARN)
    return
  end

  local root = find_rails_root()
  local files = glob_files_from_root(root, glob)

  if #files == 0 then
    notify_no_files(category_key, root, glob)
    return
  end

  pickers
    .new({}, {
      prompt_title = string.format("%s: %s", M.opts.prompt_title, category_key),
      finder = finders.new_table({
        results = files,
        entry_maker = function(path)
          local displ = display_path(path, root)
          return {
            value = path,
            ordinal = displ,
            display = displ,
            path = path,
          }
        end,
      }),
      previewer = conf.file_previewer({}),
      sorter = conf.file_sorter({}),
      cwd = root,
      attach_mappings = function(prompt_bufnr, map)
        local function select_and_open()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            open_file(selection.path or selection.value or selection[1])
          end
        end

        map("i", "<CR>", select_and_open)
        map("n", "<CR>", select_and_open)
        return true
      end,
    })
    :find()
end

function M.rails_nav()
  local categories = category_list()

  pickers
    .new({}, {
      prompt_title = M.opts.category_title,
      finder = finders.new_table({
        results = categories,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.label,
            ordinal = entry.label .. " " .. entry.key,
            key = entry.key,
            label = entry.label,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function choose_category()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value and selection.value.key then
            open_file_picker_for_category(selection.value.key)
          end
        end

        map("i", "<CR>", choose_category)
        map("n", "<CR>", choose_category)
        return true
      end,
    })
    :find()
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
