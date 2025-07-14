fx_version 'cerulean'
game 'gta5'

name 'qb-uid'
description 'QBCore Sequential UID System - Assigns permanent numerical IDs to players'
author 'Cayne'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'oxmysql'
}

exports {
    'GetPlayerUID',
    'GetPlayerUIDByCitizenID', 
    'GetPlayerByUID',
    'UIDExists'
}

-- Ensure this resource starts after qb-core
dependency 'qb-core'

lua54 'yes'