return {
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        lazy = true,
        config = false,
        init = function()
            -- Disable automatic setup, we are doing it manually
            vim.g.lsp_zero_extend_lspconfig = 0
            vim.g.lsp_zero_extend_cmp = 0
        end,
    },
    {
        'williamboman/mason.nvim',
        lazy = false,
        config = true,
    },

    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            {'L3MON4D3/LuaSnip'},
        },
        config = function()
            local cmp = require('cmp')
            local lsp_zero = require('lsp-zero')
            local cmp_action = lsp_zero.cmp_action()
            cmp.setup({
                formatting = lsp_zero.cmp_format({details = true}),
                mapping = {
                    ['<Tab>'] = cmp_action.tab_complete(),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),
                    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
                    ['<C-b>'] = cmp_action.luasnip_jump_backward(),
                }
            })
            -- Here is where you configure the autocompletion settings.
            lsp_zero.extend_cmp()
        end
    },

    -- LSP
    {
        'neovim/nvim-lspconfig',
        cmd = {
            'LspInfo',
            'LspInstall',
            'LspStart'
        },
        event = {'BufReadPre', 'BufNewFile'},
        dependencies = {
            {'hrsh7th/cmp-nvim-lsp'},
            {'williamboman/mason-lspconfig.nvim'},
        },
        config = function()
            -- This is where all the LSP shenanigans will live
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_lspconfig()

            --- if you want to know more about lsp-zero and mason.nvim
            --- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
            lsp_zero.on_attach(function(client, bufnr)
                -- see :help lsp-zero-keybindings
                -- to learn the available actions
                lsp_zero.default_keymaps({buffer = bufnr})
            end)

            require('mason-lspconfig').setup({
                ensure_installed = {},
                handlers = {
                    lsp_zero.default_setup,
                    lua_ls = function()
                        -- (Optional) Configure lua language server for neovim
                        local lua_opts = lsp_zero.nvim_lua_ls()
                        require('lspconfig').lua_ls.setup(lua_opts)
                    end,
                    jdtls = function()
                        -- makes sure you dont start two clients
                        return true
                    end

                }
            })
        end
    },
    {
        "mfussenegger/nvim-jdtls",
        -- enabled = false,
        lazy = true,
        ft = { "java" },
        config = function()
            -- Configuration file to be loaded whenever a java file is edited

            local mason_path_jdtls = vim.fn.stdpath("data") .. "/mason/packages/jdtls/plugins/"
            local mason_path_java_debug = vim.fn.stdpath("data") .. "/mason/packages/java-debug-adapter/extension/server/"

            local equinox
            -- if vim.fn.isdirectory(mason_path_jdtls) == 1 then
            --     for file in io.popen("ls " .. mason_path_jdtls):lines() do
            --         if string.find(file, "launcher_") then
            --             equinox = mason_path_jdtls .. file
            --             break
            --         end
            --     end
            -- else
            --     print("Mason Path JDTLS does not exist!")
            -- end
            for file in io.popen("dir " .. mason_path_jdtls .. " /b"):lines() do
                if string.find(file, "launcher_") then
                    equinox = mason_path_jdtls .. file
                    break
                end
            end

            local debug_jar
            for file in io.popen("dir " .. mason_path_java_debug .. " /b"):lines() do
                if string.find(file, "debug") then
                    debug_jar = mason_path_java_debug .. file
                    break
                end
            end
            -- local debug_jar
            -- for file in io.popen("ls " .. mason_path_java_debug):lines() do
            --     if string.find(file, "debug") then
            --         debug_jar = mason_path_java_debug .. file
            --         break
            --     end
            -- end

            local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
            -- local data_dir = vim.fn.getcwd()
            -- local data_dir = vim.fn.stdpath("data") .. '/jdtls/workspace' .. project_name
            -- local data_dir = project_name
            -- local data_dir = '/path/to/workspace-root/' .. project_name
            local data_dir = '/home/boopity/.local/share/nvim/jdtls/workspace' .. project_name
            local config_linux = vim.fn.stdpath("data") .. "/mason/packages/jdtls/config_linux"

            -- print(equinox)
            -- print(debug_jar)
            -- print(data_dir)
            -- print(config_linux)

            local config = {
                -- The command that starts the language server
                -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
                cmd = {
                    "java",
                    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                    "-Dosgi.bundles.defaultStartLevel=4",
                    "-Declipse.product=org.eclipse.jdt.ls.core.product",
                    "-Dlog.protocol=true",
                    "-Dlog.level=ALL",
                    "-Xmx1g",
                    "--add-modules=ALL-SYSTEM",
                    "--add-opens", "java.base/java.util=ALL-UNNAMED",
                    "--add-opens", "java.base/java.lang=ALL-UNNAMED",

                    -- "-jar", equinox,
                    -- "-configuration", config_linux,

                    "-jar", equinox,
                    "-configuration", config_linux,
                    "-data", data_dir,
                },
                -- root_dir = vim.fs.root(0, {".git", "mvnw", "gradlew"}),
                root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
                -- root_dir = require("jdtls.setup").find_root({ ".git", "gradlew" }),

                -- Here you can configure eclipse.jdt.ls specific settings
                -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
                -- for a list of options
                settings = {
                    java = {},
                },

                -- Language server `initializationOptions`
                -- You need to extend the `bundles` with paths to jar files
                -- if you want to use additional eclipse.jdt.ls plugins.
                --
                -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
                --
                -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
                init_options = {
                    bundles = {
                        -- vim.fn.glob(debug_jar, true),
                    },
                },
            }
            require("jdtls").start_or_attach(config)
        end
    },
}
