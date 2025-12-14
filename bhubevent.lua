
local M = {}


function M.init(Rayfield, beastHubNotify, Window, myFunctions, beastHubIcon, equipItemByName, equipItemByNameV2, getMyFarm, getFarmSpawnCFrame, getAllPetNames, sendDiscordWebhook)
    local Event = Window:CreateTab("Event", "gift")

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

    -- --Event Shop
    -- Event:CreateSection("Event Shop")
    -- Event:CreateButton({
    --     Name = "Test3",
    --     Callback = function()
    --         local function getEventItems()
    --             local ReplicatedStorage = game:GetService("ReplicatedStorage") 
    --             local dataTbl = require(ReplicatedStorage.Data.EventShopData)
    --             local listItems = {}

    --             for _, eventType in pairs(dataTbl) do
    --                 for _,item in ipairs(eventType) do
    --                     local itemToType = tostring(item) or "" .." | ".. tostring(item.ItemType) or ""
    --                     table.insert(listItems, itemToType)
    --                     print(tostring(itemToType))
    --                 end

                    
    --             end
    --             return listItems
    --         end

    --         local allShopItems = getEventItems()
    --     end,
    -- })

end

return M
