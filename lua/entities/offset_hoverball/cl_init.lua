
include("shared.lua")

local ToolMode = GetConVar("gmod_toolmode")
local ShouldRenderLasers = GetConVar("offset_hoverball_showlasers")
local AlwaysRenderLasers = GetConVar("offset_hoverball_alwaysshowlasers")
local ShowDecimals = GetConVar("offset_hoverball_showdecimals")

-- Localize material as calling the function is expensive
local laser = Material("sprites/bluelaser1")
local light = Material("Sprites/light_glow02_add")

--[[
 Based on garrysmod/lua/derma/init.lua
 It looks like the game comes with the Roboto font,
 so it should be safe to use on all platforms?
]]
surface.CreateFont("OHBTipFont", {
	font = "Roboto Regular",
	size = 24,
	weight = 13,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	extended = true
})

surface.CreateFont("OHBTipFontGlow", {
	font = "Roboto Regular",
	size = 24,
	weight = 13,
	scanlines = 0,
	antialias = true,
	extended = true,
	blursize = 5
})

surface.CreateFont("OHBTipFontSmall", {
	font = "Roboto Regular",
	size = 20,
	weight = 13,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	extended = true
})

local CoOHBName = Color(200, 200, 200)
local CoOHBValue = Color(80, 220, 80)
local CoOHBBack20 = Color(20, 20, 20)
local CoOHBBack60 = Color(60, 60, 60)
local CoOHBBack70 = Color(70, 70, 70)
local CoLaserBeam = Color(100, 100, 255)
local CoPulseMode = Color(0, 0, 0, 200)

local TableDrPoly = {
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0}
}; TableDrPoly.Size = #TableDrPoly

local TableOHBInf = {
	{2, "Hover height:"    },
	{3, "Hover force:"     },
	{4, "Air resistance:"  },
	{5, "Angular damping:" },
	{6, "Hover damping:"   },
	{7, "Brake resistance:"}
}; TableOHBInf.Size = #TableOHBInf

local function GetTextSizeY(font)
	if(font) then surface.SetFont(font) end
	return select(2,surface.GetTextSize("X"))
end

local function GetPulseColor()
	local Tim = 2.5 * CurTime()
	local Frc = Tim - math.floor(Tim)
	local Mco = math.abs(2 * (Frc - 0.5))
	local Com = math.Clamp(Mco, 0.1, 1)
	CoPulseMode.r = Com * 255
	CoPulseMode.g = Com * 200
	return CoPulseMode
end

function ENT:DrawTablePolygon(co, x1, y1, x2, y2, x3, y3)
	TableDrPoly[1].x = x1; TableDrPoly[1].y = y1
	TableDrPoly[2].x = x2; TableDrPoly[2].y = y2
	TableDrPoly[3].x = x3; TableDrPoly[3].y = y3
	surface.SetDrawColor(co)
	draw.NoTexture()
	surface.DrawPoly(TableDrPoly)
end

function ENT:DrawInfoPointy(PosX, PosY, SizX, SizY)
	-- Base functionality for drawing the pointy arrow. Please adjust the API calls only
	local x1, y1 = PosX, PosY+SizY/2    -- Triangle pointy point
	local x2, y2 = PosX+SizX, PosY      -- Triangle top point
	local x3, y3 = PosX+SizX, PosY+SizY -- Triangle bottom point
	self:DrawTablePolygon(CoOHBBack20, x1  , y1, x2, y2  , x3, y3) 	 -- Outline
	self:DrawTablePolygon(CoOHBBack60, x1+3, y1, x2, y2+2, x3, y3-2) -- Background
end

function ENT:DrawInfoBox(PosX, PosY, SizX, SizY)
	-- Base functionality for drawing the box container. Please adjust the API calls only
	draw.RoundedBox(8, PosX  , PosY  , SizX  , SizY  , CoOHBBack20) -- Back box (black)
	draw.RoundedBox(8, PosX+1, PosY+1, SizX-2, SizY-2, CoOHBBack60) -- Data box (Grey)
end

