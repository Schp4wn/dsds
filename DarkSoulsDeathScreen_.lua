
local print, strsplit, select, tonumber, tostring, wipe, remove
    = print, strsplit, select, tonumber, tostring, wipe, table.remove
local CreateFrame, GetSpellInfo, PlaySoundFile, UIParent, UnitBuff, C_Timer
    = CreateFrame, GetSpellInfo, PlaySoundFile, UIParent, UnitBuff, C_Timer
    
--local me = ...


local NUM_VERSIONS = 2
local MEDIA_PATH = [[Interface\Addons\DarkSoulsDeathScreen\media\]]
local YOU_DIED = MEDIA_PATH .. [[YOUDIED.tga]]
local THANKS_OBAMA = MEDIA_PATH .. [[THANKSOBAMA.tga]]
local YOU_DIED_SOUND = MEDIA_PATH .. [[YOUDIED.ogg]]
-- local BONFIRE_LIT = MEDIA_PATH .. [[BONFIRELIT.tga]]
-- local BONFIRE_LIT_BLUR = MEDIA_PATH .. [[BONFIRELIT_BLUR.tga]]
-- local BONFIRE_LIT_SOUND = {
--     [1] = MEDIA_PATH .. [[BONFIRELIT.ogg]],
--     [2] = MEDIA_PATH .. [[BONFIRELIT2.ogg]],
-- }
local YOU_DIED_WIDTH_HEIGHT_RATIO = 0.32 -- width / height
-- local BONFIRE_WIDTH_HEIGHT_RATIO = 0.36 -- w / h

local BG_STRATA = "HIGH"
local TEXT_STRATA = "DIALOG"

local BG_END_ALPHA = {
    [1] = 0.75, -- [0,1] alpha
    [2] = 0.9, -- [0,1] alpha
}
local TEXT_END_ALPHA = 0.5 -- [0,1] alpha
--local BONFIRE_TEXT_END_ALPHA = 0.8 -- [0,1] alpha
-- local BONFIRE_TEXT_END_ALPHA = {
--     [1] = 0.7, -- [0,1] alpha
--     [2] = 0.9, -- [0,1] alpha
-- }
-- local BONFIRE_BLUR_TEXT_END_ALPHA = {
--     [1] = 0.63, -- [0,1] alpha
--     [2] = 0.75, -- [0,1] alpha
-- }
local TEXT_SHOW_END_SCALE = 1.25 -- scale factor
-- local BONFIRE_START_SCALE = 1.15 -- scale factor
-- local BONFIRE_END_SCALE_X = 2.5 -- scale factor
-- local BONFIRE_END_SCALE_Y = 2.5 -- scale factor
-- local BONFIRE_BLUR_END_SCALE_X = 1.5 -- scale factor
-- local BONFIRE_BLUR_END_SCALE_Y = 1.5 -- scale factor
-- local BONFIRE_FLARE_SCALE_X = {
--     [1] = 1.1, -- scale factor
--     [2] = 1.035, -- scale factor
-- }
-- local BONFIRE_FLARE_SCALE_Y = {
--     [1] = 1.065, -- scale factor
--     [2] = 1,
-- }
-- local BONFIRE_FLARE_OUT_TIME = {
--     [1] = 0.22, -- seconds
--     [2] = 1.4, -- seconds
-- }
-- local BONFIRE_FLARE_OUT_END_DELAY = {
--     [1] = 0.1, -- seconds
--     [2] = 0,
-- }
-- local BONFIRE_FLARE_IN_TIME = 0.6 -- seconds
local TEXT_FADE_IN_DURATION = {
    [1] = 0.15, -- seconds
    [2] = 0.3, -- seconds
}
local FADE_IN_TIME = {
    [1] = 0.45, -- in seconds
    [2] = 0.13, -- seconds
}
local FADE_OUT_TIME = {
    [1] = 0.3, -- in seconds
    [2] = 0.16, -- seconds
}
local FADE_OUT_DELAY = 0.4 -- in seconds
-- local BONFIRE_FADE_OUT_DELAY = {
--     [1] = 0.55, -- seconds
--     [2] = 0, -- seconds
-- }
local TEXT_END_DELAY = 2.5 -- in seconds
-- local BONFIRE_END_DELAY = 0.05 -- in seconds
local BACKGROUND_GRADIENT_PERCENT = 0.15 -- of background height
local BACKGROUND_HEIGHT_PERCENT = 0.21 -- of screen height
local TEXT_HEIGHT_PERCENT = 0.18 -- of screen height

