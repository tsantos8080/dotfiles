local M = {}

function M.run_test()
    local filepath = vim.fn.expand('%')
    local phpunit_command = "./vendor/bin/phpunit " .. filepath

    local ts_utils = require('nvim-treesitter.ts_utils')

    local expr = ts_utils.get_node_at_cursor()
    while expr do
        if expr:type() == 'method_declaration' then
            local method_name = (ts_utils.get_node_text(expr:child(2)))[1]
	    phpunit_command = phpunit_command .. ' --filter ' .. method_name
            break
        end
        expr = expr:parent()
    end

    local command = "!docker exec $(docker ps --filter='expose=9000' | grep melhorenvio-php | awk '{print $1}') bash -c '" .. phpunit_command .. "'"
    
    vim.cmd(command)
end

return M
