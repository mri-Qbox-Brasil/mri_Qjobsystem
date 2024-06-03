
fx_version 'adamant'

game 'gta5'

description 'Polisek scripts'

dependencies {'ox_lib'}

shared_scripts { 
    "BRIDGE/config.lua",
    "BRIDGE/server/framework.lua",
    'config.lua',
    "secure.lua",
    '@ox_lib/init.lua',  
}


client_scripts {
    "BRIDGE/client/inventory.lua",
    "BRIDGE/client/target.lua",
	'client/*.lua',
}

server_scripts {
    "BRIDGE/server/inventory.lua",
    'server/server.lua',
}



lua54 "yes"