local ScreenWidth, ScreenHeight = UIParent:GetWidth(), UIParent:GetHeight()
local db

local ADDON_COLOR = "ffFF6600"
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(format("|c%sDSDS|r: %s",ADDON_COLOR, msg))
end

local function UnrecognizedVersion()
    local msg = "[|cffFF0000Error|r] Unrecognized version flag, \"%s\"!"
    Print(msg:format(tostring(db.version)))
    
    -- just correct the issue
    db.version = 1
end

-- ------------------------------------------------------------------
-- Init
-- ------------------------------------------------------------------
local type = type
local function OnEvent()
    if type(this[event]) == "function" then
        this[event]()
    end
end

local DSFrame = CreateFrame("Frame") -- helper frame
DSFrame:SetScript("OnEvent", OnEvent)

-- ----------
-- BACKGROUND
-- ----------

local UPDATE_TIME = 0.04
local function BGFadeIn()
    this.elapsed = (this.elapsed or 0) + arg1
    local progress = this.elapsed / FADE_IN_TIME[this.version]
    if progress <= 1 then
        this:SetAlpha(progress * BG_END_ALPHA[this.version])
    else
        this:SetScript("OnUpdate", nil)
        this.elapsed = nil
        -- force the background to hit its final alpha in case 'e' is too small
        this:SetAlpha(BG_END_ALPHA[this.version])
    end
end

local function BGFadeOut()
    this.elapsed = (this.elapsed or 0) + arg1
    local progress = 1 - (this.elapsed / FADE_OUT_TIME[this.version])
    if progress >= 0 then
        this:SetAlpha(progress * BG_END_ALPHA[this.version])
    else
        this:SetScript("OnUpdate", nil)
        this.elapsed = nil
        -- force the background to hide at the end of the animation
        this:SetAlpha(0)
    end
end

local background = {} -- bg frames

local function GetBackground(version)
    if not version then return nil end
    
    local frame = background[version]
    if not frame then
        frame = CreateFrame("Frame")
        frame.version = version
        background[version] = frame
        
        local bg = frame:CreateTexture()
        bg:SetTexture(0, 0, 0)
        
        local top = frame:CreateTexture()
        top:SetTexture(0, 0, 0)
        top:SetGradientAlpha("VERTICAL", 0, 0, 0, 1, 0, 0, 0, 0) -- orientation, startR, startG, startB, startA, endR, endG, endB, endA (start = bottom, end = top)
        
        local btm = frame:CreateTexture()
        btm:SetTexture(0, 0, 0)
        btm:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 1)
        
        -- size the frame
        local height = BACKGROUND_HEIGHT_PERCENT * ScreenHeight
        local bgHeight = BACKGROUND_GRADIENT_PERCENT * height
        frame:SetWidth(ScreenWidth)
        frame:SetHeight(height)
        frame:SetFrameStrata(BG_STRATA)
        
        --[[
        1: bg positioned in center of screen
        2: bg positioned 60% from top of screen
        --]]
        if version == 1 then
            frame:SetPoint("CENTER", 0, 0)
        elseif version == 2 then
            local y = 0.6 * ScreenHeight - bgHeight
            frame:SetPoint("TOP", 0, -y)
        end
        
        -- size the background's constituent components
        top:ClearAllPoints()
        top:SetPoint("TOPLEFT", 0, 0)
        top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -bgHeight)
        
        bg:ClearAllPoints()
        bg:SetPoint("TOPLEFT", 0, -bgHeight)
        bg:SetPoint("BOTTOMRIGHT", 0, bgHeight)
        
        btm:ClearAllPoints()
        btm:SetPoint("BOTTOMLEFT", 0, 0)
        btm:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, bgHeight)
    end
    return frame
