-- Safe Trigger Tracker GUI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SafeTriggerTrackerGUI"
ScreenGui.Parent = game.CoreGui

-- Frame utama
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 400, 0, 300)
Frame.Position = UDim2.new(0, 20, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- ScrollFrame untuk log
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -50)
Scroll.Position = UDim2.new(0, 5, 0, 5)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 10, 0)
Scroll.ScrollBarThickness = 8
Scroll.Parent = Frame

-- UIListLayout
local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

-- Tombol Start/Stop
local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 180, 0, 30)
StartButton.Position = UDim2.new(0, 10, 0, 255)
StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
StartButton.TextColor3 = Color3.new(1,1,1)
StartButton.Text = "Start Tracking"
StartButton.Parent = Frame

local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(0, 180, 0, 30)
StopButton.Position = UDim2.new(0, 200, 0, 255)
StopButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
StopButton.TextColor3 = Color3.new(1,1,1)
StopButton.Text = "Stop Tracking"
StopButton.Parent = Frame

-- Fungsi log ke GUI
local function logToGUI(msg, color)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 25)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = color or Color3.fromRGB(0, 255, 0)
    Label.Font = Enum.Font.SourceSansBold
    Label.TextSize = 18
    Label.Text = msg
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Scroll
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 5)
end

-- Variabel kontrol
local running = false
local connections = {}

-- Fungsi start tracking aman
local function StartTracking()
    if running then return end
    running = true
    logToGUI("=== Safe Tracking dimulai ===", Color3.fromRGB(0, 255, 255))

    -- Track ProximityPrompt & ClickDetector
    local function trackWorkspace(obj)
        if obj:IsA("ProximityPrompt") then
            local conn = obj.Triggered:Connect(function(plr)
                if plr == LocalPlayer then
                    logToGUI("[ProximityPrompt] "..obj:GetFullName())
                end
            end)
            table.insert(connections, conn)
        elseif obj:IsA("ClickDetector") then
            local conn = obj.MouseClick:Connect(function(plr)
                if plr == LocalPlayer then
                    logToGUI("[ClickDetector] "..obj:GetFullName())
                end
            end)
            table.insert(connections, conn)
        end
    end

    for _, obj in pairs(Workspace:GetDescendants()) do
        trackWorkspace(obj)
    end
    table.insert(connections, Workspace.DescendantAdded:Connect(trackWorkspace))

    -- Track RemoteEvent & RemoteFunction di folder tertentu
    local function trackFolder(folder)
        for _, obj in pairs(folder:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local conn = obj.OnClientEvent:Connect(function(...)
                    logToGUI("[RemoteEvent RECEIVED] "..obj:GetFullName())
                end)
                table.insert(connections, conn)
            elseif obj:IsA("RemoteFunction") then
                local oldInvoke = obj.OnClientInvoke
                obj.OnClientInvoke = function(...)
                    logToGUI("[RemoteFunction INVOKED] "..obj:GetFullName())
                    if oldInvoke then
                        return oldInvoke(...)
                    end
                end
            end
        end
    end
    trackFolder(ReplicatedStorage) -- bisa diganti folder spesifik
end

-- Fungsi stop tracking
local function StopTracking()
    if not running then return end
    running = false
    logToGUI("=== Tracking dihentikan ===", Color3.fromRGB(255, 0, 0))
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
end

-- Tombol event
StartButton.MouseButton1Click:Connect(StartTracking)
StopButton.MouseButton1Click:Connect(StopTracking)
