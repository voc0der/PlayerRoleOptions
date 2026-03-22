local addonName = ...
local PlayerRoleOptions = _G.PlayerRoleOptions or {}
_G.PlayerRoleOptions = PlayerRoleOptions

local MENU_TITLE = _G.SET_ROLE or "Set Role"
local ROLE_LABELS = {
    TANK = _G.TANK or "Tank",
    HEALER = _G.HEALER or "Healer",
    DAMAGER = _G.DAMAGER or "DPS",
    NONE = "Clear Role",
}

local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER", "NONE" }
-- Tagged unit popup names vary across Blizzard menu implementations, so register
-- against the common player, party, and raid variants and filter by unit token.
local MODERN_MENU_TAGS = {
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_PLAYER",
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

RegisterModernMenus()
RegisterLegacyMenu()

PlayerRoleOptions.addonName = addonName or "PlayerRoleOptions"
PlayerRoleOptions._test = {
    AddRoleMenu = AddRoleMenu,
    AddRoleChoicesModern = AddRoleChoicesModern,
    AddRoleMenuModern = AddRoleMenuModern,
    CanShowForUnit = CanShowForUnit,
    IsUnitInCurrentGroup = IsUnitInCurrentGroup,
    GetModernMenuUnit = GetModernMenuUnit,
    IsLeaderForRoleChanges = IsLeaderForRoleChanges,
    MenuAlreadyHasRoleSupport = MenuAlreadyHasRoleSupport,
    RegisterLegacyMenu = RegisterLegacyMenu,
    RegisterModernMenus = RegisterModernMenus,
    SetUnitRole = SetUnitRole,
}

return PlayerRoleOptions
