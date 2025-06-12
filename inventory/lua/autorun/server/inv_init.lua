include("inv_config.lua")
include("inv_shared.lua")

if SERVER then
    -- ─────────────────────────────────────────────────────────────
    --  FILE DISTRIBUTION TO CLIENT
    -- ─────────────────────────────────────────────────────────────
    AddCSLuaFile("lua/autorun/client/inv_base_slot.lua")
    AddCSLuaFile("lua/autorun/client/inv_base_window.lua")
    AddCSLuaFile("lua/autorun/client/inv_gui.lua")
    AddCSLuaFile("lua/autorun/client/inv_bank_gui.lua")
    AddCSLuaFile("lua/autorun/client/inv_init_c.lua")
    local loadData
    local saveData

        return {
            isOccupied = false,
            Count = 0,
            Name = "unknown",
            ItemClass = "unknown",
            WeaponClass = "unknown",
            SingleWeight = 0,
            MaxStack = 20
        }
    AddCSLuaFile("lua/inv_shared.lua")
    AddCSLuaFile("lua/inv_config.lua")

    -- ─────────────────────────────────────────────────────────────
    --  NETWORK STRINGS
    -- ─────────────────────────────────────────────────────────────
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

    -- trading
    util.AddNetworkString("trade_open")
    util.AddNetworkString("trade_select")
    util.AddNetworkString("trade_confirm")
    util.AddNetworkString("trade_update")
    util.AddNetworkString("trade_end")

    -- ─────────────────────────────────────────────────────────────
    --  TRADE STATE
    -- ─────────────────────────────────────────────────────────────
    local ActiveTrades = {}

    local function clearSlot()
        return {
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

    -- tries to drop an item into the first compatible slot, else first free slot
    local function insertItem(inv, data)
        for i = 1, 40 do
            local s = inv[i]
            if s.ItemClass == data.ItemClass
               and s.Name == data.Name
               and s.Count + data.Count <= (s.MaxStack or data.MaxStack or 20) then
                s.Count      = s.Count + data.Count
                s.isOccupied = true
                return true
            end
        end
        for i = 1, 40 do
            if not inv[i].isOccupied then
                inv[i] = table.Copy(data)
                return true
            end
        end
        return false
    end

    -- send both players a fresh view of the trade window
    local function tradeBroadcast(p1, p2)
        local s1, s2 = ActiveTrades[p1], ActiveTrades[p2]
        if not s1 or not s2 then return end
        net.Start("trade_update")
            net.WriteEntity(p2)
            net.WriteTable(s1.offers)
            net.WriteTable(s1.wants)
            net.WriteBool(s1.confirmed)
            net.WriteTable(s2.offers)
            net.WriteTable(s2.wants)
            net.WriteBool(s2.confirmed)
        net.Send({p1, p2})
    end

    local function endTrade(p1, p2)
        ActiveTrades[p1] = nil
        ActiveTrades[p2] = nil
        net.Start("trade_end")
        net.Send({p1, p2})
    end

    -- actually move items once both players confirm
    local function finalizeTrade(p1, p2)
        local inv1 = loadData(p1, "Inventory")
        local inv2 = loadData(p2, "Inventory")

        for id in pairs(ActiveTrades[p1].offers) do
            local slot = inv1[id]
            if slot and slot.Count > 0 then
                if not insertItem(inv2, slot) then
                    showNotification(p1, InventoryConfig.Messages.noSpace)
                    showNotification(p2, InventoryConfig.Messages.noSpace)
                    endTrade(p1, p2)
                    return
        local path = InventoryConfig.General.playerDataFolder .. "/" .. ply:SteamID64() .. "_" .. typ .. ".dat"
        if file.Exists(path, "DATA") then
            local data = util.JSONToTable(file.Read(path, "DATA")) or {}
                data[i] = data[i] or clearSlot()
            for i = 1, range do
                eq[i] = clearSlot()
            end
            if not file.Exists(InventoryConfig.General.playerDataFolder, "DATA") then
                file.CreateDir(InventoryConfig.General.playerDataFolder)
            file.Write(path, util.TableToJSON(eq))
            end
        end
        saveData(p1, inv1, "Inventory")
        saveData(p2, inv2, "Inventory")
        endTrade(p1, p2)
    end

    local function startTrade(p1, p2)
        ActiveTrades[p1] = {partner = p2, offers = {}, wants = {}, confirmed = false}
        ActiveTrades[p2] = {partner = p1, offers = {}, wants = {}, confirmed = false}

        net.Start("trade_open")
            net.WriteEntity(p2)
            net.WriteTable(loadData(p1, "Inventory"))
            net.WriteTable(loadData(p2, "Inventory"))
        net.Send(p1)

        net.Start("trade_open")
            net.WriteEntity(p1)
            net.WriteTable(loadData(p2, "Inventory"))
            net.WriteTable(loadData(p1, "Inventory"))
        net.Send(p2)
    end

    local function showNotification(ply, msg)
        net.Start("inv_showNotification")
            net.WriteString(msg)
        net.Send(ply)
    end

    -- ─────────────────────────────────────────────────────────────
    --  FILE PERSISTENCE HELPERS
    -- ─────────────────────────────────────────────────────────────
    local function saveData() end -- forward declaration so loadData compiles

    local function loadData(ply, typ)
        local path = InventoryConfig.General.playerDataFolder
        local filePath = string.format("%s/%s_%s.dat", path, ply:SteamID64(), typ)

        if file.Exists(filePath, "DATA") then
            local data = util.JSONToTable(file.Read(filePath, "DATA")) or {}
            local max  = (typ == "Inventory") and 40 or 32

            for i = 1, max do
                data[i] = data[i] or clearSlot()
                data[i].MaxStack = data[i].MaxStack or 20   ---- merge note: safeguard
            end
            return data
        end

        -- first time load → create empty structure
        local fresh = {}
        local max = (typ == "Inventory") and 40 or 32
        for i = 1, max do fresh[i] = clearSlot() end
        saveData(ply, fresh, typ)
        return fresh
    end

    function saveData(ply, tbl, typ)
        local dir = InventoryConfig.General.playerDataFolder
        if not file.Exists(dir, "DATA") then
            file.CreateDir(dir)
        end

        local filePath = string.format("%s/%s_%s.dat", dir, ply:SteamID64(), typ)
        file.Write(filePath, util.TableToJSON(tbl))

        if typ == "Inventory" then
            net.Start("forceRefresh_inv")
            net.WriteTable(tbl)
            net.Send(ply)
        elseif typ == "Bank" then
            net.Start("forceRefresh_bank")
            net.WriteTable(tbl)
            net.Send(ply)
        end
    end

    -- client requests a refresh (e.g., on reconnect)
    net.Receive("inv_requestUpdate", function(_, ply)
        net.Start("forceRefresh_inv")
            net.WriteTable(loadData(ply, "Inventory"))
        net.Send(ply)

        net.Start("forceRefresh_bank")
            net.WriteTable(loadData(ply, "Bank"))
        net.Send(ply)
    end)

    -- ─────────────────────────────────────────────────────────────
    --  DROP / USE ITEMS
    -- ─────────────────────────────────────────────────────────────
    net.Receive("dropEnt_inv", function(_, ply)
        local id       = tonumber(net.ReadString())
        local typ      = net.ReadString()       -- "Inventory" or "Bank"
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
            local phys = ent:GetPhysicsObject()
            if phys:IsValid() then phys:Wake() end

            -- adjust slot
            dat[id].Count = dat[id].Count - 1
            if dat[id].Count <= 0 then
                dat[id] = clearSlot()
            end
        end

        saveData(ply, dat, typ)
    end)

    net.Receive("useEnt_inv", function(_, ply)
        local id       = tonumber(net.ReadString())
        local typ      = net.ReadString()
        local dat      = loadData(ply, typ)
        local class    = dat[id].ItemClass
        local model    = dat[id].Model
        local wepClass = net.ReadString()

        if class == "spawned_weapon" and wepClass then
            local ent = ents.Create(wepClass)
            ent.nodupe = true
            timer.Simple(0.1, function()
                ent:SetPos(ply:GetPos())
                ent:Spawn()
                ent:Activate()
                ent:Use(ply, ply, USE_ON, 1)
            end)
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

        dat[id].Count = dat[id].Count - 1
        if dat[id].Count <= 0 then dat[id] = clearSlot() end
        saveData(ply, dat, typ)
    end)

    -- ─────────────────────────────────────────────────────────────
    --  PLAYER META – PICKUP
    -- ─────────────────────────────────────────────────────────────
    local plyMeta = FindMetaTable("Player")

    function plyMeta:AddInventoryItem(ent, count)
        local eq = loadData(self, "Inventory")

        -- find slot: first same-item stack with room, else empty
        for _, slot in ipairs(eq) do
            ent.StackSize = ent.StackSize or 1
            if (not slot.isOccupied) or (slot.ItemClass == ent:GetClass() and slot.Count < ent.StackSize) then
                slot.isOccupied   = true
                slot.Count        = slot.Count + 1
                slot.Name         = ent.Name or ent:GetClass()
                slot.ItemClass    = ent:GetClass()
                slot.Model        = ent:GetModel()
                slot.MaxStack     = ent.StackSize
                slot.SingleWeight = ent.Weight or 1
        showNotification(self, InventoryConfig.Messages.noSpace)

                saveData(self, eq, "Inventory")

                -- remove or decrement dropped entity
                if slot.ItemClass == "spawned_weapon" and ent:Getamount() > 1 then
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

    -- allow pressing E on nearby pickable props / money / weapons
    local debounceLastTime = 0
    hook.Add("Think", "inv_trace_think", function()
        for _, ply in ipairs(player.GetAll()) do
            local tr = ply:GetEyeTrace()
            local ent = tr.Entity
            if IsValid(ent) and (ent:GetClass() == "spawned_weapon" or ent.Pickable) then
                if tr.HitPos:Distance(ply:GetPos()) <= 90 then
                    function ent:Use(activator, caller)
                        if CurTime() > debounceLastTime + 0.1 then
                            caller:AddInventoryItem(self, 1)
                        end
                        debounceLastTime = CurTime()
                    end
                end
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────────
    --  INVENTORY <--> BANK SWAP & REORDER
    -- ─────────────────────────────────────────────────────────────
    net.Receive("swapItems_inv", function(_, ply)
        local a  = tonumber(net.ReadString())
        local b  = tonumber(net.ReadString())
        if a == b then return end

        local typ = net.ReadString() -- "Inventory" or "Bank"
        local eq  = loadData(ply, typ)

        if eq[a].ItemClass == eq[b].ItemClass
           and eq[a].Name == eq[b].Name
           and eq[a].Count + eq[b].Count <= (eq[b].MaxStack or eq[a].MaxStack or 20) then
            -- merge two stacks
            eq[a].Count      = eq[a].Count + eq[b].Count
            eq[b]            = clearSlot()
        else
            eq[a], eq[b] = eq[b], eq[a] -- simple swap
        end

        sound.Play(InventoryConfig.Sounds.dragItem, ply:GetPos())
        saveData(ply, eq, typ)
    end)

    net.Receive("transferItems_inv", function(_, ply)
        local invID        = tonumber(net.ReadString()) -- slot in inventory
        local bankID       = tonumber(net.ReadString()) -- slot in bank-gui
        local dest         = net.ReadString()           -- "Inventory" or "Bank"
        local inv          = loadData(ply, "Inventory")
        local bank         = loadData(ply, "Bank")

        -- same item? try to merge
        if inv[invID].Name == bank[bankID].Name
           and inv[invID].ItemClass == bank[bankID].ItemClass
           and inv[invID].Count + bank[bankID].Count <= (bank[bankID].MaxStack or inv[invID].MaxStack or 20) then

            if dest == "Inventory" then
                inv[invID].Count = inv[invID].Count + bank[bankID].Count
                bank[bankID]     = clearSlot()
            else
                bank[bankID].Count = inv[invID].Count + bank[bankID].Count
                inv[invID]         = clearSlot()
            end
        else
            -- just swap slots
            bank[bankID], inv[invID] = inv[invID], bank[bankID]
        end

        sound.Play(InventoryConfig.Sounds.dragItem, ply:GetPos())
        saveData(ply, bank, "Bank")
        saveData(ply, inv,  "Inventory")
    end)

    -- ─────────────────────────────────────────────────────────────
    --  TRADE NET MSGS
    -- ─────────────────────────────────────────────────────────────
    net.Receive("trade_select", function(_, ply)
        local own    = net.ReadBool()
        local slotID = net.ReadUInt(8)
        local s      = ActiveTrades[ply]
        if not s then return end

        s.confirmed = false
        ActiveTrades[s.partner].confirmed = false

        local tbl = own and s.offers or s.wants
        if tbl[slotID] then
            tbl[slotID] = nil
        else
            tbl[slotID] = true
        end
        tradeBroadcast(ply, s.partner)
    end)

    net.Receive("trade_confirm", function(_, ply)
        local s = ActiveTrades[ply]
        if not s then return end
        s.confirmed = true
        tradeBroadcast(ply, s.partner)

        if ActiveTrades[s.partner] and ActiveTrades[s.partner].confirmed then
            finalizeTrade(ply, s.partner)
        end
    end)

    -- ─────────────────────────────────────────────────────────────
    --  TRADE CLEANUP HELPERS
    -- ─────────────────────────────────────────────────────────────
    hook.Add("PlayerSay", "inventory_trade_cmd", function(ply, txt)
        if string.Trim(string.lower(txt)) == "/trade nearby" then
            local target
            for _, p in ipairs(player.GetAll()) do
                if p ~= ply and p:GetPos():Distance(ply:GetPos()) <= 100 then
                    target = p
                    break
                end
            end
            if target then
                if not ActiveTrades[ply] and not ActiveTrades[target] then
                    startTrade(ply, target)
                end
            else
                showNotification(ply, "No nearby player")
            end
            return ""
        end
    end)

    hook.Add("PlayerDisconnected", "inventory_trade_cleanup", function(ply)
        local s = ActiveTrades[ply]
        if s then endTrade(ply, s.partner) end
    end)
end
