require("deepcore/std/class")
require("deepcore/crossplot/crossplot")
require("eawx-util/StoryUtil")
require("eawx-util/StringUtil")
require("eawx-util/UnitUtil")

---@class GovernmentProteus
GovernmentProteus = class()

---@param gc GalacticConquest
---@param GovEmpire GovernmentEmpire
function GovernmentProteus:new(gc, GovEmpire)
    self.gc = gc
    self.GovEmpire = GovEmpire
    self.PlayerImperial_Proteus = Find_Player("Imperial_Proteus")

    self.production_finished_event = gc.Events.GalacticProductionFinished
    self.production_finished_event:attach_listener(self.on_production_finished, self)

    self.gamble_table = require("GambleLibrary")
    self.market_updates = {
        ["DUMMY_RECRUIT_GROUP_DELURIN"] = "DRAGON",
        ["DUMMY_RECRUIT_GROUP_WESSEX"] = "WESSEX",
    }
    self.proteus_markets = {"KUAT"}

    -- Project Proteus specific hero SSDs
    self.hero_ssd_table = {
        ["HARRSK_MEGADOR"] = "TEXT_GOVERNMENT_EMPIRE_SSD_HERO_HARRSK",
        ["DESANNE_DOMINION"] = "TEXT_GOVERNMENT_EMPIRE_SSD_HERO_DESANNE",
        ["THARKUS_AMBITION"] = "TEXT_GOVERNMENT_EMPIRE_SSD_HERO_THARKUS",
        ["TAXEVADER_DREAM_OF_A_QUIET_LIFE"] = "TEXT_GOVERNMENT_EMPIRE_SSD_HERO_TAX",
        ["MICHAEL_TERROR"] = "TEXT_GOVERNMENT_EMPIRE_SSD_HERO_MICHAEL",
    }

    -- Append to GovernmentEmpire hero SSD tables
    for key, value in pairs(self.hero_ssd_table) do
        GovEmpire.hero_ssd_table[key] = value
    end

    crossplot:subscribe("DASTA_FIGHTER_CHOICE_OPTION", self.dasta_fighters, self)
    crossplot:subscribe("KUAT_BC_CHOICE_OPTION", self.kuat_battlecruisers, self)
end

function GovernmentProteus:update()
    --Logger:trace("entering GovernmentProteus:update")
    local proteus = GlobalValue.Get("PROTEUS_GROUP_NAME")
    if proteus == "DASTA" then
        if GlobalValue.Get("CURRENT_ERA") >= 14 then
            local dasta = Find_First_Object("RAGEZ_DASTA_MARAUDER")
            if TestValid(dasta) then
                dasta.Despawn()
                if self.PlayerImperial_Proteus.Is_Human() then
                    StoryUtil.Multimedia("TEXT_CONQUEST_PROTEUS_DASTA_RAGEZ_RETIRE", 10, nil, "Ragez_DAsta_Loop", 0)
                end
                self.GovEmpire.leader_table["FEENA_DASTA_TEAM"] = "FEENA_DASTA"
            end
        end
    end
end

---@param planet Planet
---@param object_type_name string Assumes all CAPS
function GovernmentProteus:on_production_finished(planet, object_type_name)
    --Logger:trace("entering GovernmentProteus:on_production_finished")
    local event = self.market_updates[object_type_name]
    if event ~= nil then
        if self.proteus_markets[GlobalValue.Get("PROTEUS_GROUP_NAME")] then
            crossplot:publish("UPDATE_MARKET", event)
        end
    elseif string.find(object_type_name, "DUMMY_RANDOM_UNIT_") then
        self:gamble_manager(object_type_name)
    elseif object_type_name == "KUAT_CHOOSE_BC" then
        GenericPopup("KUAT_BC_CHOICE", {"PRAETOR_II_BATTLECRUISER", "PRAETOR_CARRIER_BATTLECRUISER", "COMMUNICATIONS_BATTLECRUISER", "SORANNAN_STAR_DESTROYER"}, "KUAT_BC_CHOICE_OPTION")
    elseif object_type_name == "DASTA_PROCURE_FIGHTERS" then
        GenericPopup("DASTA_FIGHTER_CHOICE", {"IMPERIAL", "REBEL"}, "DASTA_FIGHTER_CHOICE_OPTION")
    end
end

---@param choice string Assumes all CAPS
function GovernmentProteus:dasta_fighters(choice)
    --Logger:trace("entering GovernmentProteus:dasta_fighters")
    local option = string.gsub(choice, "DASTA_FIGHTER_CHOICE_", "")
    option = string.lower(option)
    option = CapitalizeFirstCharacterOfEachSentence(option)
    Set_Fighter_Research("DastaFighters"..option)
end

---@param choice string Assumes all CAPS
function GovernmentProteus:kuat_battlecruisers(choice)
    --Logger:trace("entering GovernmentProteus:kuat_battlecruisers")
    crossplot:publish("UPDATE_MARKET", "KUAT_BC")
    local battlecruiser = string.gsub(choice, "KUAT_BC_CHOICE_", "")
    if TestValid(Find_Object_Type(battlecruiser)) then
        self.PlayerImperial_Proteus.Unlock_Tech(Find_Object_Type(battlecruiser))
    end
end

---@param unit_type string Assumes all CAPS
function GovernmentProteus:gamble_manager(unit_type)
    --Logger:trace("entering GovernmentProteus:gamble_manager")
    local src_data = self.gamble_table[unit_type]
    local posnr = GameRandom.Free_Random(1,table.getn(src_data))
    local dummy_object = Find_First_Object(unit_type)
    if not TestValid(dummy_object) then
        return
    end

    local planet_object = dummy_object.Get_Planet_Location()
    local unit_to_spawn = Find_Object_Type(src_data[posnr])
    if TestValid(unit_to_spawn) then
        Spawn_Unit(unit_to_spawn, planet_object, self.PlayerImperial_Proteus)
    end
    dummy_object.Despawn()
end
