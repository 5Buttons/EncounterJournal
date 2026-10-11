-- Addon/Core/PanelChrome.lua — shared "modern ButtonFrameTemplate chrome" for
-- PlayerInteractionManager panels (reskin an EXISTING Era ButtonFrameTemplate frame:
-- hide classic border → retail NineSlice on f.NineSlice + rock Bg + TopTileStreaks +
-- modern CloseButton).
--
-- ADOPTERS (all on PC.Apply now — the per-frame bespoke copies were normalized onto this
-- one path): GuildRegistrar, GossipFrame, MailFrame (+ OpenMailFrame), MerchantFrame. Each
-- keeps only its genuinely frame-specific extras around PC.Apply (Gossip: parchment+gutter;
-- Mail: Mail-Icon removal + title rehost; Merchant: portrait/name/repair hides + bottom band).
--
-- NOT this pattern (do NOT route through PC.Apply): frames that LAYER their own backgrounds
-- and apply the nineslice to the frame itself (Bank, CharacterPanel — "own-bg, self-host"),
-- and build-new NE_ frames (EncounterJournal, Professions, Talents) which just call
-- EJ.nineslice.ApplyLayout directly (no classic chrome to hide). Calendar is a different
-- chrome family entirely. See Core/CHROME_REFACTOR_PLAN.md for the full taxonomy.
--
-- Composable primitives, NOT a monolithic Modernize(): callers compose PC.Apply + PC.Keep +
-- PC.ModernizeCloseButton + EJ.portrait per frame (the umbrella was rejected as
-- over-engineering — frames diverge too much for one options table).
--
-- All ops are texture Show/Hide + SetTexture/SetAtlas + SetFrameLevel — never
-- protected — so callers may re-assert in combat (PIM frames can open mid-combat).

EJ = EJ or {}
EJ.panelchrome = EJ.panelchrome or {}
local PC = EJ.panelchrome

local ROCK_FDID = 374155  -- UI-Background-Rock (retail ButtonFrameTemplate default)

-- ButtonFrameTemplate / PortraitFrameTemplate border pieces to hide so our modern
-- NineSlice shows through. Same set GossipFrame/MailFrame hide. NOTE: TopTileStreaks
-- is deliberately absent — retail keeps it; ApplyModernChrome re-textures it.
local BORDER_KEYS = {
  "PortraitFrame", "TopRightCorner", "TopBorder", "TopLeftCorner",
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder",
  "RightBorder", "TitleBg",
}

-- Register a frame-owned BACKGROUND texture (a content parchment, the NPC portrait,
-- …) so HideClassicChrome's region walk preserves it instead of hiding it.
function PC.Keep(f, tex)
  if not f or not tex then return end
  f._ejPanelKeep = f._ejPanelKeep or {}
  f._ejPanelKeep[tex] = true
end

-- Thin alias to the canonical helper (Core/FrameUtil.lua). Kept so the many existing
-- EJ.panelchrome.PinPixelPerfect call sites don't churn; now also honors a userScale arg.
function PC.PinPixelPerfect(f, userScale)
  EJ.FrameUtil.PinPixelPerfect(f, userScale)
end

-- Canonical panel title TEXT styling. Normalizes the title FontString of a chrome'd
-- window to retail's PortraitFrameTemplate spec (retail SharedUIPanelTemplates.xml:492-498):
--   GameFontNormal (gold 1,0.82,0), no word-wrap, JustifyH CENTER, anchored within its
--   TitleContainer at TOP(0,-5) + LEFT + RIGHT.
-- It resolves the frame's existing title region (the template's TitleContainer.TitleText,
-- or a hand-rolled f.Title) so EVERY window reads with the same font / colour / vertical
-- placement instead of each frame's ad-hoc FontString (some anchored CENTER, ~5px low).
-- It deliberately does NOT touch the TitleContainer's own anchors — those insets are
-- legitimately per-frame (portrait width, doublewide AH, no-portrait frames), captured from
-- each retail frame. Only the text styling is shared.
--   EJ.panelchrome.SetTitle(f, MERCHANT or "Merchant")
-- Rehosted titles (Era frames whose template TitleContainer path is dead or buried under
-- the nineslice — the caller moved the FontString onto its own band container): pass the
-- FontString + its container explicitly: SetTitle(f, nil, fs, band). Pair with
-- PC.TitleBand below for the container.
function PC.SetTitle(frame, text, fs, anchorTo)
  if not frame then return end
  local tc = frame.TitleContainer
  fs = fs or (tc and tc.TitleText) or frame.Title
  if not fs then return end
  fs:SetFontObject(GameFontNormal)             -- gold (1,0.82,0), the retail title font
  if fs.SetWordWrap then fs:SetWordWrap(false) end
  fs:SetJustifyH("CENTER")
  anchorTo = anchorTo or tc or frame
  fs:ClearAllPoints()
  fs:SetPoint("TOP",   anchorTo, "TOP", 0, -5)
  fs:SetPoint("LEFT",  anchorTo, "LEFT")
  fs:SetPoint("RIGHT", anchorTo, "RIGHT")
  if text ~= nil then fs:SetText(text) end
  frame._ejTitle = fs
  return fs
