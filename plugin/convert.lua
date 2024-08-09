-- TODO: fallabck to plenary

function ConvertVisualSelected(converter, text)
    local http = require("http")
    local json = require("json")

    local payload, err = json.encode({
        converter = converter,
        apiKey = vim.g.fanhuaji_key,
        text = text,
    })
    if err then error(err) end

    local response, err = http.request("GET", vim.g.fanhuaji_server, {
        headers = {
            timeout = vim.g.fanhuaji_timeout .. "s",
            headers = {
                Accept = "application/json",
                ["Content-Type"] = "application/json",
            },
            body = payload,
        }
    })
    if err then error(err) end

    -- TODO: error handling
    return response.data.text
end
