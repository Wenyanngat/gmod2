include('inv_shared.lua')
include('inv_config.lua')
include('autorun/client/inv_base_slot.lua')
include('autorun/client/inv_base_window.lua')   
include('autorun/client/inv_init_c.lua')
if CLIENT then  
    hook.Add( "InitPostEntity", "d61125x15", function()
    local scale = 1.8     
    local ply = LocalPlayer()  
    ply.BankSlots = {}       
    Invenotry_Gui.BankFrame = vgui.Create( "inv_window" )
    Invenotry_Gui.BankFrame:ShowCloseButton( true )  
    Invenotry_Gui.BankFrame:SetTitle( "Хранилище" )     
    Invenotry_Gui.BankFrame:SetSize( (72*8+35), 220*scale )    
    Invenotry_Gui.BankFrame:SetDeleteOnClose(false)  
    Invenotry_Gui.BankFrame:SetVisible(false)  
 
    local WeightLabel = vgui.Create("DLabel", Invenotry_Gui.BankFrame) 
    local fx, fy = Invenotry_Gui.BankFrame:GetSize()
    WeightLabel:SetSize(fx, 50)
    WeightLabel:SetPos(0,fy-55)  
    WeightLabel:SetContentAlignment( 5 )  
    WeightLabel:SetColor(InventoryConfig.Colors.textColor)
    WeightLabel:SetFont("WeightFont")               
    WeightLabel:SetText(InventoryConfig.GuiText.totalWeight.."0 / "..getMaxWeight(LocalPlayer(), "Хранилище").." кг")

    net.Receive( "openBankGui", function( len, player )
        local invW, invH = Invenotry_Gui.InvFrame:GetSize()
        local bankW, bankH = Invenotry_Gui.BankFrame:GetSize()
          
        Invenotry_Gui.InvFrame:SetPos((ScrW()-(invW + bankW))/2,(ScrH()/2)-invH/2)   local invX, invY = Invenotry_Gui.InvFrame:GetPos()
        Invenotry_Gui.BankFrame:SetPos(invW+invX+5,(ScrH()/2)-bankH/2) 

        Invenotry_Gui.InvFrame:SetVisible(true)
        Invenotry_Gui.BankFrame:SetVisible(true)  
        Invenotry_Gui.InvFrame:MakePopup()
        Invenotry_Gui.BankFrame:MakePopup()
        gui.EnableScreenClicker(true) 
        sound.Play( InventoryConfig.Sounds.openStorage, LocalPlayer():GetPos() )
        net.Start("inv_requestUpdate")
        net.SendToServer()
   end ) 

    local lastTime=0  
    function refreshBank(tab)
        if tab ~= nil then
            local totalWeight = 0
            for i = 1, 32 do 
                LocalPlayer().BankSlots[i].IsOccupied  = tab[i].IsOccupied 
                LocalPlayer().BankSlots[i].VGui:SetCount(tab[i].Count)  
                if tab[i].Model ~= nil and tab[i].Count > 0 then
                    LocalPlayer().BankSlots[i].VGui:SetModel(tab[i].Model) 
                end 
                LocalPlayer().BankSlots[i].VGui:SetName(tab[i].Name) 
                LocalPlayer().BankSlots[i].VGui:SetItemClass(tab[i].ItemClass) 
                LocalPlayer().BankSlots[i].VGui:SetWeaponClass(tab[i].WeaponClass) 
                totalWeight = (totalWeight + (tonumber(tab[i].SingleWeight) * tonumber(tab[i].Count)))
            end 
            WeightLabel:SetText(InventoryConfig.GuiText.totalWeight..totalWeight.." / "..getMaxWeight(LocalPlayer(), "Хранилище").." кг")
        end
    end 
    net.Receive( "forceRefresh_bank", function( len, ply ) refreshBank(net.ReadTable())  end)

    local grid = vgui.Create( "DGrid", Invenotry_Gui.BankFrame )
    grid:SetPos( 10*scale, 30*scale ) 
    grid:SetCols( 8 )
    grid:SetColWide( 72 )          
    grid:SetRowHeight(72)     
    
    for i = 1, 32 do                   
        ply.BankSlots[i] = {}          
        ply.BankSlots[i].VGui = vgui.Create("inv_slot", Invenotry_Gui.BankFrame)
        ply.BankSlots[i].VGui.Icon:Droppable("bank_drop")
        ply.BankSlots[i].IsOccupied = false 
        ply.BankSlots[i].VGui.Id = i 
        ply.BankSlots[i].VGui.Icon.Id = i 
        ply.BankSlots[i].VGui:Receiver( 'inv_drop', 
        function( pnl, item, drop, i, x, y )
            item = item[1]
            for e = 1, 32 do    
                if ply.BankSlots[e].VGui.Id == pnl.Id then 
                 ply.BankSlots[e].VGui:SetAlpha(100)
            else
                 ply.BankSlots[e].VGui:SetAlpha(255) 
                end
            end
            for e = 1, 16 do
                ply.InventorySlots[e].VGui:SetAlpha(255) 
            end
            if drop then
                -- drop na bank  
                net.Start("transferItems_inv")
                net.WriteString(tostring(item.Id))
                net.WriteString(tostring(pnl.Id)) 
                net.WriteString("Хранилище")
                net.SendToServer()
                --pnl.Id -- bank
                --item.Id -- inv
                ply.BankSlots[pnl.Id].VGui:SetAlpha(255) 
            end 
        end, {} )
        ply.BankSlots[i].VGui:Receiver( 'bank_drop', 
        function( pnl, item, drop, i, x, y )
            item = item[1] 
            for e = 1, 32 do    
                if ply.BankSlots[e].VGui.Id == pnl.Id then 
                 ply.BankSlots[e].VGui:SetAlpha(100)
            else
                 ply.BankSlots[e].VGui:SetAlpha(255) 
                end
            end
            for e = 1, 16 do
                ply.InventorySlots[e].VGui:SetAlpha(255) 
            end
            if drop then
                net.Start("swapItems_inv")
                net.WriteString(pnl.Id)
                net.WriteString(item:GetParent().Id)
                net.WriteString("Хранилище")
                net.SendToServer()  
                ply.BankSlots[pnl.Id].VGui:SetAlpha(255) 
            end
        end, {} )
        ply.BankSlots[i].VGui.Icon:Droppable("inv_droppingFromBank") 
        grid:AddItem( ply.BankSlots[i].VGui)    
    end    
end)
end 
  