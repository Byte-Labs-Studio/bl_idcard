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
            idType = 'license'
        }
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
        license = {
            type  = 'license',
            title = 'SAN ANDREAS',
            titleColour = '#3A84AD',

            label = 'DRIVER LICENSE',
        
            stamp = true,
            profileStamp = true,
        
            signature = false,
        
            bgColour = '#F1E6DB',
            bgColourSecondary = '#D3F7FF',
        
            textColour = '#323443',
        },
        female_id = {
            type  = 'female_id',
            title = 'SAN ANDREAS',
            titleColour = '#F97C81',

            label = 'ID CARD',
        
            stamp = true,
            profileStamp = true,
        
            signature = true,
        
            bgColour = '#f1e6db',
            bgColourSecondary = '#d3f7ff',
        
            textColour = '#323443',
        },
        male_id = {
            type  = 'male_id',
            title = 'SAN ANDREAS',
            titleColour = '#3A84AD',

            label = 'ID CARD',
        
            stamp = true,
            profileStamp = true,
        
            signature = true,
        
            bgColour = '#F1E6DB',
            bgColourSecondary = '#D3F7FF',
        
            textColour = '#323443',
        },
    }
}