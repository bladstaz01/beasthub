local M = {}

function M.init(Rayfield, beastHubNotify, Window, myFunctions, reloadScript, beastHubIcon)
    -- ==Close Script Destroy Rayfield
    local function closeScript()
        -- Reset global flags
        getgenv().BeastHubLoaded = false
        getgenv().BeastHubRayfield = nil
        getgenv().BeastHubLink = nil
        getgenv().BeastHubFunctions = nil
        getgenv().InfiniteJumpConnection = nil
        autoPlaceEggsEnabled = false
        autoPlaceEggsThread = nil
        --  Safely disconnect the proximity connection if it exists
        if connectionHideProximity then
            connectionHideProximity:Disconnect()
            connectionHideProximity = nil
        end

        -- Stop any running loops in support module
        if getgenv().BeastHubFunctions then
            local M = getgenv().BeastHubFunctions
            if myFunctions._fairyAutoRejoinRunning then
                myFunctions._fairyAutoRejoinRunning = false
                print("Stopped Fairy Auto Rejoin loop")
            end
        end
        if typeof(Rayfield) == "table" and Rayfield.Destroy then
            pcall(function() Rayfield:Destroy() end)
            print("Rayfield destroyed via reference")
        else
            local coreRayfield = game:GetService("CoreGui"):FindFirstChild("Rayfield")
            if coreRayfield then
                pcall(function() coreRayfield:Destroy() end)
                print("Rayfield destroyed in CoreGui")
            end
        end
        print("BeastHub closed")
    end

    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local Humanoid = character:WaitForChild("Humanoid")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    local Main = Window:CreateTab("Main", "home")
    -- Main>Script
    Main:CreateSection("Script")
    --==
    Main:CreateButton({
        Name = "Reload Script",
        Callback = function()
            print("Reloading BeastHub..")
            Rayfield:Notify({
                Title = "BeastHub",
                Content = "Updating script..",
                Duration = 4,
                Image = beastHubIcon
            })
            task.wait(2)
            reloadScript("Reload")
        end
    })
    local Slider_walkSpeed = nil
    local Slider_jumpPower = nil
    local Toggle_infiniteJump = nil
    local Toggle_fly = nil

    Main:CreateButton({
        Name = "Reset All Settings",
        Callback = function()
            -- ===Reset config button
            local function resetPlayerDefaults()
                local default_walkSpeed = 20
                local default_jumpPower = 50

                Slider_walkSpeed:Set(default_walkSpeed)
                Slider_jumpPower:Set(default_jumpPower)
                Toggle_infiniteJump:Set(false)
                Toggle_fly:Set(false)
                return
            end

            local path = "BeastHub/userConfig.rfld" -- adjust extension if needed
            if isfile and delfile then
                if isfile(path) then
                    delfile(path)
                    task.wait(.5)
                    reloadScript("Reset config")
                    task.wait(.5)
                    Rayfield:Notify({
                        Title = "BeastHub",
                        Content = "Some player effects need game rejoin to fully reset",
                        Duration = 5,
                        Image = beastHubIcon
                    })
                    resetPlayerDefaults()
                end
            end
        end
    })

    -- Exit Script
    Main:CreateButton({
        Name = "Exit Script",
        Image = "badge-x",
        Callback = function()
            print("Closing BeastHub..")
            closeScript()
            -- Destroy Luck GUI
            if luckGUI and luckGUI.Parent then
                luckGUI:Destroy()
                print("Luck GUI destroyed")
            end
        end
    })
    local Paragraph = Main:CreateParagraph({Title = "Shortcut Key = H", Content = "Press H in keyboard to hide/unhide script interface"})

    -- Main>Player
    Main:CreateDivider()
    Main:CreateSection("Player")
    -- local Label_player = Main:CreateLabel("Player")

    --=== WalkSpeed Slider
    Slider_walkSpeed = Main:CreateSlider({
        Name = "Walk Speed",
        Range = {20, 100},       -- Normal speed = 20, max = 100
        Increment = 1,
        Suffix = "",
        CurrentValue = 20,
        Flag = "walkSpeed",
        Callback = function(Value)
            if character and character:FindFirstChildOfClass("Humanoid") then
                character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
            end
        end,
    })

    --===Jump Power
    Slider_jumpPower = Main:CreateSlider({
        Name = "Jump Power",
        Range = {50, 200}, -- realistic jump power range
        Increment = 5,
        Suffix = "",
        CurrentValue = 50, -- start at default
        Flag = "jumpPower",
        Callback = function(Value)
            Humanoid.JumpPower = Value
        end,
    })


    --=== Infinite jump
    Toggle_infiniteJump = Main:CreateToggle({
        Name = "Infinite jump",
        CurrentValue = false,
        Flag = "infiniteJump",
        Callback = function(enabled)
            local UIS = game:GetService("UserInputService")
            local player = game.Players.LocalPlayer
            if enabled then
                -- Connect once
                if not getgenv().InfiniteJumpConnection then
                    getgenv().InfiniteJumpConnection = UIS.JumpRequest:Connect(function()
                        local char = player.Character
                        if char and char:FindFirstChildOfClass("Humanoid") then
                            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end)
                end
            else
                -- Disable: disconnect
                if getgenv().InfiniteJumpConnection then
                    getgenv().InfiniteJumpConnection:Disconnect()
                    getgenv().InfiniteJumpConnection = nil
                end
            end
        end,
    })




    -- === Fly Toggle
    local flying = false
    local speed = 50
    local bodyVelocity
    local bodyVelocityConnection

    local moveDir = {W=false, A=false, S=false, D=false}
    local upDown = {Space=false}

    -- Left Shift listener for Dash (Fly and Walk)
    UserInputService.InputBegan:Connect(function(input, processed)
        local dashWalkSpeed = 100 --dash
        if processed then return end
        if input.KeyCode == Enum.KeyCode.LeftShift then
            speed = 150
            player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = dashWalkSpeed
        end
    end)

    UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.LeftShift then
            speed = 50
            player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed =
                Rayfield.Flags["walkSpeed"].CurrentValue
        end
    end)


    -- Movement input tracking (PC)
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then moveDir.W = true end
        if input.KeyCode == Enum.KeyCode.A then moveDir.A = true end
        if input.KeyCode == Enum.KeyCode.S then moveDir.S = true end
        if input.KeyCode == Enum.KeyCode.D then moveDir.D = true end
        if input.KeyCode == Enum.KeyCode.Space then upDown.Space = true end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then moveDir.W = false end
        if input.KeyCode == Enum.KeyCode.A then moveDir.A = false end
        if input.KeyCode == Enum.KeyCode.S then moveDir.S = false end
        if input.KeyCode == Enum.KeyCode.D then moveDir.D = false end
        if input.KeyCode == Enum.KeyCode.Space then upDown.Space = false end
    end)

    -- Create Rayfield toggle
    Toggle_fly = Main:CreateToggle({
        Name = "Fly",
        CurrentValue = false,
        Flag = "fly",
        Callback = function(state)
            flying = state
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local cam = workspace.CurrentCamera
            if flying then
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
                bodyVelocity.Velocity = Vector3.new(0,0,0)
                bodyVelocity.Parent = hrp

                bodyVelocityConnection = RunService.RenderStepped:Connect(function()
                    if not flying then return end
                    local moveVec = Vector3.new()
                    local humanoid = character:WaitForChild("Humanoid")

                    -- detect mobile properly (MuMu may fake both true)
                    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

                    if not isMobile then
                        -- PC fly: full camera-relative movement
                        if moveDir.W then moveVec = moveVec + cam.CFrame.LookVector end
                        if moveDir.S then moveVec = moveVec - cam.CFrame.LookVector end
                        if moveDir.D then moveVec = moveVec + cam.CFrame.RightVector end
                        if moveDir.A then moveVec = moveVec - cam.CFrame.RightVector end
                        if upDown.Space then moveVec = moveVec + Vector3.new(0,1,0) end
                    else
                        -- Mobile input (use Humanoid.MoveDirection instead of Thumbstick)
                        --deleted, joystick flying seems impossible
                    end -- end else


                    if moveVec.Magnitude > 0 then
                        bodyVelocity.Velocity = moveVec.Unit * speed
                    else
                        bodyVelocity.Velocity = Vector3.new(0,0,0)
                    end
                end)
            else
                if bodyVelocity then bodyVelocity:Destroy() end
                if bodyVelocityConnection then bodyVelocityConnection:Disconnect() end
            end
        end
    })
    local Paragraph = Main:CreateParagraph({Title = "Dash", Content = "F key shortcut for Fly. Left Shift key to Dash while Walking or Flying."})

    -- F listener
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.F then
            Toggle_fly:Set(not flying)
        end
    end)

    -- Continuously enforce noclip while flying
    RunService.Stepped:Connect(function()
        if flying and character then
            myFunctions.setNoclip(flying)
        end
    end)


    -- Main>Server
    Main:CreateDivider()
    Main:CreateSection("Server")
    -- local Label_script = Main:CreateLabel("Server")
    -- ===Instant rejoin button
    Main:CreateButton({
        Name = "Instant rejoin",
        Callback = function()
            myFunctions.delayedRejoin(.1)
        end,
    })


    -- ===Auto rejoin / delayed rejoin
    local Slider_rejoinDelay = Main:CreateSlider({
        Name = "Auto Rejoin Delay",
        Range = {5, 100},
        Increment = 1,
        Suffix = "seconds",
        CurrentValue = 30,
        Flag = "rejoinDelay",
        Callback = function(Value)
            --print("rejoin delay: "..Value)        
        end,
    })
    local Toggle_autoRejoin = Main:CreateToggle({
        Name = "Enable Auto Rejoin",
        CurrentValue = false,
        Flag = "autoRejoin", 
        Callback = function(Value)
            if Value == true then
                local delaySec = Slider_rejoinDelay.CurrentValue
                myFunctions.delayedRejoin(delaySec)
            end    
        end,
    })
    local Paragraph = Main:CreateParagraph({Title = "Note:", Content = "Auto rejoin will activate continuously upon game rejoin unless you turn it off."})
    Main:CreateDivider()
end

return M
