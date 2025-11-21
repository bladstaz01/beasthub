--security checks
local username = game.Players.LocalPlayer.Name
local expectedURL = "https://pastebin.com/raw/rKZ0j0E4"
local expectedHash = "24de0a462dcff14bab1fcedacf6c87fc3af9a8b4321585d38c5d1f740821461a"
local whitelistMonitoringURL = "https://discord.com/api/webhooks/1441321774859157525/sX-UH3dzHSxmoW0rkhixXnVMLXyByr2U2Bd_U_gikQlqBxBEHBaOzwfRnRogLN_N2Moq"

local function showWhitelistErrorMessage(msg)
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- destroy old popup if exists
    if playerGui:FindFirstChild("WhitelistMessage") then
        playerGui.WhitelistMessage:Destroy()
    end

    -- container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WhitelistMessage"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 420, 0, 185)
    frame.Position = UDim2.new(0.5, -210, 0.20, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- CLOSE BUTTON (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 20
    closeBtn.Text = "X"
    closeBtn.AutoButtonColor = true
    closeBtn.Parent = frame

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- message text
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -70)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.1
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 22
    label.TextWrapped = true
    label.Text = msg
    label.Parent = frame

    -- Discord Link TextBox (copyable)
    local linkBox = Instance.new("TextBox")
    linkBox.Size = UDim2.new(1, -20, 0, 35)
    linkBox.Position = UDim2.new(0, 10, 0, 105)
    linkBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    linkBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    linkBox.Font = Enum.Font.SourceSans
    linkBox.TextSize = 18
    linkBox.Text = "https://discord.gg/v4NChX7YCB"
    linkBox.ClearTextOnFocus = false
    linkBox.Parent = frame

    -- copy button
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 80, 0, 30)
    copyBtn.Position = UDim2.new(1, -90, 0, 145)
    copyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.Font = Enum.Font.SourceSansBold
    copyBtn.TextSize = 18
    copyBtn.Text = "Copy"
    copyBtn.Parent = frame

    -- copy functionality
    copyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(linkBox.Text)
        end
        copyBtn.Text = "Copied!"
        task.delay(1.5, function()
            copyBtn.Text = "Copy"
        end)
    end)
end
local function sendDiscordWebhook(webhookUrl, message)
    -- print("webhookUrl: "..webhookUrl)
    if typeof(webhookUrl) ~= "string" or webhookUrl == "" then
        warn("[Webhook] Invalid webhook URL")
        return
    end
    local payload = game:GetService("HttpService"):JSONEncode({ content = message })
    -- Directly use executor HTTP request (Synapse, KRNL, Fluxus, etc.)
    local req = syn and syn.request or http_request or request
    if not req then
        warn("[Webhook] Your executor does not support HTTP requests!")
        return
    end
    local success, result = pcall(function()
        return req({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = payload
        })
    end)
    if success and result.Success then
        -- print("[Webhook] Message sent successfully!")
    else
        warn("[Webhook] Failed to send: " .. tostring(result and result.StatusCode or result))
    end
end
local shaLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Egor-Skriptunoff/pure_lua_SHA/master/sha2.lua"))()
local function sha256(str)
    return shaLib.sha256(str)
end

-- Hash the URL itself (not the content)
local calculated = sha256(expectedURL)

if calculated ~= expectedHash then
    -- instantly stop execution
    sendDiscordWebhook(whitelistMonitoringURL, "Tampering detected! Username: "..username)
    showWhitelistErrorMessage("Pleast stop tampering and support BeastHub Developer instead :(\nJoin our Discord to request access:")
    error("Tampering detected. Script halted.", 0)
    return
end

--=============================================================
--check whitelist
local whitelist = loadstring(game:HttpGet("https://pastebin.com/raw/rKZ0j0E4"))()



local isVerified = whitelist.verify(username)
if not isVerified then
    showWhitelistErrorMessage("You are not whitelisted in BeastHub!\n\nJoin our Discord to request access:")
    sendDiscordWebhook(whitelistMonitoringURL, "Login attempt but whitelist error: "..username)
    error("Whitelist verification failed, stopping script.")
end




--==========================================================
-- Load Rayfield **once**
if not getgenv().BeastHubRayfield then
    getgenv().BeastHubRayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end
local Rayfield = getgenv().BeastHubRayfield
local beastHubIcon = 88823002331312

-- Prevent multiple Rayfield instances
if getgenv().BeastHubLoaded then
    if Rayfield then
        Rayfield:Notify({
            Title = "BeastHub",
            Content = "Already running! Press H",
            Duration = 5,
            Image = beastHubIcon
        })
    else
        warn("BeastHub is already running!")
    end    
    return
end
getgenv().BeastHubLoaded = true

-- Store your script link for reloading
getgenv().BeastHubLink = "https://pastebin.com/raw/GjsWnygW"

-- Load my reusable functions
if not getgenv().BeastHubFunctions then
    getgenv().BeastHubFunctions = loadstring(game:HttpGet("https://pastebin.com/raw/wEUUnKuv"))()
end
local myFunctions = getgenv().BeastHubFunctions
-- Create Luck GUI for playtime luck
local luckGUI = myFunctions.createLuckGUI()

-- ================== MAIN ==================
local Window = Rayfield:CreateWindow({
   Name = "BeastHub",
   Icon = beastHubIcon, --BeastHub logo
   LoadingTitle = "BeastHub",
   LoadingSubtitle = "by Team Forgotten",
   ShowText = "Rayfield",
   Theme = "Default",
   ToggleUIKeybind = "H",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "BeastHub",
      FileName = "userConfig"
   }
})

local function beastHubNotify(title, message, duration)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Image = beastHubIcon
    })
end

local mainModule = loadstring(game:HttpGet("https://pastebin.com/raw/K4yBnmbf"))()
mainModule.init(Rayfield, beastHubNotify, Window, myFunctions, reloadScript, beastHubIcon)



local Shops = Window:CreateTab("Shops", "circle-dollar-sign")
local Pets = Window:CreateTab("Pets", "cat")
local PetEggs = Window:CreateTab("Eggs", "egg")
local Misc = Window:CreateTab("Misc", "code")
-- ===Declarations
local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
--local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local placeId = game.PlaceId
local character = player.Character
local Humanoid = character:WaitForChild("Humanoid")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")







-- Safe Reload button
local function reloadScript(message)
    -- Reset flags first so main script can run again
    getgenv().BeastHubLoaded = false
    getgenv().BeastHubRayfield = nil
 
    -- Destroy existing Rayfield UI safely
    if Rayfield and Rayfield.Destroy then
        Rayfield:Destroy()
        print("Rayfield destroyed")
    elseif game:GetService("CoreGui"):FindFirstChild("Rayfield") then
        game:GetService("CoreGui").Rayfield:Destroy()
        print("Rayfield destroyed in CoreGui")
    end
 
    -- Reload main script from Pastebin
    if getgenv().BeastHubLink then
        local ok, err = pcall(function()
            loadstring(game:HttpGet(getgenv().BeastHubLink))()
        end)
        if ok then
            Rayfield = getgenv().BeastHubRayfield
            Rayfield:Notify({
                Title = "BeastHub",
                Content = message.." successful",
                Duration = 3,
                Image = beastHubIcon
            })
            print("BeastHub reloaded successfully")
        else
            warn("Failed to reload BeastHub:", err)
        end
    else
        warn("Reload link not set!")
    end
end