end

local function SpawnBackground(version)
    local frame = GetBackground(version)
    if frame then
        frame:SetAlpha(0)
        -- ideally this would use Animations, but they seem to set the alpha on all elements in the region which destroys the alpha gradient
        -- ie, the background becomes just a solid-color rectangle
        frame:SetScript("OnUpdate", BGFadeIn)
    else
        UnrecognizedVersion()
    end
end

local function HideBackgroundAfterDelay(self)
    if not self.hide then
        return
    end
    self.elapsed = (self.elapsed or 0) + arg1
    if self.elapsed > (self.delay or 0) then
        local bg = background[db.version or 0]
        if bg then
            bg:SetScript("OnUpdate", BGFadeOut)
        else
            UnrecognizedVersion()
        end
        self.hide = nil
        self.elapsed = nil
    end
end

-- --------
-- YOU DIED
-- --------

local youDied = {} -- frames

-- "YOU DIED" text reveal from Dark Souls 2
local function YouDiedReveal()
    this.elapsed = (this.elapsed or 0) + arg1
    local progress = this.elapsed / 0.5
    if progress <= 1 then
        -- set the texture size so it does not become distorted
        this:SetWidth(this.width * progress)
        this:SetHeight(this.height * progress)
        --self:SetSize(self.width, (1/self.height)^progress + self.height)
        -- expand texcoords until the entire texture is shown
        local y = 0.5 * progress
        this.tex:SetTexCoord(0, 1, 0.5 - y, 0.5 + y)
    else
        -- ensure the entire texture is visible
        this:SetWidth(this.width)
        this:SetHeight(this.height)
        this.tex:SetTexCoord(0, 1, 0, 1)
    end
end

local function playAnim(this)
    for _, animGroup in this.animGroups do
        for _, anim in animGroup.anims do
            anim.finished = nil
        end
        animGroup.finished = nil
    end
    this.animTime = 0
    this.elapsed = nil
end

local function animate()
    this.animTime = this.animTime + arg1
    local time = this.animTime
    if time then
        local nextStart = 0
        for _, animGroup in this.animGroups do
            local start = nextStart
            for _, anim in animGroup.anims do
                local progress = time - anim.delay - start
                nextStart = max(nextStart, start + anim.delay + anim.duration + anim.endDelay)
                if not anim.finished then
                    if progress > anim.duration then
                        anim:fun(anim.duration)
                        anim.finished = true
                    elseif progress > 0 then
                        anim:fun(progress)
                    end
                end
            end
            if time > nextStart and animGroup.onFinished and not animGroup.finished then
                animGroup.onFinished()
                animGroup.finished = true
            end
        end
        if time > nextStart then
            time = nil
        end
    end
end

local function scaleAnim(self, time)
    local old = max(time - arg1, 0)
    this:SetScale(this:GetScale() / ((self.scale-1)/self.duration*old +1) * ((self.scale-1)/self.duration*time +1))
end
local function alphaAnim(self, time)
    local old = max(time - arg1, 0)
    this:SetAlpha(this:GetAlpha() + (time - old)/self.duration*self.alpha)
end

