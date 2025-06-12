include('inv_config.lua')
include('inv_shared.lua')
include('autorun/client/inv_base_slot.lua')
include('autorun/client/inv_base_window.lua')
if CLIENT then
    local function createTradeSlots(parent, startIndex, count)
        local grid = vgui.Create('DGrid', parent)
        grid:SetCols(5)
        grid:SetColWide(72)
        grid:SetRowHeight(72)
        local slots = {}
        for i = 1, count do
            local s = vgui.Create('inv_slot', parent)
            s:SetSize(70, 70)
            s.Highlighted = false
            s.Id = startIndex + i - 1
            grid:AddItem(s)
            slots[i] = s
        end
        return grid, slots
    end

    local myData, otherData
    local partner
    net.Receive('trade_open', function()
        partner = net.ReadEntity()
        myData = net.ReadTable()
        otherData = net.ReadTable()

        if IsValid(Invenotry_Gui.TradeFrame) then Invenotry_Gui.TradeFrame:Remove() end
        Invenotry_Gui.TradeFrame = vgui.Create('inv_window')
        Invenotry_Gui.TradeFrame:SetTitle('Trade with ' .. partner:Nick())
        Invenotry_Gui.TradeFrame:SetSize(72 * 8 + 80, 420)
        Invenotry_Gui.TradeFrame:Center()
        Invenotry_Gui.TradeFrame:ShowCloseButton(true)
        Invenotry_Gui.TradeFrame:SetVisible(true)

        local scrollL = vgui.Create('DScrollPanel', Invenotry_Gui.TradeFrame)
        scrollL:SetPos(10, 30)
        scrollL:SetSize(72 * 4, 72 * 4)
        local gridL = vgui.Create('DGrid', scrollL)
        gridL:Dock(FILL)
        gridL:SetCols(4)
        gridL:SetColWide(72)
        gridL:SetRowHeight(72)

        LocalPlayer().TradeSlotsL = {}
        for i = 1, 40 do
            local slot = vgui.Create('inv_slot', Invenotry_Gui.TradeFrame)
            slot.Id = i
            slot:SetModel(myData[i].Model)
            slot:SetCount(myData[i].Count)
            slot:SetName(myData[i].Name)
            slot:SetItemClass(myData[i].ItemClass)
            slot:SetWeaponClass(myData[i].WeaponClass)
            slot.Icon.DoClick = function()
                net.Start('trade_select')
                net.WriteBool(true)
                net.WriteUInt(slot.Id, 8)
                net.SendToServer()
            end
            gridL:AddItem(slot)
            LocalPlayer().TradeSlotsL[i] = slot
        end

        local scrollR = vgui.Create('DScrollPanel', Invenotry_Gui.TradeFrame)
        scrollR:SetPos(Invenotry_Gui.TradeFrame:GetWide() - (72 * 4 + 10), 30)
        scrollR:SetSize(72 * 4, 72 * 4)
        local gridR = vgui.Create('DGrid', scrollR)
        gridR:Dock(FILL)
        gridR:SetCols(4)
        gridR:SetColWide(72)
        gridR:SetRowHeight(72)

        LocalPlayer().TradeSlotsR = {}
        for i = 1, 40 do
            local slot = vgui.Create('inv_slot', Invenotry_Gui.TradeFrame)
            slot.Id = i
            slot:SetModel(otherData[i].Model)
            slot:SetCount(otherData[i].Count)
            slot:SetName(otherData[i].Name)
            slot:SetItemClass(otherData[i].ItemClass)
            slot:SetWeaponClass(otherData[i].WeaponClass)
            slot.Icon.DoClick = function()
                net.Start('trade_select')
                net.WriteBool(false)
                net.WriteUInt(slot.Id, 8)
                net.SendToServer()
            end
            gridR:AddItem(slot)
            LocalPlayer().TradeSlotsR[i] = slot
        end

        local centerPanel = vgui.Create('DPanel', Invenotry_Gui.TradeFrame)
        centerPanel:SetSize(72 * 5, 150)
        centerPanel:SetPos((Invenotry_Gui.TradeFrame:GetWide() - centerPanel:GetWide()) / 2, 30)
        local gridC, tradeSlots = createTradeSlots(centerPanel, 1, 10)
        gridC:Dock(FILL)
        LocalPlayer().TradeCenterSlots = tradeSlots

        Invenotry_Gui.TradeFrame.Approve = vgui.Create('DButton', Invenotry_Gui.TradeFrame)
        Invenotry_Gui.TradeFrame.Approve:SetText('Approve (0/2)')
        Invenotry_Gui.TradeFrame.Approve:SetPos((Invenotry_Gui.TradeFrame:GetWide() - 120) / 2, centerPanel:GetY() + centerPanel:GetTall() + 10)
        Invenotry_Gui.TradeFrame.Approve:SetSize(120, 25)
        Invenotry_Gui.TradeFrame.Approve.DoClick = function()
            net.Start('trade_confirm')
            net.SendToServer()
        end
    end)

    net.Receive('trade_update', function()
        partner = net.ReadEntity()
        local myOffers = net.ReadTable()
        local myWants = net.ReadTable()
        local myC = net.ReadBool()
        local otherOffers = net.ReadTable()
        local otherWants = net.ReadTable()
        local otherC = net.ReadBool()

        local approved = 0
        if myC then approved = approved + 1 end
        if otherC then approved = approved + 1 end
        if IsValid(Invenotry_Gui.TradeFrame) then
            Invenotry_Gui.TradeFrame.Approve:SetText('Approve (' .. approved .. '/2)')
        end
    end)

    net.Receive('trade_end', function()
        if IsValid(Invenotry_Gui.TradeFrame) then
            Invenotry_Gui.TradeFrame:Close()
        end
    end)
end
