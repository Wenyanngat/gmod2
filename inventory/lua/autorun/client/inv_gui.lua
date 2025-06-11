include("inv_shared.lua")
include("inv_config.lua")
include("autorun/client/inv_base_slot.lua")
include("autorun/client/inv_base_window.lua")
include("autorun/client/inv_init_c.lua")
if CLIENT then
    hook.Add(
        "InitPostEntity",
        "dc61x15",
        function()
            local scale = 1.8
            local ply = LocalPlayer()
            ply.InventorySlots = {}
            Invenotry_Gui.InvFrame = vgui.Create("inv_window")
            Invenotry_Gui.InvFrame:ShowCloseButton(true)
            Invenotry_Gui.InvFrame:SetTitle("Рюкзак")
            Invenotry_Gui.InvFrame:SetSize((72 * 4 + 35), 220 * scale)
            Invenotry_Gui.InvFrame:Center()
            Invenotry_Gui.InvFrame:SetDeleteOnClose(false)
            Invenotry_Gui.InvFrame:SetVisible(false)

            -- Weight system removed
            local lastTime = 0
            function refreshInv(tab)
                if tab ~= nil then
                    for i = 1, 40 do
                        LocalPlayer().InventorySlots[i].IsOccupied = tab[i].IsOccupied
                        LocalPlayer().InventorySlots[i].VGui:SetCount(tab[i].Count)
                        if tab[i].Model ~= nil and tab[i].Count > 0 then
                            LocalPlayer().InventorySlots[i].VGui:SetModel(tab[i].Model)
                        end
                        LocalPlayer().InventorySlots[i].VGui.isInventory = true
                        LocalPlayer().InventorySlots[i].VGui:SetName(tab[i].Name)
                        LocalPlayer().InventorySlots[i].VGui:SetItemClass(tab[i].ItemClass)
                        LocalPlayer().InventorySlots[i].VGui:SetWeaponClass(tab[i].WeaponClass)
                    end
                end
            end
            net.Receive(
                "forceRefresh_inv",
                function(len, ply)
                    refreshInv(net.ReadTable())
                end
            )

            local function bindThinkInv()
                if Invenotry_Gui.InvFrame:IsVisible() or Invenotry_Gui.BankFrame:IsVisible() then 
                    if not vgui.CursorVisible() then
                        local x,y = input.GetCursorPos()
                        gui.EnableScreenClicker(true)
                        input.SetCursorPos(x, y)
                    end
                end
                if CurTime() > lastTime + 0.2 then
                    if input.IsKeyDown(InventoryConfig.General.keyBind) then
                        if Invenotry_Gui.InvFrame:IsVisible() and Invenotry_Gui.BankFrame:IsVisible() then
                            Invenotry_Gui.BankFrame:Close()
                            Invenotry_Gui.InvFrame:Close()
                            gui.EnableScreenClicker(false)
                            lastTime = CurTime()
                            return
                        end
                        if Invenotry_Gui.InvFrame:IsVisible() then
                            Invenotry_Gui.InvFrame:SetVisible(false)
                            Invenotry_Gui.BankFrame:SetVisible(false)
                            gui.EnableScreenClicker(false)
                        else
                            if vgui.CursorVisible() then
                                Invenotry_Gui.InvFrame:SetVisible(false)
                                Invenotry_Gui.BankFrame:SetVisible(false)
                                gui.EnableScreenClicker(false)
                            else
                                net.Start("inv_requestUpdate")
                                net.SendToServer()
                                for e = 1, 40 do
                                    ply.InventorySlots[e].VGui:SetAlpha(255)
                                end
                                for e = 1, 32 do
                                    ply.BankSlots[e].VGui:SetAlpha(255)
                                end
                                Invenotry_Gui.InvFrame.startTime = SysTime()
                                Invenotry_Gui.InvFrame:SetVisible(true)
                                Invenotry_Gui.InvFrame:Center()
                                gui.SetMousePos(ScrW() / 2, ScrH() / 2)
                                gui.EnableScreenClicker(true)
                            end
                        end
                        lastTime = CurTime()
                    end
                end
            end
            hook.Add("Think", "bindThinkInv", bindThinkInv)

            local scroll = vgui.Create("DScrollPanel", Invenotry_Gui.InvFrame)
            scroll:SetPos(10 * scale, 30 * scale)
            scroll:SetSize(72 * 4, 72 * 4)

            local grid = vgui.Create("DGrid", scroll)
            grid:Dock(FILL)
            grid:SetCols(4)
            grid:SetColWide(72)
            grid:SetRowHeight(72)

            for i = 1, 40 do
                ply.InventorySlots[i] = {}
                ply.InventorySlots[i].VGui = vgui.Create("inv_slot", Invenotry_Gui.InvFrame)
                ply.InventorySlots[i].IsOccupied = false
                ply.InventorySlots[i].VGui.Id = i
                ply.InventorySlots[i].VGui.Highlighted = false
                ply.InventorySlots[i].VGui.Icon.Id = i
                grid:AddItem(ply.InventorySlots[i].VGui)
                ply.InventorySlots[i].VGui:Receiver(
                    "inv_drop",
                    function(pnl, item, drop, i, x, y)
                        item = item[1]
                        if pnl.Id == nil then
                            for e = 1, 40 do
                                ply.InventorySlots[e].VGui:SetAlpha(255)
                            end
                        end
                        for e = 1, 40 do
                            if ply.InventorySlots[e].VGui.Id == pnl.Id then
                                ply.InventorySlots[e].VGui:SetAlpha(100)
                            else
                                ply.InventorySlots[e].VGui:SetAlpha(255)
                            end
                        end
                        for e = 1, 32 do
                            ply.BankSlots[e].VGui:SetAlpha(255)
                        end
                        if drop then
                            net.Start("swapItems_inv")
                            net.WriteString(pnl.Id)
                            net.WriteString(item:GetParent().Id)
                            net.WriteString("Рюкзак")
                            net.SendToServer()
                            ply.InventorySlots[pnl.Id].VGui:SetAlpha(255)
                        end
                    end,
                    {}
                )

                ply.InventorySlots[i].VGui:Receiver(
                    "inv_droppingFromBank",
                    function(pnl, item, drop, i, x, y)
                        item = item[1]
                        for e = 1, 40 do
                            if ply.InventorySlots[e].VGui.Id == pnl.Id then
                                ply.InventorySlots[e].VGui:SetAlpha(100)
                            else
                                ply.InventorySlots[e].VGui:SetAlpha(255)
                            end
                        end
                        for e = 1, 32 do
                            ply.BankSlots[e].VGui:SetAlpha(255)
                        end
                        if drop then
                            ply.InventorySlots[pnl.Id].VGui:SetAlpha(255)
                            net.Start("transferItems_inv")
                            net.WriteString(tostring(pnl.Id))
                            net.WriteString(tostring(item.Id))
                            net.WriteString("Рюкзак")
                            net.SendToServer()
                        end
                    end,
                    {}
                )
            end
        end
    )
end
