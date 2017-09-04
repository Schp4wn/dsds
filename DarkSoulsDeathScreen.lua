----------------------------------------------------------------
-- "UP VALUES" FOR SPEED ---------------------------------------
----------------------------------------------------------------

local type = type
local tonumber = tonumber
local tostring = tostring

local table_remove = table.remove
local table_insert = table.insert

local string_gfind = string.gfind
local string_format = string.format
local string_lower = string.lower
local string_upper = string.upper

local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local PlaySoundFile = PlaySoundFile
local UIParent = UIParent
local UnitBuff = UnitBuff

----------------------------------------------------------------
-- HELPER FUNCTIONS --------------------------------------------
----------------------------------------------------------------

local function isTable(p_table)
    return type(p_table) == "table"
end

local function isString(p_string)
    return type(p_string) == "string"
end

local function isNumber(p_number)
    return type(p_number) == "number"
end

local function isBoolean(p_boolean)
    return type(p_boolean) == "boolean"
end

local function isFunction(p_function)
    return type(p_function) == "function"
end

local function merge(left, right)
    local t = {}

    if not isTable(left) or not isTable(right) then
        error("Usage: merge(left <table>, right <table>)")
    end

    -- copy left into temp table.
    for k, v in pairs(left) do
        t[k] = v
    end

    -- Add or overwrite right values.
    for k, v in pairs(right) do
        t[k] = v
    end

    return t
end

local function print(p_message)
    local message

    message = tostring(p_message)

    if not isString(message) then
        error('Could not cast message to string')
    end

    if message and message ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end

----------------------------------------------------------------
-- INTERNAL CONSTANTS ------------------------------------------
----------------------------------------------------------------

local ADDON_NAME = 'DeathMessage'

local SLASH_CMD_CONSTANT_1 = '/'..string_lower(ADDON_NAME)

local SCRIPTHANDLER_ON_EVENT = 'OnEvent'
local SCRIPTHANDLER_ON_UPDATE = 'OnUpdate'

local ADDON_LOADED_EVENT = 'ADDON_LOADED'
local PLAYER_LOGIN_EVENT = 'PLAYER_LOGIN'
local PLAYER_LOGOUT_EVENT = 'PLAYER_LOGOUT'
local PLAYER_DEAD_EVENT = 'PLAYER_DEAD'

local MEDIA_PATH = [[Interface\Addons\DarkSoulsDeathScreen\media\]]
local YOU_DIED = MEDIA_PATH .. [[YOUDIED.tga]]
local YOU_DIED_SOUND = MEDIA_PATH .. [[YOUDIED.ogg]]

local BACKGROUND_GRADIENT_PERCENT = 0.15 -- of background height
local BACKGROUND_HEIGHT_PERCENT = 0.21 -- of screen height

local BG_STRATA = "HIGH"

----------------------------------------------------------------
-- PUBLIC CONSTANTS --------------------------------------------
----------------------------------------------------------------

-- Good to use to expose parts of your addon to the rest of the world

----------------------------------------------------------------
-- ADDON -------------------------------------------------------
----------------------------------------------------------------

local this = CreateFrame("FRAME", ADDON_NAME, UIParent)

----------------------------------------------------------------
-- DATABASE KEYS -----------------------------------------------
----------------------------------------------------------------

-- IF ANY OF THE >>VALUES<< CHANGE YOU WILL RESET THE STORED
-- VARIABLES OF THE PLAYER. EFFECTIVELY DELETING THEIR CUSTOM-
-- ISATION SETTINGS!!!
--
-- Changing the constant itself may cause errors in some cases.
-- Or outright kill the addon alltogether.

-- #TODO:   Make these version specific, allowing full
--          backwards-compatability. Though doing so manually
--          is very error prone. Not sure how to do this auto-
--          matically. Yet.
--
--          Consider doing something like a property list.
--          When changing a property using the slash-cmds or
--          perhaps an in-game editor, we can change the version
--          and keep a record per version.

