-- Net MSGs --
util.AddNetworkString("tax_info")
util.AddNetworkString("tax_request")
util.AddNetworkString("tax_notification")

--[[ Vars ]]--
local taxAmount = taxConfig.perct
local taxDelay = taxConfig.delay
local minAmount = taxConfig.min
local curTime   = CurTime()
local economy 	= {}
economy.ply 	= {}
economy.money 	= {}
economy.total   = {}
economy.prct    = {}
economy.canTax  = {}
local tax = {}
tax.GroupEligible = {}
tax.earnings = {}
tax.tempearnings = {}

--[[ Main Code ]]--
local function UpdateTable()
	local TempTotal = 0
	table.Empty(economy.total)
	table.Empty(economy.prct)

	for x = 1, #player.GetAll() do
		ply = player.GetAll()[x]

		if tax.earnings[x] == nil then
			table.insert( tax.earnings, 0)
			table.insert( tax.GroupEligible, 1)
		elseif economy.money[x] != nil then
			dif = ply.DarkRPVars.money - economy.money[x]
			tax.earnings[x] = tax.earnings[x] + dif
			for i = 1, #taxConfig.Groups do
				if tax.tempearnings[x] == nil and tax.earnings[x] >= taxConfig.GroupBaseMoney * (taxConfig.GroupMultiplier * i) then
					tax.GroupEligible[x] = i
				elseif tax.tempearnings[x] != nil and tax.tempearnings[x] >= taxConfig.GroupBaseMoney * (taxConfig.GroupMultiplier * i) then
					tax.GroupEligible[x] = i
				end
			end
		end

		if economy.ply[x] == nil then
			table.insert( economy.ply, ply )
			table.insert( economy.money, ply.DarkRPVars.money )

			if economy.money[x] > minAmount then
				table.insert( economy.canTax, true)
			else
				table.insert( economy.canTax, false)
			end
		else
			economy.ply[x] = ply
			economy.money[x] = ply.DarkRPVars.money

			if economy.money[x] > minAmount then
				economy.canTax[x] = true
			else
				economy.canTax[x] = false
			end
		end

		TempTotal = TempTotal + ply.DarkRPVars.money
	end
	table.insert( economy.total, TempTotal )

	for x = 1, #economy.ply do
		table.insert( economy.prct, economy.money[x] / economy.total[1] * 100)
	end
end

UpdateTable()

local function removedPly(ply)
	for x = 1, #economy.ply do
		if economy.ply[x] == ply then
			table.remove(economy.ply, x)
			table.remove(economy.money, x)
			table.remove(economy.canTax, x)
			table.remove(economy.prct, x)
			table.remove(tax.earnings, x)
			table.remove(tax.GroupEligible, x)
		end
	end
end

net.Receive("tax_request", function(len, pl)
	for x = 1, #economy.ply do
		if economy.ply[x] == pl then
			net.Start("tax_info")
				net.WriteInt(economy.money[x], 32)
				net.WriteInt(economy.total[1], 32)
				net.WriteFloat(economy.prct[x])
				if #economy.ply >= 2 then
					net.WriteInt( math.Round( ( ( ( (taxAmount + (taxConfig.GroupMultiplier/2.5 * tax.GroupEligible[x])) + economy.prct[x]/10) /100 ) * economy.money[x])/30), 32)
					net.WriteFloat( ( ((taxAmount + (taxConfig.GroupMultiplier/2.5 * tax.GroupEligible[x]))) + economy.prct[x]/10 )/30)
				else
					net.WriteInt( math.Round( ( ( economy.money[x] / taxAmount)/30)), 32)
					net.WriteFloat(taxAmount/30) 
				end
				net.WriteString(tostring(taxConfig.Groups[tax.GroupEligible[x]]))
			net.Send(pl)
		end
	end
end)

local function TaxPayDay()
	local DeductAmount = 0
	local TotalTax = 0
	local CantTax = 0

	for x = 1, #economy.ply do

		if tax.tempearnings[x] == nil then
			tax.tempearnings[x] = tax.earnings[x]
		else
			dif = tax.earnings[x] - tax.tempearnings[x]
			if dif < tax.tempearnings[x] / 1.3 then
				tax.tempearnings[x] = tax.tempearnings[x] / 1.3
			else
				tax.tempearnings[x] = tax.tempearnings[x] + dif
			end
		end

		if #economy.ply >= 2 then 
			DeductAmount = math.Round( ( ( ( (taxAmount + (taxConfig.GroupMultiplier/2.5 * tax.GroupEligible[x])) + economy.prct[x]/10) /100 ) * economy.money[x])/30)
		else 
			DeductAmount = math.Round( ( ( economy.money[x] / (taxAmount + (taxConfig.GroupMultiplier * tax.GroupEligible[x])))/30)) 
		end

		if economy.canTax[x] then
			economy.ply[x]:addMoney(-DeductAmount)
			net.Start("tax_notification")
				net.WriteString(DarkRP.formatMoney(DeductAmount).." has been taxed from your account")
			net.Send(economy.ply[x])
			TotalTax = TotalTax + DeductAmount
		else
			CantTax = CantTax + 1
		end
	end

	for x = 1, #economy.ply do
		if !economy.canTax[x] then
			AddAmount = math.Round( (TotalTax / (taxAmount/2)) / CantTax)
			economy.ply[x]:addMoney( math.Round(AddAmount) )

			net.Start("tax_notification")
				net.WriteString(DarkRP.formatMoney(math.Round(AddAmount)).." has been added to your account")
			net.Send(economy.ply[x])
		end
	end
end

--[[ Tax Timer ]]--
timer.Create("TaxTimer", taxDelay, 0, TaxPayDay)

--[[ Table Update ]]--
timer.Create("TableUpdate", 10, 0, UpdateTable)

--[[ Hooks ]]--
hook.Add("PlayerConnect", "UpdateOnConnect", function( name, ip )
	UpdateTable()
end)

hook.Add("PlayerDisconnected", "RemovePly", removedPly(ply))