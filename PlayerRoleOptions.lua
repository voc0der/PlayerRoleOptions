local addonName = ...
local PlayerRoleOptions = _G.PlayerRoleOptions or {}
_G.PlayerRoleOptions = PlayerRoleOptions

local MENU_TITLE = _G.SET_ROLE or "Set Role"
local SETTINGS_CATEGORY_NAME = addonName or "PlayerRoleOptions"
local LFG_DEFAULT_ROLE_LABEL = "LFG Default Role"
local LFG_DEFAULT_ROLE_TOOLTIP = "Selects the LFG roles this addon applies on login."
local LFG_DEFAULT_ROLE_SETTING = "PLAYER_ROLE_OPTIONS_LFG_DEFAULT_ROLE"
local LFG_DEFAULT_ROLE_NONE = 0
local LFG_DEFAULT_ROLE_DAMAGER = 1
local LFG_DEFAULT_ROLE_TANK = 2
local LFG_DEFAULT_ROLE_HEALER = 3
local LFG_DEFAULT_ROLE_TANK_HEALER = 4
local LFG_DEFAULT_ROLE_TANK_DAMAGER = 5
local LFG_DEFAULT_ROLE_HEALER_DAMAGER = 6
local LFG_DEFAULT_ROLE_ALL = 7
local ROLE_LABELS = {
    TANK = _G.TANK or "Tank",
    HEALER = _G.HEALER or "Healer",
    DAMAGER = _G.DAMAGER or "DPS",
    NONE = "Clear Role",
}

local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER", "NONE" }
local LFG_ROLE_VALUE_BY_KEY = {
    ["000"] = LFG_DEFAULT_ROLE_NONE,
    ["001"] = LFG_DEFAULT_ROLE_DAMAGER,
    ["100"] = LFG_DEFAULT_ROLE_TANK,
    ["010"] = LFG_DEFAULT_ROLE_HEALER,
    ["110"] = LFG_DEFAULT_ROLE_TANK_HEALER,
    ["101"] = LFG_DEFAULT_ROLE_TANK_DAMAGER,
    ["011"] = LFG_DEFAULT_ROLE_HEALER_DAMAGER,
    ["111"] = LFG_DEFAULT_ROLE_ALL,
}
local LFG_ROLE_SELECTIONS = {
    [LFG_DEFAULT_ROLE_NONE] = {
        tank = false,
        healer = false,
        dps = false,
        text = _G.NONE or "None",
    },
    [LFG_DEFAULT_ROLE_DAMAGER] = {
        tank = false,
        healer = false,
        dps = true,
        text = ROLE_LABELS.DAMAGER,
    },
    [LFG_DEFAULT_ROLE_TANK] = {
        tank = true,
        healer = false,
        dps = false,
        text = ROLE_LABELS.TANK,
    },
    [LFG_DEFAULT_ROLE_HEALER] = {
        tank = false,
        healer = true,
        dps = false,
        text = ROLE_LABELS.HEALER,
    },
    [LFG_DEFAULT_ROLE_TANK_HEALER] = {
        tank = true,
        healer = true,
        dps = false,
        text = ROLE_LABELS.TANK .. " + " .. ROLE_LABELS.HEALER,
    },
    [LFG_DEFAULT_ROLE_TANK_DAMAGER] = {
        tank = true,
        healer = false,
        dps = true,
        text = ROLE_LABELS.TANK .. " + " .. ROLE_LABELS.DAMAGER,
    },
    [LFG_DEFAULT_ROLE_HEALER_DAMAGER] = {
        tank = false,
        healer = true,
        dps = true,
        text = ROLE_LABELS.HEALER .. " + " .. ROLE_LABELS.DAMAGER,
    },
    [LFG_DEFAULT_ROLE_ALL] = {
        tank = true,
        healer = true,
        dps = true,
        text = ROLE_LABELS.TANK .. " + " .. ROLE_LABELS.HEALER .. " + " .. ROLE_LABELS.DAMAGER,
    },
}
local LFG_ROLE_OPTIONS = {
    { value = LFG_DEFAULT_ROLE_NONE, text = LFG_ROLE_SELECTIONS[LFG_DEFAULT_ROLE_NONE].text },
    { value = LFG_DEFAULT_ROLE_DAMAGER, text = LFG_ROLE_SELECTIONS[LFG_DEFAULT_ROLE_DAMAGER].text },
    { value = LFG_DEFAULT_ROLE_TANK, text = LFG_ROLE_SELECTIONS[LFG_DEFAULT_ROLE_TANK].text },
    { value = LFG_DEFAULT_ROLE_HEALER, text = LFG_ROLE_SELECTIONS[LFG_DEFAULT_ROLE_HEALER].text },
    { value = LFG_DEFAULT_ROLE_TANK_HEALER, text = LFG_ROLE_SELECTIONS[LFG_DEFAULT_ROLE_TANK_HEALER].text },
    { value = LFG_DEFAULT_ROLE_TANK_DAMAGER, text = LFG_ROLE_SELECTIONS[LFG_DEFAULT_ROLE_TANK_DAMAGER].text },
    { value = LFG_DEFAULT_ROLE_HEALER_DAMAGER, text = LFG_ROLE_SELECTIONS[LFG_DEFAULT_ROLE_HEALER_DAMAGER].text },
    { value = LFG_DEFAULT_ROLE_ALL, text = LFG_ROLE_SELECTIONS[LFG_DEFAULT_ROLE_ALL].text },
}
-- Tagged unit popup names vary across Blizzard menu implementations, so register
-- against the common player, party, and raid variants and filter by unit token.
local MODERN_MENU_TAGS = {
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_SELF",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_PARTY_PLAYER",
    "MENU_UNIT_RAID",
    "MENU_UNIT_RAID_PLAYER",
}