end

-- The retail title BAND for rehosted titles: a container spanning the retail
-- TitleContainer geometry — TOPLEFT(58,-1) → TOPRIGHT(-24,-1), height 20 (retail
-- SharedUIPanelTemplates.xml:576-588) — at a frame level above the NineSlice child, so
-- the title draws over the metal top edge. Idempotent per frame. Frames whose retail
-- counterpart uses a different span (doublewide, no-portrait) anchor their own container
-- and pass it to SetTitle instead.
function PC.TitleBand(f)
  if f._ejTitleBand then return f._ejTitleBand end
  local tc = CreateFrame("Frame", nil, f)
  tc:SetPoint("TOPLEFT",  f, "TOPLEFT",  58, -1)
  tc:SetPoint("TOPRIGHT", f, "TOPRIGHT", -24, -1)
  tc:SetHeight(20)
  tc:EnableMouse(false)
  local nsLevel = (f.NineSlice and f.NineSlice.GetFrameLevel and f.NineSlice:GetFrameLevel())
    or f:GetFrameLevel() or 1
  tc:SetFrameLevel(nsLevel + 10)
  f._ejTitleBand = tc
  return tc
end

-- Hide the classic chrome. The BACKGROUND-layer walk is what kills name-collision
-- classic backgrounds (e.g. an explicit `<Frame>Bg` texture sharing the global name
-- with the inherited ButtonFrameTemplate f.Bg) — we keep only f.Bg + caller keeps.
function PC.HideClassicChrome(f)
  if not f then return end
  for _, key in ipairs(BORDER_KEYS) do
    local r = f[key]
    if r and r.Hide then r:Hide() end
  end
  -- NOTE: the InsetFrameTemplate marble Bg is intentionally NOT hidden here. It's only
  -- a conflict for frames that supply their OWN content background (Gossip/GuildRegistrar
  -- parchment) — those hide it themselves alongside their parchment. Frames that use the
  -- marble AS their dark content backing (Merchant, Mail) must keep it, so the hide lives
  -- with the parchment, not in this shared teardown.

  local keep = f._ejPanelKeep
  EJ.FrameUtil.ForEachRegion(f, "Texture", "BACKGROUND", function(r)
    if r ~= f.Bg and not (keep and keep[r]) then r:Hide() end
  end)
end

-- layout (optional): which registered NineSlice layout to apply to f.NineSlice.
-- Defaults to "PortraitFrameTemplate" (the ButtonFrameTemplate/PortraitFrameTemplate
-- adopters). Pass "ButtonFrameTemplateNoPortrait" for DefaultPanelTemplate frames
-- (HelpFrame) whose metal border lacks the portrait-corner overhang.
function PC.ApplyModernChrome(f, layout)
  if not f then return end
  -- f.Bg → tiled UI-Background-Rock (retail ButtonFrameTemplate default).
  if f.Bg then
    local localPath = EJ.tex.localFiles and EJ.tex.localFiles[ROCK_FDID]
    f.Bg:SetTexture(localPath or ROCK_FDID, "REPEAT", "REPEAT")
    f.Bg:SetHorizTile(true)
    f.Bg:SetVertTile(true)
    f.Bg:Show()
  end
  -- Modern nineslice on the inherited f.NineSlice (PortraitFrameBaseTemplate).
  if f.NineSlice and EJ.nineslice and EJ.nineslice.ApplyLayout then
    f.NineSlice:Show()
    EJ.nineslice.ApplyLayout(f.NineSlice, layout or "PortraitFrameTemplate")
  end
  -- TopTileStreaks: Era's virtual texture resolves to classic art; swap to the
  -- modern atlas (same FDID 1723833 used on QuestFrame/Gossip).
  if f.TopTileStreaks then
    EJ.tex.SetAtlas(f.TopTileStreaks, "_ui-frame-toptilestreaks", false)
    f.TopTileStreaks:SetHorizTile(true)
    f.TopTileStreaks:SetHeight(43)
    f.TopTileStreaks:Show()
  end
  -- Retail's frame-level ordering (PortraitFrameMixin).
  if f.SetFrameLevelsFromBaseLevel then f:SetFrameLevelsFromBaseLevel(1) end
  -- Uniform title styling for every chrome'd window, from one place (no per-frame title
  -- FontString styling). No-ops if the frame has no TitleContainer.TitleText / .Title.
  PC.SetTitle(f)