local function GetYouDiedFrame(version)
    if not version then return nil end
    
    local frame = youDied[version]
    if not frame then
        local parent = background[version]
        frame = CreateFrame("Frame")
        youDied[version] = frame
        frame:SetPoint("CENTER", parent, 0, 0)
        local FADE_IN_TIME = FADE_IN_TIME[version]
        local FADE_OUT_TIME = FADE_OUT_TIME[version]
        local TEXT_FADE_IN_DURATION = TEXT_FADE_IN_DURATION[version]
        
        frame.animGroups = {}
        -- intial animation (fade-in + zoom)
        local show = {anims = {}}
        local fadein = {}
        fadein.fun = alphaAnim
        fadein.alpha = TEXT_END_ALPHA
        fadein.delay = FADE_IN_TIME
        fadein.duration = FADE_IN_TIME + TEXT_FADE_IN_DURATION
        fadein.endDelay = TEXT_END_DELAY
        tinsert(show.anims,fadein)
        local zoom = {
            delay = 0,
            fun = scaleAnim,
            scale = TEXT_SHOW_END_SCALE,
            duration = 1.3,
            endDelay = TEXT_END_DELAY
        }
        tinsert(show.anims,zoom)
        tinsert(frame.animGroups,show)
                
        -- hide animation (fade-out + slower zoom)
        local hide = {anims = {}}
        local fadeout = { endDelay = 0 }
        fadeout.fun = alphaAnim
        fadeout.alpha = -1
        --fadeout:SetSmoothing("IN_OUT")
        fadeout.delay = FADE_OUT_DELAY
        fadeout.duration = FADE_OUT_TIME + FADE_OUT_DELAY
        fadeout.HideBackgroundAfterDelay = HideBackgroundAfterDelay
        tinsert(hide.anims, fadeout)
        tinsert(frame.animGroups,hide)
        
        frame:SetFrameStrata(TEXT_STRATA)
        
        frame.tex = frame:CreateTexture()
        frame.tex:SetAllPoints()
        
        if version == 1 then
            -- local y = (0.6 * ScreenHeight) + height
            -- frame:SetPoint("TOP", 0, -y)
        
            local zoom = { delay = 0, endDelay = 0 }
            zoom.fun = scaleAnim
            zoom.scale = 1.05
            zoom.duration = FADE_OUT_TIME + FADE_OUT_DELAY + 0.3
            tinsert(hide.anims, zoom)
        elseif version == 2 then
        end
        
        show.onFinished = function()
            -- hide once the delay finishes
            frame:SetAlpha(TEXT_END_ALPHA)
            frame:SetScale(TEXT_SHOW_END_SCALE)
        end
        hide.onFinished = function()
            -- reset to initial state
            frame:SetAlpha(0)
            frame:SetScale(1)
            fadeout.hide = true
        end
        
        frame:SetScript("OnUpdate", function()
            animate()
            if this.animTime > fadein.delay then
                YouDiedReveal()
            end
            fadeout:HideBackgroundAfterDelay()
        end)
    end
    return frame
end

local function YouDied(version)
    local frame = GetYouDiedFrame(version)
    if frame then
        if frame.tex:GetTexture() ~= db.tex then
            frame.tex:SetTexture(db.tex)
        end
        --frame.tex:SetTexture("greenboxerino")
        frame:SetAlpha(0)
        frame:SetScale(1)
        
        local height = TEXT_HEIGHT_PERCENT * ScreenHeight
        frame:SetWidth(height / YOU_DIED_WIDTH_HEIGHT_RATIO)
        frame:SetHeight(height)
        frame.width, frame.height = frame:GetWidth(), frame:GetHeight()
        
        playAnim(frame)
    else
        UnrecognizedVersion()
    end
end

-- -----------
-- BONFIRE LIT
-- -----------

-- local bonfireIsLighting -- anim is running flag
-- local bonfireLit = {} -- frames

