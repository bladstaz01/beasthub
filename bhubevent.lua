local M = {}


function M.init(Rayfield, beastHubNotify, Window, myFunctions, beastHubIcon, equipItemByName, equipItemByNameV2, getMyFarm, getFarmSpawnCFrame, getAllPetNames, sendDiscordWebhook)
    local Event = Window:CreateTab("Event", "gift")

    Event:CreateSection("New Year Event")
    local autoClaimNewYearLoginEnabled = false
    local autoClaimNewYearLoginThread = nil

    Event:CreateToggle({
        Name = "Auto Claim Daily login",
        CurrentValue = false,
        Flag = "event_autoClaimNewYearLogin",
        Callback = function(Value)
            autoClaimNewYearLoginEnabled = Value

            if autoClaimNewYearLoginEnabled then
                if autoClaimNewYearLoginThread then return end

                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local player = game.Players.LocalPlayer

                autoClaimNewYearLoginThread = task.spawn(function()
                    while autoClaimNewYearLoginEnabled do
                        local playerData = require(ReplicatedStorage.Modules.DataService):GetData()
                        local adventDays = playerData.NewYearsEvent and playerData.NewYearsEvent.Advent and playerData.NewYearsEvent.Advent.Days or {}

                        for dayIndex, dayInfo in ipairs(adventDays) do
                            if dayInfo.State == "Complete" then
                                pcall(function()
                                    ReplicatedStorage.GameEvents.NewYearsEvent.ClaimAdventCalendarDay:FireServer(dayIndex)
                                end)
                                break
                            end
                        end

                        task.wait(60) -- lightweight delay before next check
                    end

                    autoClaimNewYearLoginThread = nil
                end)
            else
                autoClaimNewYearLoginEnabled = false
                autoClaimNewYearLoginThread = nil
            end
        end,
    })

    Event:CreateDivider()

    -- --Event Shop
    Event:CreateSection("Event Shop")
    -- local parag_eventName = Event:CreateParagraph({Title = "Event Name:", Content = "None"})
    local curEventName
    local function getEventItems()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local dataTbl = require(ReplicatedStorage.Data.EventShopData)
        local listItems = {}

        for eventName,eventItems in pairs(dataTbl) do
            curEventName = eventName
            for itemName,itemData in pairs(eventItems) do
                local itemType = tostring(itemData.ItemType or "")
                local itemToType = itemName.." | "..itemType
                table.insert(listItems, itemToType)
                -- print(itemToType)
            end
        end

        return listItems
    end
    local allShopItems = getEventItems()
    task.wait()
    if #allShopItems > 0 then
        -- print("allShopItems have contents")
    else
        -- print("allShopItems nil")
    end

    local autoBuyEventLookup = {}
    local dropdown_eventShopItems = Event:CreateDropdown({
        Name = "Select Items",
        Options = allShopItems,
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "autoBuyEventShopItems", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
        Callback = function(Options)
            -- parag_eventName:Set({Title = "Event Name:", Content = curEventName})
            if #Options > 0 then
                autoBuyEventLookup = {}
                for _, option in ipairs(Options) do
                    local curItemName = option:match("^(.-)%s*|")
                    if curItemName then
                        autoBuyEventLookup[curItemName] = true
                    end
                end
            end
        end,
    })

    Event:CreateButton({
        Name = "Clear",
        Callback = function()
            dropdown_eventShopItems:Set({})
            -- dropdown_eventShopItems:Refresh(allShopItems)
        end,
    })

    local allowShopBuy = {"New Years Shop"} --for multiple 
    local autoBuyEventShopEnabled = false
    local autoBuyEventShopThread = nil
    local toggle_autoBuyEventShop = Event:CreateToggle({
        Name = "Auto Buy Event Shop",
        CurrentValue = false,
        Flag = "autoBuyEventShop",
        Callback = function(Value)
            autoBuyEventShopEnabled = Value
            if autoBuyEventShopEnabled then
                if autoBuyEventShopThread then
                    return
                end
                -- beastHubNotify("Auto event shop check running","",3)
                autoBuyEventShopThread = task.spawn(function()
                    local function getPlayerData()
                        local dataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
                        return dataService:GetData()
                    end
                    while autoBuyEventShopEnabled do
                        local listToBuy = dropdown_eventShopItems and dropdown_eventShopItems.CurrentOption or {}
                        if #listToBuy == 0 then
                            task.wait(60)
                            continue
                        end
                        local playerData = getPlayerData()
                        local eventStock = playerData and playerData.EventShopStock
                        if eventStock then
                            for eventName, eventData in pairs(eventStock) do
                                if eventName == curEventName or #allowShopBuy > 0 then
                                    local stocks = eventData.Stocks
                                    if stocks then
                                        for itemName, stockData in pairs(stocks) do
                                            local curStock = stockData.Stock
                                            if curStock and curStock > 0 then
                                                if autoBuyEventLookup[itemName] == true then
                                                    for i = 1, curStock do
                                                        local args = {
                                                            [1] = itemName,
                                                            [2] = curEventName
                                                        }
                                                        game:GetService("ReplicatedStorage").GameEvents.BuyEventShopStock:FireServer(unpack(args))
                                                        task.wait(0.15)
                                                        --for allow buy
                                                        if #allowShopBuy > 0 then
                                                            for _, allowBuy in ipairs(allowShopBuy) do
                                                                local args = {
                                                                    [1] = itemName,
                                                                    [2] = allowBuy
                                                                }
                                                                game:GetService("ReplicatedStorage").GameEvents.BuyEventShopStock:FireServer(unpack(args))
                                                                task.wait(0.15)
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(60)
                    end
                    autoBuyEventShopThread = nil
                end)
            else
                autoBuyEventShopEnabled = false
                autoBuyEventShopThread = nil
            end
        end,
    })


    Event:CreateDivider()

    Event:CreateSection("Christmas Event - Auto Player Gift")
    local receiver_name = Event:CreateInput({
        Name = "Receiver Username",
        CurrentValue = "",
        PlaceholderText = "username",
        RemoveTextAfterFocusLost = false,
        Flag = "xmasEventGiftReceiver",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })

    local event_numOfGifts = Event:CreateInput({
        Name = "# of gifts to send",
        CurrentValue = "",
        PlaceholderText = "number",
        RemoveTextAfterFocusLost = false,
        Flag = "xmasEventNumOfGiftsToSend",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })

    local event_delayToSend = Event:CreateInput({
        Name = "Delay to send",
        CurrentValue = "",
        PlaceholderText = "seconds",
        RemoveTextAfterFocusLost = false,
        Flag = "xmasEventDelayToSend",
        Callback = function(Text)
        -- The function that takes place when the input is changed
        -- The variable (Text) is a string for the value in the text box
        end,
    })

    local giftSendRunning = false

    Event:CreateButton({
        Name = "Send",
        Callback = function()
            if giftSendRunning then
                beastHubNotify("Gift sending already running", "", 3)
                return
            end

            local receiverName = receiver_name.CurrentValue
            local giftCount = tonumber(event_numOfGifts.CurrentValue)
            local delaySeconds = tonumber(event_delayToSend.CurrentValue) or 0

            if type(receiverName) ~= "string" or receiverName:gsub("%s+", "") == "" then
                beastHubNotify("Invalid receiver username", "", 3)
                return
            end

            if not giftCount or giftCount <= 0 or giftCount % 1 ~= 0 then
                beastHubNotify("Invalid gift count", "", 3)
                return
            end

            if not delaySeconds or delaySeconds < 0 then
                beastHubNotify("Invalid delay value", "", 3)
                return
            end

            local players = game:GetService("Players")
            if not players then
                beastHubNotify("Players service unavailable", "", 3)
                return
            end

            local targetPlayer = players:FindFirstChild(receiverName)
            if not targetPlayer then
                beastHubNotify("Player not found", "", 3)
                return
            end

            local replicatedStorage = game:GetService("ReplicatedStorage")
            if not replicatedStorage then
                beastHubNotify("ReplicatedStorage unavailable", "", 3)
                return
            end

            local gameEvents = replicatedStorage:FindFirstChild("GameEvents")
            if not gameEvents then
                beastHubNotify("GameEvents folder missing", "", 3)
                return
            end

            local tryUseGear = gameEvents:FindFirstChild("TryUseGear")
            if not tryUseGear then
                beastHubNotify("TryUseGear remote missing", "", 3)
                return
            end

            giftSendRunning = true

            task.spawn(function()
                for i = 1, giftCount do
                    if not giftSendRunning then
                        beastHubNotify("Gift sending stopped", "", 3)
                        break
                    end

                    local ok, err = pcall(function()
                        equipItemByName("Player Gift")
                        task.wait(0.2)
                        tryUseGear:FireServer("Player Gift", targetPlayer)
                    end)

                    if not ok then
                        beastHubNotify("Failed to send gift at "..i, "", 3)
                        break
                    end

                    if delaySeconds > 0 then
                        task.wait(delaySeconds)
                    end
                end

                giftSendRunning = false
            end)
        end,
    })


    Event:CreateButton({
        Name = "Stop",
        Callback = function()
            if giftSendRunning then
                giftSendRunning = false
                beastHubNotify("Gift sending stopped", "", 3)
            end
        end,
    })
    Event:CreateDivider()

    

    Event:CreateSection("Auto Submit Christmas Event")
    local eventDelayToSubmit = 5
    Event:CreateInput({
        Name = "Delay to submit",
        CurrentValue = "5",
        PlaceholderText = "seconds",
        RemoveTextAfterFocusLost = false,
        Flag = "eventDelayToSubmit",
        Callback = function(Text)
            eventDelayToSubmit = tonumber(Text)
            if not eventDelayToSubmit then
                eventDelayToSubmit = 5
            end
        end,
    })
    local autoSubmitAllEventEnabled = false
    local autoSubmitAllEventThread = nil
    Event:CreateToggle({
        Name = "Auto Submit all",
        CurrentValue = false,
        Flag = "eventAutoSubmitAll",
        Callback = function(Value)
            autoSubmitAllEventEnabled = Value
            if autoSubmitAllEventEnabled then
                if autoSubmitAllEventThread then
                    return
                end
                beastHubNotify("Auto submit all for event running","",3)
                autoSubmitAllEventThread = task.spawn(function()
                    while autoSubmitAllEventEnabled do
                        game:GetService("ReplicatedStorage").GameEvents.ChristmasEvent.ChristmasTree_SubmitAll:FireServer()
                        task.wait(eventDelayToSubmit)
                    end
                    autoSubmitAllEventThread = nil
                end)
            else
                autoSubmitAllEventEnabled = false
                autoSubmitAllEventThread = nil
            end
        end,
    })
    Event:CreateDivider()

    --bring back
    Event:CreateButton({
        Name = "Bring Back Christmas Event Platforms",
        Callback = function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local adventPlatform = ReplicatedStorage.Modules.UpdateService:WaitForChild("AdventPlatformOld")
            local lumberjackPlatform = ReplicatedStorage.Modules.UpdateService:WaitForChild("LumberjackPlatformOld")
            adventPlatform.Parent = workspace
            lumberjackPlatform.Parent = workspace

        end,
    })
    Event:CreateDivider()
end

return M
