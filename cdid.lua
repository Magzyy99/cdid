local function setupDestinationManager()
    local destinationManager = {
        discoveredDestinations = {},
        destinationWeights = {},
        currentRoute = {}
    }

    local function discoverDestinations()
        -- Cari semua destination points di game
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Part") or obj:IsA("Model") then
                local nameLower = obj.Name:lower()
                if nameLower:find("destination") or nameLower:find("deliver") or nameLower:find("dropoff") then
                    if not destinationManager.discoveredDestinations[obj] then
                        destinationManager.discoveredDestinations[obj] = {
                            position = obj.Position,
                            usageCount = 0,
                            averageSpeed = 0
                        }
                        print("📍 Discovered destination: " .. obj:GetFullName())
                    end
                end
            end
        end
    end

    local function optimizeRoute()
        -- Buat route optimal berdasarkan distance dan speed bonus potential
        local destinations = {}
        for dest, data in pairs(destinationManager.discoveredDestinations) do
            table.insert(destinations, {
                object = dest,
                data = data,
                weight = data.usageCount / (data.averageSpeed + 1) -- Weight formula
            })
        end
        
        -- Sort by weight (lower is better)
        table.sort(destinations, function(a, b) return a.weight < b.weight end)
        
        -- Pilih top destinations untuk route
        destinationManager.currentRoute = {}
        for i = 1, math.min(3, #destinations) do
            table.insert(destinationManager.currentRoute, destinations[i].object)
        end
        
        print("🗺️ Optimized route created with " .. #destinationManager.currentRoute .. " destinations")
    end

    return {
        discover = discoverDestinations,
        optimize = optimizeRoute,
        getRoute = function() return destinationManager.currentRoute end,
        updateStats = function(destination, speed)
            if destinationManager.discoveredDestinations[destination] then
                local data = destinationManager.discoveredDestinations[destination]
                data.usageCount += 1
                data.averageSpeed = (data.averageSpeed * (data.usageCount - 1) + speed) / data.usageCount
            end
        end
    }
end

-- Gunakan destination manager
local destManager = setupDestinationManager()
destManager.discover()
destManager.optimize()
