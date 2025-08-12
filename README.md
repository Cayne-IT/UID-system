# UID-system
UID system for qb-core

place this in either the qb folder or in the root folder 

run the uid.sql in your sql database 


make sure you ensure qb-uid in your server.cfg if you have not placed in the qb core file

if you want full integration

1. Understand how it works
It stores a permanent uid for each player based on their license.

The UID is saved in a table called user_uid, and synced every time a player connects.

The key export is:

[lua]
exports["uid-system"]:getUID(source)

2. Use UID as permID in your systems
Replace other identifiers with UID in:

🔁 qb-core/server/player.lua:
In the LoadPlayer function (or wherever you assign citizenid), fetch the UID like this:

[lua]
local uid = exports["uid-system"]:getUID(src)
PlayerData.citizenid = uid
Or store it in a new field like PlayerData.uid = uid

 3. Modify player metadata
Update how you save/load user data:

If you want UID to replace citizenid, change DB queries and player save logic.

Otherwise, add a new field:

[lua]

Player.Functions.SetMetaData("uid", uid)

 4. Update Admin Menus and Staff Tools
In places like:

qb-adminmenu

SCRP-admin (as you're rebranding)

Any custom staff panel

Replace:
[lua]
player.citizenid
with:

[lua]
exports["uid-system"]:getUID(player.source)
And update the UI to show the UID instead of citizenid or license.

5. Update Logging, Webhooks, and Anti-Cheat
Anywhere you log:

[lua]
player.name .. ' (' .. license .. ')'
Replace with:

[lua]
player.name .. ' (' .. exports["uid-system"]:getUID(player.source) .. ')'

 6. Add UID to player_connect events and player loading
Inside qb-core/server/events.lua, during the player loading:

[lua]
local uid = exports["uid-system"]:getUID(src)
-- Store or pass this to client/metadata/etc.

 7. Database Changes (Optional)
If you want to use UID as a primary key:

Add uid to your players table

Replace citizenid wherever used as a unique identifier (risky if you're deep into existing data)

Or just reference it as a secondary unique ID.

9. Client-side Usage (If Needed)
If you need the UID client-side:

Trigger a server callback that returns the UID

Never expose UID directly in NUI unless needed

[lua]
RegisterNetEvent("your_script:getUID")
AddEventHandler("your_script:getUID", function(cb)
    local uid = exports["uid-system"]:getUID(source)
    cb(uid)
end)