local DB_VERSION = 'db_version'

local default_db = {
    [DB_VERSION] = 1
}

----------------------------------------------------------------
-- PRIVATE VARIABLES -------------------------------------------
----------------------------------------------------------------

local event_handlers
local slash_commands

local unit_name
local realm_name
local profile_id

local local_db

local deathMessage
local deathMessageBackground

----------------------------------------------------------------
-- PRIVATE FUNCTIONS -------------------------------------------
----------------------------------------------------------------

local function report(p_label, p_message)
    local str
    local label
    local mesage

    label = tostring(p_label)
    message = tostring(p_message)

    -- TODO: Turn this into a string.gsub thing
    str = "|cff22ff22"..ADDON_NAME.."|r - |cff999999"..label..":|r "..message

    print(str)
end

local function toColourisedString(value)
    local val

    if isString(value) then
        val = "|cffffffff" .. value .. "|r"
    elseif isNumber(value) then
        val = "|cffffff33" .. tostring(value) .. "|r"
    elseif isBoolean(value) then
        val = "|cff9999ff" .. tostring(value) .. "|r"
    end

    return val
end

-- Addon specific functions

-- This is an example of a toggle switch from slashcommands. Change/Remove it
local function toggleClockHandler()
    -- check current db value
    -- turn on or off clock
    -- report to user
end

local function createMessage()
    -- Create the message frame here (look at createBackground)
    -- You want to be able to add a texture with the media file in this one though
    -- That's the tricky bit.
    local deathMessage = CreateFrame("Frame")

    return deathMessage
end

local function createBackground()
    local frame
    local bg
    local top
    local btm
    local bgHeight
    local height

    frame = CreateFrame("Frame")
    frame:Hide()

    bg = frame:CreateTexture()
    bg:SetTexture(0, 0, 0)

    top = frame:CreateTexture()
    top:SetTexture(0, 0, 0)
    -- orientation, startR, startG, startB, startA, endR, endG, endB, endA (start = bottom, end = top)
    top:SetGradientAlpha("VERTICAL", 0, 0, 0, 1, 0, 0, 0, 0)

    btm = frame:CreateTexture()
    btm:SetTexture(0, 0, 0)
    btm:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 1)

    height = BACKGROUND_HEIGHT_PERCENT * UIParent:GetHeight()

    frame:SetWidth(UIParent:GetWidth())
    frame:SetHeight(height)
    frame:SetFrameStrata(BG_STRATA)

    frame:SetPoint("CENTER", 0, 0)

    bgHeight = BACKGROUND_GRADIENT_PERCENT * height

    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -bgHeight)

    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -bgHeight)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, bgHeight)

    btm:ClearAllPoints()
    btm:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    btm:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, bgHeight)

    return frame
end

local function createDeathMessage()
    local message
    local background

    local function calculateMessageAlpha(p_progress)
        local result

        result = 1

        return result
    end

    local function calculateMessageScale(p_progress)
        local result

        result = 1

        return result
    end

    local function calculateBackgroundAlpha(p_progress)
        local result

        -- first 40% we go from 0 to 80
        -- then we stay there till 70%
        -- from 70% to 100% we go from 80 to 0

        if p_progress < 0.4 then
            result = 0.8 * (p_progress / 0.4)
        elseif p_progress > 0.8 then
            result = 0.8 * (1 - (p_progress / 0.2))
        end

        return result
    end

    local function calculateBackgroundScale(p_progress)
        local result

        result = 1

        return result
    end

    local function setMessageProgress(p_progress)
        local progress
        local msg_alpha
        local msg_scale
        local bg_alpha
        local bg_scale

        if not isNumber(p_progress) then
            error('progress should be a number')
        end

        if p_progress < 0 then
            progress = 0
        elseif p_progress > 1 then
            progress = 1
        else
            progress = p_progress
        end

        -- Build your big animation logic here
        msg_alpha = calculateMessageAlpha(progress)
        msg_scale = calculateMessageScale(progress)
        bg_alpha = calculateBackgroundAlpha(progress)
        bg_scale = calculateBackgroundScale(progres)

        message:SetAlpha(msg_alpha)
        message:SetScale(msg_scale)
        background:SetAlpha(bg_alpha)
        background:SetScale(bg_scale)
    end

    message = createMessage()
    -- Expose this function
    message.SetProgress = setMessageProgress

    background = createBackground()

    return message
