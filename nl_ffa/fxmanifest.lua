fx_version "cerulean"
lua54 "yes"
game "gta5"
name "nl_ffa"
author "0Resmon"
version "1.0.0"
description "FiveM Free For All script with lobby system"

shared_scripts {
    "@ox_lib/init.lua",
    "shared/**/*"
}

client_scripts {
    "client/**/*"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/**/*"
}

ui_page "ui/index.html"

files {
    "ui/index.html",
    "ui/**/*"
}

escrow_ignore {
    "client/**/*",
    "server/**/*",
    "shared/**/*",
    "ui/**/*"
}

dependencies {
    "ox_lib",
    "ox_target",
    "oxmysql"
}