-- local function GetBonfireLitFrame(version)
--     if not version then return nil end
--     
--     local frame = bonfireLit[version]
--     if not frame then
--         local parent = background[version]
--         frame = CreateFrame("Frame")
--         frame.version = version
--         bonfireLit[version] = frame
--         frame:SetPoint("CENTER", parent, 0, 0)
--         
--         local FADE_IN_TIME = FADE_IN_TIME[version]
--         local FADE_OUT_TIME = FADE_OUT_TIME[version]
--         local TEXT_FADE_IN_DURATION = TEXT_FADE_IN_DURATION[version]
--         local BONFIRE_TEXT_END_ALPHA = BONFIRE_TEXT_END_ALPHA[version]
--         local BONFIRE_BLUR_TEXT_END_ALPHA = BONFIRE_BLUR_TEXT_END_ALPHA[version]
--         local BONFIRE_FLARE_SCALE_X = BONFIRE_FLARE_SCALE_X[version]
--         local BONFIRE_FLARE_SCALE_Y = BONFIRE_FLARE_SCALE_Y[version]
--         local BONFIRE_FLARE_OUT_TIME = BONFIRE_FLARE_OUT_TIME[version]
--         local BONFIRE_FLARE_OUT_END_DELAY = BONFIRE_FLARE_OUT_END_DELAY[version]
--         local BONFIRE_FADE_OUT_DELAY = BONFIRE_FADE_OUT_DELAY[version]
--         
--         --[[
--         'static' BONFIRE LIT
--         --]]
--         frame.tex = frame:CreateTexture()
--         frame.tex:SetAllPoints()
--         frame.tex:SetTexture(BONFIRE_LIT)
--         
--         -- intial animation (fade-in)
--         local show = frame:CreateAnimationGroup()
--         local fadein = show:CreateAnimation("Alpha")
--         fadein:SetChange(BONFIRE_TEXT_END_ALPHA)
--         fadein:SetOrder(1)
--         fadein:SetDuration(FADE_IN_TIME + TEXT_FADE_IN_DURATION)
--         fadein:SetEndDelay(TEXT_END_DELAY)
--         
--         -- hide animation (fade-out)
--         local hide = frame:CreateAnimationGroup()
--         local fadeout = hide:CreateAnimation("Alpha")
--         fadeout:SetChange(-1)
--         fadeout:SetOrder(1)
--         fadeout:SetSmoothing("IN_OUT")
--         fadeout:SetStartDelay(BONFIRE_FADE_OUT_DELAY)
--         fadeout:SetDuration(FADE_OUT_TIME)
--         --fadeout:SetDuration(FADE_OUT_TIME + FADE_OUT_DELAY)
--         
--         frame:SetFrameStrata(TEXT_STRATA)
--         
--         if version == 1 then
--             fadein:SetScript("OnUpdate", function()
--                 this.elapsed = (this.elapsed or 0) + arg1
--                 local progress = this.elapsed / BONFIRE_FLARE_OUT_TIME
--                 if progress <= 1 then
--                     --frame.tex:SetVertexColor(progress, progress, progress, 1)
--                 else
--                     this:SetScript("OnUpdate", nil)
--                     this.elapsed = nil
--                     frame.tex:SetVertexColor(1, 1, 1, 1)
--                 end
--             end)
--         elseif version == 2 then
--             local zoom = hide:CreateAnimation("Scale")
--             zoom:SetScale(BONFIRE_END_SCALE_X, BONFIRE_END_SCALE_Y)
--             zoom:SetOrder(1)
--             zoom:SetSmoothing("IN")
--             zoom:SetStartDelay(BONFIRE_FADE_OUT_DELAY)
--             zoom:SetDuration(FADE_OUT_TIME)
--             --zoom:SetDuration(fadeout:GetDuration())
--         end
--         
--         show:SetScript("OnFinished", function()
--             frame:SetAlpha(BONFIRE_TEXT_END_ALPHA)
--         end)
--         hide:SetScript("OnFinished", function()
--             -- reset to initial state
--             frame:SetAlpha(0)
--             frame:SetScale(BONFIRE_START_SCALE)
--         end)
--         frame.show = show
--         frame.hide = hide
--         
--         --[[
--         'blurred' BONFIRE LIT
--         --]]
--         frame.blurred = CreateFrame("Frame")
--         frame.blurred:SetPoint("CENTER", parent, 0, 0)
--         frame.blurred:SetFrameStrata(TEXT_STRATA)
--     
--         -- blurred "BONFIRE LIT"
--         frame.blurred.tex = frame.blurred:CreateTexture()
--         frame.blurred.tex:SetAllPoints()
--         frame.blurred.tex:SetTexture(BONFIRE_LIT_BLUR)
--         
--         -- intial animation
--         local show = frame.blurred:CreateAnimationGroup()
--         local fadein = show:CreateAnimation("Alpha")
--         fadein:SetChange(BONFIRE_BLUR_TEXT_END_ALPHA)
--         fadein:SetOrder(1)
--         fadein:SetSmoothing("IN")
--         -- delay the flare animation until the base texture is almost fully visible
--         if frame.version == 1 then
--             fadein:SetStartDelay(FADE_IN_TIME * 0.75)
--         elseif frame.version == 2 then
--             fadein:SetStartDelay(FADE_IN_TIME + TEXT_FADE_IN_DURATION * 0.9)
--         end
--         fadein:SetDuration(FADE_IN_TIME + TEXT_FADE_IN_DURATION + 0.25)
--         local flareOut = show:CreateAnimation("Scale")
--         flareOut:SetOrigin("CENTER", 0, 0)
--         flareOut:SetScale(BONFIRE_FLARE_SCALE_X, BONFIRE_FLARE_SCALE_Y) -- flare out
--         flareOut:SetOrder(1)
--         flareOut:SetSmoothing("OUT")
--         flareOut:SetStartDelay(FADE_IN_TIME + TEXT_FADE_IN_DURATION) -- TODO: v2 needs to wait
--         flareOut:SetEndDelay(BONFIRE_FLARE_OUT_END_DELAY)
--         flareOut:SetDuration(BONFIRE_FLARE_OUT_TIME)
--         
--         -- hide animation (fade-out)
--         local hide = frame.blurred:CreateAnimationGroup()
--         local fadeout = hide:CreateAnimation("Alpha")
--         fadeout:SetChange(-1)
--         fadeout:SetOrder(1)
--         fadeout:SetSmoothing("IN_OUT")
--         fadeout:SetStartDelay(BONFIRE_FADE_OUT_DELAY)
--         fadeout:SetDuration(FADE_OUT_TIME)
--         --fadeout:SetDuration(FADE_OUT_TIME + FADE_OUT_DELAY)
--         
--         -- set the end scale of the animation to prevent the frame
--         -- from snapping to its original scale
--         local function SetEndScale()
--             local xScale, yScale = this:GetScale()
--             local height = TEXT_HEIGHT_PERCENT * ScreenHeight
--             local width = height / BONFIRE_WIDTH_HEIGHT_RATIO
--             if frame.version == 1 then
--                 -- account for the flare-out scaling
--                 xScale = xScale * BONFIRE_FLARE_SCALE_X
--                 yScale = yScale * BONFIRE_FLARE_SCALE_Y
--             end
--             
--             frame.blurred:SetSize(width * xScale, height * yScale)
--         end
--         
--         if version == 1 then
--             local flareIn = show:CreateAnimation("Scale")
--             flareIn:SetOrigin("CENTER", 0, 0)
--             -- scale back down (just a little larger than the starting amount)
--             local xScale = (1 / BONFIRE_FLARE_SCALE_X) + 0.021
--             flareIn:SetScale(xScale, 1 / BONFIRE_FLARE_SCALE_Y)
--             flareIn:SetOrder(2)
--             flareIn:SetSmoothing("OUT")
--             flareIn:SetDuration(BONFIRE_FLARE_IN_TIME)
--             flareIn:SetEndDelay(BONFIRE_END_DELAY)
--             
--             flareIn:SetScript("OnFinished", SetEndScale)
--         elseif version == 2 then
--             --frame.blurred:SetPoint("CENTER", 0, -0.1 * ScreenHeight)
--             
--             local zoom = hide:CreateAnimation("Scale")
--             zoom:SetOrigin("CENTER", 0, 0)
--             zoom:SetScale(BONFIRE_BLUR_END_SCALE_X, BONFIRE_BLUR_END_SCALE_Y)
--             zoom:SetOrder(1)
--             zoom:SetSmoothing("IN")
--             zoom:SetStartDelay(BONFIRE_FADE_OUT_DELAY)
--             zoom:SetDuration(FADE_OUT_TIME)
--             --zoom:SetDuration(fadeout:GetDuration())
--             
--             flareOut:SetScript("OnFinished", SetEndScale)
--         end
--         
--         show:SetScript("OnFinished", function()
--             -- hide once the delay finishes
--             frame.blurred:SetAlpha(BONFIRE_BLUR_TEXT_END_ALPHA)
--             
--             fadeout:SetScript("OnUpdate", HideBackgroundAfterDelay)
--             frame.hide:Play() -- static hide
--             hide:Play() -- blurred hide
--         end)
--         hide:SetScript("OnFinished", function()
--             -- reset to initial state
--             frame.blurred:SetAlpha(0)
--             frame.blurred:SetScale(BONFIRE_START_SCALE)
--             
--             bonfireIsLighting = nil
--         end)
--         frame.blurred.show = show
--     end
--     return frame
-- end

