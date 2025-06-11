include('inv_config.lua')
include('inv_shared.lua')

if SERVER then
    AddCSLuaFile("lua/autorun/client/inv_base_slot.lua")
    AddCSLuaFile("lua/autorun/client/inv_base_window.lua")
    AddCSLuaFile("lua/autorun/client/inv_gui.lua")
    AddCSLuaFile("lua/autorun/client/inv_bank_gui.lua")
    AddCSLuaFile("lua/autorun/client/inv_init_c.lua")
    AddCSLuaFile("lua/inv_shared.lua")
    AddCSLuaFile("lua/inv_config.lua")

    util.AddNetworkString("dropEnt_inv")
    util.AddNetworkString("swapItems_inv")
    util.AddNetworkString("forceRefresh_inv")
    util.AddNetworkString("forceRefresh_bank")
    util.AddNetworkString("useEnt_inv")
    util.AddNetworkString("addInventoryItem")
    util.AddNetworkString("inv_showNotification")
    util.AddNetworkString("openBankGui")
    util.AddNetworkString("transferItems_inv")
    util.AddNetworkString("validateFiles_inv")
    util.AddNetworkString("inv_requestUpdate")

    local function showNotification(ply, msg)
        net.Start("inv_showNotification")
        net.WriteString(msg)
        net.Send(ply)
    end

    -- Stub to allow forward call in loadData
    local function saveData() end

    local function loadData(ply, typ)
        local dataPath = InventoryConfig.General.playerDataFolder .. "/" .. ply:SteamID64() .. "_" .. typ .. ".dat"
        if file.Exists(dataPath, "DATA") then
            local data = util.JSONToTable(file.Read(dataPath, "DATA")) or {}
            local maxSlots = (typ == "Inventory") and 40 or 32

            for i = 1, maxSlots do
                data[i] = data[i] or {
                    isOccupied   = false,
                    Count        = 0,
                    Name         = "unknown",
                    ItemClass    = "unknown",
                    WeaponClass  = "unknown",
                    Model        = nil,
                    SingleWeight = 0,
                    MaxStack     = 20
                }
                if data[i].MaxStack == nil then
                    data[i].MaxStack = 20
                end
            end

            return data
        else
            local eq = {}
            local maxSlots = (typ == "Inventory") and 40 or 32

            for i = 1, maxSlots do
                eq[i] = {
                    isOccupied   = false,
                    Count        = 0,
                    Name         = "unknown",
                    ItemClass    = "unknown",
                    WeaponClass  = "unknown",
                    Model        = nil,
                    SingleWeight = 0,
                    MaxStack     = 20
                }
            end

            saveData(ply, eq, typ)
            return eq
        end
    end

    local function saveData(ply, invslot, typ)
        if not file.Exists(InventoryConfig.General.playerDataFolder, "DATA") then
            file.CreateDir(InventoryConfig.General.playerDataFolder)
        end

        file.Write(
            InventoryConfig.General.playerDataFolder .. "/" .. ply:SteamID64() .. "_" .. typ .. ".dat",
            util.TableToJSON(invslot)
        )

        if typ == "Inventory" then
            net.Start("forceRefresh_inv")
            net.WriteTable(invslot)
            net.Send(ply)
        elseif typ == "Bank" then
            net.Start("forceRefresh_bank")
            net.WriteTable(invslot)
            net.Send(ply)
        end
    end

    net.Receive("inv_requestUpdate", function(len, ply)
        net.Start("forceRefresh_inv")
        net.WriteTable(loadData(ply, "Inventory"))
        net.Send(ply)

        net.Start("forceRefresh_bank")
        net.WriteTable(loadData(ply, "Bank"))
        net.Send(ply)
    end)

    net.Receive("dropEnt_inv", function(len, ply)
        local id       = tonumber(net.ReadString())
        local typ      = net.ReadString()
        local dat      = loadData(ply, typ)
        local class    = dat[id].ItemClass
        local model    = dat[id].Model
        local wepClass = dat[id].WeaponClass
        local count    = tonumber(net.ReadString())

        for i = 1, count do
            local ent = ents.Create(class)
            ent:SetPos(ply:EyePos() + ply:GetAimVector() * math.random(60, 70))
            ent:SetModel(model)
            ent:Spawn()
            ent:Activate()
            if class == "spawned_weapon" then
                ent:Setamount(1)
                ent:SetWeaponClass(wepClass)
            end
            ent:PhysicsInit(SOLID_VPHYSICS)
            ent:SetMoveType(MOVETYPE_VPHYSICS)
            ent:SetSolid(SOLID_VPHYSICS)

            dat[id].Count = dat[id].Count - 1
            if dat[id].Count < 1 then
                dat[id].isOccupied   = false
                dat[id].Count        = 0
                dat[id].Name         = "unknown"
                dat[id].ItemClass    = "unknown"
                dat[id].WeaponClass  = "unknown"
                dat[id].Model        = nil
                dat[id].SingleWeight = 0
                dat[id].MaxStack     = 20
            end

            if count == i and count ~= 1 then
                dat[id].isOccupied   = false
                dat[id].Count        = 0
                dat[id].Name         = "unknown"
                dat[id].ItemClass    = "unknown"
                dat[id].WeaponClass  = "unknown"
                dat[id].Model        = nil
                dat[id].SingleWeight = 0
                dat[id].MaxStack     = 20
            end

            local phys = ent:GetPhysicsObject()
            if phys:IsValid() then phys:Wake() end

            saveData(ply, dat, typ)
        end
    end)

    net.Receive("useEnt_inv", function(len, ply)
        local id       = tonumber(net.ReadString())
        local typ      = net.ReadString()
        local dat      = loadData(ply, typ)
        local class    = dat[id].ItemClass
        local model    = dat[id].Model
        local wepClass = net.ReadString()

        if class == "spawned_weapon" then
            if wepClass then
                local ent = ents.Create(wepClass)
                ent.nodupe = true
                timer.Simple(0.1, function()
                    ent:SetPos(ply:GetPos())
                    ent:Spawn()
                    ent:Activate()
                    ent:Use(ply, ply, USE_ON, 1)
                end)
            end
        else
            local ent = ents.Create(class)
            ent:SetModel(model)
            ent:SetPos(ply:EyePos() + ply:GetAimVector() * math.random(60, 70))
            local phys = ent:GetPhysicsObject()
            if phys:IsValid() then phys:Wake() end
            timer.Simple(0.1, function()
                ent:Spawn()
                ent:Activate()
                ent:Use(ply, ply, USE_ON, 1)
            end)
        end

        if dat[id].Count - 1 < 1 then
            dat[id].isOccupied   = false
            dat[id].Count        = 0
            dat[id].Name         = "unknown"
            dat[id].ItemClass    = "unknown"
            dat[id].WeaponClass  = "unknown"
            dat[id].Model        = nil
            dat[id].SingleWeight = 0
            dat[id].MaxStack     = 20
        else
            dat[id].Count = dat[id].Count - 1
        end

        saveData(ply, dat, typ)
    end)

    local plyMeta = FindMetaTable("Player")
    function plyMeta:AddInventoryItem(ent, count)
        local eq = loadData(self, "Inventory")
        if not eq then
            eq = {}
            for i = 1, 40 do
                eq[i] = {
                    isOccupied   = false,
                    Count        = 0,
                    Name         = "unknown",
                    ItemClass    = "unknown",
                    WeaponClass  = "unknown",
                    SingleWeight = 0,
                    MaxStack     = 20
                }
            end
        end

        for _, slot in ipairs(eq) do
            ent.StackSize = ent.StackSize or 1
            if not slot.isOccupied or (slot.ItemClass == ent:GetClass() and slot.Count < ent.StackSize) then
                slot.SingleWeight = ent.Weight or 1
                slot.isOccupied   = true
                slot.Name         = ent.Name or ent:GetClass()
                slot.ItemClass    = ent:GetClass()
                slot.Count        = slot.Count + 1
                slot.Model        = ent:GetModel()
                slot.MaxStack     = ent.StackSize or 20
                slot.WeaponClass  = (slot.ItemClass == "spawned_weapon") and ent:GetWeaponClass() or nil

                saveData(self, eq, "Inventory")
                if ent:GetClass() == "spawned_weapon" and ent:Getamount() > 1 then
                    ent:Setamount(ent:Getamount() - 1)
                else
                    ent:Remove()
                end
                self:EmitSound(InventoryConfig.Sounds.pickUp)
                return
            end
        end

        showNotification(self, InventoryConfig.Messages.noSpace)
    end

    -- Picking up objects
    local debounceLastTime = 0
    hook.Add("Think", "inv_trace_think", function()
        for _, ply in ipairs(player.GetAll()) do
            local trace = ply:GetEyeTrace()
            if trace.Hit and (trace.Entity:GetClass() == "spawned_weapon" or trace.Entity.Pickable) then
                if trace.HitPos:Distance(ply:GetPos()) <= 90 then
                    function trace.Entity:Use(activator, caller, useType, value)
                        if CurTime() > debounceLastTime + 0.1 then
                            caller:AddInventoryItem(self, 1)
                        end
                        debounceLastTime = CurTime()
                    end
                end
            end
        end
    end)

    net.Receive("swapItems_inv", function(len, ply)
        local item1 = tonumber(net.ReadString())
        local item2 = tonumber(net.ReadString())
        if item1 == item2 then return end
        local typ = net.ReadString()
        local eq  = loadData(ply, typ)

        if eq[item1].ItemClass == eq[item2].ItemClass and
           eq[item1].Name      == eq[item2].Name      and
           eq[item1].Count + eq[item2].Count <= (eq[item2].MaxStack or eq[item1].MaxStack or 20) then

            eq[item1].Count = eq[item1].Count + eq[item2].Count
            eq[item2].isOccupied = false
            eq[item2].Count      = 0
        else
            eq[item1], eq[item2] = eq[item2], eq[item1]
        end

        sound.Play(InventoryConfig.Sounds.dragItem, ply:GetPos())
        saveData(ply, eq, typ)
    end)

    net.Receive("transferItems_inv", function(len, ply)
        local item1       = tonumber(net.ReadString())
        local item2       = tonumber(net.ReadString())
        local whereDropped= net.ReadString()
        local inv         = loadData(ply, "Inventory")
        local bank        = loadData(ply, "Bank")

        if inv[item1].Name == bank[item2].Name and
           inv[item1].ItemClass == bank[item2].ItemClass and
           inv[item1].Count + bank[item2].Count <= (bank[item2].MaxStack or inv[item1].MaxStack or 20) then

            if whereDropped == "Inventory" then
                inv[item1].Count = inv[item1].Count + bank[item2].Count
                bank[item2].isOccupied = false
                bank[item2].Count      = 0
                bank[item2].Name       = "unknown"
                bank[item2].ItemClass  = "unknown"
            else
                bank[item2].Count = inv[item1].Count + bank[item2].Count
                inv[item1].isOccupied = false
                inv[item1].Count      = 0
                inv[item1].Name       = "unknown"
                inv[item1].ItemClass  = "unknown"
            end
        else
            bank[item2], inv[item1] = inv[item1], bank[item2]
        end

        sound.Play(InventoryConfig.Sounds.dragItem, ply:GetPos())
        saveData(ply, bank, "Bank")
        saveData(ply, inv,  "Inventory")
    end)
end