-- Vars -- 
local economy 		= {}
	economy.money 	= 0
	economy.total   = 0
	economy.prct    = 0
	economy.tax     = 0
menuOpen = false

net.Receive("tax_info", function(len, pl) 
	economy.money = net.ReadInt(32)
	economy.total = net.ReadInt(32)
	economy.prct  = net.ReadFloat()
	economy.tax   = net.ReadInt(32)
	taxAmount     = net.ReadFloat()
	taxGroup      = net.ReadString()
end)

surface.CreateFont( "F1", {font = "DermaLarge",size = 18,weight = 100,blursize = 0,scanlines = 0,})

function DrawTaxInfo()
	menuOpen = true
	cMoney = 0
	cPrct  = 0
	cTax   = 0
	local TaxMenu = vgui.Create( "DFrame" )
	TaxMenu:SetSize(500, 152)
	TaxMenu:Center()
	TaxMenu:MakePopup()
	TaxMenu:SetTitle( "" )
	TaxMenu:SetDraggable( false )
	TaxMenu:ShowCloseButton( false )

	function TaxMenu:Paint(w, h)

		--[[ Background & Header ]]--
		draw.RoundedBox( 8, 0, 0, w, h, colourT.base[selCol])
		draw.RoundedBoxEx( 8, 0, 0, w, 25, Color(0,0,0,50), true, true, false, false)
		draw.RoundedBox( 0, 0, 25, w, 1, Color(255,255,255,10))
		draw.RoundedBox( 0, 0, 126, w, 1, Color(255,255,255,10))
		draw.RoundedBoxEx( 8, 0, 127, w, h, Color(0,0,0,50), false, false, true, true)
		draw.SimpleText( "Tax Info", "F1", w / 2, 12, colourT.text1[selCol], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		--[[ Info Bars ]]--
		draw.RoundedBox( 0, 10, 37, w - 20, 35, colourT.bar1a[selCol])
		draw.RoundedBox( 0, 10, 35, w - 20, 35, colourT.bar1[selCol])

		cPrct = cPrct + (economy.prct*4.80 - cPrct)/50
		draw.RoundedBox( 0, 10, 35, math.Clamp(cPrct, 0, 480), 37, Color(0,0,0, 100))
		draw.SimpleText( "You make up for "..string.sub(tostring(economy.prct), 0, 4).."% of the Economy", "F1", w / 2, 52, colourT.text2[selCol], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		--[[ Tax Bar ]]--
		draw.RoundedBox( 0, 10, 82, w - 20, 35, colourT.bar2a[selCol])
		draw.RoundedBox( 0, 10, 80, w - 20, 35, colourT.bar2[selCol])

		if economy.money > 10000 then
			cTax = cTax + (taxAmount*4.8 - cTax)/50
			draw.RoundedBox( 0, 10, 80, math.Clamp(cTax, 0, 480), 37, Color(0,0,0, 100))
			draw.SimpleText( "You pay "..DarkRP.formatMoney(economy.tax).." ("..string.sub(tostring(taxAmount), 0, 4).."% / Tax Group "..taxGroup..") towards Tax", "F1", w / 2, 97, colourT.text2[selCol], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		else
			draw.SimpleText( "You don't have enough money to pay Tax", "F1", w / 2, 97, colourT.text2[selCol], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end


		--[[ Economy Balance ]]--
		cMoney = cMoney + math.Round(((economy.total) - cMoney)/30)
		draw.SimpleText( "Current Economy - "..DarkRP.formatMoney(cMoney), "F1", w / 2, 139, colourT.text1[selCol], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local CloseButton = vgui.Create( "DButton", TaxMenu)
	CloseButton:SetText( "" )
	CloseButton:SetPos( TaxMenu:GetWide() - 30, 2 )
	CloseButton:SetSize( 30, 16 )

	function CloseButton:Paint(w, h)
		draw.SimpleText( "x", "F1", w/2, h/2, colourT.text1[selCol], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	function CloseButton:DoClick()
		menuOpen = false
		TaxMenu:Close()
	end
end

function DrawTaxNotification( string )
	local curTime = CurTime()
	local menuClose = false
	local xPos = ScrH() - 50

	local TaxN = vgui.Create( "DFrame" )
	TaxN:SetSize(320, 50)
	TaxN:SetPos( ScrW() / 2 - 160, xPos )
	TaxN:SetTitle( "" )
	TaxN:SetDraggable( false )
	TaxN:ShowCloseButton( false )

	function TaxN:Paint( w, h)
		draw.RoundedBoxEx( 8, 0, 0, w, h, colourT.base[selCol], true, true, false, false)
		draw.RoundedBoxEx( 8, 0, 0, w, 25, Color(0,0,0,50), true, true, false, false)
		draw.RoundedBox( 0, 0, 25, w, 1, Color(255,255,255,10))
		draw.RoundedBox( 0, 0, 126, w, 1, Color(255,255,255,10))
		draw.RoundedBoxEx( 8, 0, 127, w, h, Color(0,0,0,50), false, false, true, true)
		draw.SimpleText( "Tax Notification", "F1", w / 2, 12, colourT.text1[selCol], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		draw.SimpleText( string, "F1", w / 2, 36, colourT.text2[selCol], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	function TaxN:Think()
		if menuClose then
			xPos = xPos + 1
			TaxN:SetPos( ScrW() / 2 - 160, xPos )
			if xPos >= ScrH() then
				TaxN:Close()
			end
		end

		if CurTime() >= curTime + 5 then
			menuClose = true
		end
	end
end

net.Receive("tax_notification", function(len, pl)
	DrawTaxNotification( net.ReadString() )
end)

hook.Add( "OnPlayerChat", "DrawTax", function( ply, strText, bTeam, bDead )

	strText = string.lower( strText )

	if strText == "!tax" and ply == LocalPlayer() then
		net.Start("tax_request")
		net.SendToServer()
		DrawTaxInfo()
		return true
	end

end)