for partyIndex = 1, 4 do
    MODERN_MENU_TAGS[#MODERN_MENU_TAGS + 1] = "MENU_UNIT_PARTY" .. partyIndex
end

for raidIndex = 1, 40 do
    MODERN_MENU_TAGS[#MODERN_MENU_TAGS + 1] = "MENU_UNIT_RAID" .. raidIndex
end

local function EnsureSavedVariables()
    if type(_G.PlayerRoleOptionsDB) ~= "table" then
        _G.PlayerRoleOptionsDB = {}
    end

    return _G.PlayerRoleOptionsDB
end

local function IsValidLFGDefaultRole(role)
    return LFG_ROLE_SELECTIONS[role] ~= nil
end

local function GetLFGRoleSelectionKey(tank, healer, dps)
    return (tank and "1" or "0")
        .. (healer and "1" or "0")
        .. (dps and "1" or "0")
end

local function GetSavedLFGDefaultRole()
    local db = _G.PlayerRoleOptionsDB
    if type(db) ~= "table" or not IsValidLFGDefaultRole(db.lfgDefaultRole) then
        return nil
    end

    return db.lfgDefaultRole
end

local function SetSavedLFGDefaultRole(role)
    if not IsValidLFGDefaultRole(role) then
        return
    end

    EnsureSavedVariables().lfgDefaultRole = role
end

local function GetCurrentLFGDefaultRole()
    if type(GetLFGRoles) ~= "function" then
        return LFG_DEFAULT_ROLE_NONE
    end

    local _, tank, healer, dps = GetLFGRoles()
    return LFG_ROLE_VALUE_BY_KEY[GetLFGRoleSelectionKey(tank, healer, dps)] or LFG_DEFAULT_ROLE_NONE
end

local function GetConfiguredLFGDefaultRole()
    return GetSavedLFGDefaultRole() or GetCurrentLFGDefaultRole()
end

local function ApplyLFGDefaultRole(role)
    if not IsValidLFGDefaultRole(role) then
        return false
    end

    if type(SetLFGRoles) ~= "function" then
        return false
    end

    local leader = false
    if type(GetLFGRoles) == "function" then
        leader = not not select(1, GetLFGRoles())
    end

    local selection = LFG_ROLE_SELECTIONS[role]
    SetLFGRoles(
        leader,
        selection.tank,
        selection.healer,
        selection.dps
    )

    return true
end

local function ApplySavedLFGDefaultRole()
    local role = GetSavedLFGDefaultRole()
    if role == nil then
        return false
    end

    return ApplyLFGDefaultRole(role)
end

local function IsLeaderForRoleChanges()
    if not IsInGroup() then
        return false
    end

    if IsInRaid() then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end

    return UnitIsGroupLeader("player")
end

local function IsUnitInCurrentGroup(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    if UnitIsUnit(unit, "player") then
        return IsInGroup()
    end

    return UnitInParty(unit) or UnitInRaid(unit)
end

local function CanShowForUnit(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    if not UnitIsPlayer(unit) then
        return false
    end

    if not IsUnitInCurrentGroup(unit) then
        return false
    end

    return IsLeaderForRoleChanges()
end

local function MenuAlreadyHasRoleSupport(which)
    local menuEntries = _G.UnitPopupMenus and which and _G.UnitPopupMenus[which]
    if type(menuEntries) ~= "table" then
        return false
    end

    for _, entry in ipairs(menuEntries) do
        if type(entry) == "string" and string.find(entry, "SET_ROLE", 1, true) then
            return true
        end
    end

    return false
end

local function GetAssignedRole(unit)
    local role = unit and UnitGroupRolesAssigned(unit)
    if role == nil or role == "" then
        return "NONE"
    end

    return role
end

local function GetMenuUnitName(unit, providedName)
    if providedName and providedName ~= "" then
        return providedName
    end

    if not unit then
        return nil
    end

    return GetUnitName(unit, true) or UnitName(unit)
end

local function SetUnitRole(role, unit, fullName)
    local target = unit
    if not target or not UnitExists(target) then
        target = fullName
    end

    if not target or target == "" then
        return
    end

    UnitSetRole(target, role)
    if type(CloseDropDownMenus) == "function" then
        CloseDropDownMenus()
    end
end

local function AddRoleEntry(unit, fullName, role)
    local info = UIDropDownMenu_CreateInfo()
    info.text = ROLE_LABELS[role]
    info.checked = (GetAssignedRole(unit) == role)
    info.func = function()
        SetUnitRole(role, unit, fullName)
    end
    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

local function AddRoleMenu(dropdownMenu, which, unit, name)
    if UIDROPDOWNMENU_MENU_LEVEL ~= 1 then
        return
    end

    if type(UIDropDownMenu_CreateInfo) ~= "function" or type(UIDropDownMenu_AddButton) ~= "function" then
        return
    end

    if MenuAlreadyHasRoleSupport(which) then
        return
    end

    unit = unit or (dropdownMenu and dropdownMenu.unit)
    if not CanShowForUnit(unit) then
        return
    end

    name = name or GetUnitName(unit, true) or UnitName(unit)
    if not name then
        return
    end

    local title = UIDropDownMenu_CreateInfo()
    title.isTitle = true
    title.notCheckable = true
    title.text = MENU_TITLE
    UIDropDownMenu_AddButton(title, UIDROPDOWNMENU_MENU_LEVEL)

    for _, role in ipairs(ROLE_ORDER) do
        AddRoleEntry(unit, name, role)
    end
end

local function GetModernMenuUnit(owner, contextData)
    local unit = contextData and (contextData.unit or contextData.unitToken)
    if unit and UnitExists(unit) then
        return unit
    end

    unit = owner and owner.unit
    if unit and UnitExists(unit) then
        return unit
    end

    return nil
end

local function AddRoleChoicesModern(menuDescription, unit, fullName)
    for _, role in ipairs(ROLE_ORDER) do
        if type(menuDescription.CreateRadio) == "function" then
            menuDescription:CreateRadio(
                ROLE_LABELS[role],
                function()
                    return GetAssignedRole(unit) == role
                end,
                function()
                    SetUnitRole(role, unit, fullName)
                end
            )
        elseif type(menuDescription.CreateButton) == "function" then
            menuDescription:CreateButton(ROLE_LABELS[role], function()
                SetUnitRole(role, unit, fullName)
            end)
        end
    end
end

local function AddRoleMenuModern(owner, rootDescription, contextData)
    if rootDescription == nil then
        return
    end

    if type(rootDescription.CreateButton) ~= "function" then
        return
    end

    local unit = GetModernMenuUnit(owner, contextData)
    if not CanShowForUnit(unit) then
        return
    end

    local name = GetMenuUnitName(unit, contextData and (contextData.fullName or contextData.name))
    if not name then
        return
    end

    if type(rootDescription.CreateDivider) == "function" then
        rootDescription:CreateDivider()
    end

    local roleMenu = rootDescription:CreateButton(MENU_TITLE)
    if roleMenu then
        AddRoleChoicesModern(roleMenu, unit, name)
    elseif type(rootDescription.CreateTitle) == "function" then
        rootDescription:CreateTitle(MENU_TITLE)
        AddRoleChoicesModern(rootDescription, unit, name)
    end
end

local function RegisterModernMenus()
    if type(_G.Menu) ~= "table" or type(_G.Menu.ModifyMenu) ~= "function" then
        return false
    end

    local registeredAny = false
    for _, tag in ipairs(MODERN_MENU_TAGS) do
        local ok = pcall(_G.Menu.ModifyMenu, tag, AddRoleMenuModern)
        if ok then
            registeredAny = true
        end
    end

    return registeredAny
end

local function RegisterLegacyMenu()
    if type(_G.hooksecurefunc) ~= "function" or type(_G.UnitPopup_ShowMenu) ~= "function" then
        return false
    end

    return pcall(hooksecurefunc, "UnitPopup_ShowMenu", AddRoleMenu)
end

local function RegisterSettingsCategory()
    if PlayerRoleOptions.settingsCategory ~= nil then
        return true
    end

    if type(_G.Settings) ~= "table"
        or type(_G.Settings.RegisterVerticalLayoutCategory) ~= "function"
        or type(_G.Settings.RegisterProxySetting) ~= "function"
        or type(_G.Settings.CreateDropdown) ~= "function"
        or type(_G.Settings.CreateControlTextContainer) ~= "function"
        or type(_G.Settings.RegisterAddOnCategory) ~= "function"
        or type(_G.Settings.VarType) ~= "table"
    then
        return false
    end

    local category = _G.Settings.RegisterVerticalLayoutCategory(SETTINGS_CATEGORY_NAME)
    local function GetValue()
        return GetConfiguredLFGDefaultRole()
    end

    local function SetValue(value)
        if not IsValidLFGDefaultRole(value) then
            return
        end

        SetSavedLFGDefaultRole(value)
        ApplyLFGDefaultRole(value)
    end

    local setting = _G.Settings.RegisterProxySetting(
        category,
        LFG_DEFAULT_ROLE_SETTING,
        _G.Settings.VarType.Number,
        LFG_DEFAULT_ROLE_LABEL,
        LFG_DEFAULT_ROLE_NONE,
        GetValue,
        SetValue
    )

    _G.Settings.CreateDropdown(category, setting, function()
        local container = _G.Settings.CreateControlTextContainer()
        for _, option in ipairs(LFG_ROLE_OPTIONS) do
            container:Add(option.value, option.text)
        end
        return container:GetData()
    end, LFG_DEFAULT_ROLE_TOOLTIP)

    _G.Settings.RegisterAddOnCategory(category)
    PlayerRoleOptions.settingsCategory = category
    return true
end

local function OnEvent(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            EnsureSavedVariables()
        end

        RegisterSettingsCategory()
    elseif event == "PLAYER_LOGIN" then
        EnsureSavedVariables()
        ApplySavedLFGDefaultRole()
    end
end

EnsureSavedVariables()
RegisterModernMenus()
RegisterLegacyMenu()
RegisterSettingsCategory()

if type(CreateFrame) == "function" then
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:SetScript("OnEvent", OnEvent)
    PlayerRoleOptions.eventFrame = eventFrame
end

PlayerRoleOptions.addonName = addonName or "PlayerRoleOptions"
PlayerRoleOptions._test = {
    AddRoleMenu = AddRoleMenu,
    AddRoleChoicesModern = AddRoleChoicesModern,
    ApplyLFGDefaultRole = ApplyLFGDefaultRole,
    ApplySavedLFGDefaultRole = ApplySavedLFGDefaultRole,
    AddRoleMenuModern = AddRoleMenuModern,
    CanShowForUnit = CanShowForUnit,
    EnsureSavedVariables = EnsureSavedVariables,
    GetConfiguredLFGDefaultRole = GetConfiguredLFGDefaultRole,
    GetCurrentLFGDefaultRole = GetCurrentLFGDefaultRole,
    IsUnitInCurrentGroup = IsUnitInCurrentGroup,
    GetSavedLFGDefaultRole = GetSavedLFGDefaultRole,
    GetModernMenuUnit = GetModernMenuUnit,
    IsLeaderForRoleChanges = IsLeaderForRoleChanges,
    IsValidLFGDefaultRole = IsValidLFGDefaultRole,
    MenuAlreadyHasRoleSupport = MenuAlreadyHasRoleSupport,
    OnEvent = OnEvent,
    RegisterLegacyMenu = RegisterLegacyMenu,
    RegisterModernMenus = RegisterModernMenus,
    RegisterSettingsCategory = RegisterSettingsCategory,
    SetSavedLFGDefaultRole = SetSavedLFGDefaultRole,
    SetUnitRole = SetUnitRole,
}

return PlayerRoleOptions
