-- Addon/Core/ScrollbarReskin.lua — SHARED scrollbar reskin for any UIPanel
-- ScrollFrame in the addon. Visual port of retail's MinimalScrollBar
-- (retail Blizzard_SharedXML/Shared/Scroll/MinimalScrollBar.xml).
--
-- USAGE
--   EJ.scrollbar.Reskin(scrollFrame, {
--     x                  = 7,     -- horizontal offset from scroll.RIGHT (default 7)
--     strataHigh         = true,  -- raise scrollbar to HIGH strata (default true)
--     hideIfUnscrollable = false, -- hide bar when content fits viewport (default false)
--     classic            = nil,   -- keep the native UIPanelScrollBar art (default: the
--                                 -- active UI skin is "classic", Core/Options.lua)
--   })
--
-- The helper:
--   * Enables mouse wheel on the ScrollFrame (UIPanelScrollFrameTemplate's
--     XML doesn't set enableMouseWheel — without this, wheel events never
--     fire ScrollFrameTemplate_OnMouseWheel).
--   * Repositions + sizes the auto-created scrollbar (8 wide visual, with
--     hit-rect insets for click tolerance).
--   * Replaces all scrollbar art with retail's minimal-scrollbar atlases.
--   * Implements the 3-piece track and 3-piece thumb structure.
--   * Adds hover/press state swaps on the thumb (over/down variants).
--   * Optionally auto-hides the bar when content fits (hideIfUnscrollable),
--     matching retail's MinimalScrollBar.xml:312 hideIfUnscrollable=true.
--
-- ARROW POSITIONING — DESIGN NOTE
--   Retail's MinimalScrollBar uses ScrollBoxBaseMixin where the thumb is a
--   Button child of a TRACK Frame (which is inset 19 px from the slider's
--   top/bottom). The thumb's drag range is bounded by the track frame, so
--   it can't visually overlap the arrows (which sit in the inset zone).
--
--   UIPanelScrollBar uses the Slider widget. The Slider's thumb is auto-
--   positioned within the slider's FULL extent (slider.TOP → slider.BOTTOM)
--   — there's no track-inset concept. If we anchor the arrows INSIDE the
--   slider (matching retail's visual structure), the thumb extends past
--   the arrows visually.
--
--   So we keep UIPanelScrollBar's default arrow anchoring (UpButton.BOTTOM
--   at slider.TOP, DownButton.TOP at slider.BOTTOM — arrows OUTSIDE slider
--   bounds). The slider's Y inset from the scroll frame is enlarged so the
--   arrows fit within the scroll's vertical bounds. This is a divergence
--   from retail's structure but produces identical visual output.

EJ = EJ or {}
EJ.scrollbar = EJ.scrollbar or {}

-- AttachMinimal — shared builder for the MODERN WowScrollBox + MinimalScrollBar combo.
--
-- Era ships retail's MinimalScrollBar template and it renders out of the box — unlike the legacy
-- Slider bars (Reskin, below) it needs no art surgery. This just collapses the repeated create +
-- anchor + view + Init boilerplate (CharacterPanel Reputation/Sidebar, LootFrame, AH ItemList, …).
--
--   local bar = EJ.scrollbar.AttachMinimal(scrollBox, {
--     name               = "EJ_FooScrollBar",  -- optional global name
--     parent             = frame,              -- default scrollBox:GetParent()
--     x                  = 7,                  -- gap from scrollBox.RIGHT (default 0)
--     top                = 0, bottom = 0,      -- TOP/BOTTOM inset tweaks (default 0)
--     hideIfUnscrollable = true,               -- retail MinimalScrollBar.xml:312 (default false)
--     list               = false,             -- true → InitScrollBoxListWithScrollBar
--     view               = <view>,            -- caller's view; default a plain linear view
--   })
--
-- Returns the scrollbar. Bespoke extras (gutter sync, anchor-shrink-on-show, suppressing an
-- Era-built bar) stay at the call site — the helper only owns the universal create/anchor/init.
function EJ.scrollbar.AttachMinimal(scrollBox, opts)
  if not scrollBox then return end
  opts = opts or {}
  local parent = opts.parent or (scrollBox.GetParent and scrollBox:GetParent())
  local bar = CreateFrame("EventFrame", opts.name, parent, "MinimalScrollBar")
  local x = opts.x or 0
  bar:SetPoint("TOPLEFT",    scrollBox, "TOPRIGHT",    x,  opts.top    or 0)
  bar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", x,  opts.bottom or 0)
  if opts.hideIfUnscrollable ~= nil then bar.hideIfUnscrollable = opts.hideIfUnscrollable end
  if ScrollUtil then
    if opts.list then
      ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, bar, opts.view)
    else
      local view = opts.view or (CreateScrollBoxLinearView and CreateScrollBoxLinearView(0, 0, 0, 0, 0))
      ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, bar, view)
    end
  end
  return bar
