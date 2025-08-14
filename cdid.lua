-- GUI Tracker RemoteEvent/Prompt untuk Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EventTrackerGUI"
ScreenGui.Parent = game.CoreGui

-- Frame utama
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 120)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- Tombol Start Tracking
local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 180, 0, 40)
StartButton.Position = UDim2.new(0, 10, 0, 10)
StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
StartButton.TextColor3 = Color3.new(1, 1, 1)
StartButton.Text = "Start Tracking"
StartButton.Parent = Frame

-- Tombol Clear Output
local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0, 180, 0, 40)
ClearButton.Position = UDim2.new(0, 10, 0, 60)
ClearButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.Text = "Clear Output"
ClearButton.Parent = Frame

-- Fungsi tracking
local tracking = false
local function StartTracking()
    if tracking then return end
    tracking = true
    print("=== Tracker aktif! Silakan mulai job untuk melihat eventnya ===")

    -- Pantau RemoteEvent & RemoteFunction
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                print("[RemoteEvent RECEIVED]:", obj:GetFullName(), ...)
            end)
        elseif obj:IsA("RemoteFunction") then
            obj.OnClientInvoke = function(...)
                print("[RemoteFunction INVOKED]:", obj:GetFullName(), ...)
            end
        end
    end

    -- Pantau ClickDetector
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ClickDetector") then
            obj.MouseClick:Connect(function()
                print("[ClickDetector]:", obj:GetFullName())
            end)
        end
    end)

    -- Pantau ProximityPrompt
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ProximityPrompt") then
            obj.Triggered:Connect(function()
                print("[ProximityPrompt]:", obj:GetFullName())
            end)
        end
    end)

    -- Pantau Remote yang dikirim client
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            print("[Remote SENT]:", self:GetFullName(), "Method:", method, "Args:", ...)
        end
        return oldNamecall(self, ...)
    end)
end

-- Event tombol
StartButton.MouseButton1Click:Connect(function()
    StartTracking()
end)

ClearButton.MouseButton1Click:Connect(function()
    if rconsoleclear then
        rconsoleclear()
    else
        print("\n" .. string.rep("-", 50) .. "\nOutput Cleared\n" .. string.rep("-", 50))
    end
end)