-- local function BonfireLit(version)
--     local frame = GetBonfireLitFrame(version)
--     frame:SetAlpha(0)
--     frame.blurred:SetAlpha(0)
--     frame:SetScale(BONFIRE_START_SCALE)
--     -- scale the blurred texture down a bit since it is larger than the static texture
--     frame.blurred:SetScale(BONFIRE_START_SCALE * 0.97)
--     
--     local height = TEXT_HEIGHT_PERCENT * ScreenHeight
--     frame:SetSize(height / BONFIRE_WIDTH_HEIGHT_RATIO, height)
--     frame.blurred:SetSize(height / BONFIRE_WIDTH_HEIGHT_RATIO, height)
--     
--     frame.show:Play()
--     frame.blurred.show:Play()
--     bonfireIsLighting = true
-- end

-- ------------------------------------------------------------------
-- Event handlers
-- ------------------------------------------------------------------
DSFrame:RegisterEvent("ADDON_LOADED")
function DSFrame.ADDON_LOADED()
    if arg1 == "DarkSoulsDeathScreen" then
        DarkSoulsDeathScreen = DarkSoulsDeathScreen or {
            --[[
            default db
            --]]
            enabled = true, -- addon enabled flag
            sound = true, -- sound enabled flag
            tex = YOU_DIED, -- death animation texture
            version = 1, -- animation version
        }
        db = DarkSoulsDeathScreen
        if not db.enabled then
            this:SetScript("OnEvent", nil)
        end
        this.ADDON_LOADED = nil
        
        -- add the version flag to old SVs
        db.version = db.version or 1
    end
