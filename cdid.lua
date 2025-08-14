-- Fixed Safe Trigger Tracker GUI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FixedSafeTriggerTrackerGUI"
ScreenGui.Parent = game.CoreGui

-- Frame utama
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 450, 0, 350)
Frame.Position = UDim2.new(0, 20, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- ScrollFrame untuk log
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -60)
Scroll.Position = UDim2.new(0, 5, 0, 5)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 10, 0)
Scroll.ScrollBarThickness = 8
Scroll.Parent = Frame

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll
Layout.Padding = UDim.new(0,5)

-- Tombol Start/Stop
local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 220, 0, 30)
StartButton.Position = UDim2.new(0, 10, 0, 300)
StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
StartButton.TextColor3 = Color3.new(1,1,1)
StartButton.Text = "Start Tracking"
StartButton.Parent = Frame

local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(0, 220, 0, 30)
StopButton.Position = UDim2.new(0, 220, 0, 300)
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
    Label.TextSize = 16
    Label.Text = msg
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.AutomaticSize = Enum.AutomaticSize.Y
    Label.Parent = Scroll
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 5)
end

-- Variabel kontrol
local running = false
local connections = {}

-- Fungsi track ProximityPrompt & ClickDetector
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

-- Fungsi track RemoteEvent & RemoteFunction
local function trackRemote(obj)
    if obj:IsA("RemoteEvent") then
        local conn = obj.OnClientEvent:Connect(function(...)
            local args = {...}
            local argStr = ""
            for i,v in ipairs(args) do argStr = argStr .. tostring(v) .. ", " end
            argStr = argStr:sub(1, -3)
            logToGUI("[RemoteEvent RECEIVED] "..obj:GetFullName().." | Args: "..argStr)
        end)
        table.insert(connections, conn)
    elseif obj:IsA("RemoteFunction") then
        local oldInvoke = obj.OnClientInvoke
        obj.OnClientInvoke = function(...)
            local args = {...}
            local argStr = ""
            for i,v in ipairs(args) do argStr = argStr .. tostring(v) .. ", " end
            argStr = argStr:sub(1, -3)
            logToGUI("[RemoteFunction INVOKED] "..obj:GetFullName().." | Args: "..argStr)
            if oldInvoke then
                return oldInvoke(...)
            end
        end
    end
end

-- Start tracker
local function StartTracking()
    if running then return end
    running = true
    logToGUI("=== Safe Tracking dimulai ===", Color3.fromRGB(0, 255, 255))

    -- Track semua existing workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        trackWorkspace(obj)
    end
    table.insert(connections, Workspace.DescendantAdded:Connect(trackWorkspace))

    -- Track semua existing remote di ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        trackRemote(obj)
    end
    table.insert(connections, ReplicatedStorage.DescendantAdded:Connect(trackRemote))
end

-- Stop tracker
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
