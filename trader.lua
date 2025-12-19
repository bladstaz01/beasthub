local M = {}


function M.init(Rayfield, beastHubNotify, Window, myFunctions, beastHubIcon, equipItemByName, equipItemByNameV2, getMyFarm, getFarmSpawnCFrame, getAllPetNames, sendDiscordWebhook)
    local Trader = Window:CreateTab("Trader", "handshake")
    Trader:CreateSection("Farmers Market- Create Listing")
    local Paragraph_selectedPetsForCreateListing = Trader:CreateParagraph({Title = "Pets:", Content = "None"})
    
    local selectedPetsForCreateListing = {}
    local allPetList = getAllPetNames()
    local Dropdown_petListCreateListing = Trader:CreateDropdown({
        Name = "Select Pets",
        Options = allPetList,
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "selectPetsForCreateListing", 
        Callback = function(Options)
            selectedPetsForCreateListing = Options
            local names = table.concat(Options, ", ")
            if names == "" then
                names = "None"
            end
            Paragraph_selectedPetsForCreateListing:Set({
                Title = "Pets",
                Content = names
            })    
        end,
    })

    --search pets
    local searchDebounceCreateListing = nil
    Trader:CreateInput({
        Name = "Search",
        PlaceholderText = "Search Pet...",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            if searchDebounceCreateListing then
                task.cancel(searchDebounceCreateListing)
            end

            searchDebounceCreateListing = task.delay(0.5, function()
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

                Dropdown_petListCreateListing:Refresh(results)
                Dropdown_petListCreateListing:Set(selectedPetsForCreateListing)
            end)
        end,
    })

    Trader:CreateButton({
        Name = "Clear selection",
        Callback = function()
            Dropdown_petListCreateListing:Set({}) --Clear selection properly
            selectedPetsForCreateListing = {}
        end,
    })

    local listBelow
    local Dropdown_sellBelowKG = Trader:CreateDropdown({
        Name = "List Below (KG)",
        Options = {"1","2","3"},
        CurrentOption = {"3"},
        MultipleOptions = false,
        Flag = "listBelowKG", 
        Callback = function(Options)
            --if not Options or not Options[1] then return end
            listBelow = tonumber(Options[1])
        end,
    })

    local input_tokenPrice = Trader:CreateInput({
        Name = "Token Price",
        CurrentValue = "",
        PlaceholderText = "Tokens",
        RemoveTextAfterFocusLost = false,
        Flag = "tokenPriceForListing",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })

    Trader:CreateButton({
        Name = "Click to Create Listing",
        Callback = function()
            local listPrice = tonumber(input_tokenPrice.CurrentValue)
            if not listPrice then 
                beastHubNotify("Please input Token Price!", "", 3)
                return 
            end

            if #selectedPetsForCreateListing == 0 then
                beastHubNotify("Please select Pet!", "", 3)
                return
            end
            
            local function createListing(targetPets, weightTargetBelow, listPrice, onComplete)
                local function getPlayerData()
                    local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                    local logs = dataService:GetData()
                    return logs
                end
                local playerData = getPlayerData()
                local petInventory = playerData.PetsData.PetInventory.Data
                local autoListUuids = {}
                local listingCounter = 0

                local player = game.Players.LocalPlayer
                local backpack = player:WaitForChild("Backpack")

                for id, data in pairs(petInventory) do
                    local petName = data.PetType
                    local isFavorite = data.PetData.IsFavorite or ""
                    if isFavorite == true then continue end
                    local uid = id
                    local weight = tonumber(string.format("%.2f", data.PetData.BaseWeight * 1.1)) or 0
                    if weight == 0 then 
                        warn("Weight error for: "..(tostring(id) or "nil id"))
                    end 
                    
                    local isTarget = false
                    for _, name in ipairs(targetPets) do
                        if petName == name then
                            isTarget = true
                            break
                        end
                    end

                    if isTarget and weight and weight < weightTargetBelow then
                        table.insert(autoListUuids, uid)
                    end
                end
                local createListingLookup = {}
                for _, id in ipairs(autoListUuids) do
                    createListingLookup[id] = true
                end

                --loop backpack
                for _, item in ipairs(backpack:GetChildren()) do
                    local b = item:GetAttribute("b") -- pet type
                    local d = item:GetAttribute("d") -- favorite
                    if b == "l" and d == false then 
                        local curBagId = item:GetAttribute("PET_UUID")
                        local weightStr = item.Name:match("%[(%d+%.?%d*)%s*[Kk][Gg]%]")
                        local weight = weightStr and tonumber(weightStr)
                        if createListingLookup[curBagId] and weight and weight < weightTargetBelow then
                            local args = {
                                [1] = "Pet",
                                [2] = curBagId,
                                [3] = listPrice
                            }
                            game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer(unpack(args))
                            listingCounter = listingCounter + 1
                            task.wait(5.05)
                        end
                    end
                end

                -- Call the callback AFTER finishing all pets
                if typeof(onComplete) == "function" then
                    beastHubNotify("Listed # of Pet/s: "..tostring(listingCounter),"",3)
                    onComplete()
                end
            end

            createListing(selectedPetsForCreateListing, listBelow, listPrice, function() 
                beastHubNotify("Listing Successful", "", 3)
            end)
        end,
    })
    Trader:CreateDivider()
    Trader:CreateSection("Auto trade ticket - Coming Soon..")
    Trader:CreateDivider()

end
return M
