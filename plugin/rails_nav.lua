-- Default keymap: <leader>rn
vim.api.nvim_create_autocmd("User", {
  pattern = "TelescopeLoaded",
  callback = function()
    pcall(function()
      vim.keymap.set("n", "<leader>rn", function()
        require("telescope").extensions.rails_nav.rails_nav()
      end, { desc = "Rails Nav picker" })
    end)
  end,
})

-- Fallback in case User event isn't fired by setup
vim.schedule(function()
  pcall(function()
    vim.keymap.set("n", "<leader>rn", function()
      require("telescope").extensions.rails_nav.rails_nav()
    end, { desc = "Rails Nav picker" })
  end)
end)
