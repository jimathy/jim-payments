print("Jim-Payments v2 - Payments Script by Jimathy")

-- If you need support I now have a discord available, it helps me keep track of issues and give better support.

-- https://discord.gg/xKgQZ6wZvS

Config = {}

Config.TicketSystem = false -- Enable this if you want to use the ticket system

Config.PaymentRadius = 30 -- This is how far the player list will check

-- MinAmountforTicket should be your cheapest item
-- PayPerTicket should never be higher than MinAmountforTicket
Config.Jobs = {
	['popsdiner'] = { MinAmountforTicket = 50, PayPerTicket = 50 },
	['henhouse'] = { MinAmountforTicket = 50, PayPerTicket = 50 },
	['pizzathis'] = { MinAmountforTicket = 50, PayPerTicket = 50 },
	['burgershot'] = { MinAmountforTicket = 50, PayPerTicket = 50 },
	['catcafe'] = { MinAmountforTicket = 50, PayPerTicket = 50 },
	['tequilala'] = { MinAmountforTicket = 50, PayPerTicket = 50 },
	['vanilla'] = { MinAmountforTicket = 50, PayPerTicket = 50 },
	['mechanic'] = { MinAmountforTicket = 1000, PayPerTicket = 500 },
}
