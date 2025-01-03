return {
    Debug = true,

    items = {
        ['id_card'] = {
            prop = `prop_franklin_dl`,
            genderIdType = {
                female = 'female_id',
                male = 'male_id'
            }
        },
        ['driver_license'] = {
            prop = `prop_franklin_dl`,
            idType = 'driver_license'
        },

        ['weaponlicense'] = {
            prop = `prop_franklin_dl`,
            idType = 'weapon_license'
        },
    },

    range = 2.0, -- Range to show the ped looking at

    popup = {
        autoclose = 5000, -- 0 to disable
        key = 'back', -- key to close the popup
    },

    animation = {
        dict = 'paper_1_rcm_alt1-9',
        clip = 'player_one_dual-9',
    },

    idTypes = {
        driver_license = {
            type = 'driver_license',
            title = 'SAN ANDREAS',
            titleColour = '#bdbdbd',

            label = 'DRIVER LICENSE',
        
            stamp = true,
            profileStamp = false,
        
            signature = true,
        
            bgColour = '#000',
            bgColourSecondary = '#000',
        
            textColour = '#FFF',
        },

        weapon_license = {
            type = 'weapon_license',
            title = 'SAN ANDREAS',
            titleColour = '#ff4538',

            label = 'WEAPON LICENSE',
        
            stamp = true,
            profileStamp = false,
        
            signature = true,
        
            bgColour = '#460000',
            bgColourSecondary = '#E90000',
        
            textColour = '#FFF',
        },

        female_id = {
            type = 'female_id',
            title = 'SAN ANDREAS',
            titleColour = '#F97C81',

            label = 'ID CARD',
        
            stamp = true,
            profileStamp = true,
        
            signature = true,
        
            bgColour = '#f1e6db',
            bgColourSecondary = '#ff75bc',
        
            textColour = '#323443',
        },
        
        male_id = {
            type = 'male_id',
            title = 'SAN ANDREAS',
            titleColour = '#89B1FF',

            label = 'ID CARD',
        
            stamp = true,
            profileStamp = true,
        
            signature = true,
        
            bgColour = '#E5FCFF',
            bgColourSecondary = '#6FCBE9',
        
            textColour = '#323443',
        },
    }
}