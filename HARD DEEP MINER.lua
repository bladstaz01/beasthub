--HARD DEEP MINER 9001 🛠️ (With Require Timeout)
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Recursively convert tables to string with indentation
local function deepToString(tbl, indent, visited)
    indent = indent or 0
    visited = visited or {}
    if visited[tbl] then
        return string.rep("  ", indent) .. "[Circular Reference]\n"
    end
    visited[tbl] = true

    local result = ""
    local prefix = string.rep("  ", indent)
    for k, v in pairs(tbl) do
        local key = "[" .. tostring(k) .. "]"
        if type(v) == "table" then
            result = result .. prefix .. key .. " = {\n"
            result = result .. deepToString(v, indent + 1, visited)
            result = result .. prefix .. "}\n"
        elseif type(v) == "function" then
            result = result .. prefix .. key .. " = [Function]\n"
        elseif type(v) == "userdata" then
            result = result .. prefix .. key .. " = [Userdata]\n"
        else
            result = result .. prefix .. key .. " = " .. tostring(v) .. "\n"
        end
    end
    return result
end

-- Safe require with timeout (avoids infinite yield)
local function safeRequireWithTimeout(module, timeout)
    local finished, result = false, nil
    task.spawn(function()
        local ok, res = pcall(require, module)
        if ok then
            result = res
        else
            result = nil
            warn("[BeastHub] ⚠️ Require failed for:", module:GetFullName(), "| Reason:", res)
        end
        finished = true
    end)

    local start = os.clock()
    while not finished do
        RunService.Heartbeat:Wait()
        if os.clock() - start > timeout then
            warn("[BeastHub] ⏱️ Require timed out for:", module:GetFullName())
            return nil -- skip this module
        end
    end
    return result
end

-- Main function with logs & progress
local function hardDeepMine(root)
    if not root then
        warn("[BeastHub] ❌ Invalid root passed!")
        return
    end

    local descendants = root:GetDescendants()
    local totalModules = 0
    for _, d in ipairs(descendants) do
        if d:IsA("ModuleScript") then totalModules += 1 end
    end

    print("[BeastHub] 🔥 Starting HARD DEEP MINER on:", root:GetFullName(), "| Total Modules:", totalModules)

    local output, moduleCount, failedCount = "", 0, 0
    for _, descendant in ipairs(descendants) do
        if descendant:IsA("ModuleScript") then
            moduleCount += 1
            print(string.format("[BeastHub] ⛏️ Mining Module %d/%d: %s", moduleCount, totalModules, descendant:GetFullName()))

            output = output .. "\n=============================\n"
            output = output .. "Module: " .. descendant:GetFullName() .. "\n"
            output = output .. "=============================\n"

            local result = safeRequireWithTimeout(descendant, 2) -- 2-second timeout
            if result then
                if type(result) == "table" then
                    output = output .. deepToString(result)
                else
                    output = output .. "[Returned: " .. typeof(result) .. "]\n"
                end
            else
                failedCount += 1
                output = output .. "[Skipped: Failed or Timeout]\n"
            end
        end
    end

    local filename = "DeepMineDump_" .. root.Name .. "_" .. os.time() .. ".txt"
    writefile(filename, output)
    print("[BeastHub] ✅ Done! Mined " .. moduleCount .. " modules (" .. failedCount .. " skipped).")
    print("[BeastHub] 💾 Saved to:", filename)
end

-- Run immediately
hardDeepMine(game:GetService("ReplicatedStorage"))
