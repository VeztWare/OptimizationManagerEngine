local OptimizationManager = {
    WatchDog = {
        Connections = {},
        Params = {}
    },
    CPU = {},
    GPU = {},
    API = {}
}

local RunService = cloneref(game:GetService("RunService"))
local Stats = cloneref(game:GetService("Stats"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local Players = cloneref(game:GetService("Players"))

function OptimizationManager.GPU.SetRendering(state: boolean)
    if type(state) == "boolean" then
        RunService:Set3dRenderingEnabled(state)
    end
end

function OptimizationManager.CPU.SetFPS(lim: number)
    if type(lim) == "number" and lim > 0 then
        setfpscap(lim)
    end
end

function OptimizationManager.WatchDog.MonitorMemory(max: number, frequency: number)
    if type(max) == "number" and type(frequency) == "number" then
        self.Params.LastTimeChecked = tick()
        self.Params.MaxMemoryReservation = max
        if not self.Connections["WatchDog_MonitorMemory"] then
            self.Connections["WatchDog_MonitorMemory"] = RunService.Heartbeat:Connect(function(dt)
                if tick() - self.Params.LastTimeChecked > frequency then
                    self.Params.LastTimeChecked = tick()
                    if Stats:GetTotalMemoryUsageMb() > self.Params.MaxMemoryReservation then
                        OptimizationManager.API:Rejoin()
                    end
                end
            end
        end
    end
end

function OptimizationManager.WatchDog.StopMemoryMonitor()
    local conn = self.Connections["WatchDog_MonitorMemory"]
    if conn then
        conn:Disconnect()
        self.Connections["WatchDog_MonitorMemory"] = nil
    end
end

function OptimizationManager.API.Rejoin()
    if #Players:GetPlayers() <= 1 then
		Players.LocalPlayer:Kick("\nRejoining...")
		wait()
		TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
	end
end

function OptimizationManager.API.DisableAnimations()
    for _, plr in pairs(Players:GetChildren()) do
        plr.Character.Animate.Disabled = true
    end
end

function OptimizationManager.API.CleanDrawingEffects()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Decal") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
        end
    end
end

function OptimizationManager.API.CleanRenderingEffects()
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChild("Terrain")

    local effectsToDestroy = {
        "Bloom", "DayColors", "InventoryBlur", "NightColors", "Colors",
        "SunRays", "UnderWaterBlur", "SettingsBlur", "SunRaysAlwaysOn",
        "SunRaysAlwaysOnNight", "Blur", "DisabledSkyBox", "ColorCorrection",
        "TRUEColorCorrection"
    }
    
    for _, effectName in ipairs(effectsToDestroy) do
        local effect = Lighting:FindFirstChild(effectName)
        if effect then
            effect:Destroy()
        end
    end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("SpawnLocation") or obj:IsA("WedgePart") 
           or obj:IsA("Terrain") or obj:IsA("MeshPart") then
            obj.BrickColor = BrickColor.new(155, 155, 155)
            obj.Material = Enum.Material.Plastic
        end
    end

    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("Union") or obj:IsA("CornerWedgePart") or obj:IsA("TrussPart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
        elseif (obj:IsA("Decal") or obj:IsA("Texture")) then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Lifetime = NumberRange.new(0)
        elseif obj:IsA("Explosion") then
            obj.BlastPressure = 1
            obj.BlastRadius = 1
        elseif obj:IsA("Fire") or obj:IsA("SpotLight") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        elseif obj:IsA("MeshPart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
            obj.TextureID = 1.0385902758728955e16
        end
    end

    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") 
           or effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") 
           or effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
        end
    end
end

function OptimizationManager.API.EnableAnimations()
    for _, plr in pairs(Players:GetChildren()) do
        plr.Character.Animate.Disabled = false
    end
end

function OptimizationManager.GPU.ClearVisuals()
    OptimizationManager.API:CleanDrawingEffects()
    OptimizationManager.API:CleanRenderingEffects()
    OptimizationManager.API:DisableAnimations()
end

return OptimizationManager
