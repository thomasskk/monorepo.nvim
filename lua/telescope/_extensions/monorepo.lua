local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  return
end

local finders = require("telescope.finders")
local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local messages = require("monorepo.messages")
local utils = require("monorepo.utils")

local function select_project(prompt_bufnr)
  actions.close(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  local dir = require("monorepo").currentMonorepo .. "/" .. selection.value
  vim.api.nvim_set_current_dir(dir)
  local on_select = require("monorepo").config.on_select
  if on_select then
    on_select(dir)
  end
  utils.notify(messages.SWITCHED_PROJECT .. ": " .. selection.value)
end

local function delete_entry(prompt_bufnr)
  local selected_entry = action_state.get_selected_entry(prompt_bufnr)
  if not selected_entry then
    return
  end
  if selected_entry.value == "/" then
    utils.notify(messages.CANT_REMOVE_MONOREPO)
    return
  end
  require("monorepo").remove_project(selected_entry.value)
  action_state.get_current_picker(prompt_bufnr):refresh(
    finders.new_table({
      results = require("monorepo").currentProjects,
    }),
    { reset_prompt = true }
  )
end

local function add_entry(prompt_bufnr)
  require("monorepo").prompt_project()
  action_state.get_current_picker(prompt_bufnr):refresh(
    finders.new_table({
      results = require("monorepo").currentProjects,
    }),
    { reset_prompt = true }
  )
end

local monorepo = function(opts)
  opts = opts or require("telescope.themes").get_dropdown()
  pickers
    .new(opts, {
      prompt_title = "Projects - " .. require("monorepo").currentMonorepo,
      finder = finders.new_table({
        results = require("monorepo").currentProjects,
      }),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        map("n", "dd", delete_entry)
        map("i", "<c-d>", delete_entry)
        map("i", "<c-a>", add_entry)
        actions.select_default:replace(select_project)
        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  exports = {
    monorepo = monorepo,
  },
})
