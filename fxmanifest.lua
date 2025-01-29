fx_version 'cerulean'
lua54 'yes'
game 'gta5'

-- Resource Information
name 'ox_doorlock'
author 'Overextended'
version '1.0.0'
repository 'https://github.com/overextended/ox_doorlock'
description 'Door lock system for FiveM'

-- Manifest
shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared.lua' -- Ensure QBCore shared script is included
}

client_scripts {
    'client/main.lua',
    'client/utils.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'locales/*.json'
}

dependency 'ox_lib'
