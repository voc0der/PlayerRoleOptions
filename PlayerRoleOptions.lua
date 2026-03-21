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

local function IsLeaderForRoleChanges()
    if not IsInGroup() then
        return false
    end

    if IsInRaid() then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end

    return UnitIsGroupLeader("player")
end

local function CanShowForUnit(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    if not UnitIsPlayer(unit) then
        return false
    end

    if UnitIsUnit(unit, "player") then
        return false
    end

    if not (UnitInParty(unit) or UnitInRaid(unit)) then
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

local function SetUnitRole(role, unit, fullName)
    local target = unit
    if not target or not UnitExists(target) then
        target = fullName
    end

    if not target or target == "" then
        return
    end

    UnitSetRole(target, role)
    CloseDropDownMenus()
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

hooksecurefunc("UnitPopup_ShowMenu", AddRoleMenu)

PlayerRoleOptions.addonName = addonName or "PlayerRoleOptions"
PlayerRoleOptions._test = {
    AddRoleMenu = AddRoleMenu,
    CanShowForUnit = CanShowForUnit,
    IsLeaderForRoleChanges = IsLeaderForRoleChanges,
    MenuAlreadyHasRoleSupport = MenuAlreadyHasRoleSupport,
    SetUnitRole = SetUnitRole,
}

return PlayerRoleOptions
