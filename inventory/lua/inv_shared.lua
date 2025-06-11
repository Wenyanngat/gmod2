include('inv_config.lua')
if CLIENT then
    surface.CreateFont( "inv_title_font", {
        font = "Arial",
        extended = false,
        size = 16,
        weight = 500, 
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = true,
        additive = false,
        outline = false,
    } ) 
    surface.CreateFont( "WeightFont", {
        font = "Arial",
        extended = false,
        size = 20,
        weight = 750,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = true,
        additive = false,
        outline = false,
    } )  

end
Invenotry_Gui = {}  

function getMaxWeight(ply, typ)
    if InventoryConfig.Groups[ply:GetUserGroup()] then
        if typ == "Inventory" then
            return InventoryConfig.Groups[ply:GetUserGroup()].inventoryMaxWeight
        else  
            return InventoryConfig.Groups[ply:GetUserGroup()].bankMaxWeight
        end
    else
        if InventoryConfig.Groups["user"] then 
            if typ == "Inventory" then
                return InventoryConfig.Groups["user"].inventoryMaxWeight
            else  
                return InventoryConfig.Groups["user"].bankMaxWeight
            end
        end 
    end
    return 30 -- We want to avoid this situation..
end
