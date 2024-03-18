



# OX Inventory
```lua
	["id_card"] = {
		label = "ID Card",
		weight = 0,
		stack = false,
		close = false,
		description = "A card containing all your information to identify yourself",
	},

    ["driver_license"] = {
		label = "Drivers License",
		weight = 0,
		stack = false,
		close = false,
		description = "Permit to show you can drive a vehicle",
	},

	["weaponlicense"] = {
		label = "Weapon License",
		weight = 0,
		stack = false,
		close = true,
		description = "Weapon License",
	},
```

## QB / QS / PS Inventory
```lua
    ['id_card']  = {
        name = 'id_card',
        label = 'ID Card',
        weight = 0,
        type = 'item',
        description = 'A card containing all your information to identify yourself',
        unique = true,
        useable = true,
        image = 'id_card.png',
        combinable = nil,
    },

    ['driver_license'] = {
        name = 'driver_license',
        label = 'Drivers License',
        weight = 0,
        type = 'item',
        description = 'Permit to show you can drive a vehicle',
        unique = true,
        useable = true,
        image = 'driver_license.png',
        combinable = nil,
    },

    ['weaponlicense'] = {
        name = 'weaponlicense',
        label = 'Weapon License',
        weight = 0,
        type = 'item',
        description = 'Weapon License',
        unique = true,
        useable = true,
        image = 'weaponlicense.png',
        combinable = nil,
    },
```