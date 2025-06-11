include('inv_config.lua')
include('inv_shared.lua')
if CLIENT then
    local FRAME = {} 
    AccessorFunc( FRAME, "m_bclossable",		"Closable",		FORCE_BOOL )
    function FRAME:Init()
        FRAME.CloseButton = vgui.Create("DButton", self)
        FRAME.Title = vgui.Create( "DLabel", self )
        FRAME.Title:SetText("inv_window")
        FRAME.Title:SetFont("inv_title_font")
        FRAME.Title:SetContentAlignment( 4 )

        self.startTime = SysTime() 
    end        
    function FRAME:ShowCloseButton( bShow ) 
        self:SetClosable(bShow)
    end
    function FRAME:SetTitle( strTitle )
        FRAME.Title:SetText(strTitle)
    end 
    function FRAME:GetTitle( ) 
        return FRAME.Title:GetText()
    end
    function FRAME:PerformLayout()
        FRAME.CloseButton:SetSize(25-5,25-5)
        FRAME.CloseButton:SetPos((self:GetWide()-23.5),2.5)
        FRAME.CloseButton:SetVisible(self:GetClosable())
        FRAME.CloseButton:SetText("X") 
        FRAME.CloseButton:SetTextColor(InventoryConfig.Colors.textColor)
        FRAME.CloseButton.Paint = function (self,w,h)
            draw.RoundedBox( 0, 0, 0, w, h, InventoryConfig.Colors.secondaryColor )
        end
        FRAME.CloseButton.DoClick = function()
            Invenotry_Gui.InvFrame:SetVisible(false)
            Invenotry_Gui.BankFrame:SetVisible(false)  
            gui.EnableScreenClicker(false)
        end
        self.btnClose:SetVisible(false)
        self.btnMaxim:SetVisible(false)
        self.btnMinim:SetVisible(false)
        self.lblTitle:SetVisible(false)
        FRAME.Title:SetSize(self:GetWide()-80, 25)
        FRAME.Title:SetPos(10,0)
    end
    function FRAME:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, InventoryConfig.Colors.primaryColor )
        draw.RoundedBox( 0, 2.5, 2.5, w-5, h-5, InventoryConfig.Colors.secondaryColor )
        draw.RoundedBox( 0, 0, 0, w, 25, InventoryConfig.Colors.primaryColor )
   end
   vgui.Register( "inv_window", FRAME, "DFrame" )
end