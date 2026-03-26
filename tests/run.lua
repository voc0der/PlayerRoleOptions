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

local function assert_false(value, message)
    if value then
        error(message or "assert_false failed")
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
        frames = {},
        hooks = {},
        lfg_roles = copy_table(opts.lfg_roles or {}),
        modified_menus = {},
        settings_categories = {},
        settings_dropdowns = {},
        settings_proxy_settings = {},
        units = copy_table(opts.units or {}),
        in_group = not not opts.in_group,
        in_raid = not not opts.in_raid,
        leaders = copy_table(opts.leaders or {}),
        assistants = copy_table(opts.assistants or {}),
        unit_popup_menus = copy_table(opts.unit_popup_menus or {}),
    }

    _G.PlayerRoleOptions = nil
    _G.PlayerRoleOptionsDB = copy_table(opts.saved_vars)
    _G.TANK = "Tank"
    _G.HEALER = "Healer"
    _G.DAMAGER = "DPS"
    _G.SET_ROLE = "Set Role"
    _G.UIDROPDOWNMENU_MENU_LEVEL = 1
    _G.UnitPopupMenus = state.unit_popup_menus
    _G.UnitPopup_ShowMenu = nil

    if not opts.disable_legacy_unit_popup then
        _G.UnitPopup_ShowMenu = function() end
    end

    _G.hooksecurefunc = function(function_name, callback)
        if type(_G[function_name]) ~= "function" then
            error(function_name .. " is not a function")
        end
        state.hooks[function_name] = callback
    end

    _G.Menu = nil
    if opts.modern_menu then
        _G.Menu = {
            ModifyMenu = function(tag, callback)
                state.modified_menus[tag] = callback
            end,
        }
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

    _G.CreateFrame = function()
        local frame = {
            events = {},
            scripts = {},
        }

        function frame:RegisterEvent(event)
            self.events[event] = true
        end

        function frame:SetScript(scriptType, handler)
            self.scripts[scriptType] = handler
        end

        state.frames[#state.frames + 1] = frame
        return frame
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

    _G.GetLFGRoles = function()
        return not not state.lfg_roles.leader,
            not not state.lfg_roles.tank,
            not not state.lfg_roles.healer,
            not not state.lfg_roles.dps
    end

    _G.SetLFGRoles = function(leader, tank, healer, dps)
        state.last_lfg_roles_set = {
            leader = not not leader,
            tank = not not tank,
            healer = not not healer,
            dps = not not dps,
        }
        state.lfg_roles = copy_table(state.last_lfg_roles_set)
    end

    _G.Settings = nil
    if opts.settings_api then
        _G.Settings = {
            VarType = {
                Number = "Number",
            },
        }

        function _G.Settings.RegisterVerticalLayoutCategory(name)
            local category = {
                name = name,
            }
            state.settings_categories[#state.settings_categories + 1] = category
            return category
        end

        function _G.Settings.RegisterProxySetting(category, variable, variableType, name, defaultValue, getValue, setValue)
            local setting = {
                category = category,
                defaultValue = defaultValue,
                getValue = getValue,
                name = name,
                setValue = setValue,
                variable = variable,
                variableType = variableType,
            }

            function setting:GetValue()
                return self.getValue()
            end

            function setting:SetValue(value)
                self.setValue(value)
            end

            state.settings_proxy_settings[#state.settings_proxy_settings + 1] = setting
            return setting
        end

        function _G.Settings.CreateControlTextContainer()
            local entries = {}
            return {
                Add = function(_, value, text)
                    entries[#entries + 1] = {
                        value = value,
                        text = text,
                    }
                end,
                GetData = function()
                    return copy_table(entries)
                end,
            }
        end

        function _G.Settings.CreateDropdown(category, setting, getOptions, tooltip)
            local dropdown = {
                category = category,
                options = getOptions(),
                setting = setting,
                tooltip = tooltip,
            }
            state.settings_dropdowns[#state.settings_dropdowns + 1] = dropdown
            return dropdown
        end

        function _G.Settings.RegisterAddOnCategory(category)
            state.registered_addon_category = category
        end
    end

    local chunk = assert(loadfile("PlayerRoleOptions.lua"))
    state.exports = chunk("PlayerRoleOptions")
    state.event_frame = state.frames[1]
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

local function attach_menu_methods(description)
    function description:CreateDivider()
        local child = { kind = "divider" }
        self.children[#self.children + 1] = child
        return child
    end

    function description:CreateTitle(text)
        local child = { kind = "title", text = text }
        self.children[#self.children + 1] = child
        return child
    end

    function description:CreateRadio(text, isSelected, setSelected, data)
        local child = {
            kind = "radio",
            text = text,
            checked = isSelected and isSelected(data) or false,
            func = function()
                if setSelected then
                    setSelected(data)
                end
            end,
        }
        self.children[#self.children + 1] = child
        return child
    end

    function description:CreateButton(text, callback)
        local child = {
            kind = "button",
            text = text,
            func = callback,
            children = {},
        }
        attach_menu_methods(child)
        self.children[#self.children + 1] = child
        return child
    end
end

local function create_root_description()
    local rootDescription = {
        kind = "root",
        children = {},
    }
    attach_menu_methods(rootDescription)
    return rootDescription
end

local function find_child_by_text(children, text)
    for _, child in ipairs(children) do
        if child.text == text then
            return child
        end
    end
end

local function find_dropdown_option_value(dropdown, text)
    for _, option in ipairs(dropdown.options) do
        if option.text == text then
            return option.value
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

local function test_allows_self_when_leader()
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
    assert_equal(#selfState.added_buttons, 5, "should add menu for self when leader")

    local clearButton = find_button_by_text(selfState.added_buttons, "Clear Role")
    assert_true(clearButton and type(clearButton.func) == "function", "expected clear role callback for self")
    clearButton.func()
    assert_equal(selfState.last_unit_set_role.target, "player", "expected self unit token target")
    assert_equal(selfState.last_unit_set_role.role, "NONE", "expected self clear role selection")
end

local function test_skips_menu_for_non_leader()
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

local function test_registers_modern_menu_for_current_clients()
    local state = setup_env({
        modern_menu = true,
        disable_legacy_unit_popup = true,
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

    assert_true(type(state.menu_hook) ~= "function", "legacy hook should be skipped when UnitPopup_ShowMenu is unavailable")
    assert_true(type(state.modified_menus.MENU_UNIT_PLAYER) == "function", "expected Menu.ModifyMenu registration")

    local root = create_root_description()
    state.modified_menus.MENU_UNIT_PLAYER(
        { unit = "party1" },
        root,
        { unit = "party1", fullName = "Alice-Atiesh" }
    )

    assert_equal(#root.children, 2, "expected divider and Set Role submenu")
    assert_equal(root.children[2].text, "Set Role", "expected modern submenu button")
    assert_equal(#root.children[2].children, 4, "expected four role entries inside submenu")
    assert_equal(root.children[2].children[1].text, "Tank", "expected tank entry")
    assert_equal(root.children[2].children[2].text, "Healer", "expected healer entry")
    assert_true(root.children[2].children[2].checked, "expected current role to be checked")

    local tankButton = find_child_by_text(root.children[2].children, "Tank")
    assert_true(tankButton and type(tankButton.func) == "function", "expected tank entry callback")
    tankButton.func()

    assert_equal(state.last_unit_set_role.target, "party1", "expected unit token target for modern menu")
    assert_equal(state.last_unit_set_role.role, "TANK", "expected selected role for modern menu")
    assert_true(state.menus_closed, "expected dropdown close guard to run when available")
end

local function test_modern_menu_allows_self_assignment()
    local state = setup_env({
        modern_menu = true,
        disable_legacy_unit_popup = true,
        in_group = true,
        units = {
            player = {
                is_player = true,
                name = "Leader",
                assigned_role = "DAMAGER",
            },
        },
        leaders = {
            player = true,
        },
    })

    local root = create_root_description()
    state.modified_menus.MENU_UNIT_PLAYER(
        { unit = "player" },
        root,
        { unit = "player", fullName = "Leader" }
    )

    assert_equal(#root.children, 2, "expected modern self menu to add a submenu")

    local clearButton = find_child_by_text(root.children[2].children, "Clear Role")
    assert_true(clearButton and type(clearButton.func) == "function", "expected self clear role callback in modern menu")
    clearButton.func()

    assert_equal(state.last_unit_set_role.target, "player", "expected modern self unit token target")
    assert_equal(state.last_unit_set_role.role, "NONE", "expected modern self clear role selection")
end

local function test_can_show_for_self_only_when_in_group_and_leader()
    local leaderState = setup_env({
        in_group = true,
        units = {
            player = { is_player = true, name = "Leader" },
        },
        leaders = {
            player = true,
        },
    })

    assert_true(leaderState.exports._test.CanShowForUnit("player"), "leader should be able to set own role while grouped")

    local soloState = setup_env({
        units = {
            player = { is_player = true, name = "Solo" },
        },
        leaders = {
            player = true,
        },
    })

    assert_false(soloState.exports._test.CanShowForUnit("player"), "solo player should not get a role menu")
end

local function test_loads_without_popup_api()
    local ok, state = pcall(setup_env, {
        disable_legacy_unit_popup = true,
    })

    assert_true(ok, "addon should load without popup menu APIs")
    assert_true(type(state.menu_hook) ~= "function", "should not register legacy hook when popup API is missing")
    assert_true(next(state.modified_menus) == nil, "should not register modern menus when menu API is missing")
end

local function test_ignores_registration_failures_during_load()
    local ok = pcall(function()
        setup_env({
            modern_menu = true,
            disable_legacy_unit_popup = true,
        })
    end)

    assert_true(ok, "load should not fail when registration APIs are present")

    local state = {
        modified_menus = {},
    }

    _G.PlayerRoleOptions = nil
    _G.PlayerRoleOptionsDB = nil
    _G.TANK = "Tank"
    _G.HEALER = "Healer"
    _G.DAMAGER = "DPS"
    _G.SET_ROLE = "Set Role"
    _G.UnitPopupMenus = {}
    _G.UnitPopup_ShowMenu = function() end
    _G.hooksecurefunc = function()
        error("legacy registration failed")
    end
    _G.Menu = {
        ModifyMenu = function(tag, callback)
            if tag == "MENU_UNIT_PLAYER" then
                error("modern registration failed")
            end
            state.modified_menus[tag] = callback
        end,
    }
    _G.UIDropDownMenu_CreateInfo = function()
        return {}
    end
    _G.UIDropDownMenu_AddButton = function() end
    _G.CloseDropDownMenus = function() end
    _G.IsInGroup = function()
        return false
    end
    _G.IsInRaid = function()
        return false
    end
    _G.UnitIsGroupLeader = function()
        return false
    end
    _G.UnitIsGroupAssistant = function()
        return false
    end
    _G.UnitExists = function()
        return false
    end
    _G.UnitIsPlayer = function()
        return false
    end
    _G.UnitIsUnit = function()
        return false
    end
    _G.UnitInParty = function()
        return false
    end
    _G.UnitInRaid = function()
        return false
    end
    _G.UnitGroupRolesAssigned = function()
        return nil
    end
    _G.GetUnitName = function()
        return nil
    end
    _G.UnitName = function()
        return nil
    end
    _G.UnitSetRole = function() end
    _G.GetLFGRoles = function()
        return false, false, false, false
    end
    _G.SetLFGRoles = function() end
    _G.Settings = nil
    _G.CreateFrame = function()
        return {
            RegisterEvent = function() end,
            SetScript = function() end,
        }
    end

    local chunk = assert(loadfile("PlayerRoleOptions.lua"))
    local loadOk = pcall(chunk, "PlayerRoleOptions")

    assert_true(loadOk, "addon should ignore load-time registration failures")
    assert_true(type(state.modified_menus.MENU_UNIT_RAID) == "function", "should continue registering other modern tags")
end

local function test_registers_settings_category_with_dropdown()
    local state = setup_env({
        settings_api = true,
        lfg_roles = {
            healer = true,
        },
    })

    assert_equal(#state.settings_categories, 1, "expected one addon settings category")
    assert_equal(state.settings_categories[1].name, "PlayerRoleOptions", "expected settings category name")
    assert_true(state.registered_addon_category == state.settings_categories[1], "expected addon category registration")
    assert_equal(#state.settings_dropdowns, 1, "expected one dropdown control")
    assert_equal(state.settings_dropdowns[1].setting.name, "LFG Default Role", "expected dropdown label")
    assert_equal(state.settings_dropdowns[1].options[1].text, "None", "expected none option")
    assert_equal(state.settings_dropdowns[1].options[2].text, "DPS", "expected dps option")
    assert_equal(state.settings_dropdowns[1].options[3].text, "Tank", "expected tank option")
    assert_equal(state.settings_dropdowns[1].options[4].text, "Healer", "expected healer option")
    assert_equal(state.settings_dropdowns[1].options[5].text, "Tank + Healer", "expected tank healer option")
    assert_equal(state.settings_dropdowns[1].options[6].text, "Tank + DPS", "expected tank dps option")
    assert_equal(state.settings_dropdowns[1].options[7].text, "Healer + DPS", "expected healer dps option")
    assert_equal(state.settings_dropdowns[1].options[8].text, "Tank + Healer + DPS", "expected all roles option")
end

local function test_settings_dropdown_reads_current_lfg_role_when_unset()
    local state = setup_env({
        settings_api = true,
        lfg_roles = {
            tank = true,
            healer = true,
        },
    })

    assert_equal(state.exports._test.GetSavedLFGDefaultRole(), nil, "expected no saved default role")
    assert_equal(state.settings_proxy_settings[1]:GetValue(), state.exports._test.GetCurrentLFGDefaultRole(), "dropdown should reflect current LFG role when unset")
    assert_equal(state.settings_proxy_settings[1]:GetValue(), find_dropdown_option_value(state.settings_dropdowns[1], "Tank + Healer"), "expected current multi-role selection to map to combo option")
end

local function test_settings_dropdown_change_saves_and_applies_role()
    local state = setup_env({
        settings_api = true,
        lfg_roles = {
            leader = true,
            healer = true,
        },
    })

    local dropdown = state.settings_dropdowns[1]
    local tankDpsValue = find_dropdown_option_value(dropdown, "Tank + DPS")
    state.settings_proxy_settings[1]:SetValue(tankDpsValue)

    assert_equal(state.exports._test.GetSavedLFGDefaultRole(), tankDpsValue, "expected selected role to be saved")
    assert_true(state.last_lfg_roles_set ~= nil, "expected dropdown change to apply role")
    assert_true(state.last_lfg_roles_set.leader, "expected leader flag to be preserved")
    assert_true(state.last_lfg_roles_set.tank, "expected tank role to be enabled")
    assert_false(state.last_lfg_roles_set.healer, "expected healer role to be cleared")
    assert_true(state.last_lfg_roles_set.dps, "expected dps role to be enabled")
end

local function test_player_login_applies_saved_lfg_default_role()
    local state = setup_env({
        settings_api = true,
        lfg_roles = {
            leader = true,
        },
    })

    local healerDpsValue = find_dropdown_option_value(state.settings_dropdowns[1], "Healer + DPS")
    state.exports._test.SetSavedLFGDefaultRole(healerDpsValue)
    state.last_lfg_roles_set = nil

    state.exports._test.OnEvent(nil, "PLAYER_LOGIN")

    assert_true(state.last_lfg_roles_set ~= nil, "expected saved role to apply on login")
    assert_true(state.last_lfg_roles_set.leader, "expected leader flag to remain enabled")
    assert_false(state.last_lfg_roles_set.tank, "expected tank role cleared on login")
    assert_true(state.last_lfg_roles_set.healer, "expected healer role applied on login")
    assert_true(state.last_lfg_roles_set.dps, "expected dps role applied on login")
end

local tests = {
    { name = "adds role entries for party member", fn = test_adds_role_entries_for_party_member },
    { name = "allows self when leader", fn = test_allows_self_when_leader },
    { name = "skips menu for non-leader", fn = test_skips_menu_for_non_leader },
    { name = "raid assistant can assign roles", fn = test_raid_assistant_can_assign_roles },
    { name = "skips when Blizzard menu returns", fn = test_skips_when_blizzard_menu_returns },
    { name = "registers modern menu for current clients", fn = test_registers_modern_menu_for_current_clients },
    { name = "modern menu allows self assignment", fn = test_modern_menu_allows_self_assignment },
    { name = "can show for self only when in group and leader", fn = test_can_show_for_self_only_when_in_group_and_leader },
    { name = "loads without popup api", fn = test_loads_without_popup_api },
    { name = "ignores registration failures during load", fn = test_ignores_registration_failures_during_load },
    { name = "registers settings category with dropdown", fn = test_registers_settings_category_with_dropdown },
    { name = "settings dropdown reads current lfg role when unset", fn = test_settings_dropdown_reads_current_lfg_role_when_unset },
    { name = "settings dropdown change saves and applies role", fn = test_settings_dropdown_change_saves_and_applies_role },
    { name = "player login applies saved lfg default role", fn = test_player_login_applies_saved_lfg_default_role },
}

for _, testCase in ipairs(tests) do
    testCase.fn()
    io.write("ok - " .. testCase.name .. "\n")
end

io.write("all tests passed\n")
