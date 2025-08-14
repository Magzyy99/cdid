-- Tracker RemoteEvent / RemoteFunction
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Fungsi buat log ke chat lokal
local function logToChat(msg)
    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text = "[TRACKER] " .. msg,
        Color = Color3.fromRGB(0, 255, 0),
        Font = Enum.Font.SourceSansBold
    })
end

-- Fungsi hook event
local function trackFolder(folder)
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                logToChat("RemoteEvent terpanggil: " .. obj.Name)
            end)
        elseif obj:IsA("RemoteFunction") then
            obj.OnClientInvoke = function(...)
                logToChat("RemoteFunction terpanggil: " .. obj.Name)
            end
        end
    end

    -- Kalau ada object baru
    folder.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                logToChat("RemoteEvent baru terpanggil: " .. obj.Name)
            end)
        elseif obj:IsA("RemoteFunction") then
            obj.OnClientInvoke = function(...)
                logToChat("RemoteFunction baru terpanggil: " .. obj.Name)
            end
        end
    end)
end

-- Track ReplicatedStorage
trackFolder(ReplicatedStorage)
