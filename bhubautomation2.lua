local M = {}

M.isSafeToPickPlace = true

function M.init(Rayfield, beastHubNotify, Window, myFunctions, beastHubIcon, equipItemByName, equipItemByNameV2, getMyFarm, getFarmSpawnCFrame, getAllPetNames, sendDiscordWebhook, allSeedsData, allSeedsOnly, equipFruitById)
    local Automation = Window:CreateTab("Automation", "bot")
    
    
    --Cancel Animation
    Automation:CreateSection("Cancel READY Animation (Quick Cast)")
    local parag_cancelAnim = Automation:CreateParagraph({
        Title = "Pickup/Place:",
        Content = "None"
    })
    local dropdown_selectPetsForCancelAnim = Automation:CreateDropdown({
        Name = "Select Pet/s",
        Options = {},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectPetsForCancelAnim", 
        Callback = function(Options)
            local listText = table.concat(Options, ", ")
            if listText == "" then
                listText = "None"
            end

            parag_cancelAnim:Set({
                Title = "Pickup/Place:",
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
                dropdown_selectPetsForCancelAnim:Refresh(namesToId)
            else
                beastHubNotify("equipped pets error", "", 3)
            end
        end,
    })
    Automation:CreateButton({
        Name = "Clear Selected",
        Callback = function()
            dropdown_selectPetsForCancelAnim:Set({})
            parag_cancelAnim:Set({
                Title = "Pickup/Place:",
                Content = "None"
            })
        end,
    })
    local animation_cancelDelay = Automation:CreateInput({
        Name = "Animation Cancel delay",
        CurrentValue = "",
        PlaceholderText = "seconds",
        RemoveTextAfterFocusLost = false,
        Flag = "animationCancelDelay",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })

    local cancelAnimationEnabled
    local cancelAnimationThread = nil
    local cooldownListenerCancelAnim = nil
    local petCooldownsCancelAnim = {}
    Automation:CreateToggle({
        Name = "Cancel Animation",
        CurrentValue = false,
        Flag = "cancelAnimation",
        Callback = function(Value)
            cancelAnimationEnabled = Value

            if cancelAnimationEnabled then
                if cancelAnimationThread then return end
                -- Hook PetCooldownsUpdated
                cooldownListenerCancelAnim = game:GetService("ReplicatedStorage").GameEvents.PetCooldownsUpdated.OnClientEvent:Connect(function(petId, data)
                    if typeof(data) == "table" and data[1] and data[1].Time then
                        petCooldownsCancelAnim[petId] = data[1].Time
                    else
                        petCooldownsCancelAnim[petId] = 0
                    end
                end)

                -- Validate setup
                local pickupList, animDelay, t = {}, tonumber(animation_cancelDelay.CurrentValue), 0
                while t < 3 do
                    pickupList = dropdown_selectPetsForCancelAnim.CurrentOption or {}
                    animDelay = tonumber(animation_cancelDelay.CurrentValue)
                    if #pickupList > 0 then
                        if not animDelay then
                            beastHubNotify("Invalid delay/cd input", "", 3)
                            return
                        end
                        break
                    end
                    task.wait(0.5)
                    t = t + 0.5
                end
                if #pickupList == 0 then
                    beastHubNotify("Missing setup, please select pets", "", 3)
                    return
                end

                -- Equip function
                local function equipPetByUuid(uuid)
                    local player = game.Players.LocalPlayer
                    local backpack = player:WaitForChild("Backpack")
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:GetAttribute("PET_UUID") == uuid then
                            player.Character.Humanoid:EquipTool(tool)
                        end
                    end
                end

                local function isEquipped(uuid)
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

                    local equippedPets = equippedPets()
                    if equippedPets then
                        for _,id in ipairs(equippedPets) do
                            if id == uuid then
                                return true
                            end
                        end
                    end

                    return false
                end

                local function isPetInWorkspace(petId)
                    local petsFolder = workspace:FindFirstChild("PetsPhysical")
                    if not petsFolder then return false end

                    for _, pet in ipairs(petsFolder:GetChildren()) do
                        if pet:GetAttribute("UUID") == petId then
                            return true
                        end
                    end

                    return false
                end


                
                beastHubNotify("Cancel animation running", "", 3)
                local location = CFrame.new(getFarmSpawnCFrame():PointToWorldSpace(Vector3.new(8,0,-50)))

                -- Main auto pickup thread
                local activeCancelTasks = {}
                cancelAnimationThread = task.spawn(function()
                    while cancelAnimationEnabled do
                        if M.isSafeToPickPlace then
                            pickupList = dropdown_selectPetsForCancelAnim.CurrentOption or {}
                            for _, pickupEntry in ipairs(pickupList) do
                                if not cancelAnimationEnabled then break end
                                local petId = (pickupEntry:match("^[^|]+|%s*(.+)$") or ""):match("^%s*(.-)%s*$")
                                if not activeCancelTasks[petId] then
                                    local timeLeft = petCooldownsCancelAnim[petId] or 0
                                    if timeLeft == 0 and isEquipped(petId) then
                                        activeCancelTasks[petId] = true
                                        task.spawn(function()
                                            task.wait(animDelay)
                                            if cancelAnimationEnabled and M.isSafeToPickPlace and isPetInWorkspace(petId) then
                                                game:GetService("ReplicatedStorage").GameEvents.PetsService:FireServer("UnequipPet", petId)
                                                task.wait(0.05)
                                                equipPetByUuid(petId)
                                                task.wait(0.05)
                                                game:GetService("ReplicatedStorage").GameEvents.PetsService:FireServer("EquipPet", petId, location)
                                            else
                                                -- print("not in workspace: "..petId)
                                            end
                                            activeCancelTasks[petId] = nil
                                        end)
                                    end
                                end
                            end
                        end
                        task.wait(0.05)
                    end
                    cancelAnimationThread = nil
                end)

            else
                -- Disable
                if cooldownListenerCancelAnim then
                    cooldownListenerCancelAnim:Disconnect()
                    cooldownListenerCancelAnim = nil
                end
                cancelAnimationEnabled = false
                cancelAnimationThread = nil
            end
        end
    })
    Automation:CreateDivider()




    --Auto pick & place
    Automation:CreateSection("Auto Pick then place Middle (Force Domino)")
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
                Title = "Pickup:",
                Content = "None"
            })
        end,
    })
    
    --when ready
    Automation:CreateDivider()
    local parag_petsToMonitor = Automation:CreateParagraph({
        Title = "When ready:",
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
                Title = "When ready:",
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
                Title = "When ready:",
                Content = "None"
            })
        end,
    })

    local when_petCDis = Automation:CreateInput({
        Name = "When pet cooldown is",
        CurrentValue = "",
        PlaceholderText = "seconds",
        RemoveTextAfterFocusLost = false,
        Flag = "whenPetCDis",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })

    local nextPickup_delay = Automation:CreateInput({
        Name = "Delay for next Pickup",
        CurrentValue = "",
        PlaceholderText = "seconds",
        RemoveTextAfterFocusLost = false,
        Flag = "nextPickupDelay",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })

    -- Auto PickUp toggle variables
    local autoPickupEnabled = false
    local autoPickupThread = nil
    local cancelAnimationThread = nil
    local cooldownListener = nil
    local petCooldowns = {}
    
    Automation:CreateToggle({
        Name = "Auto Pick & Place",
        CurrentValue = false,
        Flag = "autoPickup",
        Callback = function(Value)
            autoPickupEnabled = Value

            if autoPickupEnabled then
                if autoPickupThread then return end

                -- Hook PetCooldownsUpdated
                cooldownListener = game:GetService("ReplicatedStorage").GameEvents.PetCooldownsUpdated.OnClientEvent:Connect(function(petId, data)
                    if typeof(data) == "table" and data[1] and data[1].Time then
                        petCooldowns[petId] = data[1].Time
                    else
                        petCooldowns[petId] = 0
                    end
                end)

                -- Validate setup
                local pickupList, monitorList, delayForNextPickup, whenPetCdIs, t = {}, {}, tonumber(nextPickup_delay.CurrentValue), tonumber(when_petCDis.CurrentValue), 0
                while t < 3 do
                    pickupList = dropdown_selectPetsForPickup.CurrentOption or {}
                    monitorList = dropdown_selectPetsForMonitor.CurrentOption or {}
                    delayForNextPickup = tonumber(nextPickup_delay.CurrentValue)
                    whenPetCdIs = tonumber(when_petCDis.CurrentValue)
                    if #pickupList > 0 and #monitorList > 0 then
                        if not delayForNextPickup or not whenPetCdIs then
                            beastHubNotify("Invalid delay/cd input", "", 3)
                            return
                        end
                        break
                    end
                    task.wait(0.5)
                    t = t + 0.5

                end
                if #pickupList == 0 or #monitorList == 0 then
                    beastHubNotify("Missing setup, please select pets to pick and place", "", 3)
                    return
                end

                -- Equip function
                local function equipPetByUuid(uuid)
                    local player = game.Players.LocalPlayer
                    local backpack = player:WaitForChild("Backpack")
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:GetAttribute("PET_UUID") == uuid then
                            player.Character.Humanoid:EquipTool(tool)
                        end
                    end
                end

                local function isEquipped(uuid)
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

                    local equippedPets = equippedPets()
                    if equippedPets then
                        for _,id in ipairs(equippedPets) do
                            if id == uuid then
                                return true
                            end
                        end
                    end
                    return false
                end
                
                beastHubNotify("Auto Pick/place running", "", 3)
                local location = CFrame.new(getFarmSpawnCFrame():PointToWorldSpace(Vector3.new(8,0,-50)))

                -- Main auto pickup thread
                autoPickupThread = task.spawn(function()
                    local justCasted = false
                    while autoPickupEnabled do
                        if M.isSafeToPickPlace then
                            for _, monitorEntry in ipairs(monitorList) do
                                if not autoPickupEnabled or justCasted then
                                    task.wait(delayForNextPickup)
                                    justCasted = false
                                    break
                                end

                                local curMonitorPetId = (monitorEntry:match("^[^|]+|%s*(.+)$") or ""):match("^%s*(.-)%s*$")
                                local timeLeft = petCooldowns[curMonitorPetId] or 0
                                -- beastHubNotify("timeLeft: "..timeLeft, "",1)
                                if (timeLeft == whenPetCdIs or timeLeft == (whenPetCdIs-1) or timeLeft == 0) and not justCasted and M.isSafeToPickPlace then
                                    -- beastHubNotify("timeLeft TRUE: "..timeLeft, "",1)
                                    for _, pickupEntry in ipairs(pickupList) do
                                        if not autoPickupEnabled then break end
                                        local curPickupPetId = (pickupEntry:match("^[^|]+|%s*(.+)$") or ""):match("^%s*(.-)%s*$")
                                        local isCurPicked = false

                                        if M.isSafeToPickPlace and isEquipped(curPickupPetId) then
                                            -- Unequip pet
                                            -- beastHubNotify("Picking up!","",1)
                                            isCurPicked = true
                                            game:GetService("ReplicatedStorage").GameEvents.PetsService:FireServer("UnequipPet", curPickupPetId)
                                            task.wait()
                                            -- Equip to hand
                                            equipPetByUuid(curPickupPetId)
                                            task.wait()
                                            -- Equip to farm
                                            game:GetService("ReplicatedStorage").GameEvents.PetsService:FireServer("EquipPet", curPickupPetId, location)
                                            task.wait()
                                        end
                                        
                                        -- task.wait(.5)
                                        -- task.wait(delayForNextPickup+0.5)
                                        -- if M.isSafeToPickPlace and isCurPicked then
                                        --     --for the monitoring pet
                                        --     game:GetService("ReplicatedStorage").GameEvents.PetsService:FireServer("UnequipPet", curMonitorPetId)
                                        --     task.wait()
                                        --     equipPetByUuid(curMonitorPetId)
                                        --     task.wait()
                                        --     game:GetService("ReplicatedStorage").GameEvents.PetsService:FireServer("EquipPet", curMonitorPetId, location)
                                        --     task.wait()
                                        -- end

                                        -- task.wait(delayForNextPickup)
                                        justCasted = true

                                    end
                                end
                                task.wait(.25)
                            end
                        end
                        
                        task.wait(0.1)
                    end

                    autoPickupThread = nil
                end)
            else
                -- Disable
                if cooldownListener then
                    cooldownListener:Disconnect()
                    cooldownListener = nil
                end
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
                beastHubNotify("Auto pet boost running", "", 3)
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

    --Auto feed
    Automation:CreateSection("Auto Feed")
    local parag_petsToFeed = Automation:CreateParagraph({
        Title = "Pet/s to feed:",
        Content = "None"
    })
    local dropdown_selectPetsForFeed = Automation:CreateDropdown({
        Name = "Select Pet/s",
        Options = {},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectPetsForFeed", 
        Callback = function(Options)
            local listText = table.concat(Options, ", ")
            if listText == "" then
                listText = "None"
            end

            parag_petsToFeed:Set({
                Title = "Pet/s to feed:",
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
                dropdown_selectPetsForFeed:Refresh(namesToId)
            else
                beastHubNotify("equipped pets error", "", 3)
            end
        end,
    })

    Automation:CreateButton({
        Name = "Clear Selected",
        Callback = function()
            dropdown_selectPetsForFeed:Set({})
            parag_petsToFeed:Set({
                Title = "Pet/s to feed:",
                Content = "None"
            })
        end,
    })
    
    local input_autoFeedPercentage = Automation:CreateInput({
        Name = "Auto feed when Hunger % is:",
        CurrentValue = "25",
        PlaceholderText = "number",
        RemoveTextAfterFocusLost = false,
        Flag = "autoFeedPercentage",
        Callback = function(Text)
        end,
    })

    local input_autoFeedUntilPercentage = Automation:CreateInput({
        Name = "Auto feed until % is:",
        CurrentValue = "100",
        PlaceholderText = "number",
        RemoveTextAfterFocusLost = false,
        Flag = "autoFeedUntilPercentage",
        Callback = function(Text)
        end,
    })

    local selectedFruitsForAutoFeed
    local dropdown_selectedFruitForAutoFeed = Automation:CreateDropdown({
        Name = "Select Fruit",
        Options = allSeedsOnly,
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectedFruit_autoFeed", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
        Callback = function(Options)
            selectedFruitsForAutoFeed = Options
        end,
    })
    local searchDebounce_seedForFeed = nil
    Automation:CreateInput({
        Name = "Search fruit",
        PlaceholderText = "fruit",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            if searchDebounce_seedForFeed then
                task.cancel(searchDebounce_seedForFeed)
            end
            searchDebounce_seedForFeed = task.delay(0.5, function()
                local results = {}
                local query = string.lower(Text)

                if query == "" then
                    results = allSeedsOnly
                else
                    for _, fruitName in ipairs(allSeedsOnly) do
                        if string.find(string.lower(fruitName), query, 1, true) then
                            table.insert(results, fruitName)
                        end
                    end
                end
                dropdown_selectedFruitForAutoFeed:Refresh(results)
                dropdown_selectedFruitForAutoFeed:Set(selectedFruitsForAutoFeed) --set to current selected

            end)
        end,
    })
    Automation:CreateButton({
        Name = "Clear fruit",
        Callback = function()
            dropdown_selectedFruitForAutoFeed:Set({})
        end,
    })

    local autoPetFeedEnabled = false
    local autoPetFeedThread = nil

    Automation:CreateToggle({
        Name = "Auto Feed",
        CurrentValue = false,
        Flag = "autoFeed",
        Callback = function(Value)
            autoPetFeedEnabled = Value

            if autoPetFeedEnabled then
                if autoPetFeedThread then
                    return
                end

                beastHubNotify("Auto pet feed running", "", 3)

                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local function getPlayerData()
                    local dataService = require(ReplicatedStorage.Modules.DataService)
                    return dataService:GetData()
                end

                local okRegistry, PetRegistry = pcall(function()
                    return require(ReplicatedStorage.Data.PetRegistry.PetList)
                end)

                if not okRegistry or type(PetRegistry) ~= "table" then
                    warn("AutoFeed: failed to load PetRegistry")
                    return
                end

                local petDefaultHunger = {}
                for petName, data in pairs(PetRegistry) do
                    if type(data) == "table" and data.DefaultHunger then
                        petDefaultHunger[petName] = data.DefaultHunger
                    end
                end

                autoPetFeedThread = task.spawn(function()
                    local function getPetHungerPercent(petId)
                        local playerData = getPlayerData()
                        if not playerData then return nil end

                        local petInventory = playerData
                            and playerData.PetsData
                            and playerData.PetsData.PetInventory
                            and playerData.PetsData.PetInventory.Data

                        if not petInventory then return nil end

                        for id, data in pairs(petInventory) do
                            if tostring(id) == tostring(petId) then
                                if not data.PetData or not data.PetData.Hunger or not data.PetType then
                                    return nil
                                end

                                local defaultHunger = petDefaultHunger[data.PetType]
                                if not defaultHunger then
                                    return nil
                                end

                                return (data.PetData.Hunger / defaultHunger) * 100
                            end
                        end

                        return nil
                    end

                    local function getFeedFruitUid(playerData, selectedFruits)
                        if not playerData or not playerData.InventoryData then
                            return nil
                        end

                        for uid, item in pairs(playerData.InventoryData) do
                            if item.ItemType == "Holdable" then
                                local itemData = item.ItemData
                                if itemData and not itemData.IsFavorite then
                                    if table.find(selectedFruits, itemData.ItemName) then
                                        return uid
                                    end
                                end
                            end
                        end

                        return nil
                    end

                    while autoPetFeedEnabled do
                        local petList = dropdown_selectPetsForFeed and dropdown_selectPetsForFeed.CurrentOption or {}
                        local fruitList = dropdown_selectedFruitForAutoFeed and dropdown_selectedFruitForAutoFeed.CurrentOption or {}
                        local hungerLimit = tonumber((input_autoFeedPercentage.CurrentValue or ""):match("%d+"))
                        local targetHunger = tonumber((input_autoFeedUntilPercentage.CurrentValue or ""):match("%d+")) or 100

                        if targetHunger >= 100 then
                            targetHunger = 99
                        end

                        if not hungerLimit or hungerLimit <= 0 or hungerLimit >= 100 then
                            task.wait(1)
                            continue
                        end

                        if #petList == 0 or #fruitList == 0 then
                            task.wait(1)
                            continue
                        end

                        local playerData = getPlayerData()
                        if not playerData then
                            task.wait(1)
                            continue
                        end

                        for _, pet in ipairs(petList) do
                            if not autoPetFeedEnabled then
                                break
                            end

                            local petId = (pet:match("^[^|]+|%s*(.+)$") or ""):match("^%s*(.-)%s*$")
                            if petId == "" then
                                continue
                            end

                            local hungerPercent = getPetHungerPercent(petId)
                            if not hungerPercent then
                                continue
                            end

                            if hungerPercent <= hungerLimit then
                                while hungerPercent < targetHunger and autoPetFeedEnabled do
                                    local fruitUid = getFeedFruitUid(playerData, fruitList)
                                    if fruitUid then
                                        equipFruitById(fruitUid)
                                        task.wait()
                                        ReplicatedStorage.GameEvents.ActivePetService:FireServer("Feed", petId)
                                        task.wait(0.2)
                                    else
                                        break
                                    end
                                    hungerPercent = getPetHungerPercent(petId)
                                end
                            end
                        end

                        task.wait(2)
                    end

                    autoPetFeedThread = nil
                end)
            else
                autoPetFeedEnabled = false
                autoPetFeedThread = nil
                beastHubNotify("Auto pet feed disabled", "", 3)
            end
        end,
    })








    Automation:CreateDivider()


    --auto sprink
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

                beastHubNotify("Auto sprinkler running", "", 3)
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

    Automation:CreateSection("Static loadout switching (NOT FOR AUTO HATCHING)")
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

                beastHubNotify("Static switcher running", "", 3)
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
end

return M
