
include("shared.lua")

local laser = Material("sprites/bluelaser1")
local light = Material("Sprites/light_glow02_add")
local ShouldRenderLasers = GetConVar("offset_hoverball_showlasers")
local ShouldAlwaysRenderLasers = GetConVar("offset_hoverball_alwaysshowlasers")
local ToolMode = GetConVar("gmod_toolmode")

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

function GetTextSizeY(font, text)
	if(font) then surface.SetFont(font) end
	return select(2,surface.GetTextSize("X"))
end

function ENT:GetPulseColor()
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

function ENT:DrawInfoPointy(PosX, PosY)
	-- Draws at same height regardless of the box size. (Pointing at hoverball)
	local PosX, PosY = (PosX or (ScrW() / 2)), (PosY or (ScrH() / 2))
	-- Base functionality for drawing the pointy arrow. Please adjust the API calls only
	self:DrawTablePolygon(CoOHBBack20, PosX-17, PosY+16, PosX  , PosY  , PosX  , PosY+32)
	self:DrawTablePolygon(CoOHBBack60, PosX-15, PosY+16, PosX+1, PosY+1, PosX+1, PosY+31)
end

function ENT:DrawInfoBox(PosX, PosY, SizX, SizY)
	local PosX, PosY = (PosX or (ScrW() / 2)), (PosY or (ScrH() / 2))
	-- Base functionality for drawing the box container. Please adjust the API calls only
	draw.RoundedBox(8, PosX  , PosY  , SizX  , SizY+2, CoOHBBack20) -- Back box (black)
	draw.RoundedBox(8, PosX+1, PosY+1, SizX-2, SizY  , CoOHBBack60) -- Data box (Grey)
end

function ENT:DrawInfoTitle(StrT, PosX, PosY, SizX, SizY)
	local CoDyn, StrT = self:GetPulseColor(), tostring(StrT)
	local PosX, PosY = (PosX or (ScrW() / 2)), (PosY or (ScrH() / 2))
	local TxtX, TxtY = (PosX + (SizX / 2)), (PosY + 28)
	-- Base functionality for drawing the title. Please adjust the API calls only
	draw.RoundedBoxEx(8, PosX, PosY, SizX, 30, CoOHBBack20, true, true, false, false) -- Header Outline
	draw.RoundedBoxEx(8, PosX+1, PosY+1, SizX-2, 30, CoOHBBack70, true, true, false, false) -- Header BG
	draw.SimpleText(StrT, "OHBTipFontGlow", TxtX, TxtY, CoDyn, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(StrT, "OHBTipFont", TxtX, TxtY, CoOHBName, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:DrawInfoContent(TData, PosX, PosY, SizX)
	local Font = "OHBTipFontSmall" -- Localize font name
	local TxtY = GetTextSizeY(Font) + 2 -- Obtain the small font size
	local PosX, PosY = (PosX or (ScrW() / 2)), (PosY or (ScrH() / 2))
	-- Loop trough confuguration and draw HB contents
	for di = 1, TableOHBInf.Size do
		local inf = TableOHBInf[di]
		local idx, txt = inf[1], inf[2]
		local hby = PosY + 30 + ((di - 1) * TxtY)
		local hbx, hvx = (PosX + 10), (PosX + (SizX - 10))
		draw.SimpleText(txt, Font, hbx, hby, CoOHBName, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(TData[idx], Font, hvx, hby, CoOHBValue, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
end

function ENT:DrawLaser()
	if not IsValid(self) then return end
	local OwnPlayer = LocalPlayer()
	if ShouldAlwaysRenderLasers:GetBool() or
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
	-- Validate whenever we have to draw something
	if not IsValid(LookingAt) then return end
	if LookingAt:GetClass() ~= "offset_hoverball" then return end
	if (LookingAt:GetPos():DistToSqr(OwnPlayer:GetShootPos()) > 90000) then return end
	-- When the HB tip is empty do nothing
	local TipNW = LookingAt:GetNWString("OHB-BetterTip")
	if not TipNW or TipNW == "" then return end
	local HBData, TextX, TextY = TipNW:Split(","), 0, 0
	local SW, SH = ScrW(), ScrH()
	local BoxOffsetX = (SW / 2) + 60
	local BoxOffsetY = (SH / 2) - 80
	local SizeX = (SW - (SW / 1.618)) / 2.5
	local SizeY = (TableOHBInf.Size * (GetTextSizeY("OHBTipFontSmall") + 2))
	-- Overlay first argument is present
	if HBData[1] ~= "" then
		-- Draw sontents including the special title
		LookingAt:DrawInfoBox(BoxOffsetX, BoxOffsetY+20, SizeX, SizeY+10)
		LookingAt:DrawInfoPointy(BoxOffsetX, BoxOffsetY+60)
		LookingAt:DrawInfoTitle(HBData[1], BoxOffsetX, BoxOffsetY, SizeX, SizeY)
		LookingAt:DrawInfoContent(HBData, BoxOffsetX, BoxOffsetY+12, SizeX)
	else
		-- Draw sontents without the special title
		LookingAt:DrawInfoBox(BoxOffsetX, BoxOffsetY, SizeX, SizeY)
		LookingAt:DrawInfoPointy(BoxOffsetX, BoxOffsetY + 60)
		LookingAt:DrawInfoContent(HBData, BoxOffsetX, BoxOffsetY-18, SizeX)
	end
end)

function ENT:Draw()
	self:DrawModel() -- Draws Model Client Side. Only drawn when player is looking.
	if ShouldRenderLasers:GetBool() or ShouldAlwaysRenderLasers:GetBool() then self:DrawLaser() end
end
