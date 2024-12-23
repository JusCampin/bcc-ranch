local createdPed = nil
function ButcherAnimals(animalType)
    local model, tables, spawnCoords
    BCCRanchMenu:Close()

    local selectAnimalFuncts = {
        ['cows'] = function()
            if tonumber(RanchData.cows_age) < ConfigAnimals.animalSetup.cows.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
                return
            end
            tables = ConfigAnimals.animalSetup.cows
            model = 'a_c_cow'
            spawnCoords = json.decode(RanchData.cow_coords)
        end,
        ['pigs'] = function()
            if tonumber(RanchData.pigs_age) < ConfigAnimals.animalSetup.pigs.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
                return
            end
            tables = ConfigAnimals.animalSetup.pigs
            model = 'a_c_pig_01'
            spawnCoords = json.decode(RanchData.pig_coords)
        end,
        ['sheeps'] = function()
            if tonumber(RanchData.sheeps_age) < ConfigAnimals.animalSetup.sheeps.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
                return
            end
            tables = ConfigAnimals.animalSetup.sheeps
            model = 'a_c_sheep_01'
            spawnCoords = json.decode(RanchData.sheep_coords)
        end,
        ['goats'] = function()
            if tonumber(RanchData.goats_age) < ConfigAnimals.animalSetup.goats.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
                return
            end
            tables = ConfigAnimals.animalSetup.goats
            model = 'a_c_goat_01'
            spawnCoords = json.decode(RanchData.goat_coords)
        end,
        ['chickens'] = function()
            if tonumber(RanchData.chickens_age) < ConfigAnimals.animalSetup.chickens.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
                return
            end
            tables = ConfigAnimals.animalSetup.chickens
            model = 'a_c_chicken_01'
            spawnCoords = json.decode(RanchData.chicken_coords)
        end
    }

    if selectAnimalFuncts[animalType] then
        selectAnimalFuncts[animalType]()
    end

    -- Check if spawnCoords is nil, notify the player if true
    if not spawnCoords or not spawnCoords.x or not spawnCoords.y or not spawnCoords.z then
        VORPcore.NotifyRightTip(_U("noCoordsSet"), 4000)
        return
    end

    IsInMission = true

    createdPed = BccUtils.Ped.CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, false)
    local blip = BccUtils.Blip:SetBlip(_U("choreLocation"), 960467426, 0.2, spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetBlockingOfNonTemporaryEvents(createdPed, true)
    Citizen.InvokeNative(0x9587913B9E772D29, createdPed, true)
    FreezeEntityPosition(createdPed, true)
    VORPcore.NotifyRightTip(_U("killAnimal"), 4000)

    while true do
        Wait(5)
        if IsEntityDead(PlayerPedId()) then break end
        if IsEntityDead(createdPed) then
            VORPcore.NotifyRightTip(_U("skinAnimal"), 4000)
            break
        end
    end

    local PromptGroup = BccUtils.Prompts:SetupPromptGroup()
    local firstprompt = PromptGroup:RegisterPrompt(_U("skinAnimal"), BccUtils.Keys[ConfigRanch.ranchSetup.skinKey], 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })
    while true do
        Wait(5)
        if IsEntityDead(PlayerPedId()) then break end
        if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(createdPed)) < 3 then
            PromptGroup:ShowGroup('')
            if firstprompt:HasCompleted() then
                -- Player performs a crouch action, and the animal is butchered.
                BccUtils.Ped.ScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_CROUCH_INSPECT', 5000)
                DeletePed(createdPed)
                VORPcore.NotifyRightTip(_U("animalKilled"), 4000)

                -- Prepare the parameters
                local params = {
                    animalType = animalType,
                    ranchId = RanchData.ranchid,
                    table = tables
                }

                BccUtils.RPC:Call("bcc-ranch:ButcherAnimalHandler", params, function(success)
                    if success then
                        devPrint("Animal butchered successfully and items added.")
                    else
                        devPrint("Failed to butcher the animal.")
                    end
                end)
                break
            end
        end
    end

    if IsEntityDead(PlayerPedId()) then
        VORPcore.NotifyRightTip(_U("failed"), 4000)
    end
    blip:Remove()
    IsInMission = false
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DeletePed(createdPed)
        createdPed = nil
    end
end)
