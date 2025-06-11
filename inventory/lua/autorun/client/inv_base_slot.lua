include('inv_config.lua')
if CLIENT then 
    PANEL = {}
    AccessorFunc( PANEL, "m_bcount_inv",		"Count" )
    AccessorFunc( PANEL, "m_bname_inv",		"Name" )
    AccessorFunc( PANEL, "m_bclass_inv",		"ItemClass" )
    AccessorFunc( PANEL, "m_bwepclass_inv",		"WeaponClass" )
    
    function PANEL:SetModel(mdl)
        if mdl ~= nil and mdl ~= "Unknown" then
            self.Icon:SetModel(mdl) 
            self.Model = mdl
        end  
    end
    function PANEL:GetModel() 
        return self.Model  
    end
    function PANEL:Init()   
        self:SetSize(70,70) 
        self:SetPos(150,50)    
        self.Icon = vgui.Create("SpawnIcon", self)   
        self.Icon:Droppable("inv_drop") 
        self:Receiver( 'inv_drop', 
        function( pnl, item, drop, i, x, y )
            item = item[1]
            if drop then
                net.Start("swapItems_inv")
                net.WriteString(pnl.Id)
                net.WriteString(item:GetParent().Id)
                net.WriteString("Inventory")
                net.SendToServer()  
            end 
        end, {} )
        self:Receiver( 'inv_droppingFromBank', 
        function( pnl, item, drop, i, x, y )
            if drop then
                item = item[1] 
                net.Start("transferItems_inv")
                net.WriteString(tostring(pnl.Id))
                net.WriteString(tostring(item.Id))
                net.WriteString("Inventory")
                net.SendToServer()
            end
        end, {} )
        self.Icon:SetSize(70,70)   
        self.Icon:Center() 
        self.Icon:SetMouseInputEnabled( true )
        function self.Icon:PaintOver()end
        function self.Icon:Paint(w,h)
            if self.Highlighted then 
                draw.RoundedBox( 0, 0, 0, w, h, Color(255,0,0) )
            else
                draw.RoundedBox( 0, 0, 0, w, h, InventoryConfig.Colors.primaryColor )
            end
        end
        function self.Icon.DoClick()
            self.Menu = DermaMenu()
            self.Menu:AddOption( InventoryConfig.GuiText.use ):SetIcon( "icon16/accept.png" )
            self.Menu:AddSpacer()
            self.Menu:AddOption( InventoryConfig.GuiText.drop ):SetIcon( "icon16/cancel.png" )
            self.Menu:AddOption( InventoryConfig.GuiText.dropAll ):SetIcon( "icon16/cancel.png" )
            self.Menu:SetPos(gui.MousePos())
            self.Menu:MoveToFront()
            self.Menu:MakePopup()
            function self.Menu.OptionSelected(btn, option, text )
                if text == InventoryConfig.GuiText.use then 
                    net.Start( "useEnt_inv" )
                    net.WriteString(tostring(self.Id))
                    if self.isInventory == nil then  net.WriteString("Bank") else net.WriteString("Inventory") end
                    if self:GetWeaponClass() ~= nil then  
                        net.WriteString(self:GetWeaponClass())
                    end  
                    net.SendToServer(LocalPlayer())
                    if self:GetCount() > 1 then 
                        self:SetCount(self:GetCount()-1)
                    else 
                        self:SetCount(0) 
                        self.IsOccupied = false
                    end
                end    
                if text == InventoryConfig.GuiText.drop then 
                    net.Start( "dropEnt_inv" )
                    net.WriteString(tostring(self.Id))
                    if self.isInventory == nil then  net.WriteString("Bank") else  net.WriteString("Inventory") end
                    net.WriteString("1") 
                    net.SendToServer(LocalPlayer()) 
                    if self:GetCount() > 1 then 
                        self:SetCount(self:GetCount()-1)
                    else
                        self:SetCount(0)
                    end
                end
                if text == InventoryConfig.GuiText.dropAll then 
                    net.Start( "dropEnt_inv" ) 
                    net.WriteString(tostring(self.Id))  
                    if self.isInventory == nil then  net.WriteString("Bank") else  net.WriteString("Inventory") end
                    net.WriteString(tostring(self:GetCount())) 
                    net.SendToServer(LocalPlayer())
                    self:SetCount(0)
                end
                
            end
        end
    end    
    function PANEL:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, InventoryConfig.Colors.primaryColor )
    end 
    function PANEL:PaintOver(w,h) 
        self.Icon:SetTooltip(false)
        if not (self:GetName() == "unknown" or self:GetName() == "Unknown" or self.IsOccupied == false) then
            if self:GetName() ~= self:GetItemClass() then
                self.Icon:SetTooltip(self:GetName())
            end
        end 
        
        if self.Icon:GetModelName() == nil then 
            self.Icon:SetVisible(false)
        else
            self.Icon:SetVisible(true)
        end
        if self:GetCount() == nil or self:GetCount() == 0 then
            self.Icon:SetVisible(false)
            return
        end
        if self:GetCount() > 1 then 
            draw.DrawText( self:GetCount().."x", "DermaDefault", 6, 6, InventoryConfig.Colors.textColor, TEXT_ALIGN_LEFT )
        end 
    end 
    vgui.Register( "inv_slot", PANEL, "DPanel" ) 
end 