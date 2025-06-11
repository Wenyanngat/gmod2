include('inv_config.lua')
include('inv_shared.lua')
inv_HoloItems = {}  
if CLIENT then 
    hook.Add( "Think", "inv_trace_think", function()
        if InventoryConfig.General.haloEnabled then
            local trace = LocalPlayer():GetEyeTrace()  
            if trace.Hit then
                if trace.Entity:GetClass() == "spawned_weapon" or trace.Entity.Pickable == true then
                    if trace.HitPos:Distance(LocalPlayer():GetPos()) <= 90 then 
                        inv_HoloItems[0] = trace.Entity
                    else
                        inv_HoloItems[0] = nil
                    end  
                else  
                    inv_HoloItems[0] = nil    
                end     
            end
        end
    end )          
    hook.Add( "PreDrawHalos", "AddPropHalos_inv", function()
        if InventoryConfig.General.haloColor == nil then InventoryConfig.General.haloColor = Color(255,255,255) end
        halo.Add( inv_HoloItems, InventoryConfig.General.haloColor, 3, 3, 3 )
    end )   
    net.Receive( "inv_showNotification", function( len, ply )
        notification.AddLegacy( net.ReadString(), NOTIFY_ERROR, 2 )
        surface.PlaySound( "buttons/button15.wav" )
    end ) 
end

hook.Add( "Think", "clearAlphaIfNeeded", function()
    if not input.IsMouseDown(MOUSE_LEFT) and (Invenotry_Gui.InvFrame:IsVisible() or Invenotry_Gui.BankFrame:IsVisible()) then
        for e=1,32 do  
            LocalPlayer().BankSlots[e].VGui:SetAlpha(255)
        end
        for e=1,16 do   
            LocalPlayer().InventorySlots[e].VGui:SetAlpha(255)
        end
    end
end)