end

--local SpiritOfRedemption = GetSpellInfo(20711)
--local FeignDeath = GetSpellInfo(5384)
DSFrame:RegisterEvent("PLAYER_DEAD")
function DSFrame.PLAYER_DEAD()
--    local SOR = UnitBuff("player", SpiritOfRedemption)
  --  local FD = UnitBuff("player", FeignDeath)
    -- event==nil means a fake event
   -- if not event or not (UnitBuff("player", SpiritOfRedemption) or UnitBuff("player", FeignDeath)) then
    
        -- TODO? cancel other anims (ie, bonfire lit)
        
        if db.sound then
            PlaySoundFile(YOU_DIED_SOUND, "Master")
        end
        
        SpawnBackground(db.version)
        YouDied(db.version)
--    end
end


-- ------------------------------------------------------------------
-- Slash cmd
-- ------------------------------------------------------------------
local slash = "/dsds"
SLASH_DARKSOULSDEATHSCREEN1 = slash

local function OnOffString(bool)
    return bool and "|cff00FF00enabled|r" or "|cffFF0000disabled|r"
end

-- local split = {}
-- local function pack(...)
--     wipe(split)

--     local numArgs = select('#', ...)
--     for i = 1, numArgs do
--         split[i] = select(i, ...)
--     end
--     return split
-- end

