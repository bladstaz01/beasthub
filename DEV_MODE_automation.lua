local M = {}

M.isSafeToPickPlace = true

function M.init(Rayfield, beastHubNotify, Window, myFunctions, beastHubIcon, equipItemByName, equipItemByNameV2, getMyFarm, getFarmSpawnCFrame, getAllPetNames, sendDiscordWebhook)
    local Automation = Window:CreateTab("Automation", "bot")
    
    --Auto pick & place
    Automation:CreateSection("Auto Pick & Place")
    local parag_petsToPickup = Automation:CreateParagraph({
        Title = "Pickup:",
        Content = "None"
    })
    local dropdown_selectPetsForPickup = Automation:CreateDropdown({
        Name = "Select Pet/s",
        Options = {},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectPetsForPickUp", 
        Callback = function(Options)
            local listText = table.concat(Options, ", ")
            if listText == "" then
                listText = "None"
            end

            parag_petsToPickup:Set({
                Title = "Pickup:",
                Content = listText
            })
        end,

    })
    Automation:CreateButton({
        Name = "Refresh list",
        Callback = function()
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

            local function getPetNameUsingId(uid)
                local playerData = getPlayerData()
                if playerData.PetsData.PetInventory.Data then
                    local data = playerData.PetsData.PetInventory.Data
                    for id,petData in pairs(data) do
                        if id == uid then
                            return petData.PetType.." > "..petData.PetData.Name.." > "..string.format("%.2f", petData.PetData.BaseWeight * 1.1).."kg"
                        end
                    end
                end
            end

            local equipped = equippedPets()
            local namesToId = {}
            for _,id in ipairs(equipped) do
                local petName = getPetNameUsingId(id)
                table.insert(namesToId, petName.." | "..id)
            end

            if equipped and #equipped > 0 then
                dropdown_selectPetsForPickup:Refresh(namesToId)
            else
                beastHubNotify("equipped pets error", "", 3)
            end
        end,
    })
    Automation:CreateButton({
        Name = "Clear Selected",
        Callback = function()
            dropdown_selectPetsForPickup:Set({})
            parag_petsToPickup:Set({
                Title = "Pet/s to Pickup:",
                Content = "None"
            })
        end,
    })

    --when ready
    Automation:CreateDivider()
    local parag_petsToMonitor = Automation:CreateParagraph({
        Title = "When Ready:",
        Content = "None"
    })
    local dropdown_selectPetsForMonitor = Automation:CreateDropdown({
        Name = "Select Pet/s",
        Options = {},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectPetsForPickMonitor", 
        Callback = function(Options)
            local listText = table.concat(Options, ", ")
            if listText == "" then
                listText = "None"
            end

            parag_petsToMonitor:Set({
                Title = "When Ready:",
                Content = listText
            })
        end,

    })
    Automation:CreateButton({
        Name = "Refresh list",
        Callback = function()
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

            local function getPetNameUsingId(uid)
                local playerData = getPlayerData()
                if playerData.PetsData.PetInventory.Data then
                    local data = playerData.PetsData.PetInventory.Data
                    for id,petData in pairs(data) do
                        if id == uid then
                            return petData.PetType.." > "..petData.PetData.Name.." > "..string.format("%.2f", petData.PetData.BaseWeight * 1.1).."kg"
                        end
                    end
                end
            end

            local equipped = equippedPets()
            local namesToId = {}
            for _,id in ipairs(equipped) do
                local petName = getPetNameUsingId(id)
                table.insert(namesToId, petName.." | "..id)
            end

            if equipped and #equipped > 0 then
                dropdown_selectPetsForMonitor:Refresh(namesToId)
            else
                beastHubNotify("equipped pets error", "", 3)
            end
        end,
    })
    Automation:CreateButton({
        Name = "Clear Selected",
        Callback = function()
            dropdown_selectPetsForMonitor:Set({})
            parag_petsToMonitor:Set({
                Title = "Pet/s to Monitor:",
                Content = "None"
            })
        end,
    })

    -- Auto PickUp toggle variables
    local autoPickupEnabled = false
    local autoPickupThread = nil
    Automation:CreateToggle({
        Name = "Auto Pick Up",
        CurrentValue = false,
        Flag = "autoPickup",
        Callback = function(Value)
            autoPickupEnabled = Value

            if autoPickupEnabled then
                if autoPickupThread then
                    return
                end

                local function GetAnimationIndexFromUUID(targetUUID)
                    local modulePath = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("PetServices"):WaitForChild("ActivePetsService")

                    local service
                    local ok, res = pcall(function()
                        return require(modulePath)
                    end)
                    if not ok then
                        warn("ActivePetsService require failed")
                        return
                    end
                    service = res

                    local clientState = service.ClientPetState
                    if not clientState then
                        warn("ClientPetState missing")
                        return
                    end

                    local foundState = nil
                    for ownerName, pets in pairs(clientState) do
                        for uuid, petState in pairs(pets) do
                            if tostring(uuid) == targetUUID then
                                foundState = petState
                                break
                            end
                        end
                        if foundState then
                            break
                        end
                    end

                    if not foundState then
                        print("UUID not found:", targetUUID)
                        return
                    end

                    if not foundState.CurrentAnimation then
                        print("No CurrentAnimation found")
                        return
                    end

                    local currentAnim = foundState.CurrentAnimation
                    local loaded = foundState.LoadedAnimations
                    if not loaded or type(loaded) ~= "table" then
                        print("No LoadedAnimations table")
                        return
                    end

                    local index = 0
                    local position = nil

                    for animName, animObj in pairs(loaded) do
                        index = index + 1
                        if animObj == currentAnim then
                            position = index
                            break
                        end
                    end

                    if position then
                        -- print("Current animation index:", position)
                        -- beastHubNotify("Current animation index: "..tostring(position) or "", "", 3)
                    else
                        -- print("Current animation not found in LoadedAnimations")
                    end

                    return position
                end

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

                local function equipPetByUuid(uuid)
                    local player = game.Players.LocalPlayer
                    local backpack = player:WaitForChild("Backpack")
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:GetAttribute("PET_UUID") == uuid then
                            player.Character.Humanoid:EquipTool(tool)
                        end
                    end
                end

                -- local location = getPetEquipLocation()
                local spawnCFrame = getFarmSpawnCFrame()
                local offset = Vector3.new(8,0,-50)
                local dropPos = spawnCFrame:PointToWorldSpace(offset)
                local location = CFrame.new(dropPos)

                local pickupList, monitorList, t = {}, {}, 0
                while t < 3 do
                    pickupList = dropdown_selectPetsForPickup and dropdown_selectPetsForPickup.CurrentOption or {}
                    monitorList = dropdown_selectPetsForMonitor and dropdown_selectPetsForMonitor.CurrentOption or {}
                    if #pickupList > 0 and #monitorList > 0 then break end
                    task.wait(0.5)
                    t += 0.5
                end
                if #pickupList == 0 or #monitorList == 0 then
                    beastHubNotify("Missing Setup, please select pets to pick and place", "", 3)
                    return
                end


                autoPickupThread = task.spawn(function()
                    local sessionFirstCast = true
                    
                    while autoPickupEnabled and M.isSafeToPickPlace do
                        for _, monitorEntry in ipairs(monitorList) do
                            if not autoPickupEnabled then
                                break
                            end

                            local curMonitorPetId = (monitorEntry:match("^[^|]+|%s*(.+)$") or ""):match("^%s*(.-)%s*$")
                            local animIndex = GetAnimationIndexFromUUID(curMonitorPetId)
                        
                            --if ready
                            if animIndex == 1 and sessionFirstCast then
                                sessionFirstCast = false
                                --pickup loop here
                                print("pet ready detected!")
                                for _, pickupEntry in ipairs(pickupList) do
                                    if not autoPickupEnabled then
                                        break
                                    end
                                    local curPickupPetId = (pickupEntry:match("^[^|]+|%s*(.+)$") or ""):match("^%s*(.-)%s*$")
                                    --UnequipPet
                                    beastHubNotify("Picking up pet", "", 2)
                                    local args = {
                                        [1] = "UnequipPet";
                                        [2] = curPickupPetId;
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args))
                                    task.wait()
                                    --equip to hand
                                    -- beastHubNotify("Equipping pet", "", 1)
                                    equipPetByUuid(curPickupPetId)
                                    --equip to farm
                                    beastHubNotify("Placing pet", "", 2)
                                    local args2 = {
                                        [1] = "EquipPet";
                                        [2] = curPickupPetId;
                                        [3] = location;
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetsService", 9e9):FireServer(unpack(args2))
                                    beastHubNotify("Pet placed","", 2)
                                    task.wait()
                                end
                            else
                                sessionFirstCast = true
                            end
                            

                            task.wait(0.001)
                        end

                        task.wait(0.001)
                    end

                    autoPickupThread = nil
                end)
            else
                autoPickupEnabled = false
                autoPickupThread = nil
            end
        end
    })
    Automation:CreateDivider()
    



    --Auto Pet boost
    Automation:CreateSection("Auto Pet Boost")
    -- --select pet
    local parag_petsToBoost = Automation:CreateParagraph({
        Title = "Pet/s to boost:",
        Content = "None"
    })
    local dropdown_selectPetsForPetBoost = Automation:CreateDropdown({
        Name = "Select Pet/s",
        Options = {},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectPetsForPetBoost", 
        Callback = function(Options)
            local listText = table.concat(Options, ", ")
            if listText == "" then
                listText = "None"
            end

            parag_petsToBoost:Set({
                Title = "Pet/s to boost:",
                Content = listText
            })
        end,

    })

    Automation:CreateButton({
        Name = "Refresh list",
        Callback = function()
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

            local function getPetNameUsingId(uid)
                local playerData = getPlayerData()
                if playerData.PetsData.PetInventory.Data then
                    local data = playerData.PetsData.PetInventory.Data
                    for id,petData in pairs(data) do
                        if id == uid then
                            return petData.PetType.." > "..petData.PetData.Name.." > "..string.format("%.2f", petData.PetData.BaseWeight * 1.1).."kg"
                        end
                    end
                end
            end

            local equipped = equippedPets()
            local namesToId = {}
            for _,id in ipairs(equipped) do
                local petName = getPetNameUsingId(id)
                table.insert(namesToId, petName.." | "..id)
            end

            if equipped and #equipped > 0 then
                dropdown_selectPetsForPetBoost:Refresh(namesToId)
            else
                beastHubNotify("equipped pets error", "", 3)
            end
        end,
    })

    Automation:CreateButton({
        Name = "Clear Selected",
        Callback = function()
            dropdown_selectPetsForPetBoost:Set({})
            parag_petsToBoost:Set({
                Title = "Pet/s to boost:",
                Content = "None"
            })
        end,
    })

    -- --select toy
    local dropdown_selectedToys = Automation:CreateDropdown({
        Name = "Select Toy/s",
        Options = {"Small Pet Toy", "Medium Pet Toy", "Large Pet Toy"},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectToysForPetBoost", 
        Callback = function(Options)
        -- The function that takes place when the selected option is changed
        -- The variable (Options) is a table of strings for the current selected options
        end,
    })

    local autoPetBoostEnabled = false
    local autoPetBoostThread = nil
    Automation:CreateToggle({
        Name = "Auto Boost",
        CurrentValue = false,
        Flag = "autoBoost",
        Callback = function(Value)
            autoPetBoostEnabled = Value

            if autoPetBoostEnabled then
                if autoPetBoostThread then
                    return
                end

                autoPetBoostThread = task.spawn(function()
                    local function checkBoostTimeLeft(toyName, petId) 
                        local toyToBoostAmount = {
                            ["Small Pet Toy"] = 0.1,
                            ["Medium Pet Toy"] = 0.2,
                            ["Large Pet Toy"] = 0.3
                        }

                        local function getPlayerData()
                            local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                            local logs = dataService:GetData()
                            return logs
                        end
                        
                        local playerData = getPlayerData()
                        local petData = playerData.PetsData.PetInventory.Data
                        for id, data in pairs(petData) do
                            if tostring(id) == tostring(petId) then
                                if data.PetData and data.PetData.Boosts then
                                --have boost, check if matching
                                    local boosts = data.PetData.Boosts
                                    for _,boost in ipairs(boosts) do
                                        local boostType = boost.BoostType
                                        local boostAmount = boost.BoostAmount
                                        local boostTime = boost.Time

                                        if boostType == "PASSIVE_BOOST" then
                                            if toyToBoostAmount[toyName] == boostAmount then
                                                return boostTime
                                            end
                                        end
                                    end
                                    return 0
                                else
                                    return 0
                                end
                            end
                        end
                    end 

                    while autoPetBoostEnabled do
                        local petList = dropdown_selectPetsForPetBoost and dropdown_selectPetsForPetBoost.CurrentOption or {}
                        local toyList = dropdown_selectedToys and dropdown_selectedToys.CurrentOption or {}

                        if #petList == 0 or #toyList == 0 then
                            task.wait(1)
                            continue
                        end

                        
                        for _, pet in ipairs(petList) do
                            for _, toy in ipairs(toyList) do
                                if not autoPetBoostEnabled then
                                    break
                                end

                                local petId = (pet:match("^[^|]+|%s*(.+)$") or ""):match("^%s*(.-)%s*$")
                                local toyName = toy
                                
                                --check if already boosted
                                local timeLeft = checkBoostTimeLeft(toyName, petId)

                                --boost only if good to boost
                                -- beastHubNotify("timeLeft: "..tostring(timeLeft), "", "1")
                                if timeLeft <= 0 then
                                    -- print("inside if")
                                    --equip boost
                                    if equipItemByName(toyName) then
                                        task.wait(.1)
                                        --boost
                                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                                        local PetBoostService = ReplicatedStorage.GameEvents.PetBoostService -- RemoteEvent 
                                        PetBoostService:FireServer(
                                            "ApplyBoost",
                                            petId
                                        )
                                    else
                                        -- print("not good to boost")
                                    end
                                    
                                end
                                task.wait(0.2)
                            end
                            if not autoPetBoostEnabled then
                                break
                            end
                        end

                        task.wait(2)
                    end

                    autoPetBoostThread = nil
                end)
            else
                autoPetBoostEnabled = false
                autoPetBoostThread = nil
            end
        end,
    })
    Automation:CreateDivider()


    Automation:CreateSection("Auto Sprinkler")
    local parag_sprinklers = Automation:CreateParagraph({Title="Sprinklers",Content="None"})

    local dropdown_sprinks = Automation:CreateDropdown({
        Name = "Select Sprinkler/s",
        Options = {"Basic Sprinkler","Advanced Sprinkler","Godly Sprinkler","Master Sprinkler","Grandmaster Sprinkler"},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectSprinklerList",
        Callback = function(Options)
            if #Options == 0 then
                parag_sprinklers:Set({Title = "Sprinklers", Content = "None"})
            else
                parag_sprinklers:Set({Title = "Sprinklers", Content = table.concat(Options, ", ")})
            end
        end,
    })

    local dropdown_sprinklerLocation = Automation:CreateDropdown({
        Name="Target Location",
        Options={"Middle"},
        CurrentOption={"Middle"},
        MultipleOptions=false,
        Flag="autoSprinklerLocation",
        Callback=function(Options)
        end
    })

    local autoSprinklerEnabled=false
    local autoSprinklerThread=nil

    Automation:CreateToggle({
        Name = "Auto Sprinkler",
        CurrentValue = false,
        Flag = "autoSprinkler",
        Callback = function(Value)
            autoSprinklerEnabled = Value
            if autoSprinklerEnabled then
                if autoSprinklerThread then
                    return
                end

                local sprinklerDuration = {
                    ["Basic Sprinkler"] = 300,
                    ["Advanced Sprinkler"] = 300,
                    ["Godly Sprinkler"] = 300,
                    ["Master Sprinkler"] = 600,
                    ["Grandmaster Sprinkler"] = 600
                }

                local activeSprinklerThreads = {}

                autoSprinklerThread = task.spawn(function()
                    while autoSprinklerEnabled do
                        local selectedSprinklers = dropdown_sprinks.CurrentOption

                        if not selectedSprinklers or #selectedSprinklers == 0 or selectedSprinklers[1] == "None" then
                            task.wait(1)
                            continue
                        end

                        for _, sprinkName in ipairs(selectedSprinklers) do
                            if autoSprinklerEnabled and not activeSprinklerThreads[sprinkName] then
                                activeSprinklerThreads[sprinkName] = task.spawn(function()
                                    local duration = sprinklerDuration[sprinkName] or 300

                                    while autoSprinklerEnabled do
                                        local spawnCFrame = getFarmSpawnCFrame()
                                        local offset = Vector3.new(8,0,-50)
                                        local dropPos = spawnCFrame:PointToWorldSpace(offset)
                                        local finalCF = CFrame.new(dropPos)

                                        equipItemByName(sprinkName)
                                        task.wait(.1)
                                        local args = {
                                            [1] = "Create",
                                            [2] = finalCF
                                        }

                                        game:GetService("ReplicatedStorage").GameEvents.SprinklerService:FireServer(unpack(args))

                                        task.wait(duration)
                                    end

                                    activeSprinklerThreads[sprinkName] = nil
                                end)
                                task.wait(.5)
                            end
                        end

                        task.wait(1)
                    end

                    for name, thread in pairs(activeSprinklerThreads) do
                        activeSprinklerThreads[name] = nil
                    end

                    autoSprinklerThread = nil
                end)

            else
                autoSprinklerEnabled = false
                autoSprinklerThread = nil
            end
        end,
    })
    Automation:CreateDivider()



    Automation:CreateSection("Custom Loadouts")

    Automation:CreateDivider()
    M.customLoadout1 = Automation:CreateParagraph({Title = "Custom 1:", Content = "None"})
    Automation:CreateButton({
        Name = "Set current Team as Custom 1",
        Callback = function()
            local saveFolder = "BeastHub"
            local saveFile = saveFolder.."/custom_1.txt"
            if not isfolder(saveFolder) then
                makefolder(saveFolder)
            end
            local function getPlayerData()
                local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                local logs = dataService:GetData()
                return logs
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
            local function getPetNameUsingId(uid)
                local playerData = getPlayerData()
                if playerData.PetsData.PetInventory.Data then
                    local data = playerData.PetsData.PetInventory.Data
                    for id, petData in pairs(data) do
                        if id == uid then
                            return petData.PetType.." > "..petData.PetData.Name.." > "..string.format("%.2f", petData.PetData.BaseWeight * 1.1).."kg"
                        end
                    end
                end
            end
            local equipped = equippedPets()
            local petsString = ""
            if equipped then
                for _, id in ipairs(equipped) do
                    local petName = getPetNameUsingId(id)
                    petsString = petsString..petName..">"..id.."|\n"
                end
            end
            if equipped and #equipped > 0 then
                M.customLoadout1:Set({Title = "Custom 1:", Content = petsString})
                writefile(saveFile, petsString)
                beastHubNotify("Saved Custom 1!", "", 3)
            else
                beastHubNotify("No pets equipped", "", 3)
            end
        end
    })
    Automation:CreateButton({
        Name = "Load Custom 1",
        Callback = function()
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
                    return readfile("BeastHub/custom_1.txt")
                end)
                if not ok then
                    warn("Failed to read custom_1.txt")
                    return ids
                end
                for line in string.gmatch(content, "([^\n]+)") do
                    local id = string.match(line, "({[%w%-]+})") -- keep the {} with the ID
                    if id then
                        print("id loaded")
                        print(id or "")
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
            if #equipped > 0 then
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
                beastHubNotify("Custom 1 is empty", "", 3)
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

            beastHubNotify("Loaded Custom 1", "", 3)
        end
    })


    Automation:CreateDivider()
    M.customLoadout2 = Automation:CreateParagraph({Title = "Custom 2:", Content = "None"})
    Automation:CreateButton({
        Name = "Set current Team as Custom 2",
        Callback = function()
            local saveFolder = "BeastHub"
            local saveFile = saveFolder.."/custom_2.txt"
            if not isfolder(saveFolder) then
                makefolder(saveFolder)
            end
            local function getPlayerData()
                local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                local logs = dataService:GetData()
                return logs
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
            local function getPetNameUsingId(uid)
                local playerData = getPlayerData()
                if playerData.PetsData.PetInventory.Data then
                    local data = playerData.PetsData.PetInventory.Data
                    for id, petData in pairs(data) do
                        if id == uid then
                            return petData.PetType.." > "..petData.PetData.Name.." > "..string.format("%.2f", petData.PetData.BaseWeight * 1.1).."kg"
                        end
                    end
                end
            end
            local equipped = equippedPets()
            local petsString = ""
            if equipped then
                for _, id in ipairs(equipped) do
                    local petName = getPetNameUsingId(id)
                    petsString = petsString..petName..">"..id.."|\n"
                end
            end
            if equipped and #equipped > 0 then
                M.customLoadout2:Set({Title = "Custom 2:", Content = petsString})
                writefile(saveFile, petsString)
                beastHubNotify("Saved Custom 2!", "", 3)
            else
                beastHubNotify("No pets equipped", "", 3)
            end
        end
    })
    Automation:CreateButton({
        Name = "Load Custom 2",
        Callback = function()
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
                    return readfile("BeastHub/custom_2.txt")
                end)
                if not ok then
                    warn("Failed to read custom_2.txt")
                    return ids
                end
                for line in string.gmatch(content, "([^\n]+)") do
                    local id = string.match(line, "({[%w%-]+})")
                    if id then
                        print("id loaded")
                        print(id or "")
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
            if #equipped > 0 then
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
                beastHubNotify("Custom 2 is empty", "", 3)
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

            beastHubNotify("Loaded Custom 2", "", 3)
        end
    })
    Automation:CreateDivider()


    M.customLoadout3 = Automation:CreateParagraph({Title = "Custom 3:", Content = "None"})
    Automation:CreateButton({
        Name = "Set current Team as Custom 3",
        Callback = function()
            local saveFolder = "BeastHub"
            local saveFile = saveFolder.."/custom_3.txt"
            if not isfolder(saveFolder) then
                makefolder(saveFolder)
            end
            local function getPlayerData()
                local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                local logs = dataService:GetData()
                return logs
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
            local function getPetNameUsingId(uid)
                local playerData = getPlayerData()
                if playerData.PetsData.PetInventory.Data then
                    local data = playerData.PetsData.PetInventory.Data
                    for id, petData in pairs(data) do
                        if id == uid then
                            return petData.PetType.." > "..petData.PetData.Name.." > "..string.format("%.2f", petData.PetData.BaseWeight * 1.1).."kg"
                        end
                    end
                end
            end
            local equipped = equippedPets()
            local petsString = ""
            if equipped then
                for _, id in ipairs(equipped) do
                    local petName = getPetNameUsingId(id)
                    petsString = petsString..petName..">"..id.."|\n"
                end
            end
            if equipped and #equipped > 0 then
                M.customLoadout3:Set({Title = "Custom 3:", Content = petsString})
                writefile(saveFile, petsString)
                beastHubNotify("Saved Custom 3!", "", 3)
            else
                beastHubNotify("No pets equipped", "", 3)
            end
        end
    })
    Automation:CreateButton({
        Name = "Load Custom 3",
        Callback = function()
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
                    return readfile("BeastHub/custom_3.txt")
                end)
                if not ok then
                    warn("Failed to read custom_3.txt")
                    return ids
                end
                for line in string.gmatch(content, "([^\n]+)") do
                    local id = string.match(line, "({[%w%-]+})")
                    if id then
                        print("id loaded")
                        print(id or "")
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
            if #equipped > 0 then
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
                beastHubNotify("Custom 3 is empty", "", 3)
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

            beastHubNotify("Loaded Custom 3", "", 3)
        end
    })
    Automation:CreateDivider()

    M.customLoadout4 = Automation:CreateParagraph({Title = "Custom 4:", Content = "None"})
    Automation:CreateButton({
        Name = "Set current Team as Custom 4",
        Callback = function()
            local saveFolder = "BeastHub"
            local saveFile = saveFolder.."/custom_4.txt"
            if not isfolder(saveFolder) then
                makefolder(saveFolder)
            end

            local function getPlayerData()
                local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                local logs = dataService:GetData()
                return logs
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

            local function getPetNameUsingId(uid)
                local playerData = getPlayerData()
                if playerData.PetsData.PetInventory.Data then
                    local data = playerData.PetsData.PetInventory.Data
                    for id, petData in pairs(data) do
                        if id == uid then
                            return petData.PetType.." > "..petData.PetData.Name.." > "..string.format("%.2f", petData.PetData.BaseWeight * 1.1).."kg"
                        end
                    end
                end
            end

            local equipped = equippedPets()
            local petsString = ""
            if equipped then
                for _, id in ipairs(equipped) do
                    local petName = getPetNameUsingId(id)
                    petsString = petsString..petName..">"..id.."|\n"
                end
            end

            if equipped and #equipped > 0 then
                M.customLoadout4:Set({Title = "Custom 4:", Content = petsString})
                writefile(saveFile, petsString)
                beastHubNotify("Saved Custom 4!", "", 3)
            else
                beastHubNotify("No pets equipped", "", 3)
            end
        end
    })

    Automation:CreateButton({
        Name = "Load Custom 4",
        Callback = function()
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
                    return readfile("BeastHub/custom_4.txt")
                end)
                if not ok then
                    warn("Failed to read custom_4.txt")
                    return ids
                end
                for line in string.gmatch(content, "([^\n]+)") do
                    local id = string.match(line, "({[%w%-]+})")
                    if id then
                        print("id loaded")
                        print(id or "")
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
            if #equipped > 0 then
                for _, id in ipairs(equipped) do
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
                beastHubNotify("Custom 4 is empty", "", 3)
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

            beastHubNotify("Loaded Custom 4", "", 3)
        end
    })
    Automation:CreateDivider()

    Automation:CreateSection("Auto Loadout Switcher (NOT FOR AUTO HATCHING)")
    local switcher1 = Automation:CreateDropdown({
        Name = "First loadout",
        Options = {"1", "2", "3", "4", "5", "6", "custom_1","custom_2","custom_3","custom_4"},
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "firstLoadoutAutoSwitch", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
        Callback = function(Options)
        -- The function that takes place when the selected option is changed
        -- The variable (Options) is a table of strings for the current selected options
        end,
    })
    local switcher1_delay = Automation:CreateInput({
        Name = "First loadout duration",
        CurrentValue = "",
        PlaceholderText = "seconds",
        RemoveTextAfterFocusLost = false,
        Flag = "firstLoadoutAutoSwitchDuration",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })
    local switcher2 = Automation:CreateDropdown({
        Name = "Second loadout",
        Options = {"1", "2", "3", "4", "5", "6", "custom_1","custom_2","custom_3","custom_4"},
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "secondLoadoutAutoSwitch", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
        Callback = function(Options)
        -- The function that takes place when the selected option is changed
        -- The variable (Options) is a table of strings for the current selected options
        end,
    })
    local switcher2_delay = Automation:CreateInput({
        Name = "Second loadout duration",
        CurrentValue = "",
        PlaceholderText = "seconds",
        RemoveTextAfterFocusLost = false,
        Flag = "secondLoadoutAutoSwitchDuration",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })

    local autoSwitchEnabled = false
    local autoSwitcherThread = nil
    Automation:CreateToggle({
        Name = "Auto Loadout Switcher",
        CurrentValue = false,
        Flag = "autoLoadoutSwitcher",
        Callback = function(Value)
            autoSwitchEnabled = Value

            -- validate dropdowns
            local loadout1 = switcher1.CurrentOption[1]
            local loadout2 = switcher2.CurrentOption[1]

            if autoSwitchEnabled then
                if not loadout1 or loadout1 == "" then
                    beastHubNotify("Missing first loadout selection", "", "1")
                    autoSwitchEnabled = false
                    return
                end

                if not loadout2 or loadout2 == "" then
                    beastHubNotify("Missing second loadout selection", "", "1")
                    autoSwitchEnabled = false
                    return
                end

                -- validate durations
                local delay1 = tonumber(switcher1_delay.CurrentValue)
                local delay2 = tonumber(switcher2_delay.CurrentValue)

                if not delay1 or delay1 <= 0 then
                    beastHubNotify("Invalid first loadout duration", "", "1")
                    autoSwitchEnabled = false
                    return
                end

                if not delay2 or delay2 <= 0 then
                    beastHubNotify("Invalid second loadout duration", "", "1")
                    autoSwitchEnabled = false
                    return
                end

                if autoSwitcherThread then
                    return
                end

                autoSwitcherThread = task.spawn(function()
                    while autoSwitchEnabled do
                        myFunctions.switchToLoadout(loadout1, getFarmSpawnCFrame, beastHubNotify)
                        task.wait(delay1)

                        myFunctions.switchToLoadout(loadout2, getFarmSpawnCFrame, beastHubNotify)
                        task.wait(delay2)
                    end

                    autoSwitcherThread = nil
                end)
            else
                autoSwitchEnabled = false
                autoSwitcherThread = nil
            end
        end,
    })


    Automation:CreateDivider()



    -- Automation:CreateButton({
    --    Name = "Button Example",
    --    Callback = function()
    --    -- The function that takes place when the button is pressed
    --    end,
    -- })

    -- Automation:CreateButton({
    --    Name = "Button Example",
    --    Callback = function()
    --    -- The function that takes place when the button is pressed
    --    end,
    -- })
    -- Automation:CreateDivider()
end


return M
