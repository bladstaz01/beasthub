-- This file was protected using Luraph Obfuscator v14.6 [https://lura.ph/]
local function showMainte(msg)
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
    linkBox.Text = "https://discord.gg/pHEjRY9cXe"
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
showMainte("Dev is uploading new features, please try again in a few minutes. Check Discord for notice.")
-- showMainte("The script has been deleted.")