function ENT:DrawInfoTitle(StrT, PosX, PosY, SizX, SizY)
	local TxtX, TxtY = (PosX + (SizX / 2)), (PosY + 28)
	local CoDyn, StrT = GetPulseColor(), tostring(StrT)
	-- Base functionality for drawing the title. Please adjust the API calls only
	draw.RoundedBoxEx(8, PosX, PosY, SizX, SizY, CoOHBBack20, true, true, false, false) -- Header Outline
	draw.RoundedBoxEx(8, PosX+1, PosY+1, SizX-2, SizY, CoOHBBack70, true, true, false, false) -- Header BG
	draw.SimpleText(StrT, "OHBTipFontGlow", TxtX, TxtY, CoDyn, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(StrT, "OHBTipFont", TxtX, TxtY, CoOHBName, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:DrawInfoContent(TData, PosX, PosY, SizX, PadX, PadY)
	local Font = "OHBTipFontSmall" 		-- Localize font name
	local TxtY = GetTextSizeY(Font) + PadY 	-- Obtain font size

	-- Loop through TableOHBInf for labels and draw values from TData:
	for di = 1, TableOHBInf.Size do
		local inf = TableOHBInf[di]
		local idx, txt = inf[1], inf[2]
		local hby = PosY + ((di - 1) * TxtY)
		local hbx, hvx = (PosX + PadX), (PosX + (SizX - PadX))
		draw.SimpleText(txt, Font, hbx, hby, CoOHBName, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(TData[idx], Font, hvx, hby, CoOHBValue, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
end

function ENT:DrawLaser()
	if not IsValid(self) then return end
	local OwnPlayer = LocalPlayer()
	if AlwaysRenderLasers:GetBool() or
		(ToolMode:GetString() == "offset_hoverball" and
		 OwnPlayer:GetActiveWeapon():GetClass() == "gmod_tool")
	then -- Draw the hoverball lasers
		local hbpos = self:WorldSpaceCenter()
		local tr = self:GetTrace(hbpos, -500)
		-- When the trace hits make 3D rendering contest and draw laser
		if tr.Hit then
			cam.Start3D()
				render.SetMaterial(laser)
				render.DrawBeam(hbpos, tr.HitPos, 5, 0, 0, CoLaserBeam)
				render.SetMaterial(light); tr.HitPos.z = tr.HitPos.z + 1
				render.DrawQuadEasy(tr.HitPos, tr.HitNormal, 30, 30, CoLaserBeam)
				render.DrawQuadEasy(hbpos, OwnPlayer:GetAimVector(), 30, 30, CoLaserBeam)
			cam.End3D()
		end
	end
end

hook.Add("HUDPaint", "OffsetHoverballs_MouseoverUI", function()
	local OwnPlayer = LocalPlayer()
	local LookingAt = OwnPlayer:GetEyeTrace().Entity

	-- Validate whenever we have to draw something.
	if not IsValid(LookingAt) then return end
	if LookingAt:GetClass() ~= "offset_hoverball" then return end
	if (LookingAt:GetPos():DistToSqr(OwnPlayer:GetShootPos()) > 90000) then return end

	-- When the HB tip is empty do nothing.
	local TipNW = LookingAt:GetNWString("OHB-BetterTip")
	if not TipNW or TipNW == "" then return end

	local HBData = TipNW:Split(",")
	local SW, SH, CN = ScrW(), ScrH(), TableOHBInf.Size
	local SizeF = GetTextSizeY("OHBTipFontSmall")

	-- Vars that control how we draw the mouseover UI:

	-- Adjusts position of the UI, including all components. (Polygon, text, etc)
	local BoxX = (SW / 2) + 60
	local BoxY = (SH / 2) - 80

	-- Text padding:
	local PadX = 10	-- Moves text inwards, away from walls.
	local PadY = 2	-- Spacing above/below each text line.

	-- Shape scaling:
	local SizeX = (SW - (SW / 1.618)) / 4.5			-- Box width, must be wide enough to fit everything.
	local SizeY = CN * SizeF + (CN - 1) * PadY + PadX	-- Box height, scales with 'PadY' text padding.
	local SizeT = 30					-- Height of header background. Can just leave at 30.
	local SizeP = 25					-- Scaling multiplier for the little pointer arrow thing.

	--[[	
		Change the formatting of the display values if you want, just be sure to keep the keys the same. See below.
		HBData[2] = whatever	-- Hover height
		HBData[3] = whatever	-- Hover force
		HBData[4] = whatever	-- Air resistance
		HBData[5] = whatever	-- Angular damping
		HBData[6] = whatever	-- Hover damping
		HBData[7] = whatever	-- Brake resistance
	]]


	-- Optionally remove extra decimals on the UI display, and also grab the longest text width to adjust the box while we're at it.
	local Decimals = ShowDecimals:GetBool() and 2 or 0
	local TxtOfst = 0
	surface.SetFont("OHBTipFontSmall")
	for I=1,6 do
		HBData[I+1] = tostring( math.Truncate(tonumber(HBData[I+1]), Decimals) ) -- Using I+1 to skip over the header at index 1.
		local TW = select(1, surface.GetTextSize(HBData[I+1]))
		if TW > TxtOfst then TxtOfst = TW end
	end
	SizeX = SizeX+TxtOfst -- Update the box width to fit in any long text.


	if HBData[1] ~= "" then
		-- Overlay first argument is present, draw with header:
		LookingAt:DrawInfoBox(BoxX, BoxY+22, SizeX, SizeY+10)
		--LookingAt:DrawInfoPointy(BoxX-SizeP+1, SH/2-SizeP*0.5, SizeP, SizeP) -- Normal version.

		-- Fancier version of above that makes the pointy align with the center of the hoverball on the Y axis.
		-- Effect is most pronounced on larger hoverball models. Just a test, but I thought it looked kinda neat.
		LookingAt:DrawInfoPointy(BoxX-SizeP+1, math.Clamp(LookingAt:GetPos():ToScreen().y-SizeP*0.5, BoxY+30, BoxY+SizeY), SizeP, SizeP)
		LookingAt:DrawInfoTitle(HBData[1], BoxX, BoxY, SizeX, SizeT)
		LookingAt:DrawInfoContent(HBData, BoxX, BoxY+45, SizeX, PadX, PadY)
	else
		-- Draw contents without header:
		LookingAt:DrawInfoBox(BoxX, BoxY, SizeX, SizeY)
		--LookingAt:DrawInfoPointy(BoxX-SizeP+1, SH/2-SizeP*0.5, SizeP, SizeP) -- Normal version.
		LookingAt:DrawInfoPointy(BoxX-SizeP+1, math.Clamp(LookingAt:GetPos():ToScreen().y-SizeP*0.5, BoxY+10, BoxY+SizeY-32), SizeP, SizeP) -- Fancypants version.
		LookingAt:DrawInfoContent(HBData, BoxX, BoxY+15, SizeX, PadX, PadY)
	end
end)

function ENT:Draw()
	self:DrawModel()
	if ShouldRenderLasers:GetBool() or
		AlwaysRenderLasers:GetBool() then self:DrawLaser() end
end
