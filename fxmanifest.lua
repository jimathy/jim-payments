name "Jim-Payments"
author "Jimathy"
version "v1.0"
description "Payment Script By Jimathy"
fx_version "cerulean"
game "gta5"

dependencies {
	'qb-input',
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

shared_scripts {
    'config.lua',
}