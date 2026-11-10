fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author 'Byte Labs'
version '2.0.0'
description 'Byte Labs ID Card: physical ID cards and licenses shown in hand'
repository 'https://github.com/Byte-Labs-Studio/bl_idcard'

ui_page 'web/index.html'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    '@bl_bridge/imports/client.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@bl_bridge/imports/server.lua',
    'server/init.lua',
    'server/main.lua',
}

files {
    'configs/shared.lua',
    'configs/client.lua',
    'shared/*.lua',
    'locales/*.json',
    'bridge/client.lua',
    'client/modules/*.lua',
    'web/index.html',
    'web/photo.js',
    'web/popup.js',
    'web/card.html',
    'web/card.css',
    'web/card.js',
    'web/fonts/*.woff2',
    'web/images/*',
    'stream/bl_idcard.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/bl_idcard.ytyp'

dependencies {
    '/onesync',
    'ox_lib',
    'oxmysql',
    'bl_bridge',
}