end

-- Modernize a close button to retail's RedButton-Exit-2x family (4-texture swap:
-- Normal / Pushed / Highlight[ADD] / Disabled). Single source for the copies that
-- lived in CharacterPanel/CloseButton, BankFrame, Calendar, Reputation.
--
-- target : the CloseButton itself, OR a frame carrying `.CloseButton`.
-- opts (all optional):
--   size           default 24
--   anchor         { point, relPoint, x, y } vs the button's parent. Default
--                  { "TOPRIGHT", "TOPRIGHT", 1, 0 } (retail
--                  UIPanelCloseButtonDefaultAnchors). Pass `false` to leave the
--                  button where its template/XML put it (Calendar).
--   frameLevelBump add this to the parent's frame level (Bank passes 10).
--   disabled       default true — also swap the Disabled texture.
-- Idempotent via cb._ejCloseModernized.
function PC.ModernizeCloseButton(target, opts)
  local cb = target
  if cb and not cb.SetNormalTexture and cb.CloseButton then cb = cb.CloseButton end
  if not cb or not cb.SetNormalTexture or cb._ejCloseModernized then return end
  if not (EJ.tex and EJ.tex.SetAtlas) then return end
  opts = opts or {}

  local size = opts.size or 24
  cb:SetSize(size, size)

  if opts.anchor ~= false then
    local a = opts.anchor or { "TOPRIGHT", "TOPRIGHT", 1, 0 }
    cb:ClearAllPoints()
    cb:SetPoint(a[1], cb:GetParent(), a[2] or a[1], a[3] or 0, a[4] or 0)
  end
  if opts.frameLevelBump then
    local parent = cb:GetParent()
    local base = (parent and parent.GetFrameLevel and parent:GetFrameLevel()) or 0
    cb:SetFrameLevel(base + opts.frameLevelBump)
  end

  -- 3.3.5a pattern (from the DragonUI_NewEra downport): Button:SetXTexture takes a FILE PATH here,
  -- then the atlas rect goes onto the texture the button hands back via GetXTexture. Handing the
  -- template a freshly created Texture OBJECT (what the New Era source did) left the close button
  -- blank on this client. The rect + sheet come from Core/AtlasData.lua; when that art isn't
  -- shipped the button simply keeps the native 3.3.5 X (never blank).
  local function applyState(setter, getter, atlas, blend)
    local entry = EJ.tex.AtlasEntry and EJ.tex.AtlasEntry(atlas)
    local path  = entry and EJ.tex.localFiles and (entry.path or EJ.tex.localFiles[entry.file])
    if not (entry and type(path) == "string") then return false end
    cb[setter](cb, path)
    local t = cb[getter] and cb[getter](cb)
    if t then
      t:SetTexCoord(entry.left, entry.right, entry.top, entry.bottom)
      if blend then t:SetBlendMode(blend) end
    end
    return true
  end

  local okN = applyState("SetNormalTexture",    "GetNormalTexture",    "redbutton-exit-2x")
              applyState("SetPushedTexture",    "GetPushedTexture",    "redbutton-exit-pressed-2x")
              applyState("SetHighlightTexture", "GetHighlightTexture", "redbutton-highlight-2x", "ADD")
  if opts.disabled ~= false then
              applyState("SetDisabledTexture",  "GetDisabledTexture",  "redbutton-exit-disabled-2x")
  end

  -- Only mark "modernized" if the normal state took; else leave the native art in place.
  if okN then cb._ejCloseModernized = true end
end

-- Idempotent full chrome re-assert (hide classic + apply modern). Safe to call on
-- every frame open. CloseButton/pixel-scale are one-time (call them at boot).
-- layout (optional) is forwarded to ApplyModernChrome (see there).
function PC.Apply(f, layout)
  if not f then return end
  PC.HideClassicChrome(f)
  PC.ApplyModernChrome(f, layout)
end
