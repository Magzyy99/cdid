local function multiDestinationAutoFarm()
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Path utama
    local jobStarter = Workspace.Etc.Job.Truck.Starter
    local truckSpawner = Workspace.Etc.Job.Truck.Spawner
    
    -- Temukan semua destination points
    local destinationFolder = Workspace.Etc.Job.Truck:FindFirstChild("Destinations") or Workspace.Etc.Job.Truck
    local allDestinations = {}
    
    for _, child in pairs(destinationFolder:GetChildren()) do
        if child.Name:lower():find("destination") or child.Name:lower():find("deliver") then
            table.insert(allDestinations, child)
        end
    end
    
    -- Jika tidak ada folder destinations, gunakan single destination
    if #allDestinations == 0 and Workspace.Etc.Job.Truck:FindFirstChild("Destination") then
        table.insert(allDestinations, Workspace.Etc.Job.Truck.Destination)
    end
    
    print("📍 Found " .. #allDestinations .. " destination points")

    -- Remotes
    local startJobRemote = ReplicatedStorage:FindFirstChild("StartJobRemote")
    local spawnRemote = ReplicatedStorage:FindFirstChild("SpawnVehicleRemote")
    local deliveryRemote = ReplicatedStorage:FindFirstChild("DeliveryRemote")

    -- Speed Bonus Configuration
    local config = {
        baseSalary = 1000,
        speedBonusMultiplier = 0.5, -- 0.5% bonus per km/h over minimum
        minSpeedForBonus = 40,      -- Minimum speed to get bonus
        maxSpeedForBonus = 120,     -- Maximum speed for bonus calculation
        minDeliveryTime = 20,       -- Minimum time per destination
        maxDeliveryTime = 35,       -- Maximum time per destination
        destinationsPerJob = 3,     -- Number of destinations per job
        cooldownBetweenJobs = 8
    }

    local jobStats = {
        totalJobs = 0,
        totalEarnings = 0,
        bestSpeed = 0,
        bestSalary = 0
    }

    local speedMonitor = {
        currentSpeed = 0,
        maxSpeed = 0,
        averageSpeed = 0,
        samples = {}
    }

    local function calculateSpeed()
        local char = localPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return 0 end
        
        local hrp = char.HumanoidRootPart
        local currentPos = hrp.Position
        local currentTime = tick()
        
        if speedMonitor.lastPosition and speedMonitor.lastTime then
            local distance = (currentPos - speedMonitor.lastPosition).Magnitude
            local timeDiff = currentTime - speedMonitor.lastTime
            local speed = distance / timeDiff * 3.6 -- Convert to km/h
            
            speedMonitor.currentSpeed = speed
            table.insert(speedMonitor.samples, speed)
            
            -- Keep only last 10 samples
            if #speedMonitor.samples > 10 then
                table.remove(speedMonitor.samples, 1)
            end
            
            -- Calculate average
            local total = 0
            for _, spd in ipairs(speedMonitor.samples) do
                total += spd
            end
            speedMonitor.averageSpeed = total / #speedMonitor.samples
            
            -- Update max speed
            if speed > speedMonitor.maxSpeed then
                speedMonitor.maxSpeed = speed
            end
        end
        
        speedMonitor.lastPosition = currentPos
        speedMonitor.lastTime = currentTime
        return speedMonitor.currentSpeed
    end

    local function calculateSalaryBonus()
        local effectiveSpeed = math.clamp(speedMonitor.averageSpeed, config.minSpeedForBonus, config.maxSpeedForBonus)
        local speedAboveMin = effectiveSpeed - config.minSpeedForBonus
        local bonusPercentage = speedAboveMin * config.speedBonusMultiplier / 100
        
        return math.min(bonusPercentage, 1.0) -- Max 100% bonus
    end

    local function safeTeleport(position, instant)
        local char = localPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            if instant then
                hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
            else
                -- Smooth teleport dengan velocity
                hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
                hrp.Velocity = Vector3.new(0, 0, 0)
            end
            task.wait(1)
        end
    end

    local function simulateDriving(startPos, endPos, minTime, maxTime)
        local char = localPlayer.Character
        if not char then return end
        
        local hrp = char.HumanoidRootPart
        local distance = (startPos - endPos).Magnitude
        local driveTime = math.random(minTime, maxTime)
        local startTime = tick()
        
        print(string.format("🚗 Driving %.0fm - Target time: %.1fs", distance, driveTime))
        
        while tick() - startTime < driveTime do
            local progress = (tick() - startTime) / driveTime
            local currentPos = startPos:Lerp(endPos, progress)
            
            hrp.CFrame = CFrame.new(currentPos + Vector3.new(0, 3, 0))
            
            -- Maintain good speed for bonus
            local targetSpeed = math.random(60, 80) -- Good speed range for bonus
            hrp.Velocity = (endPos - currentPos).Unit * (targetSpeed / 3.6) -- Convert km/h to m/s
            
            calculateSpeed()
            print(string.format("⏱ %.1fs | 🚗 %d km/h | 📊 Avg: %d km/h", 
                tick() - startTime, math.floor(speedMonitor.currentSpeed), math.floor(speedMonitor.averageSpeed)))
            
            task.wait(0.5)
        end
        
        safeTeleport(endPos, false)
    end

    local function startTruckJob()
        print("\n🚚 Starting truck job #" .. (jobStats.totalJobs + 1))
        safeTeleport(jobStarter.Position, false)
        
        if startJobRemote then
            startJobRemote:FireServer("truck")
        end
        
        local prompt = jobStarter:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
        
        task.wait(2)
    end

    local function spawnTruckVehicle()
        print("🛻 Spawning truck...")
        safeTeleport(truckSpawner.Position, false)
        
        if spawnRemote then
            spawnRemote:FireServer("truck")
        end
        
        local prompt = truckSpawner:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
        
        task.wait(3)
    end

    local function findAndEnterTruck()
        print("🔍 Finding truck...")
        local truck
        
        local vehiclesFolder = Workspace:FindFirstChild("Vehicles") or Workspace
        local timeout = 0
        
        repeat
            for _, vehicle in pairs(vehiclesFolder:GetChildren()) do
                if vehicle:IsA("Model") and vehicle:FindFirstChild("DriveSeat") then
                    truck = vehicle
                    break
                end
            end
            task.wait(0.5)
            timeout += 0.5
        until truck or timeout >= 10
        
        if truck then
            local driveSeat = truck:FindFirstChild("DriveSeat")
            if driveSeat then
                safeTeleport(driveSeat.Position, false)
                task.wait(1)
                
                local prompt = driveSeat:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                end
            end
        end
        
        return truck
    end

    local function deliverToMultipleDestinations(truck)
        if not truck or #allDestinations == 0 then return end
        
        -- Reset speed monitor untuk job baru
        speedMonitor = {currentSpeed = 0, maxSpeed = 0, averageSpeed = 0, samples = {}}
        
        -- Pilih random destinations untuk job ini
        local jobDestinations = {}
        for i = 1, math.min(config.destinationsPerJob, #allDestinations) do
            local randomDest = allDestinations[math.random(1, #allDestinations)]
            table.insert(jobDestinations, randomDest)
        end
        
        print("📍 Delivery route: " .. #jobDestinations .. " destinations")
        
        for i, destination in ipairs(jobDestinations) do
            print("\n📦 Destination " .. i .. "/" .. #jobDestinations .. ": " .. destination.Name)
            
            local driveSeat = truck:FindFirstChild("DriveSeat")
            if not driveSeat then break end
            
            local startPos = driveSeat.Position
            local endPos = destination.Position
            
            -- Drive to destination dengan speed optimization
            simulateDriving(startPos, endPos, config.minDeliveryTime, config.maxDeliveryTime)
            
            -- Complete delivery
            safeTeleport(destination.Position, false)
            task.wait(2)
            
            if deliveryRemote then
                deliveryRemote:FireServer()
            end
            
            local prompt = destination:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                fireproximityprompt(prompt)
            end
            
            task.wait(2)
            
            -- Calculate salary bonus for this delivery
            local bonusMultiplier = calculateSalaryBonus()
            local deliverySalary = config.baseSalary * (1 + bonusMultiplier)
            
            print(string.format("💰 Delivery bonus: +%.1f%% | Earnings: $%d", 
                bonusMultiplier * 100, deliverySalary))
                
            jobStats.totalEarnings += deliverySalary
        end
        
        -- Show job summary
        print("\n🎯 Job Completed!")
        print("📊 Max Speed: " .. math.floor(speedMonitor.maxSpeed) .. " km/h")
        print("📊 Average Speed: " .. math.floor(speedMonitor.averageSpeed) .. " km/h")
        print("💰 Total Earnings: $" .. jobStats.totalEarnings)
        
        if speedMonitor.maxSpeed > jobStats.bestSpeed then
            jobStats.bestSpeed = speedMonitor.maxSpeed
        end
    end

    local function completeJobCycle()
        jobStats.totalJobs += 1
        
        -- Simulate natural delay before next job
        local cooldown = math.random(config.cooldownBetweenJobs, config.cooldownBetweenJobs + 3)
        print("⏳ Waiting " .. cooldown .. " seconds for next job...")
        task.wait(cooldown)
    end

    -- MAIN AUTO FARM LOOP
    print("🚛 Starting Multi-Destination Auto Truck Farm")
    print("💰 Speed Bonus System: ENABLED")
    print("📍 Multiple Destinations: " .. #allDestinations)
    print("⚡ Target Speed: 60-80 km/h for maximum bonus")
    
    while true do
        local success, err = pcall(function()
            startTruckJob()
            spawnTruckVehicle()
            local truck = findAndEnterTruck()
            deliverToMultipleDestinations(truck)
            completeJobCycle()
            
            print("\n" .. string.rep("=", 50))
            print("📈 TOTAL STATS:")
            print(" Jobs Completed: " .. jobStats.totalJobs)
            print(" Total Earnings: $" .. jobStats.totalEarnings)
            print(" Best Speed: " .. math.floor(jobStats.bestSpeed) .. " km/h")
            print(string.rep("=", 50) .. "\n")
        end)
        
        if not success then
            print("❌ Error:", err)
            print("🔄 Retrying in 10 seconds...")
            task.wait(10)
        end
    end
end

-- Jalankan auto farm
multiDestinationAutoFarm()