local commands = {}
commands["enable"] = function(args)
    db.enabled = true
    DSFrame:SetScript("OnEvent", OnEvent)
    Print(OnOffString(db.enabled))
end
commands["on"] = commands["enable"] -- enable alias
commands["disable"] = function(args)
    db.enabled = false
    DSFrame:SetScript("OnEvent", nil)
    Print(OnOffString(db.enabled))
end
commands["off"] = commands["disable"] -- disable alias
local function GetValidVersions()
    -- returns "1/2/3/.../k"
    local result = "1"
    for i = 2, NUM_VERSIONS do
    result = format("%s/%d",result, i)
    end
    return result
end
commands["version"] = function(args)
    local doPrint = true
    local ver = args[1]
    if ver then
        ver = tonumber(ver) or 0
        if 0 < ver and ver <= NUM_VERSIONS then
            db.version = ver
        else
            Print(("Usage: %s version [%s]"):format(slash, GetValidVersions()))
            doPrint = false
        end
    else
        -- cycle
        db.version = mod(db.version,NUM_VERSIONS) + 1
    end
    
    if doPrint then
        Print(format("Using Dark Souls %d animations",db.version))
    end
end
commands["ver"] = commands["version"]
commands["sound"] = function(args)
    local doPrint = true
    local enable = args[1]
    if enable then
        if enable == "on" or enable == "true" then
            db.sound = true
        elseif enable == "off" or enable == "false" or enable == "nil" then
            db.sound = false
        else
            Print(("Usage: %s sound [on/off]"):format(slash))
            doPrint = false
        end
    else
        -- toggle
        db.sound = not db.sound
    end
    
    if doPrint then
        Print(("Sound %s"):format(OnOffString(db.sound)))
    end
end
commands["tex"] = function(args)
    local tex = args[1]
    local currentTex = db.tex
    if tex then
        db.tex = tex
    else
        -- toggle
        if currentTex == YOU_DIED then
            db.tex = THANKS_OBAMA
            tex = "THANKS OBAMA"
        else
            -- this will also default to "YOU DIED" if a custom texture path was set
            db.tex = YOU_DIED
            tex = "YOU DIED"
        end
    end
    Print(("Texture set to '%s'"):format(tex))
end
commands["test"] = function(args)
--     local anim = args[1]
--     if anim == "b" or anim == "bonfire" then
--         DSFrame:UNIT_SPELLCAST_SUCCEEDED()
--     else
        DSFrame:PLAYER_DEAD()
--     end
end

local indent = "  "
local usage = {
    format("Usage: %s", slash),
    ("%s%s on/off: Enables/disables the death screen."),
    ("%s%s version ["..GetValidVersions().."]: Cycles through animation versions (eg, Dark Souls 1/Dark Souls 2)."),
    ("%s%s sound [on/off]: Enables/disables the death screen sound. Toggles if passed no argument."),
    ("%s%s tex [path\\to\\custom\\texture]: Toggles between the 'YOU DIED' and 'THANKS OBAMA' textures. If an argument is supplied, the custom texture will be used instead."),
    ("%s%s test [bonfire]: Runs the death animation or the bonfire animation if 'bonfire' is passed as an argument."),
    ("%s%s help: Shows this message."),
}
do -- format the usage lines
    for i = 2, getn(usage) do
        usage[i] = format(usage[i],indent, slash)
    end
end
commands["help"] = function(args)
    for i = 1, getn(usage) do
        Print(usage[i])
    end
end
commands["h"] = commands["help"] -- help alias

local delim = " "
function SlashCmdList.DARKSOULSDEATHSCREEN(msg)
    msg = msg and strlower(msg)
    local rest = msg
    local args = {}
    for s in string.gfind(msg,"%S+") do
        tinsert(args, s)
    end
    local cmd = remove(args, 1)
    
    local exec = cmd and type(commands[cmd]) == "function" and commands[cmd] or commands["h"]
    exec(args)
end