end

local SLIDER_WIDTH = 8     -- retail MinimalScrollBar.xml:16
local THUMB_WIDTH  = 8     -- retail Thumb XML:51
local THUMB_HEIGHT = 60    -- "quite large" per user feedback
local ARROW_W      = 17    -- retail XML:112
local ARROW_H      = 11    -- retail XML:112
-- Vertical math. The thumb's caps sit OUTSIDE the thumb's drag range
-- (above thumb.TOP / below thumb.BOTTOM) — this is what gives the handle
-- its rounded corners. Anchoring caps INSIDE the thumb visually loses
-- the round corners (the middle texture is plain rectangular fill).
--
-- So with caps OUTSIDE, at value=min the cap.TOP extends CAP_H px above
-- slider.TOP. To make the cap visually stop short of the arrow, the
-- arrow must sit at least CAP_H + visible-gap px ABOVE slider.TOP.
--
-- ARROW_GAP defines how far above slider.TOP the arrow.BOTTOM sits.
-- We want VISIBLE_GAP px between the cap.TOP and the arrow.BOTTOM, so:
--   ARROW_GAP = CAP_H + VISIBLE_GAP = 8 + 6 = 14
--
-- SLIDER_Y_INSET puts the slider's TOP at scroll.TOP - SLIDER_Y_INSET, so
-- arrow.TOP = slider.TOP + ARROW_GAP + ARROW_H lands at scroll.TOP exactly
-- when SLIDER_Y_INSET = ARROW_GAP + ARROW_H = 14 + 11 = 25.
-- Classic-skin metrics: the native 3.3.5 UIPanelScrollBar is 16 wide with 16-tall arrows sitting
-- outside the slider (UIPanelScrollFrameTemplate's own TOPRIGHT(6,-16)/BOTTOMRIGHT(6,16) anchors).
local CLASSIC_WIDTH   = 16
local CLASSIC_Y_INSET = 16

local CAP_H          = 8                       -- minimal-scrollbar-small-thumb-top atlas size
local VISIBLE_GAP    = 6                       -- visible buffer between thumb cap and arrow
local ARROW_GAP      = CAP_H + VISIBLE_GAP     -- 14
local SLIDER_Y_INSET = ARROW_H + ARROW_GAP     -- 25

-- Internal helpers.
local function setAtlas(tex, name, useAtlasSize)
  if tex and EJ.tex and EJ.tex.SetAtlas then
    EJ.tex.SetAtlas(tex, name, useAtlasSize)
  end
end

local function reskinArrowButton(button, normalAtlas, overAtlas, downAtlas, anchor)
  if not button then return end

  -- Re-anchor with ARROW_GAP offset from slider.TOP/BOTTOM. Arrows still
  -- live OUTSIDE the slider (so the thumb's drag range — which is the
  -- slider's full extent — can't overlap them), but with an 8 px buffer
  -- so the thumb visually stops short of the arrows. Matches retail's
  -- track inset 19 - arrow height 11 = 8 px gap (MinimalScrollBar.xml:26).
  button:ClearAllPoints()
  local sb = button:GetParent()
  if anchor == "TOP" then
    button:SetPoint("BOTTOM", sb, "TOP", 0, ARROW_GAP)
  else
    button:SetPoint("TOP",    sb, "BOTTOM", 0, -ARROW_GAP)
  end

  -- Modify the existing Normal/Pushed/Disabled/Highlight textures in
  -- place via SetAtlas (sets both texture AND the atlas's specific
  -- texcoord sub-rect). Don't replace via SetNormalTexture(newTex) —
  -- that loses the template's anchor setup.
  local n = button:GetNormalTexture()
  local p = button:GetPushedTexture()
  local d = button:GetDisabledTexture()
  local h = button:GetHighlightTexture()
  if n then setAtlas(n, normalAtlas, false) end
  if p then setAtlas(p, downAtlas,   false) end
  if d then setAtlas(d, normalAtlas, false); d:SetDesaturated(true) end
  if h then
    -- Highlight rendered ADD over the normal during hover — the "-over"
    -- atlas is a slightly brighter variant designed for this overlay.
    setAtlas(h, overAtlas, false)
    h:SetBlendMode("ADD")
  end
  button:SetSize(ARROW_W, ARROW_H)
end

local function buildTrack(sb)
  if sb._ejTrackBegin then return end  -- idempotent

  -- Track texture pieces on BACKGROUND layer of the slider. Anchored
  -- to slider's full extent (no inset — arrows live OUTSIDE the slider).
  local begin = sb:CreateTexture(nil, "BACKGROUND")
  setAtlas(begin, "minimal-scrollbar-track-top", true)
  begin:SetPoint("TOP", sb, "TOP", 0, 0)

  local endTex = sb:CreateTexture(nil, "BACKGROUND")
  setAtlas(endTex, "minimal-scrollbar-track-bottom", true)
  endTex:SetPoint("BOTTOM", sb, "BOTTOM", 0, 0)

  local middle = sb:CreateTexture(nil, "BACKGROUND")
  setAtlas(middle, "!minimal-scrollbar-track-middle", false)
  middle:SetPoint("TOPLEFT",     begin,  "BOTTOMLEFT")
  middle:SetPoint("BOTTOMRIGHT", endTex, "TOPRIGHT")

  sb._ejTrackBegin, sb._ejTrackEnd, sb._ejTrackMiddle = begin, endTex, middle
end

-- 3-piece thumb (top cap + middle + bottom cap). Hover/press state swap
-- via OnEnter/OnLeave/OnMouseDown/OnMouseUp on the slider — retail's
-- MinimalScrollBarThumbScriptsMixin handles state swap on the Thumb Button
-- itself, but Slider's ThumbTexture isn't a Button, so we attach handlers
-- to the slider instead (mouse over slider with thumb under cursor =
-- hover).
local function buildThumb(sb)
  if not sb.SetThumbTexture then return end
  local thumb = sb:GetThumbTexture()
  if not thumb then return end

  setAtlas(thumb, "minimal-scrollbar-small-thumb-middle", false)
  thumb:SetSize(THUMB_WIDTH, THUMB_HEIGHT)

  -- Cap textures host. Caps live on a CHILD FRAME at higher frame level than
  -- the slider so they render ABOVE the Slider widget's ThumbTexture. Caps
  -- anchored as siblings on the slider (ARTWORK+1 / OVERLAY+7) get covered by
  -- the slider's internal thumb render — confirmed in QuestFrame port
  -- ("scrollbar handle should have round corners, parts of the handle
  -- missing"). Mirrors MinimalScrollBar's structure (era MinimalScrollBar.xml:
  -- 50-86) where Begin/Middle/End live on the Thumb EventButton (a frame
  -- child), not directly on the slider.
  if not sb._ejThumbCapHost then
    local host = CreateFrame("Frame", nil, sb)
    host:SetFrameLevel((sb:GetFrameLevel() or 1) + 5)
    -- Anchor host TO THE THUMB so caps follow the thumb as it scrolls.
    host:SetPoint("TOPLEFT",     thumb, "TOPLEFT",     0, 0)
    host:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT", 0, 0)
    sb._ejThumbCapHost = host
  end
  if not sb._ejThumbCapTop then
    local capTop = sb._ejThumbCapHost:CreateTexture(nil, "OVERLAY")
    setAtlas(capTop, "minimal-scrollbar-small-thumb-top", true)
    capTop:SetPoint("TOP", sb._ejThumbCapHost, "TOP", 0, 0)
    sb._ejThumbCapTop = capTop
  end
  if not sb._ejThumbCapBot then
    local capBot = sb._ejThumbCapHost:CreateTexture(nil, "OVERLAY")
    setAtlas(capBot, "minimal-scrollbar-small-thumb-bottom", true)
    capBot:SetPoint("BOTTOM", sb._ejThumbCapHost, "BOTTOM", 0, 0)
    sb._ejThumbCapBot = capBot
  end

  -- Hover / press state swap. The 3 thumb textures cycle through:
  --   up   → minimal-scrollbar-small-thumb-{top,middle,bottom}        (idle)
  --   over → minimal-scrollbar-small-thumb-{top,middle,bottom}-over   (hover)
  --   down → minimal-scrollbar-small-thumb-{top,middle,bottom}-down   (drag)
  if not sb._ejThumbHoverHooked then
    sb._ejThumbHoverHooked = true
    local function applyState(suffix)
      setAtlas(thumb,             "minimal-scrollbar-small-thumb-middle" .. suffix, false)
      setAtlas(sb._ejThumbCapTop, "minimal-scrollbar-small-thumb-top"    .. suffix, true)
      setAtlas(sb._ejThumbCapBot, "minimal-scrollbar-small-thumb-bottom" .. suffix, true)
    end
    sb:HookScript("OnEnter",     function() applyState("-over") end)
    sb:HookScript("OnLeave",     function() applyState("")      end)
    sb:HookScript("OnMouseDown", function() applyState("-down") end)
    sb:HookScript("OnMouseUp",   function() applyState("-over") end)
  end
end

-- Public entry.
function EJ.scrollbar.Reskin(scroll, opts)
  if not scroll then return end
  -- UIPanelScrollFrameTemplate exposes scroll.ScrollBar; HybridScrollFrame
  -- exposes scroll.scrollBar (lowercase). Accept either.
  local sb = scroll.ScrollBar or scroll.scrollBar
  if not sb then return end
  -- Some scrollbar templates (Hybrid, Faux) name their arrows globally as
  -- $parentScrollBarScrollUpButton but don't set sb.ScrollUpButton. Resolve by
  -- name so the arrow reskin/strata/visibility below find them. Additive — only
  -- fills the field when absent, so UIPanelScrollBar callers are unaffected.
  if not sb.ScrollUpButton then
    local sbName = sb.GetName and sb:GetName()
    if sbName then
      sb.ScrollUpButton   = _G[sbName .. "ScrollUpButton"]
      sb.ScrollDownButton = _G[sbName .. "ScrollDownButton"]
    end
  end

  opts = opts or {}
  local xOffset            = opts.x                  or 7
  local strataHigh         = opts.strataHigh         ~= false
  local hideIfUnscrollable = opts.hideIfUnscrollable == true
  local classic            = opts.classic
  if classic == nil then classic = EJ.skin and EJ.skin.Is and EJ.skin.Is(EJ.skin.CLASSIC) or false end

  -- Hide the classic track art baked into the underlying Slider template so it can't
  -- bleed under our modern minimal track. UIPanelStretchableArtScrollBarTemplate
  -- (ChannelList) bakes Top/Bottom/Middle (UI-Character-ScrollBar) + a black Background
  -- straight onto the slider; the Trim/Trine variants bake trackBG/Track. We draw our own
  -- 3-piece track over the top, so these are pure leftover art — kill them everywhere
  -- (additive: callers that hand-hide named track regions, e.g. ItemTextFrame, are
  -- unaffected). Re-hide on Show in case the template's OnShow re-reveals them.
  local CLASSIC_TRACK = { "Top", "Bottom", "Middle", "Background", "trackBG", "Track" }
  local function hideClassicTrack()
    for _, key in ipairs(CLASSIC_TRACK) do
      local r = sb[key]
      if r and r ~= sb._ejTrackBegin and r ~= sb._ejTrackEnd and r ~= sb._ejTrackMiddle
         and r.Hide then r:Hide() end
    end
  end
  if not classic then hideClassicTrack() end
  if not classic and not sb._ejTrackHideHooked then
    sb._ejTrackHideHooked = true
    sb:HookScript("OnShow", hideClassicTrack)
  end

  -- Enable mouse wheel on the ScrollFrame. UIPanelScrollFrameTemplate's
  -- XML doesn't set enableMouseWheel="true" and UIPanelScrollFrame_OnLoad
  -- doesn't call self:EnableMouseWheel(true) — without explicit enablement,
  -- wheel events never fire ScrollFrameTemplate_OnMouseWheel and content
  -- can't be scrolled via the wheel. Slider drag still works independently
  -- (Slider widget has its own mouse handling).
  scroll:EnableMouseWheel(true)

  -- Position + size. Visual is retail's 8 wide; hit rect insets give a
  -- 12-wide click target for drag tolerance. SLIDER_Y_INSET leaves room
  -- for arrows OUTSIDE the slider's TOP/BOTTOM (see design note above).
  -- Classic: the native bar is twice as wide, so shift it left by half the difference to keep it
  -- centred on the same gutter line the minimal bar uses.
  sb:ClearAllPoints()
  if classic then
    local cx = xOffset - (CLASSIC_WIDTH - SLIDER_WIDTH) / 2
    sb:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    cx, -CLASSIC_Y_INSET)
    sb:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", cx,  CLASSIC_Y_INSET)
    sb:SetWidth(CLASSIC_WIDTH)
  else
    sb:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    xOffset, -SLIDER_Y_INSET)
    sb:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", xOffset,  SLIDER_Y_INSET)
    sb:SetWidth(SLIDER_WIDTH)
    sb:SetHitRectInsets(-2, -2, 0, 0)  -- 2 px beyond each side for usability
  end

  -- Strata promotion. The scrollbar otherwise gets intercepted by layered
  -- frames below (Era's parent ReputationFrame etc. with enableMouse=true).
  if strataHigh then
    sb:SetFrameStrata("HIGH")
    if sb.ScrollUpButton   then sb.ScrollUpButton:SetFrameStrata("HIGH")   end
    if sb.ScrollDownButton then sb.ScrollDownButton:SetFrameStrata("HIGH") end
  end
  sb:EnableMouse(true)

  if sb.ScrollUpButton   then sb.ScrollUpButton:EnableMouse(true)   end
  if sb.ScrollDownButton then sb.ScrollDownButton:EnableMouse(true) end

  -- Classic skin: the template's own arrows/knob are the look — skip the minimal art (and its
  -- thumb hide, which only exists to avoid a caps-only minimal thumb).
  if not classic then
    -- Arrows: anchored OUTSIDE slider TOP/BOTTOM with an 8 px gap so the
    -- thumb's drag range stops visually short of the arrows.
    reskinArrowButton(sb.ScrollUpButton,
      "minimal-scrollbar-arrow-top",
      "minimal-scrollbar-arrow-top-over",
      "minimal-scrollbar-arrow-top-down",
      "TOP")
    reskinArrowButton(sb.ScrollDownButton,
      "minimal-scrollbar-arrow-bottom",
      "minimal-scrollbar-arrow-bottom-over",
      "minimal-scrollbar-arrow-bottom-down",
      "BOTTOM")

    -- Track + thumb.
    buildTrack(sb)
    buildThumb(sb)

    -- Thumb hides when content fits the viewport (retail ScrollBarMixin:Update,
    -- ScrollBar.lua:236-239 — showThumb = hasScrollableExtent). The arrows and
    -- track stay (retail keeps the steppers visible, just disabled at the ends).
    -- Without this an unscrollable list shows a degenerate caps-only thumb with no
    -- middle ("handlebar middle isn't rendering"). Independent of the
    -- hideIfUnscrollable (whole-bar) behavior below.
    local function refreshThumb()
      local yr = (scroll.GetVerticalScrollRange and scroll:GetVerticalScrollRange()) or 0
      local show = yr and yr > 1
      local thumb = sb.GetThumbTexture and sb:GetThumbTexture()
      if thumb then EJ.SetShown(thumb, show) end
      if sb._ejThumbCapHost then EJ.SetShown(sb._ejThumbCapHost, show) end
    end
    scroll:HookScript("OnScrollRangeChanged", refreshThumb)
    if EJ.After then EJ.After(0, refreshThumb) end
  end

  -- Visibility behavior.
  if hideIfUnscrollable then
    -- Auto-hide when content fits viewport. Matches retail MinimalScrollBar.xml:312
    -- hideIfUnscrollable=true (the description-popup behavior). Hook
    -- OnScrollRangeChanged to refresh visibility whenever content height
    -- changes.
    scroll.scrollBarHideable = true
    local function applyVisibility()
      local yrange = scroll.GetVerticalScrollRange and scroll:GetVerticalScrollRange() or 0
      local visible = yrange > 0
      if sb.ScrollUpButton   then EJ.SetShown(sb.ScrollUpButton, visible)   end
      if sb.ScrollDownButton then EJ.SetShown(sb.ScrollDownButton, visible) end
      EJ.SetShown(sb, visible)
    end
    scroll:HookScript("OnScrollRangeChanged", applyVisibility)
    -- Apply initial state after a tick (yrange isn't computed until after
    -- the next frame's layout pass).
    if EJ.After then EJ.After(0, applyVisibility) end
  else
    -- Force arrows + bar always visible. Era's ScrollFrame_OnScrollRange
    -- Changed (era SecureScrollTemplates.lua:82-87) hides everything when
    -- yrange is 0 IF scrollBarHideable is set. Disable that flag, then
    -- explicit Show + hook OnScrollRangeChanged to re-Show.
    scroll.scrollBarHideable = nil
    if sb.ScrollUpButton   then sb.ScrollUpButton:Show()   end
    if sb.ScrollDownButton then sb.ScrollDownButton:Show() end
    sb:Show()
    scroll:HookScript("OnScrollRangeChanged", function()
      if sb.ScrollUpButton   then sb.ScrollUpButton:Show()   end
      if sb.ScrollDownButton then sb.ScrollDownButton:Show() end
      sb:Show()
    end)
  end
end

-- Bottom scroll shadow — retail's "more content below" gradient. The quest log's detail
-- pane is the reference: a Shadow texture (atlas questlog-frame-gradient-bottom, native
-- 307x66, QuestMapFrame.xml:578) whose alpha = Clamp(pxFromBottom / shadowHeight, 0, 1)
-- (QuestLogScrollFrameMixin:UpdateBottomShadow, retail QuestMapFrame.lua:1331-1336) — it
-- fades out as the view approaches the end and is gone entirely at the bottom.
--
-- For WowScrollBox consumers (Honor/Skills/Reputation tabs, stats sidebar, inspect honor).
-- Returns the holder frame; call holder.Update() after external relayouts if needed.
function EJ.scrollbar.AttachBottomShadow(scrollBox, host, opts)
  opts = opts or {}
  local holder = CreateFrame("Frame", nil, host or scrollBox)
  holder:SetPoint("BOTTOMLEFT",  scrollBox, "BOTTOMLEFT",  0, 0)
  holder:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT", 0, 0)
  holder:SetHeight(opts.height or 66)                       -- atlas native height
  holder:SetFrameLevel((scrollBox:GetFrameLevel() or 1) + 5)
  local tex = holder:CreateTexture(nil, "OVERLAY")
  tex:SetAllPoints(holder)
  EJ.tex.SetAtlas(tex, "questlog-frame-gradient-bottom", false)
  holder:SetAlpha(0)

  local function update()
    local range = (scrollBox.GetDerivedScrollRange and scrollBox:GetDerivedScrollRange()) or 0
    if range <= 0 then holder:SetAlpha(0); return end
    local pct = (scrollBox.GetScrollPercentage and scrollBox:GetScrollPercentage()) or 0
    local delta = (1 - pct) * range
    holder:SetAlpha(math.max(0, math.min(1, delta / holder:GetHeight())))
  end
  -- OnScroll fires with the live percentage; OnLayout covers content size changes
  -- (collapse/expand, first fill) — both era-confirmed (Shared/Scroll/ScrollBox.lua:191,277).
  if scrollBox.RegisterCallback and _G.BaseScrollBoxEvents then
    scrollBox:RegisterCallback(BaseScrollBoxEvents.OnScroll, update, holder)
    scrollBox:RegisterCallback(BaseScrollBoxEvents.OnLayout, update, holder)
  end
  if EJ.After then EJ.After(0, update) end
  holder.Update = update
  return holder
end
