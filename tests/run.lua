local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assert_equal failed") .. string.format(" (expected=%s, actual=%s)", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "assert_true failed")
    end
end

local function copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local out = {}
    for key, nested in pairs(value) do
        out[key] = copy_table(nested)
    end
    return out
end

local function setup_env(opts)
    opts = opts or {}

    local state = {
        added_buttons = {},
        hooks = {},
        units = copy_table(opts.units or {}),
        in_group = not not opts.in_group,
        in_raid = not not opts.in_raid,
        leaders = copy_table(opts.leaders or {}),
        assistants = copy_table(opts.assistants or {}),
        unit_popup_menus = copy_table(opts.unit_popup_menus or {}),
    }

    _G.PlayerRoleOptions = nil
    _G.TANK = "Tank"
    _G.HEALER = "Healer"
    _G.DAMAGER = "DPS"
    _G.SET_ROLE = "Set Role"
    _G.UIDROPDOWNMENU_MENU_LEVEL = 1
    _G.UnitPopupMenus = state.unit_popup_menus

    _G.hooksecurefunc = function(function_name, callback)
        state.hooks[function_name] = callback
    end

    _G.UIDropDownMenu_CreateInfo = function()
        return {}
    end

    _G.UIDropDownMenu_AddButton = function(info, level)
        local snapshot = {}
        for key, value in pairs(info) do
            snapshot[key] = value
        end
        snapshot.level = level
        state.added_buttons[#state.added_buttons + 1] = snapshot
    end

    _G.CloseDropDownMenus = function()
        state.menus_closed = true
    end

    _G.IsInGroup = function()
        return state.in_group
    end

    _G.IsInRaid = function()
        return state.in_raid
    end

    _G.UnitIsGroupLeader = function(unit)
        return not not state.leaders[unit]
    end

    _G.UnitIsGroupAssistant = function(unit)
        return not not state.assistants[unit]
    end

    _G.UnitExists = function(unit)
        return state.units[unit] ~= nil
    end

    _G.UnitIsPlayer = function(unit)
        local unitInfo = state.units[unit]
        return unitInfo and unitInfo.is_player ~= false or false
    end

    _G.UnitIsUnit = function(first, second)
        return first == second
    end

    _G.UnitInParty = function(unit)
        local unitInfo = state.units[unit]
        return unitInfo and unitInfo.in_party or false
    end

    _G.UnitInRaid = function(unit)
        local unitInfo = state.units[unit]
        return unitInfo and unitInfo.in_raid or false
    end

    _G.UnitGroupRolesAssigned = function(unit)
        local unitInfo = state.units[unit]
        return unitInfo and unitInfo.assigned_role
    end

    _G.GetUnitName = function(unit, show_realm_name)
        local unitInfo = state.units[unit]
        if not unitInfo then
            return nil
        end

        if show_realm_name and unitInfo.full_name then
            return unitInfo.full_name
        end

        return unitInfo.name
    end

    _G.UnitName = function(unit)
        local unitInfo = state.units[unit]
        return unitInfo and unitInfo.name
    end

    _G.UnitSetRole = function(target, role)
        state.last_unit_set_role = {
            target = target,
            role = role,
        }
    end

    local chunk = assert(loadfile("PlayerRoleOptions.lua"))
    state.exports = chunk("PlayerRoleOptions")
    state.menu_hook = state.hooks.UnitPopup_ShowMenu
    return state
end

local function find_button_by_text(buttons, text)
    for _, button in ipairs(buttons) do
        if button.text == text then
            return button
        end
    end
end

local function test_adds_role_entries_for_party_member()
    local state = setup_env({
        in_group = true,
        units = {
            player = { is_player = true, in_party = true, name = "Leader" },
            party1 = {
                is_player = true,
                in_party = true,
                name = "Alice",
                full_name = "Alice-Atiesh",
                assigned_role = "HEALER",
            },
        },
        leaders = {
            player = true,
        },
    })

    assert_true(type(state.menu_hook) == "function", "expected UnitPopup_ShowMenu hook")
    state.menu_hook({ unit = "party1" }, "PARTY", "party1", "Alice-Atiesh")

    assert_equal(#state.added_buttons, 5, "expected title plus four role entries")
    assert_equal(state.added_buttons[1].text, "Set Role", "expected role menu title")
    assert_equal(state.added_buttons[2].text, "Tank", "expected tank entry")
    assert_equal(state.added_buttons[3].text, "Healer", "expected healer entry")
    assert_equal(state.added_buttons[4].text, "DPS", "expected damage entry")
    assert_equal(state.added_buttons[5].text, "Clear Role", "expected clear entry")
    assert_true(state.added_buttons[3].checked, "expected current role to be checked")

    local tankButton = find_button_by_text(state.added_buttons, "Tank")
    assert_true(tankButton and type(tankButton.func) == "function", "expected tank button callback")
    tankButton.func()

    assert_equal(state.last_unit_set_role.target, "party1", "expected unit token target for UnitSetRole")
    assert_equal(state.last_unit_set_role.role, "TANK", "expected selected role")
    assert_true(state.menus_closed, "expected menu to close after selection")
end

local function test_skips_menu_for_self_or_non_leader()
    local selfState = setup_env({
        in_group = true,
        units = {
            player = { is_player = true, in_party = true, name = "Leader" },
        },
        leaders = {
            player = true,
        },
    })

    selfState.menu_hook({ unit = "player" }, "SELF", "player", "Leader")
    assert_equal(#selfState.added_buttons, 0, "should not add menu for self")

    local memberState = setup_env({
        in_group = true,
        units = {
            player = { is_player = true, in_party = true, name = "Member" },
            party1 = { is_player = true, in_party = true, name = "Alice" },
        },
    })

    memberState.menu_hook({ unit = "party1" }, "PARTY", "party1", "Alice")
    assert_equal(#memberState.added_buttons, 0, "should not add menu for non-leader")
end

local function test_raid_assistant_can_assign_roles()
    local state = setup_env({
        in_group = true,
        in_raid = true,
        units = {
            player = { is_player = true, in_raid = true, name = "Assistant" },
            raid4 = { is_player = true, in_raid = true, name = "Tanky" },
        },
        assistants = {
            player = true,
        },
    })

    state.menu_hook({ unit = "raid4" }, "RAID_PLAYER", "raid4", "Tanky")
    assert_equal(#state.added_buttons, 5, "raid assistants should see role menu")
end

local function test_skips_when_blizzard_menu_returns()
    local state = setup_env({
        in_group = true,
        units = {
            player = { is_player = true, in_party = true, name = "Leader" },
            party1 = { is_player = true, in_party = true, name = "Alice" },
        },
        leaders = {
            player = true,
        },
        unit_popup_menus = {
            PARTY = { "WHISPER", "SET_ROLE", "INVITE" },
        },
    })

    state.menu_hook({ unit = "party1" }, "PARTY", "party1", "Alice")
    assert_equal(#state.added_buttons, 0, "should not duplicate native Set Role menu")
end

local tests = {
    { name = "adds role entries for party member", fn = test_adds_role_entries_for_party_member },
    { name = "skips menu for self or non-leader", fn = test_skips_menu_for_self_or_non_leader },
    { name = "raid assistant can assign roles", fn = test_raid_assistant_can_assign_roles },
    { name = "skips when Blizzard menu returns", fn = test_skips_when_blizzard_menu_returns },
}

for _, testCase in ipairs(tests) do
    testCase.fn()
    io.write("ok - " .. testCase.name .. "\n")
end

io.write("all tests passed\n")
