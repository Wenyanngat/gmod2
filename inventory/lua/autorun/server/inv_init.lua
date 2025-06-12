include('inv_config.lua')
include('inv_shared.lua')
if SERVER then
    AddCSLuaFile( "lua/autorun/client/inv_base_slot.lua")
    AddCSLuaFile( "lua/autorun/client/inv_base_window.lua")

    AddCSLuaFile( "lua/autorun/client/inv_gui.lua")
    AddCSLuaFile( "lua/autorun/client/inv_bank_gui.lua")
    AddCSLuaFile( "lua/autorun/client/inv_init_c.lua")
    AddCSLuaFile( "lua/autorun/client/inv_trade_gui.lua")
    AddCSLuaFile( "lua/inv_shared.lua")
    AddCSLuaFile( "lua/inv_config.lua")
 
    util.AddNetworkString( "dropEnt_inv" )
    util.AddNetworkString( "swapItems_inv" )
    util.AddNetworkString( "forceRefresh_inv" )
    util.AddNetworkString( "forceRefresh_bank" )
    util.AddNetworkString( "useEnt_inv" )
    util.AddNetworkString( "addInventoryItem" )
    util.AddNetworkString( "inv_showNotification" )
    util.AddNetworkString( "openBankGui" )
    util.AddNetworkString( "transferItems_inv" )
    util.AddNetworkString( "validateFiles_inv" )

    -- trading
    util.AddNetworkString( "trade_open" )
    util.AddNetworkString( "trade_select" )
    util.AddNetworkString( "trade_confirm" )
    util.AddNetworkString( "trade_update" )
    util.AddNetworkString( "trade_end" )


    util.AddNetworkString( "inv_requestUpdate" )

    -- state for player trades
    local ActiveTrades = {}

    local function clearSlot()
        return {isOccupied = false, Count = 0, Name = "unknown", ItemClass = "unknown", WeaponClass = "unknown", SingleWeight = 0, MaxStack = 20}
    end

    local function insertItem(inv, data)
        for i = 1, 40 do
            local s = inv[i]
            if s.ItemClass == data.ItemClass and s.Name == data.Name and s.Count + data.Count <= (s.MaxStack or data.MaxStack or 20) then
                s.Count = s.Count + data.Count
                s.isOccupied = true
                return true
            end
        end
        for i = 1, 40 do
            local s = inv[i]
            if not s.isOccupied then
                inv[i] = table.Copy(data)
                return true
            end
        end
        return false
    end

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
                end
                inv1[id] = clearSlot()
            end
        end
        for id in pairs(ActiveTrades[p2].offers) do
            local slot = inv2[id]
            if slot and slot.Count > 0 then
                if not insertItem(inv1, slot) then
                    showNotification(p1, InventoryConfig.Messages.noSpace)
                    showNotification(p2, InventoryConfig.Messages.noSpace)
                    endTrade(p1, p2)
                    return
                end
                inv2[id] = clearSlot()
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
    -- Weight related functions removed

    local function saveData()end
    local function loadData(ply, typ)
        if file.Exists( InventoryConfig.General.playerDataFolder.."/"..ply:SteamID64().."_"..typ..".dat", "DATA" ) then
            local data = util.JSONToTable(file.Read( InventoryConfig.General.playerDataFolder.."/"..ply:SteamID64().."_"..typ..".dat", "DATA" ))
            local max = typ == "Inventory" and 40 or 32
            for i = 1, max do
                data[i] = data[i] or {isOccupied = false, Count = 0, Name = "unknown", ItemClass = "unknown", WeaponClass = "unknown", SingleWeight = 0, MaxStack = 20}
                if data[i].MaxStack == nil then
                    data[i].MaxStack = 20
                end
            end
            return data
        else
            local eq = {}
            local range = typ == "Inventory" and 40 or 32
            for i=1,range do
                eq[i] = {}
                eq[i].isOccupied = false
                eq[i].Count = 0
                eq[i].Name = "unknown"
                eq[i].ItemClass = "unknown"
                eq[i].WeaponClass = "unknown"
                eq[i].SingleWeight = 0
                eq[i].MaxStack = 20
            end
            saveData(ply, eq, typ)
            return eq
        end
    end
    local function saveData(ply, invslot, typ) 
        if not file.Exists(InventoryConfig.General.playerDataFolder, 'DATA') then
            file.CreateDir(InventoryConfig.General.playerDataFolder) 
        end
        file.Write(InventoryConfig.General.playerDataFolder.."/"..ply:SteamID64().."_"..typ..".dat",util.TableToJSON(invslot))
        if typ == "Inventory" then
            net.Start("forceRefresh_inv")
            net.WriteTable(invslot)
            net.Send(ply) 
        end
        if typ == "Bank" then 
            net.Start("forceRefresh_bank") 
            net.WriteTable(invslot)
            net.Send(ply)
        end
    end
    net.Receive( "inv_requestUpdate", function( len, ply )  
        net.Start("forceRefresh_inv")
        net.WriteTable(loadData(ply, "Inventory"))
        net.Send(ply)

        net.Start("forceRefresh_bank")
        net.WriteTable(loadData(ply, "Bank"))
        net.Send(ply)
    end ) 
    net.Receive( "dropEnt_inv", function( len, ply )
        local id = net.ReadString() 
        local type = net.ReadString()
        id = tonumber(id)
        local dat = loadData(ply, type)  
        local class = dat[id].ItemClass
        local model = dat[id].Model  
        local wepClass = dat[id].WeaponClass  
        local count = tonumber(net.ReadString())
        for i=1,count do 
            local ent = ents.Create(class)
            ent:SetPos( ply:EyePos() + ply:GetAimVector() * math.random(60,70) ) 
            ent:SetModel( model ) 
            ent:Spawn()
            ent:Activate() 
            if class == "spawned_weapon" then 
                ent:Setamount(1)
                ent:SetWeaponClass(wepClass)
            end 
            ent:PhysicsInit( SOLID_VPHYSICS )
            ent:SetMoveType( MOVETYPE_VPHYSICS )
            ent:SetSolid( SOLID_VPHYSICS )
            dat[id].Count = dat[id].Count - 1
            if dat[id].Count < 1 then
                dat[id].isOccupied = false
                dat[id].Count = 0
                dat[id].Name = "unknown"
                dat[id].ItemClass = "unknown"
                dat[id].WeaponClass = "unknown"
                dat[id].Model = nil
                dat[id].SingleWeight = 0
            end
            if count == i and count ~= 1 then 
                dat[id].isOccupied = false
                dat[id].Count = 0 
                dat[id].Name = "unknown" 
                dat[id].ItemClass = "unknown"
                dat[id].WeaponClass = "unknown"
                dat[id].Model = nil
                dat[id].SingleWeight = 0
            end  
            local phys = ent:GetPhysicsObject()
            if (phys:IsValid()) then
                phys:Wake()
            end  
            saveData(ply, dat,type)  
        end 
    end)
    net.Receive( "useEnt_inv", function( len, ply )
        local id = tonumber(net.ReadString())
        local type = net.ReadString()
        local dat = loadData(ply,type) 
        local class = dat[id].ItemClass  
        local model = dat[id].Model
        
        local wepClass = net.ReadString()
        if class == "spawned_weapon" then 
            if wepClass ~= nil then 
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
            ent:SetPos( ply:EyePos() + ply:GetAimVector() * math.random(60,70) ) 
            local phys = ent:GetPhysicsObject()
            if (phys:IsValid()) then 
                phys:Wake()
            end 
            timer.Simple(0.1, function()
                ent:Spawn()
                ent:Activate()
                ent:Use(ply, ply, USE_ON, 1)
            end)
        end
        if dat[id].Count-1 < 1 then
            dat[id].isOccupied = false
            dat[id].Count = 0 
            dat[id].Name = "unknown"
            dat[id].ItemClass = "unknown" 
            dat[id].WeaponClass = "unknown"
            dat[id].Model = nil 
            dat[id].SingleWeight = 0
        else 
            dat[id].Count = dat[id].Count - 1
        end
        saveData(ply, dat,type) 
    end )   
    local plyMeta = FindMetaTable( "Player" )         
    function plyMeta:AddInventoryItem(ent, count)
        local eq = loadData(self,"Inventory")  
        if eq == nil then
            eq = {}
            for i=1,40 do
                eq[i] = {}
                eq[i].isOccupied = false
                eq[i].Count = 0
                eq[i].Name = "unknown"
                eq[i].ItemClass = "unknown"
                eq[i].WeaponClass = "unknown"
                eq[i].SingleWeight = 0
            end
        end
        for i, slot in ipairs(eq) do
            if ent.StackSize == nil then ent.StackSize = 1 end
            if slot.isOccupied == false or (ent.StackSize > slot.Count and slot.ItemClass == ent:GetClass()) then
                if ent.Weight ~= nil then
                    slot.SingleWeight = ent.Weight
                else
                    slot.SingleWeight = 1
                end
                slot.isOccupied = true
                if ent.Name ~= nil then
                    slot.Name = ent.Name
                else
                    slot.Name = ent:GetClass()
                end
                slot.ItemClass = ent:GetClass()
                slot.Count = slot.Count + 1
                slot.Model = ent:GetModel()
                slot.MaxStack = ent.StackSize
                if slot.ItemClass == "spawned_weapon" then
                    slot.WeaponClass = ent:GetWeaponClass()
                else
                    slot.WeaponClass = nil
                end
                saveData(self, eq,"Inventory")
                if ent:GetClass() == "spawned_weapon" and ent:Getamount() > 1 then
                    ent:Setamount(ent:Getamount()-1)
                else
                    ent:Remove()
                end
                self:EmitSound(InventoryConfig.Sounds.pickUp)
                return
            end
        end
        -- no space
        showNotification(ply, InventoryConfig.Messages.noSpace)
    end
 

    -- Picking up objects
    local debounceLastTime=0  
    hook.Add( "Think", "inv_trace_think", function()
    for k, ply in ipairs( player.GetAll() ) do 
        local trace = ply:GetEyeTrace() 
        if trace.Hit then
                if trace.Entity:GetClass() == "spawned_weapon" or trace.Entity.Pickable == true then
                    if trace.HitPos:Distance(ply:GetPos()) <= 90 then 
                        function trace.Entity:Use( activator, caller, useType, vaule)  
                            if CurTime() > debounceLastTime+0.1 then 
                                caller:AddInventoryItem(self,1) 
                            end 
                            debounceLastTime = CurTime()
                        end 
                    end 
                end 
            end
        end
    end ) 
    net.Receive( "swapItems_inv", function( len, ply )
        local item1 = tonumber(net.ReadString())
        local item2 = tonumber(net.ReadString())
        if item1 == item2 then return end -- in case you're trying to drag this same item on itself
        local type = net.ReadString()
        local eq = loadData(ply,type) 
        if  eq[item1].ItemClass == eq[item2].ItemClass and
            eq[item1].Name == eq[item2].Name and
            eq[item1].Count + eq[item2].Count <= (eq[item2].MaxStack or eq[item1].MaxStack or 20) then
                eq[item1].Count = eq[item2].Count + eq[item1].Count
                eq[item2].isOccupied = false
                eq[item2].Count = 0 
            else
                local cache = eq[item1]
                eq[item1] = eq[item2]
                eq[item2] = cache
            end
            sound.Play( InventoryConfig.Sounds.dragItem, ply:GetPos() )
            saveData(ply, eq,type)
    end)
    net.Receive( "transferItems_inv", function( len, ply )
        local item1 = tonumber(net.ReadString()) -- inv id
        local item2 = tonumber(net.ReadString()) -- bank id
        local whereDropped = net.ReadString()
        local inv = loadData(ply,"Inventory")
        local bank = loadData(ply,"Bank")
        if whereDropped == "Inventory" then
            -- nothing to check when weight system is disabled
        else
            -- nothing to check when weight system is disabled
        end
        if inv[item1].Name == bank[item2].Name and inv[item1].ItemClass == bank[item2].ItemClass and
            inv[item1].Count + bank[item2].Count <= (bank[item2].MaxStack or inv[item1].MaxStack or 20) then
            if whereDropped == "Inventory" then 
                inv[item1].Count = inv[item1].Count+bank[item2].Count
                bank[item2].isOccupied = false
                bank[item2].Count = 0 
                bank[item2].Name = "Unknown"
                bank[item2].ItemClass = "Unknown"
                
            else
                bank[item2].Count = inv[item1].Count+bank[item2].Count
                inv[item1].isOccupied = false
                inv[item1].Count = 0 
                inv[item1].Name = "Unknown"
                inv[item1].ItemClass = "Unknown" 
            end
        else
            local cache = bank[item2]
            bank[item2] = inv[item1]
            inv[item1] = cache
        end
        sound.Play( InventoryConfig.Sounds.dragItem, ply:GetPos() )
        saveData(ply, bank,"Bank")
        saveData(ply, inv,"Inventory")
    end)

    net.Receive("trade_select", function(len, ply)
        local own = net.ReadBool()
        local slot = net.ReadUInt(8)
        local s = ActiveTrades[ply]
        if not s then return end
        s.confirmed = false
        ActiveTrades[s.partner].confirmed = false
        local tbl = own and s.offers or s.wants
        if tbl[slot] then
            tbl[slot] = nil
        else
            tbl[slot] = true
        end
        tradeBroadcast(ply, s.partner)
    end)

    net.Receive("trade_confirm", function(len, ply)
        local s = ActiveTrades[ply]
        if not s then return end
        s.confirmed = true
        tradeBroadcast(ply, s.partner)
        if ActiveTrades[s.partner] and ActiveTrades[s.partner].confirmed then
            finalizeTrade(ply, s.partner)
        end
    end)

    hook.Add("PlayerSay", "inventory_trade_cmd", function(ply, text)
        if string.Trim(string.lower(text)) == "/trade nearby" then
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
        if s then
            endTrade(ply, s.partner)
        end
    end)
end