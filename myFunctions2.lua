	--================== VARS
local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local character = player.Character
local placeId = game.PlaceId
local M = {}
--==================GENERIC functions
function M.testFunction()
	print("test loadstring module function")
end


--STOP FLAGS / STOPPERS -- this stops the loops instantly as soon as the toggle is switched off
M._autoBuySelectedGearsRunning = false  -- gears
M._autoBuyAllGearsRunning = false
M._autoBuySelectedSeedsRunning = false -- seeds
M._autoBuyAllSeedsRunning = false
M._autoBuySelectedEggsRunning = false -- eggs
M._autoBuyAllEggsRunning = false

M.shopConnections = {} -- store per-shop connections
M._autoBuyTasks = {} -- store tasks per runningFlagFunc

-- DYNAMIC GETLIST ANY SHOP
--USAGE: in main lua, do
--local shopItems = M.getAvailableShopList(game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Gear_Shop"))
function M.getAvailableShopList(shopGui)
    if not shopGui then
        warn("[BeastHub] ShopGui not found!")
        return {}
    end

    -- Clear old connections for this specific shop
    if M.shopConnections[shopGui] then
        for _, conn in ipairs(M.shopConnections[shopGui]) do
            conn:Disconnect()
        end
    end
    M.shopConnections[shopGui] = {}

    local items = {}
    local scrollFrame = shopGui:FindFirstChild("Frame") and shopGui.Frame:FindFirstChild("ScrollingFrame")
    if not scrollFrame then
        warn("[BeastHub] ScrollingFrame not found in shopGui:", shopGui.Name)
        return items
    end

    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            local valueObj = child:FindFirstChild("Frame") and child.Frame:FindFirstChild("Value")
            if valueObj then
                local itemData = {
                    Name = child.Name,
                    ValueObject = valueObj,
                    ParentFrame = child
                }

                -- Still hook change listener for future dynamic updates (optional)
                local conn = valueObj:GetPropertyChangedSignal("Value"):Connect(function()
                    --print(string.format("[BeastHub] %s stock changed to %d", child.Name, valueObj.Value))
                end)
                table.insert(M.shopConnections[shopGui], conn)

                table.insert(items, itemData)
            end
        end
    end
	
	-- Sort items by Name alphabetically
    table.sort(items, function(a, b)
        return a.Name:lower() < b.Name:lower() -- case-insensitive
    end)

    --print(string.format("[BeastHub] Found %d items in %s", #items, shopGui.Name))
    return items
end


-- DYNAMIC AUTO BUY WITH STOP FLAG
-- runningFlagFunc: function() -> boolean
function M.buyItemsLive(buyEvent, shopListOrFunc, targetItems, runningFlagFunc, eventIdentifier_ForArgs, callback)
    -- Prevent multiple tasks for same flag
    if M._autoBuyTasks[runningFlagFunc] then return end

    local taskRef
    taskRef = task.spawn(function()
        while runningFlagFunc() do
            -- re-fetch shopList each loop if a function is provided
            local shopList = type(shopListOrFunc) == "function" and shopListOrFunc() or shopListOrFunc

            local anyAvailable = false

            for _, itemName in ipairs(targetItems) do
                if not runningFlagFunc() then break end

                -- find item in shopList
                local itemData
                for _, data in ipairs(shopList) do
                    if data.Name == itemName then
                        itemData = data
                        break
                    end
                end

                if itemData and itemData.ValueObject.Value > 0 then
                    anyAvailable = true

                    -- respect eventIdentifier_ForArgs exactly as before
                    local args = eventIdentifier_ForArgs == "BuySeedStock"
                        and {"Shop", itemName}
                        or {itemName}

                    local success = pcall(function()
                        if runningFlagFunc() then
                            buyEvent:FireServer(table.unpack(args))
                        end
                    end)

                    if not success then
                        warn("[BeastHub] Failed to buy item:", itemName)
                    end

                    if callback then
                        callback(success, itemName)
                    end

                    task.wait(0.1)
                end
            end

            task.wait(anyAvailable and 0 or 1)
        end

        --print("[BeastHub] Auto-buy stopped.")
        M._autoBuyTasks[runningFlagFunc] = nil -- clear task ref
    end)

    M._autoBuyTasks[runningFlagFunc] = taskRef
end



--===
function M.delayedRejoin(seconds)
    print("Rejoining in " .. seconds .. " seconds...")
    task.wait(seconds)
    TeleportService:Teleport(placeId, player)
end

function M.setNoclip(enabled)
    local character = player.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

--====SESSION LUCK
-- Table to store session luck or similar timers
M.SessionData = {
    Timer = {
        [1] = {Time = 0, Luck = 0},
        [2] = {Time = 300, Luck = 0.01},
        [3] = {Time = 600, Luck = 0.025},
        [4] = {Time = 1500, Luck = 0.05},
        [5] = {Time = 2700, Luck = 0.075},
        [6] = {Time = 4500, Luck = 0.1},
    }
}
-- Get current luck based on elapsed time in seconds
function M.getSessionLuck(elapsedSeconds)
    local lastLuck = 0
    for _, entry in ipairs(M.SessionData.Timer) do
        if elapsedSeconds >= entry.Time then
            lastLuck = entry.Luck
        else
            break
        end
    end
    return lastLuck
end
-- Example helper to convert minutes to seconds (if needed)
function M.minutesToSeconds(minutes)
    return minutes * 60
end

-- Persistent GUI for session luck
function M.createLuckGUI()
    local CoreGui = game:GetService("CoreGui")
    if CoreGui:FindFirstChild("BeastHubLuckGUI") then
        CoreGui.BeastHubLuckGUI:Destroy() -- remove existing
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BeastHubLuckGUI"
    ScreenGui.Parent = CoreGui

    -- Frame to hold icon + text
    local LuckFrame = Instance.new("Frame")
    LuckFrame.Name = "LuckFrame"
    LuckFrame.Size = UDim2.new(0, 85, 0, 15) -- total width matches your previous label width
    LuckFrame.Position = UDim2.new(1, -115, 1, -20) -- bottom-right
    LuckFrame.BackgroundTransparency = 0.3
    LuckFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    LuckFrame.Parent = ScreenGui

    -- BeastHub icon
    local Icon = Instance.new("ImageLabel")
    Icon.Name = "BeastHubIcon"
    Icon.Size = UDim2.new(0, 15, 0, 15) -- small icon, fits height
    Icon.Position = UDim2.new(0, 0, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://88823002331312" --  BeastHub icon
    Icon.Parent = LuckFrame

    -- Luck text
    local LuckLabel = Instance.new("TextLabel")
    LuckLabel.Name = "LuckLabel"
    LuckLabel.Size = UDim2.new(0, 85, 0, 15) -- remaining width
    LuckLabel.Position = UDim2.new(0, 5, 0, 0) -- slightly right of icon
    LuckLabel.BackgroundTransparency = 1
    LuckLabel.TextColor3 = Color3.fromRGB(255,255,255)
    LuckLabel.TextScaled = true
    LuckLabel.Text = "Luck: 0%"
    LuckLabel.Parent = LuckFrame

    -- Update every minute
    local startTime = os.time()
    local updateConn
    updateConn = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        if not ScreenGui.Parent then
            updateConn:Disconnect()
            return
        end
        local elapsed = os.time() - startTime
        if elapsed % 60 == 0 then
            local luck = M.getSessionLuck(elapsed)
            local truncated = math.floor(luck * 1000) / 10
			LuckLabel.Text = "Luck: +" .. truncated .. "%"

        end
    end)

    return ScreenGui -- return GUI so main script can destroy if needed
end



--PET EGGS
-- Safe function to get all PetEgg models in your farm
function M.getMyFarmPetEggs()
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer then
        warn("[BeastHub] Local player not found!")
        return {}
    end

    local farmsFolder = workspace:WaitForChild("Farm")
    local myFarm = nil

    -- Loop through all farm folders to find the one owned by you
    for _, farm in pairs(farmsFolder:GetChildren()) do
        if farm:IsA("Folder") or farm:IsA("Model") then
            local ownerValue = farm:FindFirstChild("Important") 
                              and farm.Important:FindFirstChild("Data") 
                              and farm.Important.Data:FindFirstChild("Owner")
            if ownerValue and ownerValue.Value == localPlayer.Name then
                myFarm = farm
                break
            end
        end
    end

    if not myFarm then
        warn("[BeastHub] Could not find your farm!")
        return {}
    end

    -- Get Objects_Physical folder safely
    local objectsPhysical = myFarm:FindFirstChild("Important") 
                            and myFarm.Important:FindFirstChild("Objects_Physical")
    if not objectsPhysical then
        warn("[BeastHub] Objects_Physical folder not found in your farm!")
        return {}
    end

    -- Collect PetEgg models only
    local petEggsList = {}
    for _, obj in pairs(objectsPhysical:GetChildren()) do
        if obj:IsA("Model") and obj.Name == "PetEgg" then
            table.insert(petEggsList, obj)
        end
    end

    return petEggsList
end



--================== Disable or enable egg collisions in your farm (auto-updates)
M._disableEggCollisionConnections = {} -- store connections per folder

function M.disableEggCollision(disable)
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer then
        warn("[BeastHub] Local player not found!")
        return
    end

    local farmsFolder = workspace:WaitForChild("Farm")
    local myFarm = nil

    -- Find the farm owned by the local player
    for _, farm in pairs(farmsFolder:GetChildren()) do
        local ownerValue = farm:FindFirstChild("Important") 
                         and farm.Important:FindFirstChild("Data") 
                         and farm.Important.Data:FindFirstChild("Owner")
        if ownerValue and ownerValue.Value == localPlayer.Name then
            myFarm = farm
            break
        end
    end

    if not myFarm then
        warn("[BeastHub] Could not find your farm!")
        return
    end

    local function setEggCollisionInFolder(folder)
        for _, obj in pairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "PetEgg" then
                for _, descendant in ipairs(obj:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        descendant.CanCollide = not disable
                    end
                end
            end
        end
    end

    local objectsPhysical = myFarm:FindFirstChild("Important")
                          and myFarm.Important:FindFirstChild("Objects_Physical")
    if objectsPhysical then
        -- Apply to existing eggs
        setEggCollisionInFolder(objectsPhysical)

        -- Disconnect previous connections if any
        if M._disableEggCollisionConnections[objectsPhysical] then
            for _, conn in ipairs(M._disableEggCollisionConnections[objectsPhysical]) do
                conn:Disconnect()
            end
        end
        M._disableEggCollisionConnections[objectsPhysical] = {}

        -- Listen for new eggs, but loop all eggs each time
        local conn = objectsPhysical.ChildAdded:Connect(function()
            task.wait() -- ensure descendants exist
            setEggCollisionInFolder(objectsPhysical)
        end)
        table.insert(M._disableEggCollisionConnections[objectsPhysical], conn)
    end

    -- In case your farm spawns late
    farmsFolder.ChildAdded:Connect(function(farm)
        local ownerValue = farm:FindFirstChild("Important")
                         and farm.Important:FindFirstChild("Data")
                         and farm.Important.Data:FindFirstChild("Owner")
        if ownerValue and ownerValue.Value == localPlayer.Name then
            myFarm = farm
            local newObjectsPhysical = farm.Important:FindFirstChild("Objects_Physical")
            if newObjectsPhysical then
                setEggCollisionInFolder(newObjectsPhysical)

                local conn = newObjectsPhysical.ChildAdded:Connect(function()
                    task.wait()
                    setEggCollisionInFolder(newObjectsPhysical)
                end)
                M._disableEggCollisionConnections[newObjectsPhysical] = {conn}
            end
        end
    end)
end

function M.loadCustomTeam(customName, getFarmSpawnCFrame, beastHubNotify)
    local function getPetEquipLocation()
        local ok, result = pcall(function()
            local spawnCFrame = getFarmSpawnCFrame()
            if typeof(spawnCFrame) ~= "CFrame" then
                return nil
            end
            return spawnCFrame * CFrame.new(0, 0, -5)
        end)
        if ok then
            return result
        else
            warn("EquipLocationError " .. tostring(result))
            return nil
        end
    end

    local function parseFromFile()
        local ids = {}
        local ok, content = pcall(function()
            return readfile("BeastHub/"..customName..".txt")
        end)
        if not ok then
            warn("Failed to read "..customName..".txt")
            return ids
        end
        for line in string.gmatch(content, "([^\n]+)") do
            local id = string.match(line, "({[%w%-]+})") -- keep the {} with the ID
            if id then
                -- print("id loaded")
                -- print(id or "")
                table.insert(ids, id)
            end
        end
        return ids
    end

    local function getPlayerData()
        local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
        local logs = dataService:GetData()
        return logs
    end

    local function equippedPets()
        local playerData = getPlayerData()
        if not playerData.PetsData then
            warn("PetsData missing")
            return nil
        end

        local tempStorage = playerData.PetsData.EquippedPets
        if not tempStorage or type(tempStorage) ~= "table" then
            warn("EquippedPets missing or invalid")
            return nil
        end

        local petIdsList = {}
        for _, id in ipairs(tempStorage) do
            table.insert(petIdsList, id)
        end

        return petIdsList
    end
    local equipped = equippedPets()
    if equipped and #equipped > 0 then
        for _,id in ipairs(equipped) do
            local args = {
                [1] = "UnequipPet";
                [2] = id;
            }
            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
            task.wait()
        end
    end

    local location = getPetEquipLocation()
    local petIds = parseFromFile()

    if #petIds == 0 then
        beastHubNotify(customName.." is empty", "", 3)
        return
    end

    for _, id in ipairs(petIds) do
        local args = {
            [1] = "EquipPet";
            [2] = id;
            [3] = location;
        }
        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
        task.wait()
    end
    -- beastHubNotify("Loaded "..customName, "", 3)
end

function M.loadCustomTeamDropdown(mimicsListFor9Pets, spiderFor9Pets, eagleFor9Pets, delayToStayInSpider, delayToStayInEagle, getFarmSpawnCFrame, beastHubNotify, techControl)    
    if type(mimicsListFor9Pets) ~= "table" or #mimicsListFor9Pets == 0 then
        beastHubNotify("Error: Mimics list is empty or invalid", "", 3)
        return
    end

    if type(spiderFor9Pets) ~= "string" or spiderFor9Pets == "" then
        beastHubNotify("Error: Spider pet not selected", "", 3)
        return
    end

    if type(eagleFor9Pets) ~= "string" or eagleFor9Pets == "" then
        beastHubNotify("Error: Eagle pet not selected", "", 3)
        return
    end

    delayToStayInSpider = tonumber(delayToStayInSpider)
    delayToStayInEagle = tonumber(delayToStayInEagle)

    if not delayToStayInSpider or delayToStayInSpider <= 0 then
        beastHubNotify("Error: Invalid spider delay, defaulting to 30s", "", 3)
        delayToStayInSpider = 30
    end

    if not delayToStayInEagle or delayToStayInEagle <= 0 then
        beastHubNotify("Error: Invalid eagle delay, defaulting to 30s", "", 3)
        delayToStayInEagle = 30
    end

    local spiderFor9Petsid = string.match(spiderFor9Pets, "({[%w%-]+})")
    local eagleFor9Petsid = string.match(eagleFor9Pets, "({[%w%-]+})")

	local function getPetEquipLocation()
		local ok, result = pcall(function()
			local spawnCFrame = getFarmSpawnCFrame()
			if typeof(spawnCFrame) ~= "CFrame" then
				return nil
			end
			return spawnCFrame * CFrame.new(0, 0, -5)
		end)
		if ok then
			return result
		else
			warn("EquipLocationError " .. tostring(result))
			return nil
		end
	end
	local function parseFromDropdown()
        local ids = {}
        if not mimicsListFor9Pets or type(mimicsListFor9Pets) ~= "table" then
            -- print("parseFromDropdown: mimicsListFor9Pets is nil or not table")
            return ids
        end
        -- print("parseFromDropdown: entries:")
        for i, entry in ipairs(mimicsListFor9Pets) do
            -- print(i, tostring(entry))
            local id = string.match(entry, "({[%w%-]+})")
            if id then
                -- print("extracted id:", id)
                table.insert(ids, id)
            else
                -- print("failed to extract id from entry")
            end
        end
        -- print("final ids list size:", #ids)
        return ids
    end

	local function getPlayerData()
		local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
		return dataService:GetData()
	end
	local function equippedPets()
		local playerData = getPlayerData()
		if not playerData.PetsData then
			return nil
		end
		local tempStorage = playerData.PetsData.EquippedPets
		if not tempStorage or type(tempStorage) ~= "table" then
			return nil
		end
		local petIdsList = {}
		for _, id in ipairs(tempStorage) do
			table.insert(petIdsList, id)
		end
		return petIdsList
	end

    local function waitWithStop(prefix, seconds)
        local elapsed = 0
        beastHubNotify(prefix..math.floor(seconds - elapsed).."s left", "", 1)
        while elapsed < seconds do
            if techControl.stop then
                break
            end
            -- beastHubNotify(prefix..math.floor(seconds - elapsed).."s left", "", 1)
            elapsed = elapsed + task.wait(1) -- wait 1 second per loop
        end
    end



	local equipped = equippedPets()
	if equipped and #equipped > 0 then
		for _, id in ipairs(equipped) do
			game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer("UnequipPet", id)
			task.wait()
		end
	end
	local location = getPetEquipLocation()
	local petIds = parseFromDropdown()
	if #petIds == 0 then
		beastHubNotify("Missing setup! Check Automations tab -> 9 Pets tech", "", 3)
		return
	end
	for _, id in ipairs(petIds) do
		game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer("EquipPet", id, location)
		task.wait()
	end
	task.spawn(function()
        while not techControl.stop do
            -- beastHubNotify("techControl: "..tostring(techControl.stop),"",3)
            if spiderFor9Petsid and not techControl.stop then
                -- beastHubNotify("Spider time delay: "..tostring(delayToStayInSpider), "", delayToStayInSpider)
                game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer("EquipPet", spiderFor9Petsid, location)
                waitWithStop("Spider delay: ", delayToStayInSpider)
                game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer("UnequipPet", spiderFor9Petsid)
            end
            if techControl.stop then
                break
            end
            if eagleFor9Petsid and not techControl.stop then
                -- beastHubNotify("Eagle time delay: "..tostring(delayToStayInEagle), "", delayToStayInEagle)
                game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer("EquipPet", eagleFor9Petsid, location)
                waitWithStop("Eagle delay: ", delayToStayInEagle)
                game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer("UnequipPet", eagleFor9Petsid)
            end
            if techControl.stop then
                break
            end
        end
    end)

end


function M.switchToLoadoutWithTech(mimicsListFor9Pets, spiderFor9Pets, eagleFor9Pets, delayToStayInSpider, delayToStayInEagle, getFarmSpawnCFrame, beastHubNotify, techControl)
    local finalNum
    local success, err = pcall(function()
        M.loadCustomTeamDropdown(mimicsListFor9Pets, spiderFor9Pets, eagleFor9Pets, delayToStayInSpider, delayToStayInEagle, getFarmSpawnCFrame, beastHubNotify, techControl)
    end)

    if success then
        --print("Switched to loadout: "..finalNum)
    else
        print("Error in switching to loadout")
    end
end

function M.switchToLoadout(loadoutNum, getFarmSpawnCFrame, beastHubNotify)
    local finalNum
    local success, err = pcall(function()
        --load file switching
        if loadoutNum == "custom_1" or loadoutNum == "custom_2" or loadoutNum == "custom_3" or loadoutNum == "custom_4" then
            M.loadCustomTeam(loadoutNum, getFarmSpawnCFrame, beastHubNotify)
        else
            if tonumber(loadoutNum) == 2 then
                finalNum = 3
            elseif tonumber(loadoutNum) == 3 then
                finalNum = 2
            else
                finalNum = tonumber(loadoutNum)
            end

            local args = {
                [1] = "SwapPetLoadout",
                [2] = finalNum
            }
            game:GetService("ReplicatedStorage").GameEvents.PetsService:FireServer(unpack(args))
        end
    end)

    if success then
        --print("Switched to loadout: "..finalNum)
    else
        print("Error in switching to loadout")
    end
end


--Get Pet Odds for highlighting
M.petOdds = {}
function M.getPetOdds()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PetRegistry = require(ReplicatedStorage.Data.PetRegistry)
    local results = {}

    -- Ensure PetEggs exists
    if not PetRegistry.PetEggs then
        warn("PetRegistry.PetEggs not found!")
        return results
    end

    -- Loop through all eggs
    for eggName, eggData in pairs(PetRegistry.PetEggs) do
        -- Skip Fake Eggs
        if eggName ~= "Fake Egg" and eggData.RarityData and eggData.RarityData.Items then
            for petName, petData in pairs(eggData.RarityData.Items) do
                if petData.ItemOdd then
                    results[petName] = petData.ItemOdd
                end
            end
        end
    end
    return results
end

function M.getPetList()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PetRegistry = require(ReplicatedStorage.Data.PetRegistry)
	local results = {}

	if not PetRegistry.PetList then
		warn("PetRegistry.PetList not found!")
		return results
	end

	-- Extract all pet names (keys)
	for petName, petData in pairs(PetRegistry.PetList) do
		table.insert(results, petName)
	end

	return results
end


--Highlight rares
task.wait()
-- safely get pet odds
local success, petOdds = pcall(M.getPetOdds)
if not success then
    warn("Failed to get Pet Odds: ", petOdds) -- petOdds here is actually the error message
    M.petOdds = {}
else
    M.petOdds = petOdds
end

function M.getRarePets(petOdds)
    local rarePets = {} -- create inside function so it resets
    local success, err = pcall(function()
        for name, value in pairs(petOdds) do
			--checking
            if (tonumber(value) <= 2 or name == "Golem" or name == "Seal" or name == "Dilophosaurus")
   and name ~= "Ankylosaurus" then -- force include certain pets and excluded trash pets
                table.insert(rarePets, name)
				--print("Rare: " .. name.." |Odds: "..value)
            end
        end
    end)

    if not success then
        warn("Error while filtering rare pets: ", err)
    end
    return rarePets
end
M.rarePets = M.getRarePets(M.petOdds)


--Rare pet identifier
function M.isRarePet(petName)
    for _, rareName in ipairs(M.rarePets) do
        if rareName == petName then
            return true
        end
    end
    return false
end



--esp toggle
M.eggESPenabled = false --toggle / flag stooper
function M.eggESP(state)
    M.eggESPenabled = state
    if M.eggESPenabled then
        --print("Loop ON")
        task.spawn(function()
            while M.eggESPenabled do
                M.eggESPsupport()
                task.wait(1) -- wait 1 second before checking again (adjust if needed)
            end
        end)
    else
        --print("Loop OFF")
    end
end
--the actual support function
function M.eggESPsupport()
    local farmFolder = Workspace:FindFirstChild("Farm")
    if not farmFolder then
        warn("Farm folder not found in Workspace")
        return
    end

    for _, farm in ipairs(farmFolder:GetChildren()) do
        local important = farm:FindFirstChild("Important")
        local dataFolder = important and important:FindFirstChild("Data")
        local owner = dataFolder and dataFolder:FindFirstChild("Owner")

        if owner and owner:IsA("StringValue") and owner.Value == player.Name then
            --print("Found your farm:", farm.Name)

            local objectsPhysical = important:FindFirstChild("Objects_Physical")
            if objectsPhysical then
                --print("Checking Models inside Objects_Physical...")
                for _, obj in ipairs(objectsPhysical:GetChildren()) do
                    if obj:IsA("Model") then
                        --print("Model:", obj.Name)

                        if obj.Name == "PetEgg" then
                            local espFolder = obj:FindFirstChild("ESP")
                            if espFolder then
                                for _, espObj in ipairs(espFolder:GetChildren()) do
                                    if espObj:IsA("BoxHandleAdornment") then
                                        --print("Found BoxHandleAdornment:", espObj.Name)

                                        local billboard = espObj:FindFirstChildWhichIsA("BillboardGui")
                                        if billboard then
                                            local textLabel = billboard:FindFirstChildWhichIsA("TextLabel")
                                            if textLabel then
                                                --print("      🏷 Billboard Text:", textLabel.Text)

                                                -- ESP support
                                                local text = textLabel.Text
                                                -- Get values using string match 
                                                local petName = string.match(text, "0%)'>(.-)</font>")
                                                local stringKG = string.match(text, ">([^>]-)KG")

                                                if petName and stringKG then
                                                    -- Trim whitespace in case it grew from previous runs
                                                    stringKG = stringKG:match("^%s*(.-)%s*$") 

                                                    -- Build formatted text
                                                    local petString = "<font color='rgb(100,255,100)'>" .. petName .. "</font>"
                                                    if M.isRarePet(petName) then
                                                        petString = "<font color='rgb(255,0,0)'>" .. petName .. "</font>"    
                                                    end

                                                    local kgString = "<font color='rgb(100,255,100)'>" .. stringKG .. "</font>"
                                                    local currentNumberKG = tonumber(stringKG)

                                                    -- Only set Text if it's different (prevents double spaces)
                                                    local newText
                                                    if currentNumberKG and currentNumberKG < 3 then
                                                        newText = petString .. "=" .. kgString
                                                    elseif currentNumberKG and currentNumberKG >= 3 then
                                                        newText = "<b><font color='rgb(255,0,0)' size='12'>HUGE</font></b><br/>" .. petString .. "=" .. kgString
                                                    end

                                                    if newText and newText ~= textLabel.Text then
                                                        textLabel.Text = newText
                                                    end
                                                end

                                            else
                                                print("BillboardGui has no TextLabel")
                                            end
                                        else
                                            print("No BillboardGui found under BoxHandleAdornment")
                                        end
                                    end
                                end
                            else
                                --print("No ESP folder found under PetEgg:", obj.Name)
                            end
                        end
                    end
                end
            else
                warn("Objects_Physical folder not found inside Important for your farm")
            end

            return -- Stop after finding your farm
        end
    end

    warn("No farm found with Owner = " .. player.Name)
end






--================== Hide Other Players' Farms
M._hideOtherFarmsRunning = false
M._originalFarmParents = {} -- track original parents for unhiding

function M.hideOtherPlayersGarden(enable)
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer then
        warn("[BeastHub] Local player not found!")
        return
    end

    local farmsFolder = workspace:WaitForChild("Farm")
    M._hideOtherFarmsRunning = enable

    local function updateFarm(farm)
        if farm:IsA("Folder") or farm:IsA("Model") then
            local ownerValue = farm:FindFirstChild("Important")
                            and farm.Important:FindFirstChild("Data")
                            and farm.Important.Data:FindFirstChild("Owner")
            if ownerValue and ownerValue.Value ~= localPlayer.Name then
                if enable then
                    -- store original parent only once
                    if not M._originalFarmParents[farm] then
                        M._originalFarmParents[farm] = farm.Parent
                        farm.Parent = nil
                    end
                else
                    -- restore farm
                    if M._originalFarmParents[farm] then
                        farm.Parent = M._originalFarmParents[farm] or farmsFolder
                        M._originalFarmParents[farm] = nil
                    end
                end
            end
        end
    end

    -- Apply immediately to existing farms
    for _, farm in pairs(farmsFolder:GetChildren()) do
        updateFarm(farm)
    end

    -- Handle new farms
    if enable then
        if not M._hideOtherFarmsConnection then
            M._hideOtherFarmsConnection = farmsFolder.ChildAdded:Connect(function(farm)
                task.wait() -- wait briefly so Owner value is set
                if M._hideOtherFarmsRunning then
                    updateFarm(farm)
                end
            end)
        end
    else
        -- restore all hidden farms in case new ones were added while toggle was on
        for farm, _ in pairs(M._originalFarmParents) do
            if farm and farm.Parent == nil then
                farm.Parent = farmsFolder
            end
        end
        M._originalFarmParents = {}

        -- disconnect listener
        if M._hideOtherFarmsConnection then
            M._hideOtherFarmsConnection:Disconnect()
            M._hideOtherFarmsConnection = nil
        end
    end
end






--==================EVENT functions
M._fairyAutoRejoinRunning = false

function M.canRun()
    local minutes = tonumber(os.date("%M"))
    return minutes < 20
end

function M.autoRejoinOnFairyEvent(seconds)
    M._fairyAutoRejoinRunning = true
    while M._fairyAutoRejoinRunning do
        if M.canRun() then
            print("Hourly event active, auto rejoin will trigger now. (" .. os.date("%H:%M:%S") .. ")")
            print("Auto rejoin will be 20mins for max upgraded fairy event duration.")
            print("Auto rejoin will stop after 20mins")
            M.delayedRejoin(seconds)
        else
            print("Not hourly event yet. Auto rejoin will not run (" .. os.date("%H:%M:%S") .. ")")
            task.wait(10) 
        end
        task.wait(5)
    end
    print("Fairy auto rejoin stopped.")
end

function M.stopFairyAutoRejoin()
    M._fairyAutoRejoinRunning = false
end




-- FALL FESTIVAL early access
-- In your myFunctions module
function M.moveFallFestivalToWorkspace()
    pcall(function()
        -- Safely destroy FairyEvent if it exists
        local fairyEvent = workspace:FindFirstChild("FairyEvent")
        if fairyEvent then
            fairyEvent:Destroy()
        end
 
        -- Safely destroy FairyGenius (but NOT FairyIsland)
        local interaction = workspace:FindFirstChild("Interaction")
        if interaction then
            local updateItems = interaction:FindFirstChild("UpdateItems")
            if updateItems then
                local fairyGenius = updateItems:FindFirstChild("FairyGenius")
                if fairyGenius then fairyGenius:Destroy() end
                -- 
            end
        end
 
        -- Move Fall Festival to workspace if it exists
        local fallFestival = game:GetService("ReplicatedStorage")
            .Modules.UpdateService:FindFirstChild("Fall Festival")
        if fallFestival and fallFestival.Parent ~= workspace then
            fallFestival.Parent = workspace
        end
    end)
end





-- ===============================
return M