-- Shops>Seeds
-- load data
local seedsTable = myFunctions.getAvailableShopList(game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop"))
-- extract names for dropdown
local seedNames = {}
for _, item in ipairs(seedsTable) do
    table.insert(seedNames, item.Name)
end

-- UI Setup
Shops:CreateSection("Seeds - Tier 1")
local SelectedSeeds = {}

-- Create Dropdown
local Dropdown_allSeeds = Shops:CreateDropdown({
    Name = "Select Seeds",
    Options = seedNames,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "dropdownTier1Seeds",
    Callback = function(options)
        --if not options or not options[1] then return end
        for _, seed in ipairs(options) do
            if not table.find(SelectedSeeds, seed) then
                table.insert(SelectedSeeds, seed)
            end
        end
        -- Remove unselected
        for i = #SelectedSeeds, 1, -1 do
            local seed = SelectedSeeds[i]
            if not table.find(options, seed) and table.find(CurrentFilteredSeeds, seed) then
                table.remove(SelectedSeeds, i)
            end
        end
        -- print("Selected seeds:", table.concat(SelectedSeeds, ", "))
    end,
})

-- Mark All button (only visible/filtered seeds)
Shops:CreateButton({
    Name = "[ * ] select all",
    Callback = function()
        for _, seed in ipairs(seedNames) do
            if not table.find(SelectedSeeds, seed) then
                table.insert(SelectedSeeds, seed)
            end
        end
        Dropdown_allSeeds:Set(seedNames)
        -- print("All visible seeds selected:", table.concat(SelectedSeeds, ", "))
    end,
})

-- Unselect All button (only visible/filtered seeds)
Shops:CreateButton({
    Name = "[   ] unselect all",
    Callback = function()
        for i = #SelectedSeeds, 1, -1 do
            if table.find(seedNames, SelectedSeeds[i]) then
                table.remove(SelectedSeeds, i)
            end
        end
        Dropdown_allSeeds:Set({})
        -- print("Visible seeds unselected")
    end,
})

-- Auto-buy toggle for selected
myFunctions._autoBuySelectedSeedsRunning = false -- toggle stoppers seeds
myFunctions._autoBuyAllSeedsRunning = false

myFunctions._autoBuySelectedGearsRunning = false -- toggle stoppers gears 
myFunctions._autoBuyAllGearsRunning = false

myFunctions._autoBuySelectedEggsRunning = false -- toggle stoppers eggs
myFunctions._autoBuyAllEggsRunning = false



local Toggle_autoBuySeedsTier1_selected = Shops:CreateToggle({
    Name = "Auto buy selected",
    CurrentValue = false,
    Flag = "autoBuySeedsTier1_selected",
    Callback = function(Value)
        myFunctions._autoBuySelectedSeedsRunning = Value

        if Value then
            if #SelectedSeeds > 0 then
                --print("[BeastHub] Auto-buying selected seeds:", table.concat(SelectedSeeds, ", "))
                
                -- pass a function for dynamic check
                myFunctions.buyItemsLive(
                    game:GetService("ReplicatedStorage").GameEvents.BuySeedStock,
                    function()
                        return myFunctions.getAvailableShopList(game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop"))
                    end,
                    SelectedSeeds,
                    function() return myFunctions._autoBuySelectedSeedsRunning end, -- dynamic running flag
                    "BuySeedStock"
                )
            else
                warn("[BeastHub] No seeds selected!")
            end
        else
            --print("[BeastHub] Stopped auto-buy selected seeds.")
        end
    end,
})

-- Auto-buy toggle for all seeds
local Toggle_autoBuySeedsTier1_all = Shops:CreateToggle({
    Name = "Auto buy all",
    CurrentValue = false,
    Flag = "autoBuySeedsTier1_all",
    Callback = function(Value)
        myFunctions._autoBuyAllSeedsRunning = Value -- module flag
        if Value then
            -- print("[BeastHub] Auto-buying ALL seeds")
            -- Trigger live buy
            myFunctions.buyItemsLive(
                game:GetService("ReplicatedStorage").GameEvents.BuySeedStock, -- buy event
                function()
                    return myFunctions.getAvailableShopList(game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Seed_Shop"))
                end, -- shop list
                seedNames, -- all available 
                function() return myFunctions._autoBuyAllSeedsRunning end,
                "BuySeedStock"
            )
        else
            --print("[BeastHub] Stopped auto-buy ALL gears")
        end
    end,
})
Shops:CreateDivider()


-- Shops>Gear
-- load data
local gearsTable = myFunctions.getAvailableShopList(game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Gear_Shop"))
-- extract names for dropdown
local gearNames = {}
for _, item in ipairs(gearsTable) do
    table.insert(gearNames, item.Name)
end

-- UI
Shops:CreateSection("Gears")
local SelectedGears = {}

local Dropdown_allGears = Shops:CreateDropdown({
    Name = "Select Gears",
    Options = gearNames,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "dropdownGears",
    Callback = function(options)
        --if not options or not options[1] then return end
        for _, gear in ipairs(options) do
            if not table.find(SelectedGears, gear) then
                table.insert(SelectedGears, gear)
            end
        end
        -- Remove unselected
        for i = #SelectedGears, 1, -1 do
            local gear = SelectedGears[i]
            if not table.find(options, gear) and table.find(gearNames, gear) then
                table.remove(SelectedGears, i)
            end
        end
    end,
})

-- Mark All button
Shops:CreateButton({
    Name = "[ * ] select all",
    Callback = function()
        for _, gear in ipairs(gearNames) do
            if not table.find(SelectedGears, gear) then
                table.insert(SelectedGears, gear)
            end
        end
        Dropdown_allGears:Set(gearNames)
        -- print("All visible gears selected:", table.concat(SelectedGears, ", "))
    end,
})

-- Unselect All button 
Shops:CreateButton({
    Name = "[   ] unselect all",
    Callback = function()
        for i = #SelectedGears, 1, -1 do
            if table.find(gearNames, SelectedGears[i]) then
                table.remove(SelectedGears, i)
            end
        end
        Dropdown_allGears:Set({})
        -- print("Visible gears unselected")
    end,
})


--Auto buy selected gears
local Toggle_autoBuyGears_selected = Shops:CreateToggle({
    Name = "Auto buy selected",
    CurrentValue = false,
    Flag = "autoBuyGears_selected",
    Callback = function(Value)
        myFunctions._autoBuySelectedGearsRunning = Value
        if Value then
            if #SelectedGears > 0 then
                -- print("[BeastHub] Auto-buying selected gears:", table.concat(SelectedGears, ", "))
                myFunctions.buyItemsLive(
                    game:GetService("ReplicatedStorage").GameEvents.BuyGearStock,
                    gearsTable,
                    SelectedGears,
                    function() return myFunctions._autoBuySelectedGearsRunning end
                )
            else
                warn("[BeastHub] No gears selected!")
            end
        else
            -- myFunctions._autoBuySelectedGearsRunning = false
        end
    end,
})



-- Auto-buy toggle for all gears
local Toggle_autoBuyGears_all = Shops:CreateToggle({
    Name = "Auto buy all",
    CurrentValue = false,
    Flag = "autoBuyGears_all",
    Callback = function(Value)
        myFunctions._autoBuyAllGearsRunning = Value -- module flag

        if Value then
            --print("[BeastHub] Auto-buying ALL gears")
            -- Trigger live buy
            myFunctions.buyItemsLive(
                game:GetService("ReplicatedStorage").GameEvents.BuyGearStock, -- buy event
                gearsTable, -- shop list
                gearNames, -- all available gears
                function() return myFunctions._autoBuyAllGearsRunning end
            )
        else
            --print("[BeastHub] Stopped auto-buy ALL gears")
        end
    end,
})
Shops:CreateDivider()


-- Shops>Eggs
-- load data
local eggsTable = myFunctions.getAvailableShopList(game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("PetShop_UI"))
-- extract names for dropdown
local eggNames = {}
for _, item in ipairs(eggsTable) do
    table.insert(eggNames, item.Name)
end

-- UI
Shops:CreateSection("Eggs")
local SelectedEggs = {}

local Dropdown_allEggs = Shops:CreateDropdown({
    Name = "Select Eggs",
    Options = eggNames,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "dropdownEggs",
    Callback = function(options)
        --if not Options or not Options[1] then return end
        for _, egg in ipairs(options) do
            if not table.find(SelectedEggs, egg) then
                table.insert(SelectedEggs, egg)
            end
        end
        -- Remove unselected
        for i = #SelectedEggs, 1, -1 do
            local egg = SelectedEggs[i]
            if not table.find(options, egg) and table.find(eggNames, egg) then
                table.remove(SelectedEggs, i)
            end
        end
    end,
})

-- Mark All button
Shops:CreateButton({
    Name = "[ * ] select all",
    Callback = function()
        for _, egg in ipairs(eggNames) do
            if not table.find(SelectedEggs, egg) then
                table.insert(SelectedEggs, egg)
            end
        end
        Dropdown_allEggs:Set(eggNames)
    end,
})

-- Unselect All button 
Shops:CreateButton({
    Name = "[   ] unselect all",
    Callback = function()
        for i = #SelectedEggs, 1, -1 do
            if table.find(eggNames, SelectedEggs[i]) then
                table.remove(SelectedEggs, i)
            end
        end
        Dropdown_allEggs:Set({})
    end,
})

--Auto buy selected eggs
myFunctions._autoBuySelectedEggsRunning = false -- toggle stoppers
myFunctions._autoBuyAllEggsRunning = false
local Toggle_autoBuyEggs_selected = Shops:CreateToggle({
    Name = "Auto buy selected",
    CurrentValue = false,
    Flag = "autoBuyEggs_selected",
    Callback = function(Value)
        myFunctions._autoBuySelectedEggsRunning = Value
        if Value then
            if #SelectedEggs > 0 then
                myFunctions.buyItemsLive(
                    game:GetService("ReplicatedStorage").GameEvents.BuyPetEgg,
                    eggsTable,
                    SelectedEggs,
                    function() return myFunctions._autoBuySelectedEggsRunning end
                )
            else
                warn("[BeastHub] No eggs selected!")
            end
        end
    end,
})

-- Auto-buy toggle for all eggs
local Toggle_autoBuyEggs_all = Shops:CreateToggle({
    Name = "Auto buy all",
    CurrentValue = false,
    Flag = "autoBuyEggs_all",
    Callback = function(Value)
        myFunctions._autoBuyAllEggsRunning = Value
        if Value then
            myFunctions.buyItemsLive(
                game:GetService("ReplicatedStorage").GameEvents.BuyPetEgg,
                eggsTable,
                eggNames,
                function() return myFunctions._autoBuyAllEggsRunning end
            )
        end
    end,
})

Shops:CreateDivider()





-- PetEggs>Eggs
PetEggs:CreateSection("Auto Place eggs")
--Auto place eggs
--get egg list first based on registry
local function getEggNames()
    local eggNames = {}
    local success, err = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PetRegistry = require(ReplicatedStorage.Data.PetRegistry)

        -- Ensure PetEggs exists
        if not PetRegistry.PetEggs then
            warn("PetRegistry.PetEggs not found!")
            return
        end

        -- Collect egg names
        for eggName, eggData in pairs(PetRegistry.PetEggs) do
            if eggName ~= "Fake Egg" then
                table.insert(eggNames, eggName)
            end
        end
    end)

    if not success then
        warn("getEggNames failed:", err)
    end
    return eggNames
end
local allEggNames = getEggNames()
table.sort(allEggNames)


--get current egg count in garden
local function getFarmEggCount()
    local petEggsList = myFunctions.getMyFarmPetEggs()
    return #petEggsList -- simply return the number of eggs
end

--equip
local function equipItemByName(itemName)
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
	player.Character.Humanoid:UnequipTools() --unequip all first

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and string.find(tool.Name, itemName) then
            --print("Equipping:", tool.Name)
			player.Character.Humanoid:UnequipTools() --unequip all first
            player.Character.Humanoid:EquipTool(tool)
            return true -- stop after first match
        end
    end
    return false
end

--dropdown for egg list
local Dropdown_eggToPlace = PetEggs:CreateDropdown({
    Name = "Select Egg to Auto Place",
    Options = allEggNames,
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "eggToAutoPlace", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end -- nothing selected yet
    end,
})

--input egg count to place
local eggsToPlaceInput = 13
local Input_numberOfEggsToPlace = PetEggs:CreateInput({
    Name = "Number of eggs to place",
    CurrentValue = "13",
    PlaceholderText = "# of eggs",
    RemoveTextAfterFocusLost = false,
    Flag = "numberOfEggsToPlace",
    Callback = function(Text)
        eggsToPlaceInput = tonumber(Text) or 0
    end,
})


-- Listen for Notification event once for too close eggs
local tooCloseFlag = false
local petAlreadyInMachineFlag = false
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Notification = ReplicatedStorage.GameEvents.Notification
Notification.OnClientEvent:Connect(function(message)
    if typeof(message) == "string" and message:lower():find("too close to another egg") then
        tooCloseFlag = true
        --print("[DEBUG] Too close notification received, skipping increment")
    end

    if typeof(message) == "string" and message:lower():find("a pet is already in the machine!") then
        petAlreadyInMachineFlag = true
    end
end)

--=======HANDEL LOCATIONS FOR  AUTO PLACE EGG
local localPlayer = Players.LocalPlayer
-- find player's farm
local function getMyFarm()
    if not localPlayer then
        warn("[BeastHub] Local player not found!")
        return nil
    end

    local farmsFolder = workspace:WaitForChild("Farm")
    for _, farm in pairs(farmsFolder:GetChildren()) do
        if farm:IsA("Folder") or farm:IsA("Model") then
            local ownerValue = farm:FindFirstChild("Important") 
                            and farm.Important:FindFirstChild("Data") 
                            and farm.Important.Data:FindFirstChild("Owner")
            if ownerValue and ownerValue.Value == localPlayer.Name then
                return farm
            end
        end
    end

    warn("[BeastHub] Could not find your farm!")
    return nil
end

-- get farm spawn point CFrame
local function getFarmSpawnCFrame() --old code
    local myFarm = getMyFarm()
    if not myFarm then return nil end

    local spawnPoint = myFarm:FindFirstChild("Spawn_Point")
    if spawnPoint and spawnPoint:IsA("BasePart") then
        return spawnPoint.CFrame
    end

    warn("[BeastHub] Spawn_Point not found in your farm!")
    return nil
end


-- relative egg positions (local space relative to spawn point)
local eggOffsets = {
    Vector3.new(-36, 0, -18),
    Vector3.new(-27, 0, -18),
    Vector3.new(-18, 0, -18),
    Vector3.new(-9, 0, -18),

    Vector3.new(-36, 0, -33),
    Vector3.new(-27, 0, -33),
    Vector3.new(-18, 0, -33),
    Vector3.new(-9, 0, -33),

    Vector3.new(-36, 0, -48),
    Vector3.new(-27, 0, -48),
    Vector3.new(-18, 0, -48),
    Vector3.new(-9, 0, -48),

    Vector3.new(-36, 0, -63),
    Vector3.new(-27, 0, -63),
    Vector3.new(-18, 0, -63),
    Vector3.new(-9, 0, -63),
}

-- convert to world positions
local function getFarmEggLocations()
    local spawnCFrame = getFarmSpawnCFrame()
    if not spawnCFrame then return {} end

    local locations = {}
    for _, offset in ipairs(eggOffsets) do
        table.insert(locations, spawnCFrame:PointToWorldSpace(offset))
    end
    return locations
end

--=====================


--toggle auto place eggs
local autoPlaceEggsThread -- store the task
local autoPlaceEggsEnabled = false
local Toggle_autoPlaceEggs = PetEggs:CreateToggle({
    Name = "Auto place eggs",
    CurrentValue = false,
    Flag = "autoPlaceEggs",
    Callback = function(Value)
        -- Stop old loop if already running
        if autoPlaceEggsThread then
            autoPlaceEggsEnabled = false
            autoPlaceEggsThread = nil -- we just stop the thread by flipping the boolean
        end

        if Value then
            beastHubNotify("Auto place eggs: ON", "Max Eggs to place: "..tostring(eggsToPlaceInput), 4)
            autoPlaceEggsEnabled = true
            local autoPlaceEggLocations = getFarmEggLocations() --off setting for dynamic farm location
            autoPlaceEggsThread = task.spawn(function()
                while autoPlaceEggsEnabled do
                    local maxFarmEggs = eggsToPlaceInput
                    local currentEggsInFarm = getFarmEggCount()
                    --print("maxFarmEggs:", maxFarmEggs)
                    --print("currentEggsInFarm:", currentEggsInFarm)

                    if currentEggsInFarm < maxFarmEggs then
                        for _, location in ipairs(autoPlaceEggLocations) do
                            if currentEggsInFarm >= maxFarmEggs then
                                break
                            end

                            if Dropdown_eggToPlace.CurrentOption[1] then
                                equipItemByName(Dropdown_eggToPlace.CurrentOption[1])
                            end

                            local args = { "CreateEgg", location }
                            game:GetService("ReplicatedStorage").GameEvents.PetEggService:FireServer(unpack(args))
                            --add algo here to trap 'too close to another egg and dont increment'
                            task.wait(0.5)
                            if tooCloseFlag then
                                tooCloseFlag = false -- reset flag for next iteration
                                -- skip increment
                            else
                                currentEggsInFarm = currentEggsInFarm + 1
                            end
                            
                        end
                    end

                    task.wait(1.5)
                end
            end)
        else
            autoPlaceEggsEnabled = false
            autoPlaceEggsThread = nil
            beastHubNotify("Auto place eggs: OFF", "", 2)
        end
    end,
})

--Auto hatch
PetEggs:CreateButton({
    Name = "Click to HATCH ALL",
    Callback = function()
        print("[BeastHub] Hatching eggs...")
        
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")

        -- Get all PetEgg models in your farm
        local petEggs = myFunctions.getMyFarmPetEggs()
        if #petEggs == 0 then
            --print("[BeastHub] No PetEggs found in your farm!")
            return
        end

        -- Loop through all eggs and fire the hatch event
        for _, egg in ipairs(petEggs) do
            local args = {
                [1] = "HatchPet",
                [2] = egg
            }
            PetEggService:FireServer(unpack(args))
            --print("[BeastHub] Fired hatch for:", egg.Name)
        end
    end,
})
PetEggs:CreateDivider()

--PetEggs>Auto Sell Pets
local petList = myFunctions.getPetOdds()
    -- Get names only
local petListNamesOnlyAndSorted = myFunctions.getPetList()
table.sort(petListNamesOnlyAndSorted)

    --function to auto sell
local function autoSellPets(targetPets, weightTargetBelow, onComplete)
    -- USAGE:
    -- autoSellPets({"Bunny", "Dog"}, 3, function()
    --     print("Selling complete, now do next step!")
    -- end)

    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    local SellPet_RE = game:GetService("ReplicatedStorage").GameEvents.SellPet_RE
	player.Character.Humanoid:UnequipTools() --unequip last pet held from hatch

    for _, item in ipairs(backpack:GetChildren()) do
        local b = item:GetAttribute("b") -- pet type
        local d = item:GetAttribute("d") -- favorite

        if b == "l" and d == false then
            local petName = item.Name:match("^(.-)%s*%[") or item.Name
            petName = petName:match("^%s*(.-)%s*$") -- trim spaces

            local weightStr = item.Name:match("%[(%d+%.?%d*)%s*[Kk][Gg]%]")
            local weight = weightStr and tonumber(weightStr)

            local isTarget = false
            for _, name in ipairs(targetPets) do
                if petName == name then
                    isTarget = true
                    break
                end
            end

            if isTarget and weight and weight < weightTargetBelow then
                player.Character.Humanoid:UnequipTools()
                player.Character.Humanoid:EquipTool(item)
                task.wait(0.2) -- ensure pet equips before selling
                SellPet_RE:FireServer(item.Name)
                print("Sold:", item.Name)
                task.wait(0.3)
            end
        end
    end

    -- Call the callback AFTER finishing all pets
    if typeof(onComplete) == "function" then
        onComplete()
    end
end



--auto sell pets UI
local selectedPets --for UI paragraph
local selectedPetsForAutoSell = {} --container for dropdown
local sealsLoady

local Paragraph_selectedPets = PetEggs:CreateParagraph({Title = "Auto Sell Pets:", Content = "No pets selected."})
local Dropdown_sealsLoadoutNum = PetEggs:CreateDropdown({
    Name = "Select 'Seals' loadout",
    Options = {"None", "1", "2", "3"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "sealsLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        sealsLoady = tonumber(Options[1])
    end,
})
local suggestedAutoSellList = {
    "Ostrich", "Peacock", "Capybara", "Scarlet Macaw",
    "Bat", "Bone Dog", "Spider", "Black Cat",
    "Oxpecker", "Zebra", "Giraffe", "Rhino",
    "Tree Frog", "Hummingbird", "Iguana", "Chimpanzee",
    "Robin", "Badger", "Grizzly Bear",
    "Ladybug", "Pixie", "Imp", "Glimmering Sprite",
    "Dairy Cow", "Jackalope", "Seedling",
    "Bagel Bunny", "Pancake Mole", "Sushi Bear", "Spaghetti Sloth",
    "Shiba Inu", "Nihonzaru", "Tanuki", "Tanchozuru", "Kappa",
    "Parasaurolophus", "Iguanodon", "Ankylosaurus",
    "Raptor", "Triceratops", "Stegosaurus", "Pterodactyl", 
    "Flamingo", "Toucan", "Sea Turtle", "Orangutan",
    "Wasp", "Tarantula Hawk", "Moth",
    "Bee", "Honey Bee", "Petal Bee",
    "Hedgehog", "Mole", "Frog", "Echo Frog", "Night Owl",
    "Caterpillar", "Snail", "Giant Ant", "Praying Mantis",
    "Topaz Snail", "Amethyst Beetle", "Emerald Snake", "Sapphire Macaw"
}
local Dropdown_petList = PetEggs:CreateDropdown({
    Name = "Select Pets",
    Options = petListNamesOnlyAndSorted,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "autoSellPetsSelection", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        selectedPetsForAutoSell = Options
        -- Convert table to string for paragraph display
        local names = table.concat(Options, ", ")
        if names == "" then
            names = "No pets selected."
        end

        Paragraph_selectedPets:Set({
            Title = "Auto Sell Pets:",
            Content = names
        })    
    end,
})

--search pets
local searchDebounce = nil
local Input_petSearch = PetEggs:CreateInput({
    Name = "Search (click dropdown to load)",
    PlaceholderText = "Search Pet...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if searchDebounce then
            task.cancel(searchDebounce)
        end

        searchDebounce = task.delay(0.5, function()
            local results = {}
            local query = string.lower(Text)

            if query == "" then
                results = petListNamesOnlyAndSorted
            else
                for _, petName in ipairs(petListNamesOnlyAndSorted) do
                    if string.find(string.lower(petName), query, 1, true) then
                        table.insert(results, petName)
                    end
                end
            end

            Dropdown_petList:Refresh(results)

            -- Force redraw by re-setting selection (even empty table works)
            Dropdown_petList:Set(selectedPetsForAutoSell)

            -- Extra fallback: if no match, clear UI text
            if #results == 0 then
                Paragraph_selectedPets:Set({
                    Title = "Auto Sell Pets:",
                    Content = "No pets found."
                })
            end
        end)
    end,
})

PetEggs:CreateButton({
    Name = "Load Suggested List",
    Callback = function()
        Dropdown_petList:Set(suggestedAutoSellList) --Clear selection properly
        selectedPetsForAutoSell = suggestedAutoSellList
    end,
})

PetEggs:CreateButton({
    Name = "Clear selection",
    Callback = function()
        Dropdown_petList:Set({}) --Clear selection properly
        selectedPetsForAutoSell = {}
    end,
})

local sellBelow
local Dropdown_sellBelowKG = PetEggs:CreateDropdown({
    Name = "Below (KG)",
    Options = {"1","2","3"},
    CurrentOption = {"3"},
    MultipleOptions = false,
    Flag = "sellBelowKG", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        sellBelow = tonumber(Options[1])
    end,
})

PetEggs:CreateButton({
    Name = "Click to SELL",
    Callback = function()
        --print(tostring(sellBelow))
        if sealsLoady and sealsLoady ~= "None" then
            print("Switching to seals loadout first")
            myFunctions.switchToLoadout(sealsLoady)
			beastHubNotify("Waiting for Seals to load", "Auto Sell", "5")
            task.wait(6)
        end
        autoSellPets(selectedPetsForAutoSell, sellBelow)
		beastHubNotify("Auto Sell Done", "Successful", "2")
    end,
})
PetEggs:CreateDivider()

--Pet/Eggs>SMART HATCHING
PetEggs:CreateSection("SMART Auto Hatching")
-- local Paragraph = Pets:CreateParagraph({Title = "INSTRUCTIONS:", Content = "1.) Setup your Auto place Eggs above and turn on toggle for auto place eggs. 2.) Setup your selected pets for Auto Sell above. 3.) Selected desginated loadouts below. 4.) Turn on toggle for Full Auto Hatching"})
PetEggs:CreateParagraph({
    Title = "INSTRUCTIONS:",
    Content = "1.) Setup your Auto place Eggs above and turn on toggle for auto place eggs.\n2.) Setup your selected pets for Auto Sell above.\n3.) Selected designated loadouts below.\n4.) Turn on Speedhub Egg ESP, then turn on Egg ESP support below"
})
local koiLoady
-- local brontoLoady
local incubatingLoady
local webhookRares
local webhookHuge
local webhookURL
local sessionHatchCount = 0

PetEggs:CreateDropdown({
    Name = "Incubating/Eagles Loadout",
    Options = {"None", "1", "2", "3"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "incubatingLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        incubatingLoady = tonumber(Options[1])
    end,
})
PetEggs:CreateDropdown({
    Name = "Koi Loadout",
    Options = {"None", "1", "2", "3"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "koiLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        koiLoady = tonumber(Options[1])
    end,
})
-- PetEggs:CreateDropdown({
--     Name = "Bronto Loadout",
--     Options = {"None", "1", "2", "3"},
--     CurrentOption = {},
--     MultipleOptions = false,
--     Flag = "brontoLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
--     Callback = function(Options)
--         --if not Options or not Options[1] then return end
--         brontoLoady = tonumber(Options[1])
--     end,
-- })
local skipHatchRareAboveKG = "0"
PetEggs:CreateDropdown({
    Name = "Skip hatch Rare Above KG:",
    Options = {"0", "1", "1.5", "1.6", "1.7", "1.8", "1.9","2", "2.1", "2.2", "2.3", "2.4", "2.5"},
    CurrentOption = {"0"},
    MultipleOptions = false,
    Flag = "skipHatchRareAboveKG", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        skipHatchRareAboveKG = tonumber(Options[1])
    end,
})

task.wait(.5) --to wait for loadout variables to load
--Only two variables needed
local smartAutoHatchingEnabled = false
local smartAutoHatchingThread = nil

local sessionHugeList = {}
local Toggle_smartAutoHatch = PetEggs:CreateToggle({
    Name = "SMART Auto Hatching",
    CurrentValue = false,
    Flag = "smartAutoHatching",
    Callback = function(Value)
        smartAutoHatchingEnabled = Value
        if(smartAutoHatchingEnabled) then
            beastHubNotify("SMART AUTO HATCH ENABLED!", "Process will begin in 8 seconds..", 5)
            beastHubNotify("5", "", 1)
            task.wait(1)
            beastHubNotify("4", "", 1)
            task.wait(1)
            beastHubNotify("3", "", 1)
            task.wait(1)
            beastHubNotify("2", "", 1)
            task.wait(1)
            beastHubNotify("1", "", 1)
            task.wait(1)
            -- task.wait(8)
            -- Check again before proceeding
            if not smartAutoHatchingEnabled then
                beastHubNotify("SMART HATCH CANCELLED!", "Toggle was turned off before start.", 5)
                return
            end

            --recheck setup
            if not koiLoady or koiLoady == "None"
            -- or not brontoLoady or brontoLoady == "None"
            or not sealsLoady or sealsLoady == "None"
            or not incubatingLoady or incubatingLoady == "None" then
                beastHubNotify("Missing setup!", "Please recheck loadouts for koi, bronto, seals and turn on EGG ESP Support", 15)
                return
            end
        end

        -- If ON, start thread (only once)
        if smartAutoHatchingEnabled and not smartAutoHatchingThread then
            smartAutoHatchingThread = task.spawn(function()
                local function isInHugeList(target)
                    for _, value in ipairs(sessionHugeList) do
                        if value == target then
                            return true
                        end
                    end
                    return false
                end

                local function notInHugeList(tbl, target)
                    for _, value in ipairs(tbl) do
                        if value == target then
                            return false  -- found → NOT allowed
                        end
                    end
                    return true  -- not found → allowed
                end


                
                local petOdds = myFunctions.getPetOdds()
                local rarePets = myFunctions.getRarePets(petOdds)

                while smartAutoHatchingEnabled do
                
                    --check eggs
                    local myPetEggs = myFunctions.getMyFarmPetEggs()
                    local readyCounter = 0

                    for _, egg in pairs(myPetEggs) do
                        if egg:IsA("Model") and egg:GetAttribute("TimeToHatch") == 0 then
                            readyCounter += 1
                        end
                    end

                    if #myPetEggs > 0 and #myPetEggs == readyCounter and smartAutoHatchingEnabled then
                        --all eggs ready to hatch
                        beastHubNotify("All eggs Ready!", "", 3)
                        local espFolderFound
                        local rareOrHugeFound
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local PetEggService = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetEggService")
                                                            

                        --all eggs now must start with koi loadout, infinite loadout has been patched 10/24/25
                        beastHubNotify("Switching to Kois", "", 8)
                        Toggle_autoPlaceEggs:Set(false)
                        myFunctions.switchToLoadout(koiLoady)
                        task.wait(12)

                        --get egg data such as pet name and size
                        --=======================================
                        for _, egg in pairs(myPetEggs) do
                            if egg:IsA("Model") then
                                --ESP access part, this is mainly for bronto hatching
                                --====
                                local espFolder = egg:FindFirstChild("BhubESP")
                                if espFolder then
                                    print("espFolder found")
                                    espFolderFound = true
                                    for _, espObj in ipairs(espFolder:GetChildren()) do
                                        -- if espObj:IsA("BoxHandleAdornment") then
                                            local billboard = espFolder:FindFirstChild("EggBillboard")
                                            if billboard then
                                                local textLabel = billboard:FindFirstChildWhichIsA("TextLabel")
                                                if textLabel then
                                                    local text = textLabel.Text
                                                    -- Get values using string match 
                                                    -- local petName = string.match(text, "0%)'>(.-)</font>")
                                                    -- local stringKG = string.match(text, ".*=%s*<font.-'>(.-)</font>")
                                                    local petName = text:match('rgb%(%s*0,%s*255,%s*0%s*%)">(.-)</font>%s*=')
                                                    local stringKG = text:match("= (%d+%.?%d*)")
                                                    
                                                    -- print("petName")
                                                    -- print(petName)
                                                    -- print("stringKG")
                                                    -- print(stringKG)

                                                    local isRare
                                                    local isHuge

                                                    -- print("petName found: " .. tostring(petName))
                                                    -- print("stringKG found: "..tostring(stringKG))

                                                    if petName and stringKG and smartAutoHatchingEnabled then
                                                        -- Trim whitespace in case it grew from previous runs
                                                        stringKG = stringKG:match("^%s*(.-)%s*$") 
                                                        local playerNameWebhook = game.Players.LocalPlayer.Name
                                                        --print("stringKG trimmed: "..stringKG)

                                                        -- check if Rare
                                                        if type(rarePets) == "table" then
                                                            for _, rarePet in ipairs(rarePets) do
                                                                if petName == rarePet then
                                                                    isRare = true
                                                                    break
                                                                end
                                                            end
                                                        else
                                                            --exit if have trouble getting rare pets
                                                            warn("rarePets is not a table")
                                                            return
                                                        end
                                                        
                                                        -- check if Huge
                                                        local currentNumberKG = tonumber(stringKG)
                                                        if not currentNumberKG then
                                                            warn("Error in getting pet Size")
                                                            return
                                                        end
                                                        if currentNumberKG < 3 then
                                                            isHuge = false
                                                        else
                                                            isHuge = true
                                                        end

                                                        --deciding loadout code below
                                                        --if isHuge or isRare, swatch loadout bronto, wait 7 sec, hatch this 1 egg
                                                        if isRare or isHuge then
                                                            rareOrHugeFound = true
                                                            Toggle_autoPlaceEggs:Set(false)
                                                        end

                                                        if isHuge then
                                                            beastHubNotify("Skipping Huge!", "", 2)
                                                            local targetHuge = petName..stringKG
                                                            print("targetHuge")
                                                            print(targetHuge)
                                                            if targetHuge and notInHugeList(sessionHugeList, targetHuge) then
                                                                table.insert(sessionHugeList, targetHuge)

                                                                if webhookURL and webhookURL ~= "" and webhookHuge then
                                                                    sendDiscordWebhook(webhookURL, "[BeastHub] "..playerNameWebhook.." | Huge found: "..petName.." = "..stringKG.."KG")
                                                                else
                                                                    warn("No webhook URL provided for hatch!")
                                                                end
                                                            elseif  not targetHuge then
                                                                warn("Error in getting target Huge string")
                                                            end

                                                            

                                                        elseif (isRare and currentNumberKG < skipHatchRareAboveKG) or (not isRare) then --also add the skip rare threshold here 
                                                            if isRare and currentNumberKG < skipHatchRareAboveKG then
                                                                beastHubNotify("Hatching rare below threshold..", "", 3)
                                                            end

                                                            -- if not isRare then
                                                            --     print("Hatching not rare nor huge..")
                                                            -- end

                                                            --checking
                                                            -- print("hatching: ")
                                                            -- print(petName)
                                                            -- print(tostring(currentNumberKG))

                                                            local args = {
                                                                    [1] = "HatchPet";
                                                                    [2] = egg
                                                            }
                                                            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetEggService", 9e9):FireServer(unpack(args))
                                                            sessionHatchCount = sessionHatchCount + 1
                                                            task.wait(.1)

                                                            --checking
                                                            -- print("hatched: ")
                                                            -- print(petName)
                                                            -- print(tostring(currentNumberKG))

                                                            -- send webhook here
                                                            local message = nil
                                                            if isRare and webhookRares then
                                                                message = "[BeastHub] "..playerNameWebhook.." | Rare hatched: " .. tostring(petName) .. "=" .. tostring(currentNumberKG) .. "KG |Egg hatch # "..tostring(sessionHatchCount)
                                                            elseif isHuge and webhookHuge then
                                                                message = "[BeastHub] "..playerNameWebhook.." | Huge hatched: " .. tostring(petName) .. "=" .. tostring(currentNumberKG) .. "KG |Egg hatch # "..tostring(sessionHatchCount)
                                                            end

                                                            if message then
                                                                if webhookURL and webhookURL ~= "" then
                                                                    sendDiscordWebhook(webhookURL, message)
                                                                else
                                                                    warn("No webhook URL provided for hatch!")
                                                                end
                                                            end
                                                        end
                                                    end

                                                else
                                                    print("BillboardGui has no TextLabel")
                                                end
                                            else
                                                print("No BillboardGui found under BoxHandleAdornment")
                                            end
                                        -- end
                                    end
                                else
                                    espFolderFound = false
                                end
                                --====
                            else
                                warn("Object is not a model")
                                return
                            end
                        end
                        
                        --=======================================
                        --trigger auto sell first before back to eagles
                        task.wait(5)
                        if sealsLoady and sealsLoady ~= "None" and smartAutoHatchingEnabled then
                            game.Players.LocalPlayer.Character.Humanoid:UnequipTools() --prevention
                            beastHubNotify("Switching to seals", "Auto sell triggered", 10)
                            myFunctions.switchToLoadout(sealsLoady)
                            game.Players.LocalPlayer.Character.Humanoid:UnequipTools() --prevention
                            task.wait(1)
                            game.Players.LocalPlayer.Character.Humanoid:UnequipTools() --prevention
                            task.wait(1)
                            game.Players.LocalPlayer.Character.Humanoid:UnequipTools() --prevention
                            task.wait(1)
                            game.Players.LocalPlayer.Character.Humanoid:UnequipTools() --prevention
                            task.wait(1)
                            game.Players.LocalPlayer.Character.Humanoid:UnequipTools() --prevention
                            task.wait(1)
                            game.Players.LocalPlayer.Character.Humanoid:UnequipTools() --prevention
                            task.wait(10)
                            local success, err = pcall(function()
                                autoSellPets(selectedPetsForAutoSell, sellBelow, function()
                                    --print("Now switching back to main loadout...")
                                    task.wait(2)
                                    myFunctions.switchToLoadout(incubatingLoady)
                                end)
                            end)
                            if success then
                                beastHubNotify("Auto Sell Done", "Successful", 2)
                            else
                                warn("Auto Sell failed with error: " .. tostring(err))
                                beastHubNotify("Auto Sell Failed!", tostring(err), 5)
                            end
                        else
                            --this part of logic might not be possible but keeping this for now
                            -- warn("No Seals Loadout found, skipping auto-sell.")
                        end


                        --back to incubating loadout
                        task.wait(2)
                        beastHubNotify("Back to incubating", "", 6)
                        Toggle_autoPlaceEggs:Set(true)
                        --myFunctions.switchToLoadout(incubatingLoady) --loadout switch was done in the callback of auto sell 
                        task.wait(6)
                    else
                        beastHubNotify("Eggs not ready yet", "Waiting..", 3)
                        task.wait(15)
                    end
                end
                -- When flag turns false, loop ends and thread resets
                smartAutoHatchingThread = nil
            end)
        end
    end,
})

PetEggs:CreateDivider()


--Mutation machine
--get FULL pet list via registry
local function getAllPetNames()
    local success, PetRegistry = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("PetRegistry"))
    end)
    if not success or type(PetRegistry) ~= "table" then
        warn("Failed to load PetRegistry module.")
        return {}
    end
    local petList = PetRegistry.PetList
    if type(petList) ~= "table" then
        warn("PetList not found in PetRegistry.")
        return {}
    end
    local names = {}
    for petName, _ in pairs(petList) do
        table.insert(names, tostring(petName))
    end
    table.sort(names) -- alphabetical sort
    return names
end

--get pet mutations list
local function getMachineMutationTypes()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local success, PetMutationRegistry = pcall(function()
        return require(
            ReplicatedStorage:WaitForChild("Data")
                :WaitForChild("PetRegistry")
                :WaitForChild("PetMutationRegistry")
        )
    end)
    if not success or type(PetMutationRegistry) ~= "table" then
        warn("Failed to load PetMutationRegistry module.")
        return {}
    end
    local machineMutations = PetMutationRegistry.MachineMutationTypes
    if type(machineMutations) ~= "table" then
        warn("MachineMutationTypes not found in PetMutationRegistry.")
        return {}
    end
    local names = {}
    for mutationName, _ in pairs(machineMutations) do
        table.insert(names, tostring(mutationName))
    end
    table.sort(names)
    return names
end

-- get place pet location (safe)
local function getPetEquipLocation()
    local success, result = pcall(function()
        local spawnCFrame = getFarmSpawnCFrame()
        if typeof(spawnCFrame) ~= "CFrame" then
            return nil
        end
        -- offset forward 5 studs
        return spawnCFrame * CFrame.new(0, 0, -5)
    end)
    if success then
        return result
    else
        warn("[getPetEquipLocation] Error: " .. tostring(result))
        return nil
    end
end


local autoStartMachineEnabled = false
local connectionAutoStartMachine -- store the connection so we can disconnect it later
local function startMachine()
    local args = {
        [1] = "StartMachine"
    }
    game:GetService("ReplicatedStorage").GameEvents.PetMutationMachineService_RE:FireServer(unpack(args))
end

Pets:CreateSection("Mutation Machine")
Pets:CreateButton({
    Name = "Submit Held Pet",
    Callback = function()
        local args = {
            [1] = "SubmitHeldPet"
        }
        game:GetService("ReplicatedStorage").GameEvents.PetMutationMachineService_RE:FireServer(unpack(args))
    end,
})
local Toggle = Pets:CreateToggle({
    Name = "Auto Start Machine (VULN)",
    CurrentValue = false,
    Flag = "autoStartMutationMachine",
    Callback = function(Value)
        autoStartMachineEnabled = Value
        -- cleanup previous connection if exists
        if connectionAutoStartMachine then
            connectionAutoStartMachine:Disconnect()
            connectionAutoStartMachine = nil
        end
        if autoStartMachineEnabled then
            local prompt
            local success, err = pcall(function()
                prompt = workspace.NPCS.PetMutationMachine.Model.ProxPromptPart.PetMutationMachineProximityPrompt
            end)
            if not success or not prompt then
                warn("[BeastHub] Cannot find mutation machine prompt", err or "")
                return
            end

            -- Do an initial check right away
            if prompt.ActionText ~= "Skip" then
                startMachine()
                --print("Mutation Machine is available, starting machine now..")
            else
                --print("Mutation Machine is already running")
            end

            --  Connect to listen for changes after the initial check
            connectionAutoStartMachine = prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
                if prompt.ActionText ~= "Skip" then
                startMachine()
                    --print("Mutation Machine is available, starting machine now..")
                else
                    --print("Mutation Machine is already running")
                end
            end)
        end
    end,
})
Pets:CreateSection("Auto Pet Mutation")
local phoenixLoady
Pets:CreateDropdown({
    Name = "Phoenix Loadout",
    Options = {"None", "1", "2", "3"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "phoenixLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        phoenixLoady = tonumber(Options[1])
    end,
})
local levelingLoady
Pets:CreateDropdown({
    Name = "Leveling Loadout (Free 1 pet space)",
    Options = {"None", "1", "2", "3"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "levelingLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        levelingLoady = tonumber(Options[1])
    end,
})
local golemLoady
Pets:CreateDropdown({
    Name = "Golem Loadout",
    Options = {"None", "1", "2", "3"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "golemLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        golemLoady = tonumber(Options[1])
    end,
})

local levelingMethod = ""
Pets:CreateDropdown({
    Name = "Leveling Method",
    Options = {"Loadout only", "Loadout+Levelup Lollipop"},
    CurrentOption = {"Loadout+Levelup Lollipop"},
    MultipleOptions = false,
    Flag = "levelingMethod", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        levelingMethod = Options[1]
    end,
})
local allPetList = getAllPetNames()
local selectedPetsForAutoMutation = {}
local selectedMutationsForAutoMutation
local Dropdown_petListForMutation = Pets:CreateDropdown({
    Name = "Select Pet/s (excluded favorites)",
    Options = allPetList,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "autoMutationPets", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        selectedPetsForAutoMutation = Options
    end,
})

Pets:CreateButton({
    Name = "Clear selection",
    Callback = function()
        Dropdown_petListForMutation:Set({}) --  
        selectedPetsForAutoMutation = {}
    end,
})
--auto mutation flags moved top for the function to recognize them
local autoPetMutationEnabled = false
local autoPetMutationThread = nil

local mutationList = getMachineMutationTypes()
Pets:CreateDropdown({
    Name = "Select Mutation/s",
    Options = mutationList,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "selectedMutationsForAutoMutation", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        selectedMutationsForAutoMutation = Options
    end,
})

-- local Toggle_autoHatchAfterAutoMutation = Pets:CreateToggle({
--     Name = "Auto Hatch after Auto mutation",
--     CurrentValue = false,
--     Flag = "autoHatchAfterAutoMutation", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
--     Callback = function(Value)
--     end,
-- })

local Toggle_autoMutation = Pets:CreateToggle({
    Name = "Auto Mutation",
    CurrentValue = false,
    Flag = "autoMutation", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        autoPetMutationEnabled = Value
        local autoMutatePetsV2 --new function using getData
        
        if autoPetMutationEnabled then --declare function code only when condition is right
            --turn off auto smart hatching instantly
            Toggle_smartAutoHatch:Set(false)
            -- Check for missing setup
            -- Wait until Rayfield sets up the values (or timeout after 10s)
            local timeout = 3
            while timeout > 0 and (
                not phoenixLoady or phoenixLoady == "None"
                or not levelingLoady or levelingLoady == "None"
                or not golemLoady or golemLoady == "None"
                or not selectedPetsForAutoMutation
                or not selectedMutationsForAutoMutation or #selectedMutationsForAutoMutation == 0
            ) do
                task.wait(1)
                timeout = timeout - 1
            end
            --checkers here, final check, works for sudden reconnection
            if not phoenixLoady or phoenixLoady == "None"
            or not levelingLoady or levelingLoady == "None"
            or not golemLoady or golemLoady == "None" 
            or not selectedPetsForAutoMutation
            or not selectedMutationsForAutoMutation or #selectedMutationsForAutoMutation == 0 then
                beastHubNotify("Missing setup!", "Please recheck loadouts", 10)
                return
            end
            
            autoMutatePetsV2 = function(selectedPetForAutoMutation, mutations, onComplete)
                --local functions
                local HttpService = game:GetService("HttpService")
                
                local function getPlayerData()
                    local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                    local logs = dataService:GetData()
                    return logs
                end

                local function getPetInventory()
                    local playerData = getPlayerData()
                    if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                        return playerData.PetsData.PetInventory.Data
                    else
                        warn("PetsData not found!")
                        return nil
                    end
                end

                local function getCurrentPetLevelByUid(uid)
                    local playerData = getPlayerData()
                    if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                        for id, data in pairs(playerData.PetsData.PetInventory.Data) do
                            if tostring(id) == uid then
                                return data.PetData.Level
                            end
                        end
                        return nil
                    else
                        warn("PetsData not found!")
                        return nil
                    end
                end

                local function getMutationMachineData() 
                    local playerData = getPlayerData()
                    if playerData.PetMutationMachine then
                        return playerData.PetMutationMachine
                    else
                        warn("PetMutationMachine not found!")
                        return nil
                    end
                end
                -- Function you can call anytime to refresh pets data
                local function refreshPets()
                    -- USAGE: local favs, unfavs = refreshPets()
                    local pets = getPetInventory()
                    local favoritePets, unfavoritePets = {}, {}
                    if pets then
                        for uid, pet in pairs(pets) do
                            local entry = {
                                Uid = uid,
                                PetType = pet.PetType,
                                Uuid = pet.UUID, 
                                PetData = pet.PetData
                            }
                            if pet.PetData.IsFavorite then
                                table.insert(favoritePets, entry)
                            else
                                table.insert(unfavoritePets, entry)
                            end
                        end
                    end
                    --
                    return favoritePets, unfavoritePets
                end

                local function getMachineMutationsData() --all mutation data including enums
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local success, PetMutationRegistry = pcall(function()
                        return require(
                            ReplicatedStorage:WaitForChild("Data")
                                :WaitForChild("PetRegistry")
                                :WaitForChild("PetMutationRegistry")
                        )
                    end)
                    if not success or type(PetMutationRegistry) ~= "table" then
                        warn("Failed to load PetMutationRegistry module.")
                        return {}
                    end
                    local machineMutations = PetMutationRegistry.MachineMutationTypes
                    if type(machineMutations) ~= "table" then
                        warn("MachineMutationTypes not found in PetMutationRegistry.")
                        return {}
                    end
                    -- table.sort(machineMutations)
                    return machineMutations
                end

                local function equipItemByName(itemName)
                    local player = game.Players.LocalPlayer
                    local backpack = player:WaitForChild("Backpack")
                    player.Character.Humanoid:UnequipTools() --unequip all first

                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") and string.find(tool.Name, itemName) then
                            --print("Equipping:", tool.Name)
                            player.Character.Humanoid:UnequipTools() --unequip all first
                            player.Character.Humanoid:EquipTool(tool)
                            return true -- stop after first match
                        end
                    end
                    return false
                end

                local function equipPetByUuid(uuid)
                    local player = game.Players.LocalPlayer
                    local backpack = player:WaitForChild("Backpack")
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:GetAttribute("PET_UUID") == uuid then
                            player.Character.Humanoid:EquipTool(tool)
                        end
                    end
                end

                -- get place pet location (safe)
                local function getPetEquipLocation()
                    local success, result = pcall(function()
                        local spawnCFrame = getFarmSpawnCFrame()
                        if typeof(spawnCFrame) ~= "CFrame" then
                            return nil
                        end
                        -- offset forward 5 studs
                        return spawnCFrame * CFrame.new(0, 0, -5)
                    end)
                    if success then
                        return result
                    else
                        warn("[getPetEquipLocation] Error: " .. tostring(result))
                        return nil
                    end
                end

                --main function code
                --vars
                local favs, unfavs = refreshPets()
                local selectedMutationsString = string.lower(table.concat(selectedMutationsForAutoMutation, " ")) --combined into 1 string for easy search
                local selectedMutationFound --if true then no need to mutate
                local petFoundV2 = false--set to true if candidate is found
                local message = "Auto mutation stopped"
                --loop unfavs to find the selected pet to mutate
                --initial check for rejoin, copied the machine monitoring below
                local mutationMachineData = getMutationMachineData()
                if mutationMachineData.SubmittedPet then
                    if mutationMachineData.PetReady == true then
                        beastHubNotify("A Pet is ready to claim!", "Switching to phoenix loadout..", 3)
                        --claim with phoenix
                        myFunctions.switchToLoadout(phoenixLoady)
                        task.wait(6)
                        local args = {
                            [1] = "ClaimMutatedPet";
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetMutationMachineService_RE", 9e9):FireServer(unpack(args))
                        --Auto Start machine toggle VULN is advised
                    else
                        beastHubNotify("A Pet is already in machine", "Switching to golems loadout..", 3)
                        --switch to golems and wait till pet is ready
                        myFunctions.switchToLoadout(golemLoady)
                        task.wait(6)
                        --monitoring code here
                        local machineCurrentStatus = getMutationMachineData().PetReady
                        while autoPetMutationEnabled and machineCurrentStatus == false do
                            beastHubNotify("Waiting for Machine to be ready", "", 3)
                            task.wait(15)
                            machineCurrentStatus = getMutationMachineData().PetReady
                        end 
                        --claim once while loop is broken, it means pet is ready
                        if autoPetMutationEnabled and machineCurrentStatus == true then
                            beastHubNotify("A Pet is ready to claim!", "Switching to phoenix loadout..", 3)
                            myFunctions.switchToLoadout(phoenixLoady)
                            task.wait(6)
                            local args = {
                                [1] = "ClaimMutatedPet";
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetMutationMachineService_RE", 9e9):FireServer(unpack(args))
                        end
                    end
                end
                
                for _, pet in pairs(unfavs) do 
                    local curPet = pet.PetType
                    -- local uid = pet.Uuid
                    local uid = tostring(pet.Uid)
                    local curLevel = pet.PetData.Level
                    local curMutationEnum = pet.PetData.MutationType
                    local curMutation -- fetch later after enums fetch
                    local machineMutationEnums = {} --pet mutation enums container
                    local mutations = getMachineMutationsData() --all mutation data
                    for mutation, data in pairs(mutations) do --extract only enums
                        table.insert(machineMutationEnums, {mutation, data.EnumId})
                    end
                    --get current pet mutation via enum
                    for _, entry in ipairs(machineMutationEnums) do
                        local mutation = entry[1]
                        local enumId = entry[2]
                        if enumId == curMutationEnum then
                            curMutation = mutation
                            break
                        end
                    end
                    
                    if curMutation == nil then
                        --beastHubNotify("Pet found has no mutation yet", "", 3)
                    end
                    --check curPet if good for auto mutation
                    if autoPetMutationEnabled and curPet == selectedPetForAutoMutation then 
                        --match current enum if found in selectedMutationsForAutoMutation
                        if curMutation and string.find(selectedMutationsString, string.lower(curMutation)) then
                            --already mutated
                            print("Already mutated "..curPet.." with desired mutation", "", 3)
                        else
                            if curMutation == nil then
                                -- beastHubNotify("Found target!", curPet.." | ".."No mutation".." | "..curLevel.." | "..uid, 3)    
                                beastHubNotify("Found target with no mutation yet", "", 3)
                            else
                                -- beastHubNotify("Found target!", curPet.." | "..curMutation.." | "..curLevel.." | "..uid ,3)
                                beastHubNotify("Found target", "", 3)
                            end
                            petFoundV2 = true
                            --DO MAIN ACTIONS HERE TO MUTATION
                            mutationMachineData = getMutationMachineData()
                                --start machine if not started
                            if mutationMachineData.IsRunning == false then
                                beastHubNotify("Machine started","",3)
                                startMachine()
                            else
                                beastHubNotify("Machine is already running","",3)
                            end

                            --process current pet for leveling here
                            myFunctions.switchToLoadout(levelingLoady)
                            task.wait(6)

                            equipPetByUuid(uid)
                            task.wait(2)
                            --place pet to garden for leveling                                    
                            local petEquipLocation = getPetEquipLocation()
                            local args = {
                                [1] = "EquipPet",
                                [2] = uid,
                                [3] = petEquipLocation, 
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                            task.wait(1)

                            while autoPetMutationEnabled and curLevel < 50 do
                                local haveLollipop = false
                                if levelingMethod == "Loadout+Levelup Lollipop" then
                                    if equipItemByName("Levelup Lollipop") == false then 
                                        beastHubNotify("No more lollipops!", "Leveling now", 4)    
                                    else
                                        haveLollipop = true
                                        beastHubNotify("Equipping Lollipop", "Leveling now", 4) 
                                    end 
                                    task.wait(1)

                                    while autoPetMutationEnabled and haveLollipop and curLevel < 50 do
                                        task.wait(.5)
                                        local args = {
                                            [1] = "ApplyBoost";
                                            [2] = uid;
                                        }
                                        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetBoostService", 9e9):FireServer(unpack(args))
                                        curLevel = curLevel + 1
                                    end
                                    --refresh pet data
                                    task.wait(2)
                                    curLevel = getCurrentPetLevelByUid(uid)
                                    beastHubNotify("Rechecked pet level: "..curLevel, "",3)
                                    if curLevel < 50 then --if still below 50 after lollipop
                                        beastHubNotify("Still below 50 after lollipop", "",3)
                                    end
                                    --monitor level every 10 sec
                                    while autoPetMutationEnabled and curLevel < 50 do 
                                        beastHubNotify("Current Pet age: "..curLevel, "waiting to hit age 50..",3)
                                        task.wait(10)
                                        curLevel = getCurrentPetLevelByUid(uid)
                                    end
                                    --unequip once ready
                                    local args = {
                                        [1] = "UnequipPet";
                                        [2] = uid;
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                                    task.wait(1) 

                                else --loadout method only
                                    --monitor level every 10 sec
                                    while autoPetMutationEnabled and curLevel < 50 do 
                                        beastHubNotify("Current Pet age: "..curLevel, "waiting to hit age 50..",3)
                                        task.wait(10)
                                        curLevel = getCurrentPetLevelByUid(uid)
                                    end

                                    --unequip once ready
                                    local args = {
                                        [1] = "UnequipPet";
                                        [2] = uid;
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                                    task.wait(1) 
                                end
                            end


                            --check if pet is already inside machine
                            if mutationMachineData.SubmittedPet then
                                if mutationMachineData.PetReady == true then
                                    beastHubNotify("A Pet is ready to claim!", "Switching to phoenix loadout..", 3)
                                    --claim with phoenix
                                    myFunctions.switchToLoadout(phoenixLoady)
                                    task.wait(6)
                                    local args = {
                                        [1] = "ClaimMutatedPet";
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetMutationMachineService_RE", 9e9):FireServer(unpack(args))
                                    --Auto Start machine toggle VULN is advised
                                else
                                    beastHubNotify("A Pet is already in machine", "Switching to golems loadout..", 3)
                                    --switch to golems and wait till pet is ready
                                    myFunctions.switchToLoadout(golemLoady)
                                    task.wait(6)
                                    --monitoring code here
                                    local machineCurrentStatus = getMutationMachineData().PetReady
                                    while autoPetMutationEnabled and machineCurrentStatus == false do
                                        beastHubNotify("Waiting for Machine to be ready", "", 3)
                                        task.wait(15)
										machineCurrentStatus = getMutationMachineData().PetReady
                                    end 
                                    --claim once while loop is broken, it means pet is ready
                                    if autoPetMutationEnabled and machineCurrentStatus == true then
                                        beastHubNotify("A Pet is ready to claim!", "Switching to phoenix loadout..", 3)
                                        myFunctions.switchToLoadout(phoenixLoady)
                                        task.wait(6)
                                        local args = {
                                            [1] = "ClaimMutatedPet";
                                        }
                                        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetMutationMachineService_RE", 9e9):FireServer(unpack(args))
                                    end
                                end
                            end
                            --process current pet here for machine
                            if autoPetMutationEnabled and curLevel > 49 then
                                beastHubNotify("Current Pet is good to submit", "", 3)
								myFunctions.switchToLoadout(golemLoady)
                                task.wait(6)
                                --hold pet then submit      
                                equipPetByUuid(uid)
                                task.wait(2)
                                local args = {
                                    [1] = "SubmitHeldPet"
                                }
                                game:GetService("ReplicatedStorage").GameEvents.PetMutationMachineService_RE:FireServer(unpack(args))
                                beastHubNotify("Current Pet submitted", "", 3)
                                task.wait(1)
                                myFunctions.switchToLoadout(golemLoady)
                                task.wait(6)
                                --monitoring code here
                                local machineCurrentStatus = getMutationMachineData().PetReady
                                while autoPetMutationEnabled and machineCurrentStatus == false do
                                    beastHubNotify("Waiting for Machine to be ready", "", 3)
                                    task.wait(15)
									machineCurrentStatus = getMutationMachineData().PetReady
                                end 
                                --claim once while loop is broken, it means pet is ready
                                if autoPetMutationEnabled and machineCurrentStatus == true then
                                    beastHubNotify("A Pet is ready to claim!", "Switching to phoenix loadout..", 3)
                                    myFunctions.switchToLoadout(phoenixLoady)
                                    task.wait(6)
                                    local args = {
                                        [1] = "ClaimMutatedPet";
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetMutationMachineService_RE", 9e9):FireServer(unpack(args))
                                    message = "Mutation Cycle done"
                                end
                            end
                            break --break for loop for Unfavs
                        end
                    end
                end

                -- ￢ﾜﾅ Call the callback AFTER finishing
                if petFoundV2 == false then 
                    message = "No eligible pet"                     
                end
                if typeof(onComplete) == "function" then
                    onComplete(message)
                end
            end

            
            --main logic
            if autoPetMutationEnabled and not autoPetMutationThread then
                autoPetMutationThread = task.spawn(function()
                    while autoPetMutationEnabled do
                        beastHubNotify("Auto Pet mutation running..", "", 3)
                        player.Character.Humanoid:UnequipTools()
                        if selectedPetsForAutoMutation then --
                            local success, err = pcall(function()
                                --add loop for multi select    
                                local failCounter = 0            
                                for i, petName in ipairs(selectedPetsForAutoMutation) do                                
                                    autoMutatePetsV2(petName, selectedMutationsForAutoMutation, function(msg)
                                        if msg == "No eligible pet" then
                                            beastHubNotify("Not Found: "..petName, "Make sure to select the correct pet/s", 5)
											failCounter = failCounter + 1
                                            if failCounter == #selectedPetsForAutoMutation then
                                                autoPetMutationEnabled = false
                                                autoPetMutationThread = nil
                                                --check for auto hatch trigger togle
                                                -- if Toggle_autoHatchAfterAutoMutation.CurrentValue == true then
                                                --     task.wait(1)
                                                --     beastHubNotify("Auto hatching triggered", "", 3)
                                                --     myFunctions.switchToLoadout(incubatingLoady)
                                                --     task.wait(6)
                                                --     Toggle_smartAutoHatch:Set(true)
                                                -- end
                                                return
                                            end
                                        else
                                            beastHubNotify(msg, "", 5)
                                        end 
                                    end)
                                end
                            end)

                            if success then
                            else
                                warn("Auto Mutation Cycle failed with error: " .. tostring(err))
                                beastHubNotify("Auto Mutation Cycle failed with error: ", tostring(err), 5)
                            end
                        end
                        task.wait(5) --cycle delay
                    end
                    -- When flag turns false, loop ends and thread resets
                    autoPetMutationThread = nil
                end)
            end
        end
    end,
})
Pets:CreateDivider()

Pets:CreateSection("Auto Leveling")
Pets:CreateParagraph({
    Title = "INSTRUCTIONS:",
    Content = "1.) Setup the leveling loadout from 'Auto Pet Mutation'.\n2.) Make sure there 1 pet slot available in your leveling loadout. \n3.) Select desired level target and start Auto Level"
})

local Dropdown_petListForAutoLevel = Pets:CreateDropdown({
    Name = "Select Pet/s",
    Options = allPetList,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "autoLevelPets", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        
    end,
})
Pets:CreateButton({
    Name = "Clear selection",
    Callback = function()
        Dropdown_petListForAutoLevel:Set({}) --  
    end,
})

local targetLevelForAutoLevel = Pets:CreateInput({
    Name = "Target Level",
    CurrentValue = "",
    PlaceholderText = "input number..",
    RemoveTextAfterFocusLost = false,
    Flag = "autoLeveltargetLevel",
    Callback = function(Text)
    -- The function that takes place when the input is changed
    -- The variable (Text) is a string for the value in the text box
    end,
})


local autoLevelEnabled = false
local autoLevelThread = nil
--early declare togggles to access Set:(false)
local toggle_autoEle
local toggle_autoNM

local Toggle_autoLevel = Pets:CreateToggle({
    Name = "Auto level",
    CurrentValue = false,
    Flag = "autoLevel",
    Callback = function(Value)
        autoLevelEnabled = Value

        -- ￰ﾟﾧﾹ Stop thread if turned off
        if not autoLevelEnabled then
            if autoLevelThread then
                task.cancel(autoLevelThread)
                autoLevelThread = nil
                beastHubNotify("Auto Level stopped", "", 3)
            end
            return
        else
            --turn off auto hatching of auto level is on
            Toggle_smartAutoHatch:Set(false)
            toggle_autoEle:Set(false)
            toggle_autoNM:Set(false)
        end

        -- ￰Check if valid before continuing
        local targetLevel = tonumber(targetLevelForAutoLevel.CurrentValue) or nil
        local isNum = targetLevel
        local targetPetsForAutoLevel = Dropdown_petListForAutoLevel.CurrentOption or nil 
        
        -- Wait until Rayfield sets up the values (or timeout after 10s)
        local timeout = 3
        while timeout > 0 and (
            not levelingLoady or levelingLoady == "None"
            or targetPetsForAutoLevel == nil or targetPetsForAutoLevel == "None"
            or not isNum
        ) do
            task.wait(1)
            timeout = timeout - 1
            targetLevel = tonumber(targetLevelForAutoLevel.CurrentValue)
            isNum = targetLevel
        end
        
        --actual checker
        if levelingLoady == nil or levelingLoady == "None" or Dropdown_petListForAutoLevel.CurrentOption == nil or Dropdown_petListForAutoLevel.CurrentOption[1] == "None" or not isNum then
            beastHubNotify("Setup missing", "Please also make sure you select Leveling Loadout", 3)
            return
        end 

        beastHubNotify("Auto leveling start..", "",3)

        -- ￰ﾟﾧﾵ Start auto-level thread
        autoLevelThread = task.spawn(function()
            local function getPlayerData()
                local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                local logs = dataService:GetData()
                return logs
            end

            local function getPetInventory()
                local playerData = getPlayerData()
                if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                    return playerData.PetsData.PetInventory.Data
                else
                    warn("PetsData not found!")
                    return nil
                end
            end

            local function refreshPets()
                local pets = getPetInventory()
                local myPets = {}
                if pets then
                    for uid, pet in pairs(pets) do
                        table.insert(myPets, {
                            Uid = uid,
                            PetType = pet.PetType,
                            Uuid = pet.UUID,
                            PetData = pet.PetData
                        })
                    end
                end
                return myPets
            end

            local function equipPetByUuid(uuid)
                local player = game.Players.LocalPlayer
                local backpack = player:WaitForChild("Backpack")
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:GetAttribute("PET_UUID") == uuid then
                        player.Character.Humanoid:EquipTool(tool)
                    end
                end
            end

            local function getPetEquipLocation()
                local success, result = pcall(function()
                    local spawnCFrame = getFarmSpawnCFrame()
                    if typeof(spawnCFrame) ~= "CFrame" then
                        return nil
                    end
                    return spawnCFrame * CFrame.new(0, 0, -5)
                end)
                return success and result or nil
            end

            local function getCurrentPetLevelByUid(uid)
                local playerData = getPlayerData()
                if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                    for id, data in pairs(playerData.PetsData.PetInventory.Data) do
                        if tostring(id) == uid then
                            return data.PetData.Level
                        end
                    end
                end
                return nil
            end

            -- ￰ﾟﾔﾁ Main Logic
            --add loop for multi pets
            for i, petName in ipairs(Dropdown_petListForAutoLevel.CurrentOption) do
                --print("Selected pet:", petName)

                local allMyPets = refreshPets()
                -- local selectedPet = Dropdown_petListForAutoLevel.CurrentOption[1]
                local selectedPet = petName --changed to multi select
                local petFound = false

                for _, pet in pairs(allMyPets) do 
                    if not autoLevelEnabled then break end

                    local curPet = pet.PetType
                    -- local uid = pet.Uuid
                    local uid = tostring(pet.Uid)
                    local curLevel = pet.PetData.Level

                    if curPet == selectedPet and curLevel < targetLevel then
                        petFound = true
                        beastHubNotify("Found: " .. curPet, "with level: " .. curLevel, "3")

                        myFunctions.switchToLoadout(levelingLoady)
                        task.wait(6)

                        local petEquipLocation = getPetEquipLocation()
                        equipPetByUuid(uid)
                        task.wait(1)

                        local args = { "EquipPet", uid, petEquipLocation }
                        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9)
                            :WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                        task.wait(1)

                        while autoLevelEnabled and curLevel < targetLevel do
                            beastHubNotify("Current Pet age: " .. curLevel, "Waiting to hit age " .. targetLevel, 3)
                            task.wait(10)
                            curLevel = getCurrentPetLevelByUid(uid)
                            if autoLevelEnabled and curLevel >= targetLevel then
                                beastHubNotify("Target level reached for: " .. curPet .. "!", "Done for this pet", 3)
                                task.wait(.5)
                                local args = { "UnequipPet", uid }
                                game:GetService("ReplicatedStorage")
                                    :WaitForChild("GameEvents", 9e9)
                                    :WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                                task.wait(1)
                                break
                            end
                        end
                    end
                end

                if not autoLevelEnabled then
                    return
                elseif not petFound then
                    beastHubNotify(selectedPet.." not found", "", 3)
                    task.wait(1)
                else
                    beastHubNotify("Auto Level cycle done!", "", 3)  
                end
            end

            -- ￰ﾟﾧﾹ Cleanup
            autoLevelEnabled = false
            autoLevelThread = nil

        end)
    end,
})
Pets:CreateDivider()

--Auto NM
Pets:CreateSection("Auto Nightmare")
Pets:CreateParagraph({
    Title = "INSTRUCTIONS:",
    Content = "1.) Setup the leveling loadout from 'Auto Pet Mutation'.\n2.) Input target level for Nightmare requirement below."
})

local selectedPetForAutoNM
Pets:CreateDropdown({
    Name = "Select Pet (excluded favorites)",
    Options = allPetList,
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "autoNMPets", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        selectedPetForAutoNM = Options[1]
    end,
})

local targetLevelForNM = Pets:CreateInput({
    Name = "Target Level",
    CurrentValue = "",
    PlaceholderText = "level requirement..",
    RemoveTextAfterFocusLost = false,
    Flag = "autoNMtargetLevel",
    Callback = function(Text)
    -- The function that takes place when the input is changed
    -- The variable (Text) is a string for the value in the text box
    end,
})

local horsemanLoady
Pets:CreateDropdown({
    Name = "Horseman Loadout (Free 1 pet space)",
    Options = {"None", "1", "2", "3"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "horsemanLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        horsemanLoady = tonumber(Options[1])
    end,
})

local autoEleAfterAutoNMenabled = false
local toggle_autoEleAfterAutoNM = Pets:CreateToggle({
    Name = "Auto Elephant after Auto NM",
    CurrentValue = false,
    Flag = "autoEleAfterAutoNM", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        autoEleAfterAutoNMenabled = Value
    end,
})

local autoNMenabled
local autoNMthread = nil
local autoNMwebhook = false
toggle_autoNM = Pets:CreateToggle({
    Name = "Auto Nightmare",
    CurrentValue = false,
    Flag = "autoNightmare", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        autoNMenabled = Value
        local autoNM

        if autoNMenabled then
            Toggle_autoMutation:Set(false)
            -- Check for missing setup
            -- Wait until Rayfield sets up the values (or timeout after 10s)
            local timeout = 5
            while timeout > 0 and (
                not levelingLoady or levelingLoady == "None"
                or not selectedPetForAutoNM
                or not tonumber(targetLevelForNM.CurrentValue)
                or autoEleAfterAutoNMenabled == nil 
            ) do
                task.wait(1)
                timeout = timeout - 1
            end
            --checkers here, final check, works for sudden reconnection
            local targetLevel = tonumber(targetLevelForNM.CurrentValue)
            local isNum = targetLevel
            if not levelingLoady or levelingLoady == "None"
            or not selectedPetForAutoNM 
            or not horsemanLoady or horsemanLoady == "None"
            or not isNum then
                beastHubNotify("Missing setup!", "Please also check leveling loadout", 10)
                return
            end

            autoNM = function(selectedPetForAutoNM, onComplete)
                local HttpService = game:GetService("HttpService")
            
                local function getPlayerData()
                    local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                    local logs = dataService:GetData()
                    return logs
                end
            
                local function getPetInventory()
                    local playerData = getPlayerData()
                    if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                        return playerData.PetsData.PetInventory.Data
                    else
                        warn("PetsData not found!")
                        return nil
                    end
                end

                local function getCurrentPetLevelByUid(uid)
                    local playerData = getPlayerData()
                    if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                        for id, data in pairs(playerData.PetsData.PetInventory.Data) do
                            if(tostring(id) == uid) then
                                return data.PetData.Level
                            end
                        end
                        return nil
                    else
                        warn("PetsData not found!")
                        return nil
                    end
                end

                local function getPetMutationEnumByUid(uid)
                    local playerData = getPlayerData()
                    if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                        for id, data in pairs(playerData.PetsData.PetInventory.Data) do
                            if tostring(id) == uid then
                                return data.PetData.MutationType
                            end
                        end
                        return nil
                    else
                        warn("Pet Mutation not found!")
                        return nil
                    end
                end

                -- Function you can call anytime to refresh pets data
                local function refreshPets()
                    -- USAGE: local favs, unfavs = refreshPets()
                    local pets = getPetInventory()
                    local favoritePets, unfavoritePets = {}, {}
                    if pets then
                        for uid, pet in pairs(pets) do
                            local entry = {
                                Uid = uid,
                                PetType = pet.PetType,
                                Uuid = pet.UUID, 
                                PetData = pet.PetData
                            }
                            if pet.PetData.IsFavorite then
                                table.insert(favoritePets, entry)
                            else
                                table.insert(unfavoritePets, entry)
                            end
                        end
                    end
                    --
                    return favoritePets, unfavoritePets
                end

                local function equipItemByName(itemName)
                    local player = game.Players.LocalPlayer
                    local backpack = player:WaitForChild("Backpack")
                    player.Character.Humanoid:UnequipTools() --unequip all first

                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") and string.find(tool.Name, itemName) then
                            --print("Equipping:", tool.Name)
                            player.Character.Humanoid:UnequipTools() --unequip all first
                            player.Character.Humanoid:EquipTool(tool)
                            return true -- stop after first match
                        end
                    end
                    return false
                end

                local function equipPetByUuid(uuid)
                    local player = game.Players.LocalPlayer
                    local backpack = player:WaitForChild("Backpack")
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:GetAttribute("PET_UUID") == uuid then
                            player.Character.Humanoid:EquipTool(tool)
                        end
                    end
                end

                local function getPetEquipLocation()
                    local success, result = pcall(function()
                        local spawnCFrame = getFarmSpawnCFrame()
                        if typeof(spawnCFrame) ~= "CFrame" then
                            return nil
                        end
                        -- offset forward 5 studs
                        return spawnCFrame * CFrame.new(0, 0, -5)
                    end)
                    if success then
                        return result
                    else
                        warn("[getPetEquipLocation] Error: " .. tostring(result))
                        return nil
                    end
                end

                local function getMachineMutationsData() --all mutation data including enums
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local success, PetMutationRegistry = pcall(function()
                        return require(
                            ReplicatedStorage:WaitForChild("Data")
                                :WaitForChild("PetRegistry")
                                :WaitForChild("PetMutationRegistry")
                        )
                    end)
                    if not success or type(PetMutationRegistry) ~= "table" then
                        warn("Failed to load PetMutationRegistry module.")
                        return {}
                    end
                    local machineMutations = PetMutationRegistry.MachineMutationTypes
                    if type(machineMutations) ~= "table" then
                        warn("MachineMutationTypes not found in PetMutationRegistry.")
                        return {}
                    end
                    -- table.sort(machineMutations)
                    return machineMutations
                end

                local function getMachineMutationsDataWithPrint() -- all mutation data including enums
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")

                    local success, PetMutationRegistry = pcall(function()
                        return require(
                            ReplicatedStorage:WaitForChild("Data")
                                :WaitForChild("PetRegistry")
                                :WaitForChild("PetMutationRegistry")
                        )
                    end)

                    if not success or type(PetMutationRegistry) ~= "table" then
                        warn("Failed to load PetMutationRegistry module.")
                        return {}
                    end

                    local machineMutations = PetMutationRegistry.EnumToPetMutation
                    if type(machineMutations) ~= "table" then
                        warn("MachineMutationTypes not found in PetMutationRegistry.")
                        return {}
                    end

                    return machineMutations
                end


                --main function code
                --vars
                local favs, unfavs = refreshPets()
                task.wait(1)
                local petFound = false
                local message = "Auto Nightmare stopped"

                --main loop for unfavs
                for _, pet in pairs(unfavs) do 
                    local curPet = pet.PetType
                    -- local uid = pet.Uuid --bug, not all pet inventory has UUID
                    local uid = tostring(pet.Uid)
                    local curLevel = pet.PetData.Level
                    local curMutationEnum = pet.PetData.MutationType
                    local curMutation -- fetch later after enums fetch
                    local machineMutationEnums = {} --pet mutation enums container
                    -- local mutations = getMachineMutationsData() --all mutation data
                    local mutations = getMachineMutationsDataWithPrint()
                    for enum, value in pairs(mutations) do --extract only enums
                        table.insert(machineMutationEnums, {enum, value})
                    end
                    --get current pet mutation via enum
                    for _, entry in ipairs(machineMutationEnums) do
                        local mutation = entry[2]
                        local enumId = entry[1]
                        if enumId == curMutationEnum then
                            curMutation = mutation
                            break
                        end
                    end

                    
                    
                    if autoNMenabled and curPet == selectedPetForAutoNM then
                        if curMutation ~= "Nightmare" then
                            beastHubNotify("Pet found: "..curPet, curMutation or "", 5)
                            --conditions
                            if curMutation == nil then
                                beastHubNotify("Pet found has no mutation yet", "", 3) 
                            end
                            petFound = true
                            --switch to leveling
                            myFunctions.switchToLoadout(levelingLoady)
                            task.wait(6)
                            equipPetByUuid(uid)
                            task.wait(2)
                            --place pet to garden for leveling                                    
                            local petEquipLocation = getPetEquipLocation()
                            local args = {
                                [1] = "EquipPet",
                                [2] = uid,
                                [3] = petEquipLocation, 
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                            task.wait(1)

                            --monitor level
                            while autoNMenabled and curLevel < targetLevel do
                                beastHubNotify("Current Pet age: "..curLevel, "waiting to hit age "..targetLevel.."..",3)
                                task.wait(10)
                                curLevel = getCurrentPetLevelByUid(uid)
                            end
                            
                            --unequip once ready
                            local args = {
                                [1] = "UnequipPet";
                                [2] = uid;
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                            task.wait(1) 

                            --swtich to NM loady
                            if autoNMenabled then 
                                myFunctions.switchToLoadout(horsemanLoady)
                                task.wait(10)
                                --equip to garden
                                local args = {
                                    [1] = "EquipPet",
                                    [2] = uid,
                                    [3] = petEquipLocation, 
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                                task.wait(2)
                                --equip cleanse and fire
                                --
                                if equipItemByName("Cleansing Pet Shard") == false then 
                                    beastHubNotify("No more cleansing shards!", "", 4)
                                    return    
                                else
                                    beastHubNotify("Cleansing now..", "", 3) 
                                end 
                                task.wait(.5)
                                --cleanse event
                                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                                local PetShardService_RE = ReplicatedStorage.GameEvents.PetShardService_RE -- RemoteEvent
                                -- Find pet model anywhere inside PetsPhysical
                                local petPhysical = workspace:WaitForChild("PetsPhysical")
                                local targetPet = petPhysical:FindFirstChild(tostring(uid), true) -- 'true' enables recursive search
                                if targetPet then
                                    PetShardService_RE:FireServer("ApplyShard", targetPet)
                                    -- print("✅ Fired ApplyShard for pet UID:", uid, "found at", targetPet:GetFullName())
                                else
                                    beastHubNotify("Pet slot full!", "Please free 1 slot in HH loadout", 3)
                                    autoNMenabled = false
                                    return
                                    -- warn("❌ Could not find Pet model with UID:", uid)
                                end

                                task.wait(5)
                                
                                --unequip shard
                                game.Players.LocalPlayer.Character.Humanoid:UnequipTools()

                                --monitor if curLevel dropped
                                while autoNMenabled and curLevel >= targetLevel do
                                    beastHubNotify("Ready for Nightmare!", "Waiting for NM skill..",3)
                                    task.wait(10)
                                    curLevel = getCurrentPetLevelByUid(uid)
                                end
                                task.wait(.5)

                                --unequip upon exit
                                local args = {
                                    [1] = "UnequipPet";
                                    [2] = uid;
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                                task.wait(1) 

                                --get updated mutation for webhook if enabled
                                if autoNMenabled and autoNMwebhook and curLevel < targetLevel  then
                                    --get updated enuma
                                    beastHubNotify("Sending webhook","",3)
                                    -- print("Sending webhook..")
                                    -- print(curPet)
                                    -- print(uid)
                                    -- print(curLevel)
                                    task.wait(1)
                                    local updatedEnum = getPetMutationEnumByUid(uid)
                                    -- print("updatedEnum:")
                                    -- print(updatedEnum)
                                    local updatedMutation = "default_empty"
                                    --get updated pet mutation via enum
                                    for _, entry in ipairs(machineMutationEnums) do
                                        local mutation = entry[2]
                                        local enumId = entry[1]
                                        if enumId == updatedEnum then
                                            updatedMutation = mutation
                                            -- print("updatedMutation: "..updatedMutation)
                                            break
                                        end
                                    end
                                    --
                                    local playerName = game.Players.LocalPlayer.Name
                                    local webhookMsg = "[BeastHub] "..playerName.." | Auto Nightmare result: "..curPet.."="..updatedMutation
                                    sendDiscordWebhook(webhookURL, webhookMsg)
                                    -- beastHubNotify("Webhook sent", "", 2)
                                    task.wait(1)
                                end

                                

                            end
                            return
                        end
                    end --end if curpet is match
                    -- task.wait(10)

                end -- end main for loop

                -- ￢ﾜﾅ Call the callback AFTER finishing
                if petFound == false then 
                    message = "No eligible pet"                     
                end
                if typeof(onComplete) == "function" then
                    onComplete(message)
                end

            end --autoNM function end



            --MAIN logic
            autoNMthread = nil
            if autoNMenabled and not autoNMthread then
                autoNMthread = task.spawn(function()
                    while autoNMenabled do
                        beastHubNotify("Auto NM running", "", 3)
                        autoNM(selectedPetForAutoNM, function(msg)
                            if msg == "No eligible pet" then
                                beastHubNotify("Not found..", "Make sure to select the correct pet", 3)
                                autoNMenabled = false
                                task.wait(1)
                                --add auto level condition
                                if autoEleAfterAutoNMenabled == true then
                                    beastHubNotify("Auto Elephant triggered", "", 3)
                                    toggle_autoEle:Set(true)
                                end
                                return
                            else
                                beastHubNotify(msg, "", 5)
                                return
                            end
                        
                        end) --end function call
                        task.wait(2)
                    end --end while
                end) --end thread spawn
            end
        end      
    end,
})
Pets:CreateDivider()

--Auto Elephant
Pets:CreateSection("Auto Elephant")
Pets:CreateParagraph({
    Title = "INSTRUCTIONS:",
    Content = "1.) Setup the leveling loadout from 'Auto Pet Mutation'.\n2.) Fill up the rest below."
})

local selectedPetForAutoEle
Pets:CreateDropdown({
    Name = "Select Pet (excluded favorites)",
    Options = allPetList,
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "autoElePets", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        selectedPetForAutoEle = Options[1]
    end,
})

-- local targetLevelForEle = Pets:CreateInput({
--     Name = "Target Level",
--     CurrentValue = "",
--     PlaceholderText = "level requirement..",
--     RemoveTextAfterFocusLost = false,
--     Flag = "autoEletargetLevel",
--     Callback = function(Text)
--     -- The function that takes place when the input is changed
--     -- The variable (Text) is a string for the value in the text box
--     end,
-- })



local elephantUsed = Pets:CreateDropdown({
    Name = "Elephant Used",
    Options = {"Normal Elephant", "RBH Elephant"},
    CurrentOption = {"Normal Elephant"},
    MultipleOptions = false,
    Flag = "elephantUsed", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
    end,
})

local targetKGForEle = Pets:CreateInput({
    Name = "Target Base KG",
    CurrentValue = "3.85",
    PlaceholderText = "input KG",
    RemoveTextAfterFocusLost = false,
    Flag = "autoEletargetKG",
    Callback = function(Text)
    -- The function that takes place when the input is changed
    -- The variable (Text) is a string for the value in the text box
    end,
})

local elephantLoady
Pets:CreateDropdown({
    Name = "Elephant Loadout",
    Options = {"None", "1", "2", "3"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "elephantLoadoutNum", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        --if not Options or not Options[1] then return end
        elephantLoady = tonumber(Options[1])
    end,
})

-- local toyForStacking = Pets:CreateDropdown({
--     Name = "(for STACKING) Select Toy",
--     Options = {"Medium Pet Toy", "Small Pet Toy", "Do not use STACKING"},
--     CurrentOption = {"Medium Pet Toy"},
--     MultipleOptions = false,
--     Flag = "selectToyForElephantStacking", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
--     Callback = function(Options)
--         --if not Options or not Options[1] then return end
--     end,
-- })

-- local delayInMinutesForToy = Pets:CreateInput({
--     Name = "(for STACKING) Delay in minutes",
--     CurrentValue = "10",
--     PlaceholderText = "minutes..",
--     RemoveTextAfterFocusLost = false,
--     Flag = "delayInMinutesForToyBoost",
--     Callback = function(Text)
--     -- The function that takes place when the input is changed
--     -- The variable (Text) is a string for the value in the text box
--     end,
-- })

local autoLevelAfterAutoEleEnabled = false
local toggle_autoLevelAfterAutoEle = Pets:CreateToggle({
    Name = "Auto Level after Auto Elephant",
    CurrentValue = false,
    Flag = "autoLevelAfterAutoEle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        autoLevelAfterAutoEleEnabled = Value
    end,
})

local autoEleEnabled
local autoEleThread = nil
local autoEleWebhook = false
toggle_autoEle = Pets:CreateToggle({
    Name = "Auto Elephant",
    CurrentValue = false,
    Flag = "autoElephant", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        autoEleEnabled = Value
        local autoEle --function declaration

        if autoEleEnabled then
            Toggle_autoMutation:Set(false)

            local timeout = 5
            while timeout > 0 and (
                not levelingLoady or levelingLoady == "None"
                -- or toyForStacking.CurrentOption[1] == nil
                or not selectedPetForAutoEle
                -- or not tonumber(targetLevelForEle.CurrentValue)
                or elephantUsed.CurrentOption[1] == nil
                or not tonumber(targetKGForEle.CurrentValue)
                or autoLevelAfterAutoEleEnabled == nil 
            ) do
                task.wait(1)
                timeout = timeout - 1
            end
            --checkers here, final check, works for sudden reconnection
            -- local targetLevel = tonumber(targetLevelForEle.CurrentValue)
            local targetKG = tonumber(targetKGForEle.CurrentValue)
            -- local delayInMins = tonumber(delayInMinutesForToy.CurrentValue)
            -- local toyToUse = toyForStacking.CurrentOption[1]
            local eleUsed = elephantUsed.CurrentOption[1]
            -- local isNum = targetLevel
            local isNumKG = targetKG
            -- local isNumDelay = delayInMins

            if not levelingLoady or levelingLoady == "None"
            or not selectedPetForAutoEle 
            or not elephantLoady or elephantLoady == "None"
            -- or not toyToUse or toyToUse == ""
            or not isNumKG 
            or not eleUsed or eleUsed == "" then
                beastHubNotify("Missing setup!", "", 10)
                return
            end

            --main function declaration
            autoEle = function(selectedPetForAutoEle, onComplete)
                local HttpService = game:GetService("HttpService")

                local function getPlayerData()
                    local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                    local logs = dataService:GetData()
                    return logs
                end

                local function getPetInventory()
                    local playerData = getPlayerData()
                    if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                        return playerData.PetsData.PetInventory.Data
                    else
                        warn("PetsData not found!")
                        return nil
                    end
                end

                local function getCurrentPetLevelByUid(uid)
                    local playerData = getPlayerData()
                    if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                        for id, data in pairs(playerData.PetsData.PetInventory.Data) do
                            if(tostring(id) == uid) then
                                return data.PetData.Level
                            end
                        end
                        return nil
                    else
                        warn("PetsData not found!")
                        return nil
                    end
                end

                local function getCurrentPetKGByUid(uid)
                    local playerData = getPlayerData()
                    if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                        for id, data in pairs(playerData.PetsData.PetInventory.Data) do
                            if(tostring(id) == uid) then
                                return data.PetData.BaseWeight
                            end
                        end
                        return nil
                    else
                        warn("PetsData not found!")
                        return nil
                    end
                end

                local function refreshPets()
                    -- USAGE: local favs, unfavs = refreshPets()
                    local pets = getPetInventory()
                    local favoritePets, unfavoritePets = {}, {}
                    if pets then
                        for uid, pet in pairs(pets) do
                            local entry = {
                                Uid = uid,
                                PetType = pet.PetType,
                                Uuid = pet.UUID, 
                                PetData = pet.PetData
                            }
                            if pet.PetData.IsFavorite then
                                table.insert(favoritePets, entry)
                            else
                                table.insert(unfavoritePets, entry)
                            end
                        end
                    end
                    --
                    return favoritePets, unfavoritePets
                end

                local function equipPetByUuid(uuid)
                    local player = game.Players.LocalPlayer
                    local backpack = player:WaitForChild("Backpack")
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:GetAttribute("PET_UUID") == uuid then
                            player.Character.Humanoid:EquipTool(tool)
                        end
                    end
                end

                local function getPetEquipLocation()
                    local success, result = pcall(function()
                        local spawnCFrame = getFarmSpawnCFrame()
                        if typeof(spawnCFrame) ~= "CFrame" then
                            return nil
                        end
                        -- offset forward 5 studs
                        return spawnCFrame * CFrame.new(0, 0, -5)
                    end)
                    if success then
                        return result
                    else
                        warn("[getPetEquipLocation] Error: " .. tostring(result))
                        return nil
                    end
                end

                --main function code
                local favs, unfavs = refreshPets()
                task.wait(1)
                local petFound = false
                local message = "Auto Elephant stopped"
                local targetLevel
                if eleUsed == "Normal Elephant" then
                    -- targetKG = 3.85
                    targetLevel = 50
                else
                    -- targetKG = 6.05
                    targetLevel = 40
                end

                --main loop for unfavs
                for _, pet in pairs(unfavs) do 
                    local curPet = pet.PetType
                    local uid = tostring(pet.Uid)
                    local curLevel = pet.PetData.Level
                    local curBaseKG = tonumber(pet.PetData.BaseWeight) * 1.1

                    if autoEleEnabled and curPet == selectedPetForAutoEle and targetKG > curBaseKG then
                        beastHubNotify("Target found", "Auto Elephant", 3)
                        beastHubNotify(curPet, "Base KG: "..curBaseKG, 3)
                        petFound = true

                        --switch to leveling
                        myFunctions.switchToLoadout(levelingLoady)
                        task.wait(6)
                        equipPetByUuid(uid)
                        task.wait(2)
                        --place pet to garden for leveling                                    
                        local petEquipLocation = getPetEquipLocation()
                        local args = {
                            [1] = "EquipPet",
                            [2] = uid,
                            [3] = petEquipLocation, 
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                        task.wait(1)
                        
                        --monitor level
                        while autoEleEnabled and curLevel < targetLevel do
                            beastHubNotify("Current Pet age: "..curLevel, "waiting to hit age "..targetLevel.."..",3)
                            task.wait(10)
                            curLevel = getCurrentPetLevelByUid(uid)
                        end

                        --unequip once ready
                        local args = {
                            [1] = "UnequipPet";
                            [2] = uid;
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                        task.wait(1) 

                        --swtich to Ele loady
                        if autoEleEnabled then 
                            myFunctions.switchToLoadout(elephantLoady)
                            task.wait(6)
                            --equip to garden
                            local args = {
                                [1] = "EquipPet",
                                [2] = uid,
                                [3] = petEquipLocation, 
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                            task.wait(2)

                            --monitor if curLevel dropped
                            while autoEleEnabled and curLevel >= targetLevel do
                                -- local delayInSecs = (delayInMins * 60) or nil
                                beastHubNotify("Ready for Elephant!", "Waiting for Elephant skill..",5)
                                task.wait(5)
                                
                                --insert stacking code here = PATCHED!
                                -- if toyToUse ~= "Do not use STACKING" and curLevel >= targetLevel then 
                                --     --unequip target pet first to avoid cooldown abilities from affecting elephants
                                --     print("toyToUse")
                                --     print(toyToUse)
                                --     local args = {
                                --         [1] = "UnequipPet";
                                --         [2] = uid;
                                --     }
                                --     game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                                --     task.wait(.2) 
                                    
                                --     --count check first how many to boost
                                --     local safeStackingCounter = 0
                                --     local projectedBaseKG = curBaseKG + .11

                                --     while projectedBaseKG < targetKG do --stop at maximum potential stacking
                                --         safeStackingCounter = safeStackingCounter + 1
                                --         projectedBaseKG = projectedBaseKG + .11
                                --     end
                                --     --check if already in current maximum potential
                                --     if safeStackingCounter == 0 then
                                --         safeStackingCounter = 7 --set to max
                                --         beastHubNotify("Max potential KG detected!", "", 3)
                                --     end
                                --     beastHubNotify("Stacking needed: "..tostring(safeStackingCounter), "", 10)

                                --     --do countdown here  
                                --     while delayInSecs > 0 and autoEleEnabled do
                                --         beastHubNotify("Boost Countdown (seconds)", tostring(delayInSecs), 1)
                                --         task.wait(1)
                                --         delayInSecs = delayInSecs - 1
                                --         if delayInSecs == 55 then --only equip at low time left to avoid elephant conflict
                                --             --equip to garden
                                --             local args = {
                                --                 [1] = "EquipPet",
                                --                 [2] = uid,
                                --                 [3] = petEquipLocation, 
                                --             }
                                --             game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                                --             -- task.wait(2)
                                --         end
                                --     end

                                    
                                --     --boost after countdown
                                --     if autoEleEnabled then
                                --         game.Players.LocalPlayer.Character.Humanoid:UnequipTools()
                                --         task.wait(.2)
                                --         equipItemByName(toyToUse)
                                --         --boost all code here
                                --         local function getPlayerData()
                                --             local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                                --             local HttpService = game:GetService("HttpService")
                                --             local logs = dataService:GetData()
                                --             local playerData = HttpService:JSONEncode(logs)
                                --             return logs.PetsData.EquippedPets
                                --         end

                                --         local data = getPlayerData()
                                --         local ReplicatedStorage = game:GetService("ReplicatedStorage")
                                --         local PetBoostService = ReplicatedStorage.GameEvents.PetBoostService -- RemoteEvent 
                                --         local boostedCount = 0

                                --         for _, id in ipairs(data) do
                                --             -- print(id)
                                --             if id ~= uid then 
                                --                 if boostedCount < safeStackingCounter then
                                --                     PetBoostService:FireServer(
                                --                         "ApplyBoost",
                                --                         id
                                --                     )
                                --                     boostedCount = boostedCount + 1
                                --                     -- print("boosted!")
                                --                 end
                                --             end
                                --         end
                                --         task.wait(3)
                                --         curLevel = getCurrentPetLevelByUid(uid)
                                --     end
                                -- end
                                curLevel = getCurrentPetLevelByUid(uid)
                            end
                            task.wait(.3)

                            --unequip upon exit
                            local args = {
                                [1] = "UnequipPet";
                                [2] = uid;
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                            task.wait(.2) 

                            --webhook if enabled
                            if autoEleEnabled and autoEleWebhook and curLevel < targetLevel  then
                                -- local updatedKG = tostring(curBaseKG + 0.1) --static adding of KG instead of get base KG
                                curBaseKG = getCurrentPetKGByUid(uid)
                                local updatedKG = string.format("%.2f", curBaseKG * 1.1)
                                
                                beastHubNotify("Sending webhook","",3)
                                local playerName = game.Players.LocalPlayer.Name
                                local webhookMsg = "[BeastHub] "..playerName.." | Auto Elephant result: "..curPet.."="..updatedKG.."KG"
                                sendDiscordWebhook(webhookURL, webhookMsg)
                                task.wait(1)
                            end
                        end
                        return
                    end
                    
                end --end for loop

                if petFound == false then 
                    message = "No eligible pet"                     
                end
                if typeof(onComplete) == "function" then
                    onComplete(message)
                end

            end --autoEle end

            --MAIN logic
            autoEleThread = nil
            if autoEleEnabled and not autoEleThread then
                autoEleThread = task.spawn(function()
                    while autoEleEnabled do
                        beastHubNotify("Auto Elephant running", "", 3)
                        autoEle(selectedPetForAutoEle, function(msg)
                            if msg == "No eligible pet" then
                                beastHubNotify("Not found..", "Make sure to select the correct pet", 3)
                                autoEleEnabled = false
                                task.wait(1)
                                --add auto level condition
                                if autoLevelAfterAutoEleEnabled == true then
                                    beastHubNotify("Auto Leveling triggered", "", 3)
                                    Toggle_autoLevel:Set(true)
                                end
                                myFunctions.switchToLoadout(levelingLoady)
                                task.wait(5)
                                return
                            else
                                beastHubNotify(msg, "", 5)
                                return
                            end
                        
                        end) --end function call
                        task.wait(.1)
                    end --end while
                    beastHubNotify("Auto Elephant Stopped", "", 3)
                end) -- end thread spawn
            end 
        end
    end,
})
Pets:CreateDivider()

--Auto Pet Age Break
local idsOnly --storage for ids for target pet breaker dropdown
local allPetsInInventory = function()
    idsOnly = {}
    local function getPlayerData()
        local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
        local logs = dataService:GetData()
        -- print("got player data")
        return logs
    end

    local function getPetInventory()
        local playerData = getPlayerData()
        if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
            -- print("got pets data")
            return playerData.PetsData.PetInventory.Data
        else
            warn("PetsData not found!")
            return nil
        end
    end

    local function getMachineMutationsDataWithPrint() -- all mutation data including enums
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local success, PetMutationRegistry = pcall(function()
            return require(
                ReplicatedStorage:WaitForChild("Data")
                    :WaitForChild("PetRegistry")
                    :WaitForChild("PetMutationRegistry")
            )
        end)

        if not success or type(PetMutationRegistry) ~= "table" then
            warn("Failed to load PetMutationRegistry module.")
            return {}
        end

        local machineMutations = PetMutationRegistry.EnumToPetMutation
        if type(machineMutations) ~= "table" then
            warn("MachineMutationTypes not found in PetMutationRegistry.")
            return {}
        end
        return machineMutations
    end

    -- Function you can call anytime to refresh pets data
    local function refreshPets()
        -- USAGE: local favs, unfavs = refreshPets()
        local pets = getPetInventory()
        local unfavoritePets = {}
        local machineMutationEnums = {} --pet mutation enums container
        local mutations = getMachineMutationsDataWithPrint()
        for enum, value in pairs(mutations) do --extract only enums
            table.insert(machineMutationEnums, {enum, value})
        end        

        if pets then
            for uid, pet in pairs(pets) do
                local curMutation
                local curMutationEnum = pet.PetData.MutationType or nil
                --get current pet mutation via enum
                for _, entry in ipairs(machineMutationEnums) do
                    local mutation = entry[2]
                    local enumId = entry[1]
                    if enumId == curMutationEnum then
                        curMutation = mutation
                        break
                    end
                end
                local entry = {
                    nameToId = pet.PetType.." | "..(curMutation or "Normal").." | Base KG: "..(string.format("%.2f", pet.PetData.BaseWeight * 1.1)).." | Age: "..tostring(pet.PetData.Level),
                    Uid = uid
                }
                if not pet.PetData.IsFavorite and pet.PetData.Level >= 100 then --filter only allowed age for breaker
                    table.insert(unfavoritePets, entry)
                end
            end
        end
        --
        return unfavoritePets
    end

    --process here
    local unfavs = refreshPets()

    -- Sort unfavs by nameToId BEFORE extracting namesOnly and idsOnly
    table.sort(unfavs, function(a,b)
        return a.nameToId < b.nameToId
    end)

    local namesOnly = {}
    idsOnly = {}

    for _, pet in ipairs(unfavs) do
        table.insert(namesOnly, pet.nameToId)
        table.insert(idsOnly, pet.Uid)
    end

    return namesOnly

end

Pets:CreateSection("Auto Pet Age Break")
Pets:CreateParagraph({
    Title = "INSTRUCTIONS:",
    Content = "1.) Select Pet\n2.) Refresh list if pet not found\n3.) Ignore Target ID, it will auto populate"
})
local selectedPetForAgeBreaker = ""
-- local paragraph_currentId = Pets:CreateParagraph({
--     Title = "CURRENT ID:",
--     Content = "None"
-- })

local petBreakerTargetIDstored = Pets:CreateDropdown({
    Name = "Target ID (do not change)",
    Options = {""},
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "petBreakerTargetStored",
    Callback = function() end,
})

local autoPetAgeBreakEnabled = false
local autoPetAgeBreakThread = nil
local selectedIndex = nil --to know which option is selected in order to get the Uid
local selectTargetPetForBreaker = allPetsInInventory()

local selectedPetForAgeBreak = Pets:CreateDropdown({
    Name = "Select Target (Unfavorite and 100+)",
    Options = selectTargetPetForBreaker,
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "AutPetAgeBreakTarget", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
        local chosen = Options[1]
        print("=======chosen:")
        print(chosen)
        for i, v in ipairs(selectTargetPetForBreaker) do
            print("looping")
            print(v)
            if v == chosen then
                selectedIndex = i
                break
            end
        end
        selectedPetForAgeBreaker = idsOnly[selectedIndex]
        if selectedPetForAgeBreaker then
            print("storing value")
            print(selectedPetForAgeBreaker)
            petBreakerTargetIDstored:Refresh({ selectedPetForAgeBreaker }) 
            petBreakerTargetIDstored:Set({ selectedPetForAgeBreaker })
            print("stored selectedPetForAgeBreaker to stored input")
        end
        if not selectedPetForAgeBreaker then
            print("getting value from stored dropdown")
            selectedPetForAgeBreaker = petBreakerTargetIDstored.CurrentOption[1] --stored value in rayfield
            print("used pet id from stored input")
            print(selectedPetForAgeBreaker)
        end

        -- paragraph_currentId:Set({
        --     Title = "CURRENT ID:",
        --     Content = selectedPetForAgeBreaker
        -- })  
    end,
})

Pets:CreateButton({
    Name = "Refresh List",
    Callback = function()
        selectedPetForAgeBreak:Refresh(allPetsInInventory()) -- The new list of options
    end,
})

local petAgeKGsacrifice = Pets:CreateDropdown({
    Name = "Sacrifice Below Base KG:",
    Options = {"1", "2", "3"},
    CurrentOption = {"3"},
    MultipleOptions = false,
    Flag = "petAgeKGsacrifice", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
    
    end,
})


local petAgeLevelSacrifice = Pets:CreateInput({
    Name = "Sacrifice Below Level:",
    CurrentValue = "",
    PlaceholderText = "input number..",
    RemoveTextAfterFocusLost = false,
    Flag = "petAgeLevelSacrifice",
    Callback = function(Text)
    -- The function that takes place when the input is changed
    -- The variable (Text) is a string for the value in the text box
    end,
})

Pets:CreateToggle({
    Name = "Auto Pet Age Break",
    CurrentValue = false,
    Flag = "autoPetAgeBreak", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        autoPetAgeBreakEnabled = Value
        local autoBreaker --function holder
        if not autoPetAgeBreakEnabled then
            if autoPetAgeBreakThread then
                task.cancel(autoPetAgeBreakThread)
                autoPetAgeBreakThread = nil
                beastHubNotify("Auto Pet Age Break stopped", "", 3)
            end
            return
        else
            --turn off auto hatching of auto level is on
            -- Toggle_smartAutoHatch:Set(false)
            -- toggle_autoEle:Set(false)
            -- toggle_autoNM:Set(false)
            -- Toggle_autoLevel:Set(false)
        end

        --checking here
        -- Wait until Rayfield sets up the values (or timeout after 10s)
        local timeout = 3
        while timeout > 0 and (
            not selectedPetForAgeBreak.CurrentOption
            or not selectedPetForAgeBreak.CurrentOption[1]
            or selectedPetForAgeBreak.CurrentOption[1] == "None"
            or not tonumber(petAgeLevelSacrifice.CurrentValue)
            or petAgeLevelSacrifice.CurrentValue == ""
        ) do
            task.wait(1)
            timeout -= 1
        end

        --checkers here, final check, works for sudden reconnection
        if not selectedPetForAgeBreak.CurrentOption
        or not selectedPetForAgeBreak.CurrentOption[1]
        or selectedPetForAgeBreak.CurrentOption[1] == "None" 
        or not tonumber(petAgeLevelSacrifice.CurrentValue)
        or petAgeLevelSacrifice.CurrentValue == "" then
            beastHubNotify("Missing setup!", "Please recheck", 5)
            return
        end

        local sacrificePetName = (selectedPetForAgeBreak.CurrentOption[1]:match("^(.-)%s*|") or ""):match("^%s*(.-)%s*$")
        -- local selectedId = idsOnly[selectedIndex]
        local selectedId = selectedPetForAgeBreaker


        autoBreaker = function(sacrificePetNameParam, selectedIdParam)
            local function getPlayerData()
                local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                local logs = dataService:GetData()
                return logs
            end

            local function getPetIdByNameAndFilterKg(name, basekg, belowLevel, exceptId)
                -- print(name)
                -- print(basekg)
                -- print(belowLevel)
                -- print(exceptId)
                local playerData = getPlayerData()
                if playerData.PetsData and playerData.PetsData.PetInventory and playerData.PetsData.PetInventory.Data then
                    for id, data in pairs(playerData.PetsData.PetInventory.Data) do
                        local curBaseKG = tonumber(string.format("%.2f", data.PetData.BaseWeight * 1.1))
                        if not data.PetData.IsFavorite and data.PetType == name and curBaseKG < basekg and id ~= exceptId and data.PetData.Level < belowLevel then
                            return id
                        end
                    end
                    return nil
                else
                    warn("PetsData not found!")
                    return nil
                end
            end

            -- beastHubNotify("Selected: ",selectedPetForAgeBreak.CurrentOption[1], 3)


            local petIdToSacrifice = getPetIdByNameAndFilterKg(sacrificePetNameParam, tonumber(petAgeKGsacrifice.CurrentOption[1]), tonumber(petAgeLevelSacrifice.CurrentValue), selectedIdParam)
            -- print("petIdToSacrifice")
            -- print(tostring(petIdToSacrifice)) 
            
            if petIdToSacrifice and autoPetAgeBreakEnabled then
                beastHubNotify("Worthy sacrifice found!","",3)
                task.wait(2)
                --do the remotes here
                --check if machine is ready, if same id, continue monitoring
                local playerData = getPlayerData()
                if playerData.PetAgeBreakMachine then
                    print("pet age breaker machine found")
                    if playerData.PetAgeBreakMachine.IsRunning then
                        print("breaker machine is already running")
                        local runningId = playerData.PetAgeBreakMachine.SubmittedPet.UUID
                        if runningId == selectedIdParam then
                            print("the selected pet is already running in breaker machine")
                            --wait until machine is done
                        else
                            beastHubNotify("A different pet is already running", "waiting for breaker to be done", "3")
                            --wait until machine is done
                        end

                        --monitor machine
                        while autoPetAgeBreakEnabled do 
                            beastHubNotify("Waiting for breaker to be ready", "", 3)
                            task.wait(30)
                            playerData = getPlayerData()
                            if not playerData.PetAgeBreakMachine.IsRunning then
                                break
                            end
                        end

                        --claim pet ready to claim
                        task.wait(1)
                        game:GetService("ReplicatedStorage").GameEvents.PetAgeLimitBreak_Claim:FireServer()
                        beastHubNotify("Pet claimed", "", 3)
                        return
                    else
                        local function equipPetByUuid(uuid)
                            local player = game.Players.LocalPlayer
                            local backpack = player:WaitForChild("Backpack")
                            for _, tool in ipairs(backpack:GetChildren()) do
                                if tool:GetAttribute("PET_UUID") == uuid then
                                    player.Character.Humanoid:EquipTool(tool)
                                end
                            end
                        end

                        print("breaker machine is not running and ready to use")
                        --claim if there is a pet ready to claim
                        if playerData.PetAgeBreakMachine.PetReady then
                            game:GetService("ReplicatedStorage").GameEvents.PetAgeLimitBreak_Claim:FireServer()
                            beastHubNotify("Claimed any pet that is ready", "", 3)
                        else
                            --cancel pet not started
                            game:GetService("ReplicatedStorage").GameEvents.PetAgeLimitBreak_Cancel:FireServer()
                            beastHubNotify("Removed pet in breaker that was not started", "", 3)
                        end

                        --submit pet here
                        if autoPetAgeBreakEnabled then
                            equipPetByUuid(selectedId)
                            task.wait(.2)
                            game:GetService("ReplicatedStorage").GameEvents.PetAgeLimitBreak_SubmitHeld:FireServer()
                            beastHubNotify("Target Pet submitted to breaker", "",3)
                            task.wait(2)    
                        end
                        

                        --put sacrifice and start
                        if autoPetAgeBreakEnabled then
                            --submit and start
                            local args = {
                                [1] = {
                                    [1] = petIdToSacrifice
                                }
                            }
                            game:GetService("ReplicatedStorage").GameEvents.PetAgeLimitBreak_Submit:FireServer(unpack(args))
                            beastHubNotify("Breaker machine started!", "", 3)
                            task.wait(1)
                        end
                        

                        --monitor machine for newly submitted
                        while autoPetAgeBreakEnabled do 
                            beastHubNotify("Waiting for breaker to be ready", "", 3)
                            task.wait(30)
                            playerData = getPlayerData()
                            if not playerData.PetAgeBreakMachine.IsRunning then
                                break
                            end
                        end

                        --claim newly submitted pet in breaker
                        if autoPetAgeBreakEnabled then
                            game:GetService("ReplicatedStorage").GameEvents.PetAgeLimitBreak_Claim:FireServer()
                            beastHubNotify("Claimed ready pet in breaker", "", 3)
                        end

                    end
                end
            
            else
                beastHubNotify("No worthy sacrifice.", "", 3)
                autoPetAgeBreakEnabled = false
                autoPetAgeBreakThread = nil
            end

            
            beastHubNotify("Auto Pet Age Break cycle done", "", 3)
        end

        --thread code here
        if autoPetAgeBreakEnabled and not autoPetAgeBreakThread then
            autoPetAgeBreakThread = task.spawn(function()
                while autoPetAgeBreakEnabled do
                    autoBreaker(sacrificePetName, selectedId)
                end
                
            end) --end thread
        end 

        
    end,
})
Pets:CreateDivider()


--other
Pets:CreateSection("Other Pet settings")
Pets:CreateButton({
    Name = "Boost All Pets using Held item",
    Callback = function()
        local function getPlayerData()
            local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
            local HttpService = game:GetService("HttpService")
            local logs = dataService:GetData()
            local playerData = HttpService:JSONEncode(logs)
            -- print(logs.PetsData.EquippedPets)
            --setclipboard(playerData)
            return logs.PetsData.EquippedPets
        end

        local data = getPlayerData()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PetBoostService = ReplicatedStorage.GameEvents.PetBoostService -- RemoteEvent 
            
        for _, id in ipairs(data) do
            -- print(id)
            PetBoostService:FireServer(
                "ApplyBoost",
                id
            )
            -- print("boosted!")
        end
    end,
})
Pets:CreateDivider()

--Other Egg settings
PetEggs:CreateSection("Egg settings")
-- Egg ESP support --
-- local Toggle_eggESP = PetEggs:CreateToggle({
--     Name = "Egg ESP Support (Speedhub ESP enhanced)",
--     CurrentValue = false,
--     Flag = "eggESP", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
--     Callback = function(Value)
--         myFunctions.eggESP(Value)
--     end,
-- })

--bhub esp
local bhubESPenabled = false
local bhubESPthread = nil
local Toggle_bhubESP = PetEggs:CreateToggle({
    Name = "BeastHub ESP",
    CurrentValue = false,
    Flag = "bhubESP",
    Callback = function(Value)
        bhubESPenabled = Value
        local bhubEsp --function

        -- Turn OFF
        if not bhubESPenabled and bhubESPthread then
            task.cancel(bhubESPthread)
            bhubESPthread = nil

            -- ✅ Remove ALL BhubESP folders from all eggs
            local petEggs = myFunctions.getMyFarmPetEggs()
            for _, egg in ipairs(petEggs) do
                if egg:IsA("Model") then
                    local old = egg:FindFirstChild("BhubESP")
                    if old then old:Destroy() end
                end
            end

            beastHubNotify("ESP stopped and cleaned", "", 1)
            return
        end

        -- Turn ON
        if bhubESPenabled and not bhubESPthread then
            bhubEsp = function()
            
            end--end function

            bhubESPthread = task.spawn(function()
                beastHubNotify("ESP enabled", "", 1)
                while bhubESPenabled do
                    -- beastHubNotify("ESP running...", "", 1)
                    local eggEspData = {} --final table storage

                    -- Get all PetEgg models in your farm
                    local petEggs = myFunctions.getMyFarmPetEggs()
                    local withEspCount = 0
                    -- ✅ Check if ESP is already applied to ALL eggs
                    local allHaveESP = false
                    for _, egg in ipairs(petEggs) do
                        if egg:FindFirstChild("BhubESP") then
                            withEspCount = withEspCount + 1
                        end
                    end

                    -- print("withEspCount")
                    -- print(withEspCount)
                    -- print("#petEggs")
                    -- print(#petEggs)

                    if withEspCount == #petEggs then
                        allHaveESP = true
                    end

                    -- ✅ If every egg already has ESP, skip heavy processing
                    if allHaveESP then
                        -- print("stopped ESP checking, all have ESP already")
                        task.wait(2)
                        continue
                    else
                        -- print("waiting or ESP folder for some eggs")
                    end
                    
                    if #petEggs == 0 then
                        --print("[BeastHub] No PetEggs found in your farm!")
                        return
                    else
                        --process get data here
                        local function getPlayerData()
                            local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                            local logs = dataService:GetData()
                            return logs
                        end

                        local function getSaveSlots()
                            local playerData = getPlayerData()
                            if playerData.SaveSlots then
                                return playerData.SaveSlots
                            else
                                warn("SaveSlots not found!")
                                return nil
                            end
                        end
                        
                        

                        local saveSlots = getSaveSlots()
                        local selectedSlot = saveSlots.SelectedSlot
                        -- print("selectedSlot")
                        -- print(selectedSlot)
                        local allSlots = saveSlots.AllSlots
                        -- print("allSlots good")
                        for slot, slotData in pairs(allSlots) do
                            local slotNameString = tostring(slot)
                            -- print("slotNameString")
                            -- print(slotNameString)
                            if slotNameString == selectedSlot then
                                local savedObjects = slotData.SavedObjects
                                for objName, ObjData in pairs(savedObjects) do
                                    local objType = ObjData.ObjectType
                                    if objType == "PetEgg" then
                                        local eggData = ObjData.Data
                                        local timeToHatch = eggData.TimeToHatch or 0
                                        if timeToHatch == 0 then
                                            local petName = eggData.RandomPetData.Name
                                            local petKG = string.format("%.2f", eggData.BaseWeight * 1.1)
                                            -- beastHubNotify("Found!", petName.."|"..petKG, 1)
                                            local entry = {
                                                Uid = objName,
                                                PetName = petName,
                                                PetKG = petKG
                                            }
                                            table.insert(eggEspData, entry)
                                        end
                                    end
                                end
                            end
                        end
                        -- beastHubNotify("selectedSlot", selectedSlot, 3)
                    end

                    -- Loop through all to get data 
                    for _, egg in ipairs(petEggs) do
                    if egg:IsA("Model") then
                        local uuid = egg:GetAttribute("OBJECT_UUID")
                        local petName
                        local petKG
                        local hugeThreshold = 3
                        local isHuge = false
                        local isRare = false

                        for _, eggData in pairs(eggEspData) do 
                            if uuid == eggData.Uid then
                                petName = eggData.PetName
                                petKG = eggData.PetKG
                            end
                        end
                        
                        --skip non ready egg
                        if petKG == nil then
                            continue
                        end
                        
                        if tonumber(petKG) >= hugeThreshold then
                            isHuge = true
                        end

                        -- ✅ Clear previous ESP if exists
                        local old = egg:FindFirstChild("BhubESP")
                        if old then old:Destroy() end
                            -- ✅ Create new ESP folder
                            local espFolder = Instance.new("Folder")
                            espFolder.Name = "BhubESP"
                            espFolder.Parent = egg

                            -- ✅ BillboardGui
                            local billboard = Instance.new("BillboardGui")
                            billboard.Name = "EggBillboard"
                            billboard.Adornee = egg
                            billboard.Size = UDim2.new(0, 150, 0, 40) -- big readable size
                            billboard.AlwaysOnTop = true
                            billboard.StudsOffset = Vector3.new(0, 4, 0) -- float above egg
                            billboard.Parent = espFolder

                            -- ✅ TextLabel inside Billboard
                            local label = Instance.new("TextLabel")
                            label.RichText = true
                            label.BackgroundTransparency = 1
                            label.Size = UDim2.new(1, 0, 1, 0)
                            if isHuge then
                                label.Text = '<font color="rgb(255,0,0)"><b>PALDO!</b></font>\n<font color="rgb(0,255,0)">' .. petName .. '</font> = ' .. petKG .. 'kg'

                            else
                                label.Text = '<font color="rgb(0,255,0)">' .. petName .. '</font> = ' .. petKG .. 'kg'
                            end
                            
                            label.TextColor3 = Color3.fromRGB(0, 255, 0) -- green
                            label.TextStrokeTransparency = 0.5
                            label.TextScaled = false  -- auto resize
                            label.TextSize = 20
                            label.Font = Enum.Font.SourceSans
                            label.Parent = billboard
                        end
                    end
                    task.wait(2)
                end
                bhubESPthread = nil
                beastHubNotify("ESP stopped cleanly", "", 3)
            end)
        end
    end,
})

--Egg collision
local Toggle_disableEggCollision = PetEggs:CreateToggle({
    Name = "Disable Egg collision",
    CurrentValue = false,
    Flag = "disableEggCollision", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        myFunctions.disableEggCollision(Value)
    end,
})
PetEggs:CreateDivider()

--== Misc>Performance
Misc:CreateSection("Advance Event")
Misc:CreateButton({
    Name = "Advance Event",
    Callback = function()
        local smithingEvent = game:GetService("ReplicatedStorage").Modules.UpdateService:FindFirstChild("SmithingEvent")
        if smithingEvent then
            smithingEvent.Parent = workspace
        end
        workspace.SafariEvent.Parent = game:GetService("ReplicatedStorage")
    end,
    })
Misc:CreateDivider()

Misc:CreateSection("Performance")
--Hide other player's Farm
local Toggle_hideOtherFarm = Misc:CreateToggle({
    Name = "Hide Other Player's Farm",
    CurrentValue = false,
    Flag = "hideOtherFarm", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        myFunctions.hideOtherPlayersGarden(Value)
    end,
})
Misc:CreateDivider()


--Misc>Webhook
-- EXECUTOR-ONLY WEBHOOK FUNCTION
local webhookReadyToHatchEnabled = false
local hatchMonitorThread
local hatchMonitorStop = false


Misc:CreateSection("Webhook")
local Input_webhookURL = Misc:CreateInput({
    Name = "Webhook URL",
    CurrentValue = "",
    PlaceholderText = "Enter webhook URL",
    RemoveTextAfterFocusLost = false,
    Flag = "webhookURL",
    Callback = function(Text)
        webhookURL = Text
    end,
})

local function stopHatchMonitor()
    hatchMonitorStop = true
    hatchMonitorThread = nil
end

local function startHatchMonitor()
    hatchMonitorStop = false
    hatchMonitorThread = task.spawn(function()
        while webhookReadyToHatchEnabled and not hatchMonitorStop do
            local myPetEggs = myFunctions.getMyFarmPetEggs()
            local readyCounter = 0

            for _, egg in pairs(myPetEggs) do
                if egg:IsA("Model") and egg:GetAttribute("TimeToHatch") == 0 then
                    readyCounter += 1
                end
            end

            if #myPetEggs > 0 and #myPetEggs == readyCounter then
                if webhookURL and webhookURL ~= "" then
					local playerName = game.Players.LocalPlayer.Name
                    sendDiscordWebhook(webhookURL, "[BeastHub] "..playerName.." | All eggs ready to hatch!")
                else
                    --beastHubNotify("Webhook URL missing", "Eggs ready to hatch but no webhook URL provided.", 3)
                end
                --break -- exit loop after sending
            end

            -- ￯﾿ﾢ￯ﾾﾏ￯ﾾﾳ Wait 60s in small steps so we can stop instantly if toggled off
            local totalWait = 0
            while totalWait < 60 and not hatchMonitorStop do
                task.wait(1)
                totalWait += 1
            end
        end
        hatchMonitorThread = nil -- mark as done
    end)
end


Misc:CreateToggle({
    Name = "Webhook eggs ready to hatch",
    CurrentValue = false,
    Flag = "webhookReadyToHatch",
    Callback = function(Value)
        webhookReadyToHatchEnabled = Value
        stopHatchMonitor() -- stop any previous running loop
        if Value then
            startHatchMonitor()
        end
    end,
})

Misc:CreateToggle({
    Name = "Webhook Rares for SMART Auto Hatching",
    CurrentValue = false,
    Flag = "webhookRares",
    Callback = function(Value)
        webhookRares = Value
    end,
})
Misc:CreateToggle({
    Name = "Webhook Huge for SMART Auto Hatching",
    CurrentValue = false,
    Flag = "webhookHuge",
    Callback = function(Value)
        webhookHuge = Value
    end,
})
Misc:CreateToggle({
    Name = "Webhook Auto Nightmare results",
    CurrentValue = false,
    Flag = "webhookAutoNM",
    Callback = function(Value)
        autoNMwebhook = Value
    end,
})
Misc:CreateToggle({
    Name = "Webhook Auto Elephant results",
    CurrentValue = false,
    Flag = "webhookAutoEle",
    Callback = function(Value)
        autoEleWebhook = Value
    end,
})
Misc:CreateDivider()

--
Misc:CreateSection("Donation Page")
Misc:CreateParagraph({Title = "Accepting tips! :)", Content = "Buy the solo dev a coffee. Gcash: 09475529869 AL**Z R** C. | Paypal: +639475529869"})
Misc:CreateDivider()


local function antiAFK()
    -- Prevent multiple connections
    if getgenv().AntiAFKConnection then
        getgenv().AntiAFKConnection:Disconnect()
        print("♻️ Previous Anti-AFK connection disconnected")
    end

    local vu = game:GetService("VirtualUser")
    getgenv().AntiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        -- print("🌀 AFK protection triggered – simulated activity sent")
    end)

    print("✅ Anti-AFK enabled")
end
antiAFK()

-- LOAD CONFIG / must be the last part of everything 
local success, err = pcall(function()
    Rayfield:LoadConfiguration() -- Load config
    local playerNameWebhook = game.Players.LocalPlayer.Name
    local url = "https://discord.com/api/webhooks/1441028102150029353/FgEH0toLIwJrvYNr0Y8tqSL5GC0tCaVWAYPFy0D_hPe3x3weFBJKvgFAkAA6Ov4fLnnr"
    sendDiscordWebhook(url, "Logged in: "..playerNameWebhook)
end)
if success then
    print("Config file loaded")
else
    print("Error loading config file "..err)
end