end

local function OnUpdateHandler()
    local elapsed
    local current_progress

    elapsed = arg1 or 0
    -- Do calculations to determine what our current progress is based on
    -- animation speed (hint: use GetTime() or elapsed to figure this out.)
    -- You may wish to set a private constant or variable with the animation
    -- total time in seconds.
    current_progress = 0.5
    if current_progress <= 1 then
        deathMessage:SetProgress(current_progress)
    else
        deathMessage:SetScript(SCRIPTHANDLER_ON_UPDATE, nil)
    end
end

local function startDeathMessageAnimation()
    deathMessage:SetScript(SCRIPTHANDLER_ON_UPDATE, OnUpdateHandler)
end

-- Addon generic functions

local function loadProfileID()
    unit_name = UnitName("player")
    realm_name = GetRealmName()
    profile_id = unit_name .. "-" .. realm_name
end

local function loadSavedVariables()
    -- First time install
    local db_name
    local db

    -- IMPORTANT --
    -- This variable needs to match the one defined in the .toc file!!!
    db_name = ADDON_NAME..'DB'

    if not getglobal(db_name) then
        setglobal(db_name, {})
    end

    db = getglobal(db_name)
    local_db = db[profile_id] or {}

    if  (not local_db[DB_VERSION])
    or  (local_db[DB_VERSION] < default_db[DB_VERSION]) then
        local_db = merge(default_db, local_db)
    end
end

local function printSlashCommandList()
    local str
    local description
    local current_value

    report("Listing", "Slash commands")

    for name, cmd_object in pairs(slash_commands) do
        description = cmd_object.description
        if not description then
            error('Attempt to print slash command with name:"'..name ..'" without valid description')
        end

        str = SLASH_CMD_CONSTANT_1.." "..name.." "..description
        -- If the slash command sets a value we should have
        if cmd_object.value then
            str = str.." (|cff666666Currently:|r "..toColourisedString(local_db[cmd_object.value])..")"
        end
        print(str)
    end
end

local function slashCmdHandler(p_msg, chat_frame)
    local message
    local parameters
    local command_name
    local command

    message = string_lower(p_msg)

    parameters = {}
    for word in string_gfind(message, "%w+") do
        table_insert(parameters, word)
    end

    command_name = table_remove(parameters, 1)

    -- Pull the given command from our list.
    local command = slash_commands[command_name]
    if command then
        -- Run the command we found.
        if not isFunction(command.execute) then
            error("Attempt to execute slash command without execution function.")
        end

        command.execute(params)
    else
        -- print("Print our available command list.")
        printSlashCommandList()
    end
end

local function addSlashCommand(p_name, p_command, p_command_description, p_db_property)
    if  (not p_name)
    or  (p_name == "")
    or  (not p_command)
    or  (not isFunction(p_command))
    or  (not p_command_description)
    or  (p_command_description == "") then
        error("Usage: addSlashCommand(p_name <string>, p_command <function>, p_command_description <string> [, p_db_property <string>])")
    end

    -- print("Creating a slash command object into the command list");
    slash_commands[p_name] = {
        ["execute"] = p_command,
        ["description"] = p_command_description
    }

    if p_db_property then
        if not isString(p_db_property) or p_db_property == "" then
            error("p_db_property must be a non-empty string.")
        end

        if local_db[p_db_property] == nil then
            local format_string = 'The internal database property: "%s" could not be found.'
            local error_msg = string_format(format_string, p_db_property)
            error(error_msg)
        end
        -- print("Add the database property to the command list")
        slash_commands[p_name]["value"] = p_db_property
    end
