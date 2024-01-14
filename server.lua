ESX = exports.es_extended:getSharedObject()

Skillsystem = {};

function Skillsystem:Init()
    ESX.RegisterServerCallback('lowkey_skillsystem:getSkills', function(source, callback)
        local player = ESX.GetPlayerFromId(source);

        if not player then return end;

        local results = MySQL.Sync.fetchAll([[
            SELECT 
                stamina, shooting, flying, stealth, driving, strength, lung_capacity, mental_state
            FROM 
                users 
            WHERE 
                identifier = @identifier
        ]], {
            ['@identifier'] = player.identifier
        })

        callback({ success = true, skills = results[1] })
    end)

    ESX.RegisterServerCallback('lowkey_skillsystem:updateSkill', function(source, callback, data)
        local player = ESX.GetPlayerFromId(source); 

        if not player then return end; 

        local procent = data.procent; 
        local skill = data.skill;

        local newValue = self:CalculateNewValue(skill, procent, data.playerSkills);
        local results = self:UpdateSkill(player, skill, newValue); 

        callback({ success = results.success, skill = newValue })
    end)
end

function Skillsystem:InsertSkill(player, skill, newValue)
    local userSkills;

    for k,v in pairs(Config.Skills) do 
        userSkills = MySQL.Sync.fetchAll([[
            INSERT INTO 
                users_skills 
            VALUES 
                (@identifier, @skill, @procent)
        ]], {
            ['@identifier'] = player.identifier,
            ['@skill'] = k,
            ['@procent'] = v.procent
        })
    end

    return { success = true, skills = Config.Skills }
end

function Skillsystem:CalculateNewValue(skill, procent, playerSkills)
    local newValue;
    local currentProcent = playerSkills.procent or 0;  
    
    if procent >= 100 then 
        newValue = 100; 
    elseif procent + currentProcent >= 100 then 
        newValue = 100; 
    else 
        newValue = procent + currentProcent;
    end

    return newValue;
end

function Skillsystem:UpdateSkill(player, skill, newValue)
    print('Skill, procent ', skill, newValue)

    local sqlQuery = ('UPDATE users SET %s = @procent WHERE identifier = @identifier'):format(skill); 

    local rowsChanged = MySQL.Sync.execute(sqlQuery, {
        ['@identifier'] = player.identifier,
        ['@procent'] = newValue
    }); 

    if rowsChanged > 0 then 
        local skill = Config.Skills[skill];

        if not skill then return end;

        skill.procent = newValue;

        return { success = true, skill = skill }
    end

    return { success = false }
end

Citizen.CreateThread(function()
    Skillsystem:Init()
end)