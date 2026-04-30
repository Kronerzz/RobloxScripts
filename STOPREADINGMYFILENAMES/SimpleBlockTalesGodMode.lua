local http = game:GetService("HttpService")
local rep = game:GetService("ReplicatedStorage")
local sgui = game:GetService("StarterGui")

local movesFolder = rep:WaitForChild("Moves")

local playerAttributes = {
    "Description", "Icon", "SP", "Price", "SPrice", 
    "MoveType", "CallWho", "itemsc", "ItemType", "WhatBadge" 
}

local env = getgenv()

env._bt_godmode = not env._bt_godmode
env._bt_conns = env._bt_conns or {}
env._bt_orig = env._bt_orig or {}

for _, c in pairs(env._bt_conns) do
    if c.Connected then c:Disconnect() end
end
table.clear(env._bt_conns)

local function notif(title, text, time)
    task.spawn(function()
        for i = 1, 5 do
            local ok = pcall(function()
                sgui:SetCore("SendNotification", {
                    Title = title,
                    Text = text,
                    Duration = time or 5
                })
            end)
            if ok then break end
            task.wait(0.5)
        end
    end)
end

local function isEnemyMove(move)
    for _, attr in pairs(playerAttributes) do
        if move:GetAttribute(attr) ~= nil then
            return false
        end
    end
    return true
end

local function patchMove(move)
    if not move:IsA("Folder") or not isEnemyMove(move) then return end
    
    if not env._bt_orig[move] then
        env._bt_orig[move] = {
            Damage = move:GetAttribute("Damage"),
            DMGTable = move:GetAttribute("DMGTable")
        }
    end

    local dmg = move:GetAttribute("Damage")
    if type(dmg) == "number" and dmg > 0 then
        move:SetAttribute("Damage", 0)
    end

    local dmgTbl = move:GetAttribute("DMGTable")
    if type(dmgTbl) == "string" then
        local ok, parsed = pcall(function() return http:JSONDecode(dmgTbl) end)
        
        if ok and type(parsed) == "table" then
            local changed = false
            for k, v in pairs(parsed) do
                if type(v) == "number" and v > 0 then
                    parsed[k] = 0
                    changed = true
                end
            end
            if changed then
                move:SetAttribute("DMGTable", http:JSONEncode(parsed))
            end
        end
    end
end

local function restoreMove(move)
    if not move:IsA("Folder") or not isEnemyMove(move) then return end
    
    local orig = env._bt_orig[move]
    if orig then
        if orig.Damage ~= nil then move:SetAttribute("Damage", orig.Damage) end
        if orig.DMGTable ~= nil then move:SetAttribute("DMGTable", orig.DMGTable) end
    end
end

local function handleMove(move)
    if not move:IsA("Folder") then return end

    if env._bt_godmode then
        patchMove(move)
        
        local c1 = move:GetAttributeChangedSignal("Damage"):Connect(function()
            patchMove(move)
        end)
        local c2 = move:GetAttributeChangedSignal("DMGTable"):Connect(function()
            patchMove(move)
        end)
        
        table.insert(env._bt_conns, c1)
        table.insert(env._bt_conns, c2)
    else
        restoreMove(move)
    end
end

if env._bt_godmode and not env._bt_loaded then
    env._bt_loaded = true
    notif("Loaded!", "Block Tales Godmode by @IDKWHATUSERNAME | Enjoy :3", 4)
    task.wait(1)
end

for _, v in pairs(movesFolder:GetChildren()) do
    handleMove(v)
end

if env._bt_godmode then
    local newMove = movesFolder.ChildAdded:Connect(handleMove)
    table.insert(env._bt_conns, newMove)
    notif("God Mode", "Enabled! Enemy damage is 0.", 5)
else
    notif("God Mode", "Disabled! Original damage is back.", 5)
    table.clear(env._bt_orig)
end
