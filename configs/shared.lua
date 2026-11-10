return {
    flashTime = 5000,

    handover = 'lend',

    popup = {
        autoclose = 5000,
        key = 'back',
    },

    issuer = {
        state = 'SAN ANDREAS',
        country = 'USA',
        emblem = 'images/logo.svg',
    },

    items = {
        ['id_card'] = {
            label = 'ID Card',
            genderIdType = {
                female = 'female_id',
                male = 'male_id',
            },
            numberLabel = 'ID',
            prefix = 'S',
            years = 8,
        },

        ['driver_license'] = {
            label = 'Driver License',
            idType = 'driver_license',
            numberLabel = 'DL',
            prefix = 'D',
            years = 5,
            class = 'C',
        },

        ['weaponlicense'] = {
            label = 'Weapon License',
            idType = 'weapon_license',
            numberLabel = 'PMT',
            prefix = 'W',
            years = 3,
            class = 'CCW',
        },
    },

    idTypes = {
        driver_license = {
            title = 'SAN ANDREAS',
            titleColour = '#bdbdbd',
            label = 'DRIVER LICENSE',
            subtitle = 'NOT FOR FEDERAL PURPOSES',
            agency = 'Department of Motor Vehicles',
            legal = 'This license is the property of the State of San Andreas. It must be shown on demand of any peace officer.',

            stamp = true,
            profileStamp = false,
            signature = true,

            bgColour = '#000',
            bgColourSecondary = '#000',
            textColour = '#FFF',
        },

        weapon_license = {
            title = 'SAN ANDREAS',
            titleColour = '#ff4538',
            label = 'WEAPON LICENSE',
            subtitle = 'CONCEALED CARRY',
            agency = 'Department of Justice',
            legal = 'Carry this permit with the licensed firearm at all times. It must be shown on demand of any peace officer.',

            stamp = true,
            profileStamp = false,
            signature = true,

            bgColour = '#460000',
            bgColourSecondary = '#E90000',
            textColour = '#FFF',
        },

        female_id = {
            title = 'SAN ANDREAS',
            titleColour = '#F97C81',
            label = 'ID CARD',
            subtitle = 'STATE IDENTIFICATION',
            agency = 'Department of Motor Vehicles',
            legal = 'This card is the property of the State of San Andreas and must be surrendered on demand.',

            stamp = true,
            profileStamp = true,
            signature = true,

            bgColour = '#f1e6db',
            bgColourSecondary = '#ff75bc',
            textColour = '#323443',
        },

        male_id = {
            title = 'SAN ANDREAS',
            titleColour = '#89B1FF',
            label = 'ID CARD',
            subtitle = 'STATE IDENTIFICATION',
            agency = 'Department of Motor Vehicles',
            legal = 'This card is the property of the State of San Andreas and must be surrendered on demand.',

            stamp = true,
            profileStamp = true,
            signature = true,

            bgColour = '#E5FCFF',
            bgColourSecondary = '#6FCBE9',
            textColour = '#323443',
        },
    },
}
