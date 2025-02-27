local peds = {}

-------- Function to sell animals -----------
---@param animalType string
---@param animalCond integer
function SellAnimals(animalType, animalCond)
    BCCRanchMenu:Close()
    local tables, model
    local spawnCoords = nil

    local selectAnimalFuncts = {
        ['cows'] = function()
            if tonumber(RanchData.cows_age) < ConfigAnimals.animalSetup.cows.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
            else
                tables = ConfigAnimals.animalSetup.cows
                model = 'a_c_cow'
                spawnCoords = json.decode(RanchData.cow_coords)
            end
        end,
        ['pigs'] = function()
            if tonumber(RanchData.pigs_age) < ConfigAnimals.animalSetup.pigs.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
            else
                tables = ConfigAnimals.animalSetup.pigs
                model = 'a_c_pig_01'
                spawnCoords = json.decode(RanchData.pig_coords)
            end
        end,
        ['sheeps'] = function()
            if tonumber(RanchData.sheeps_age) < ConfigAnimals.animalSetup.sheeps.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
            else
                tables = ConfigAnimals.animalSetup.sheeps
                model = 'a_c_sheep_01'
                spawnCoords = json.decode(RanchData.sheep_coords)
            end
        end,
        ['goats'] = function()
            if tonumber(RanchData.goats_age) < ConfigAnimals.animalSetup.goats.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
            else
                tables = ConfigAnimals.animalSetup.goats
                model = 'a_c_goat_01'
                spawnCoords = json.decode(RanchData.goat_coords)
            end
        end,
        ['chickens'] = function()
            if tonumber(RanchData.chickens_age) < ConfigAnimals.animalSetup.chickens.AnimalGrownAge then
                VORPcore.NotifyRightTip(_U("tooYoung"), 4000)
            else
                tables = ConfigAnimals.animalSetup.chickens
                model = 'a_c_chicken_01'
                spawnCoords = json.decode(RanchData.chicken_coords)
            end
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

    --Detecting Closest Sale Barn Setup Credit to vorp_core for this bit of code, and jannings for pointing this out to me
    BccUtils.RPC:Call("bcc-ranch:UpdateAnimalsOut", { ranchId = RanchData.ranchid, isOut = true }, function(success)
        if success then
            devPrint("Animals out status updated successfully!")
        else
            devPrint("Failed to update animals out status!")
        end
    end)
    local finalSaleCoords
    local closestDistance = math.huge
    for k, v in pairs(Config.saleLocations) do
        local pCoords = GetEntityCoords(PlayerPedId())
        local currentDistance = GetDistanceBetweenCoords(v.Coords.x, v.Coords.y, v.Coords.z, pCoords.x, pCoords.y,
            pCoords.z, true)

        if currentDistance < closestDistance then
            closestDistance = currentDistance
            finalSaleCoords = vector3(v.Coords.x, v.Coords.y, v.Coords.z)
        end
    end

    local catch = 0
    repeat
        local createdPed = BccUtils.Ped.CreatePed(model, spawnCoords.x + math.random(1, 5),
            spawnCoords.y + math.random(1, 5), spawnCoords.z, true, true, false)
        SetBlockingOfNonTemporaryEvents(createdPed, true)
        Citizen.InvokeNative(0x9587913B9E772D29, createdPed, true)
        SetEntityHealth(createdPed, tables.animalHealth, 0)
        table.insert(peds, createdPed)
        catch = catch + 1
    until catch == tables.spawnAmount
    SetRelAndFollowPlayer(peds)
    VORPcore.NotifyRightTip(_U("leadAnimalsToSaleLocation"), 4000)
    BccUtils.Misc.SetGps(finalSaleCoords.x, finalSaleCoords.y, finalSaleCoords.z)
    local blip = BccUtils.Blip:SetBlip(_U("saleLocationBlip"), ConfigRanch.ranchSetup.ranchBlip, 0.2, finalSaleCoords.x,
        finalSaleCoords.y, finalSaleCoords.z)

    local animalsNear = false
    while true do
        Wait(50)
        for k, v in pairs(peds) do
            if #(GetEntityCoords(v) - finalSaleCoords) < 15 then
                animalsNear = true
            else
                animalsNear = false
            end
            if IsEntityDead(v) then
                catch = catch - 1
            end
        end
        if catch == 0 or IsEntityDead(PlayerPedId()) == true then break end

        local plc = GetEntityCoords(PlayerPedId())
        local dist = #(plc - finalSaleCoords)
        if dist < 5 and animalsNear == true then
            local pay
            if animalCond >= tables.maxCondition and catch == tables.animalHealth then
                pay = tables.maxConditionPay
            end
            if animalCond ~= tables.maxCondition then
                pay = tables.basePay
            end
            if catch ~= tables.spawnAmount then
                pay = tables.lowPay
            end
            BccUtils.RPC:Call("bcc-ranch:AnimalSold", {
                payAmount = pay,
                ranchId = RanchData.ranchid,
                animalType = animalType
            }, function(success)
                if success then
                    devPrint("Animal sold successfully for ranchId: " ..
                    RanchData.ranchid .. " with animalType: " .. animalType)
                else
                    devPrint("Failed to sell animal for ranchId: " .. RanchData.ranchid)
                end
            end)
            VORPcore.NotifyRightTip(_U("animalSold"), 4000)
            break
        end
    end
    ClearGpsMultiRoute()
    if IsEntityDead(PlayerPedId()) or catch == 0 then
        blip:Remove()
        VORPcore.NotifyRightTip(_U("failed"), 4000)
    end
    for k, v in pairs(peds) do
        DeletePed(v)
    end
    blip:Remove()
    IsInMission = false
    BccUtils.RPC:Call("bcc-ranch:UpdateAnimalsOut", { ranchId = RanchData.ranchid, isOut = false }, function(success)
        if success then
            print("Animals out status updated successfully!")
        else
            print("Failed to update animals out status!")
        end
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(peds) do
            v:Remove()
        end
        peds = {}
    end
end)