end

local function populateSlashCommandList()
    -- This is an example. Remove / change this.
    addSlashCommand(
        "clock",
        toggleClockHandler,
        '<|cff9999fftoggle|r> |cff999999-- Toggle whether to show a clock or not.|r',
        IS_CLOCK_ENABLED
    )
end

local function eventCoordinator()
    -- given:
    -- event <string> The event name that triggered.
    -- arg1, arg2, ..., arg9 <*> Given arguments specific to the event.

    local eventHandler = event_handlers[event]
    if eventHandler then
        eventHandler(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end
end

local function storeLocalDatabaseToSavedVariables()
    -- #OPTION: We could have local variables for lots of DB
    --          stuff that we can load into the local_db Object
    --          before we store it.
    --
    --          Should probably make a list of variables to keep
    --          track of which changed and should be updated.
    --          Something we can just loop through so load and
    --          unload never desync.

    -- Commit to local storage
    local db

    db = getglobal(ADDON_NAME..'DB')
    db[profile_id] = local_db
end

local function finishInitialisation()
    -- use this bit to fix stuff like UnitHealthMax('player') that are not
    -- always available after addon_loaded event fires.
end

-- Event stuff

local function addEvent(p_event_name, p_eventHandler)
    if  (not p_event_name)
    or  (p_event_name == "")
    or  (not p_eventHandler)
    or  (not isFunction(p_eventHandler)) then
        error("Usage: addEvent(p_event_name <string>, p_eventHandler <function>)")
    end

    if event_handlers[p_event_name] then
        local format_string = 'Event "%s" already has a handler'
        local error_msg = string_format(format_string, p_event_name)
        error(error_msg)
    end

    event_handlers[p_event_name] = p_eventHandler

    this:RegisterEvent(p_event_name)
end

local function removeEvent(p_event_name)
    local eventHandler

    eventHandler = event_handlers[p_event_name]
    if eventHandler then
        -- GC should pick this up when a new assignment happens
        event_handlers[p_event_name] = nil
    end

    this:UnregisterEvent(p_event_name)
end

local function removeEvents()
    for event_name, eventHandler in pairs(event_handlers) do
        if eventHandler then
            removeEvent(event_name)
        end
    end
end

local function playerLogoutHandler()
    storeLocalDatabaseToSavedVariables()
end

local function playerLoginHandler()
    -- we only need this once
    this:UnregisterEvent(PLAYER_LOGIN_EVENT)

    finishInitialisation()
end

local function playerDeadHandler()
    -- do checks to see if player is actually supposed to receive this message

    -- play
    PlaySoundFile(YOU_DIED_SOUND, "Master")
    startDeathMessageAnimation()
end

-- boot up stuff

local function populateRequiredEvents()
    addEvent(PLAYER_LOGOUT_EVENT, playerLogoutHandler)
    addEvent(PLAYER_LOGIN_EVENT, finishInitialisation)
    addEvent(PLAYER_DEAD_EVENT, playerDeadHandler)
end

local function createChildren()
    deathMessage = createDeathMessage()
end

local function initialise()
    this:UnregisterEvent(ADDON_LOADED_EVENT)
    this:SetScript(SCRIPTHANDLER_ON_EVENT, eventCoordinator)

    event_handlers = {}
    slash_commands = {}

    loadProfileID()
    loadSavedVariables()
    populateSlashCommandList()
    populateRequiredEvents()
    createChildren()
end

do
    local slash_command
    local uc_addon_name

    uc_addon_name = string_upper(ADDON_NAME)

    slash_command = 'SLASH_'..uc_addon_name..'1'
    setglobal(slash_command, SLASH_CMD_CONSTANT_1)

    SlashCmdList[uc_addon_name] = slashCmdHandler

    this:SetScript(SCRIPTHANDLER_ON_EVENT, initialise)
    this:RegisterEvent(ADDON_LOADED_EVENT)
end
