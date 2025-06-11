InventoryConfig = { 
    General = {
        playerDataFolder = "inv_data",
        haloEnabled = true, -- This is the holo around pickable items rendered when you aim at these items
        haloColor = Color(200,200,200),
        keyBind = KEY_I,
    },
    Colors = {
        primaryColor = Color(42,43.5,44.7), -- darker
        secondaryColor = Color(60,60,60), -- lighter
        textColor = Color(255,255,255), 
    },
    Sounds = {
        pickUp = "items/ammo_pickup.wav", -- Plays when you're picking up object
        dragItem = "items/ammo_pickup.wav", -- Plays when you're dragging items in inventory / bank
        openStorage = "items/ammo_pickup.wav",
    },
    Groups = {
        user = { 
            inventoryMaxWeight = 30, 
            bankMaxWeight = 250,
        },
        vip = { 
            inventoryMaxWeight = 45, 
            bankMaxWeight = 450,
        } 
    },
    Messages = {
        noSpace = "No space in inventory.",
        tooHeavy = "Too Heavy.",
    },
    GuiText = {
        use = "Use",
        drop = "Drop",
        dropAll = "Drop All",
        totalWeight = "Вес: ",
    },
}
  