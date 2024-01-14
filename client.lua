Skillsystem = {}; 

function Skillsystem:update(skill, procent, functions)
    if not Config.Skills[skill] then 
        return print('skill does not exist')
    end

    local stat = Config.Skills[skill].stat or nil; 

    if not stat then
        return print('stat does not exist')
    end

    local lastProcent = Config.Skills[skill].procent or 0;

    local results = self:TriggerCallback({
        eventName = 'lowkey_skillsystem:updateSkill', 
        args = { procent = procent, skill = skill, playerSkills = Config.Skills[skill] }
    })

    if not results.success then 
        return print('failed to update skill')
    end

    self:sendMessage(skill, results.skill, lastProcent); 
    PresenceEventUpdatestatInt(stat, results.skill, true)

    if functions.onUpdated then 
        functions.onUpdated(skill, procent)
    else
        print('skill updated', skill, procent)
    end
end

function Skillsystem:sendMessage(skill, procent, lastProcent)
    local skillData = Config.Skills[skill];

    if not skillData then return end; 
    
    local handle = RegisterPedheadshot(PlayerPedId())

    while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
        Citizen.Wait(0)
    end

    local txd = GetPedheadshotTxdString(handle)

    BeginTextCommandThefeedPost("PS_UPDATE")
    AddTextComponentInteger(50)

    local title = skillData.title or 'PSF_STAMINA'
    local p1 = 14
    local lastProgress = lastProgress
    local newProgress = procent
    local unknownBool = false

    print(title, p1, lastProgress, newProgress, unknownBool, txd, txd)

    EndTextCommandThefeedPostStats(title, p1, newProgress, lastProgress, unknownBool, txd, txd)

    local showInBrief = true
    local blink = false 

    EndTextCommandThefeedPostTicker(blink, showInBrief)
    UnregisterPedheadshot(handle)
end

function Skillsystem:TriggerCallback(data)
    local p = promise:new();

    ESX.TriggerServerCallback(data.eventName, function(results) 
        p:resolve(results)
    end, data.args)

    return Citizen.Await(p)
end 

RegisterCommand('skill', function()
    Skillsystem:update('stamina', 10, {
        onUpdated = function(skill, procent)
            -- Fortsätt här
        end
    })
end)

Citizen.CreateThread(function()
    while not ESX.IsPlayerLoaded() do 
        Citizen.Wait(100)
    end

    local player = ESX.GetPlayerData()

    local skills = Skillsystem:TriggerCallback({
        eventName = 'lowkey_skillsystem:getSkills', 
        args = {}
    })

    if not skills.success then 
        return print('failed to get skills')
    end

    for _, skill in pairs(Config.Skills) do 
        local stat = skill.stat or nil; 

        if not stat then 
            return print('stat does not exist')
        end

        StatSetInt(stat, skill.procent, true);
    end

    for name, skill in pairs(skills.skills) do 
        Config.Skills[name].procent = skill
        
        StatSetInt(Config.Skills[name].stat, Config.Skills[name].procent, true);
    end
end)