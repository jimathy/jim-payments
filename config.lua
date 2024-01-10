print("^2Jim^7-^2Payments ^7v^42^7.^48^7.^45 ^7- ^2Payments Script by ^1Jimathy^7")

-- If you need support I now have a discord available, it helps me keep track of issues and give better support.

-- https://discord.gg/xKgQZ6wZvS

Config = {
	Lan = "en",
	Debug = false,
	Notify = "qb",		-- "qb" | "okok" | "t" | "infinity" | "rr"
	Menu = "ox",

	---------------------------------
	-- Default Job Payment Systems --
	---------------------------------

	Banking = "qb-banking", 	
								-- "qb-management" 	- This is for the older version of QBCore
								-- "qb-banking" 	- This is for the latest QBCore updates
								-- "renewed"
								-- "fd" 			- currently default supported
								-- "okok"			- make sure to add societies to Config.Societies in okokBanking, This is for the latest QBCore updates

	ApGov = false, -- Toggle support for AP-Goverment Tax

	List = true, -- "true" to use nearby player list feature in the cash registers, "false" for manual id entry
	PaymentRadius = 15, -- This is how far the playerlist will check for nearby players (based on the person charging)

	Peds = true, -- "true" to enable peds spawning in banks
	PedPool = {
		`IG_Bankman`,
		`U_M_M_BankMan`,
		`S_F_M_Shop_HIGH`,
		`S_M_M_HighSec_02`,
		`S_M_M_HighSec_03`,
		`S_M_M_HighSec_04`,
		`A_F_Y_Business_01`,
		`A_F_Y_Business_02`,
		`A_F_Y_Business_03`,
		`A_F_Y_Business_04`,
		`A_M_M_Business_01`,
		`A_M_Y_Business_02`,
		`A_M_Y_Business_03`,
		`U_F_M_CasinoShop_01`,
	},

	Usebzzz = false, -- enable if you're using the prop from bzzz
	Enablecommand = true, -- Enables the cashregister command

	PhoneBank = false, 	-- Set this to false to use the popup payment system FOR CARD/BANK PAYMENTS instead of using phone invoices
						-- This doesn't affect Cash payments as they by default use confirmation now
						-- This is helpful for phones that don't support invoices well

	PhoneType = "qb", -- Change this setting to make invoices work with your phone script [still testing this currently]
						-- "qb" for qb-phone
						-- "gks"" for GKSPhone

	CashInLocation = vector4(252.23, 223.11, 106.29, 159.2), -- Default Third Window along in Pacific Bank

	TicketSystem = true, -- Enable this if you want to use the ticket system false
	TicketSystemAll = true, -- Enable this to give tickets to all workers clocked in

	Commission = true, -- Set this to true to enable Commissions and give the person charging a percentage of the total
	CommissionAll = false, -- Set this to true to give commission to workers clocked in
	CommissionDouble = false, -- Set this to true if you want the person charging to get double Commission
	CommissionLimit = false,	-- If true, this limits the Commission to only be given if over the "MinAmountForTicket".
								-- If false, Commission will be given for any amount

	-- MinAmountforTicket should be your cheapest item
	-- PayPerTicket should never be higher than MinAmountforTicket
	-- Commission is a percentage eg "0.10" becomes 10%
	Jobs = {
		-- Jim Businesses | https://jimathy666.tebex.io/
		['bakery'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['beanmachine'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['burgershot'] = { MinAmountforTicket = 50, PayPerTicket = 50 , Commission = 0.10, },
		['catcafe'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['henhouse'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['pizzathis'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['popsdiner'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['tequilala'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['vanilla'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['upnatom'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['hornys'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },

		-- JixelTay Businesses | https://jixeltay.tebex.io/
		['cigarbar'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['cluckinbell'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['smokeshop'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['pearls'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['kois'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['whitewidow'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
		['bestbuds'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },

		-- Jim Mechanic | https://jimathy666.tebex.io/
		['mechanic'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
		['tuners'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
		['ottos'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
		['lscustoms'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
		['bennys'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },

		-- Gangs | Example of a gang being supported
		['lostmc'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, gang = true, },
	},

	------------------------------
	-- Custom Job Cash Register --
	------------------------------
	-- This adds the ability to add multiple locations for each job
	-- Basically adding ready made locations, all you need to a vector4 and to confrim if you need a new prop in that location
    CustomCashRegisters = {
		-- ["jobname"] = { -- Player job role restriction
		-- 	{ coords = vector4(0, 0, 0, 0), prop = true, }, -- vector4 to place the till and the way it faces
		-- 	{ coords = vector4(0, 0, 0, 0), prop = true, }, -- "prop = true" spawns a prop at the coords
		-- },
	},

	-- The /polcharge command requires specific jobs to be set
	-- No tickets for these, it's just commission (0.25 = 25%)
	FineJobs = {
		['police'] = { Commission = 0.25, },
		['ambulance'] = { Commission = 0.25, },
	},
	FineJobConfirmation = false, --"true" makes it so fines need confirmation, "false" skips this ands just removes the money
	FineJobList = true, -- "true" to use nearby player list feature in the cash registers, "false" for manual id entry

	---------------------
	-- Banking Systems --
	---------------------
	useATM = false, -- Enable this to use the scripts ATM's and controls
	useBanks = false, -- Enable this to use my banking stuff
	BankBlips = false, -- Enable this if you disabled qb-banking and need bank locations
	ATMBlips = false, -- Enable this if you are a pyscho and need every ATM to be on the map too

	Gabz = false, 	-- "true" to enable Gabz Bank locations
					-- this corrects the ATM/Bank Cashier + Ticket Cash in location

	ATMModels = { `prop_atm_01`, `prop_atm_02`, `prop_atm_03`, `prop_fleeca_atm` },
	ATMLocations = {
	--PACIFIC BANK 10 ATMS
		vector3(265.9, 213.86, 106.28),
		vector3(265.56, 212.98, 106.28),
		vector3(265.19, 211.91, 106.28),
		vector3(264.86, 211.03, 106.28),
		vector3(264.52, 210.06, 106.28),
		vector3(236.64, 219.72, 106.29),
		vector3(237.04, 218.72, 106.29),
		vector3(237.5, 217.87, 106.29),
		vector3(237.93, 216.94, 106.29),
		vector3(238.36, 216.03, 106.29),
	},
	--QB-Target doesn't seem to like ALL ATM Props so need to manually add locations
	WallATMLocations = {
		vector3(-386.54, 6046.29, 31.5),
		vector3(-282.82, 6226.24, 31.49),
		vector3(-132.74, 6366.79, 31.48),
		vector3(-95.76, 6457.41, 31.46),
		vector3(-97.52, 6455.65, 31.47),
		vector3(155.95, 6642.99, 31.6),
		vector3(173.92, 6638.16, 31.57),
		vector3(2558.65, 350.92, 108.62),
		vector3(1077.78, -776.64, 58.35),
		vector3(1138.14, -468.88, 66.73),
		vector3(1166.93, -455.96, 66.81),
		vector3(285.37, 143.07, 104.17),
		vector3(-165.43, 234.81, 94.92),
		vector3(-165.4, 232.73, 94.92),
		vector3(-1410.41, -98.76, 52.43),
		vector3(-1409.85, -100.51, 52.38),
		vector3(-1206.0, -324.94, 37.86),
		vector3(-1205.23, -326.55, 37.86),
		vector3(-2072.28, -317.27, 13.32),
		vector3(-2974.7, 380.15, 15.0),
		vector3(-2959.01, 487.45, 15.46),
		vector3(-2956.87, 487.36, 15.46),
		vector3(-3043.98, 594.32, 7.74),
		vector3(-3241.35, 997.74, 12.55),
		vector3(-1305.59, -706.64, 25.32),
		vector3(-537.85, -854.69, 29.28),
		vector3(-709.98, -818.71, 23.73),
		vector3(-712.87, -818.71, 23.73),
		vector3(-526.71, -1223.18, 18.45),
		vector3(-256.47, -715.94, 33.55),
		vector3(-259.13, -723.29, 33.54),
		vector3(-203.82, -861.3, 30.27),
		vector3(111.38, -774.96, 31.44),
		vector3(114.56, -776.13, 31.42),
		vector3(112.46, -819.65, 31.34),
		vector3(118.93, -883.68, 31.12),
		vector3(-846.97, -340.29, 38.68),
		vector3(-846.41, -341.41, 38.68),
		vector3(-262.21, -2012.17, 30.15),
		vector3(-273.23, -2024.32, 30.15),
		vector3(24.46, -945.94, 29.36),
		vector3(-254.48, -692.74, 33.61),
		vector3(-1569.95, -546.94, 34.96),
		vector3(-1570.91, -547.63, 34.96),
		vector3(289.14, -1282.29, 29.6),
		vector3(289.18, -1256.84, 29.44),
		vector3(296.04, -896.22, 29.24),
		vector3(296.74, -894.26, 29.24),
		vector3(-301.63, -829.73, 32.43),
		vector3(-303.23, -829.44, 32.43),
		vector3(5.27, -919.87, 29.56),
		vector3(-1200.61, -885.62, 13.26),
	},

	BankLocations = {
		["legion"] = {
			vector4(149.5, -1042.08, 29.37, 342.74), -- Legion Fleeca
		},
		["hawick"] = {
			vector4(313.81, -280.43, 54.16, 342.29), -- Hawick Fleeca
		},
		["vinewood"] = {
			vector4(-351.4, -51.24, 49.04, 338.4), -- Vinewood Fleeca
		},
		["delperro"] = {
			vector4(-1212.11, -332.01, 37.78, 25.33), -- Del Perro Fleeca
		},
		["route1"] = {
			vector4(-2961.17, 482.9, 15.7, 84.68), -- Route 1 Fleeca
		},
		["route68"] = {
			vector4(1175.03, 2708.2, 38.09, 180.0), -- Route 68 Fleeca
		},
		["paleto"] = {
			vector4(-111.22, 6470.03, 31.63, 133.86), -- Paleto Bank
		},
		["pacific"] = {
			vector4(243.58, 226.25, 106.29, 169.06), -- Pacific Bank Window 1
			vector4(247.08, 224.98, 106.29, 157.75), -- Pacific Bank Window 2
		},
	},
}
-- If Gabz banks enabled, load these locations instead
if Config.Gabz then
	Config.CashInLocation = vector4(269.28, 217.24, 106.28, 69.0)
	Config.BankLocations = {
		["legion"] = {
			vector4(149.5, -1042.08, 29.37, 342.74), -- Legion Fleeca
		},
		["hawick"] = {
			vector4(313.81, -280.43, 54.16, 342.29), -- Hawick Fleeca
		},
		["vinewood"] = {
			vector4(-351.4, -51.24, 49.04, 338.4), -- Vinewood Fleeca
		},
		["delperro"] = {
			vector4(-1212.11, -332.01, 37.78, 25.33), -- Del Perro Fleeca
		},
		["route1"] = {
			vector4(-2961.17, 482.9, 15.7, 84.68), -- Route 1 Fleeca
		},
		["route68"] = {
			vector4(1175.03, 2708.2, 38.09, 180.0), -- Route 68 Fleeca
		},
		["paleto"] = {
			vector4(-110.72, 6469.82, 31.63, 222.94), -- Paleto Bank (GABZ) - 1
			vector4(-108.98, 6471.56, 31.63, 222.92), -- Paleto Bank (GABZ) - 2
		},
		["pacific"] = {
			vector4(258.55, 227.63, 106.28, 160.96), -- Pacficic Gabz 1+2
			vector4(263.21, 225.93, 106.28, 158.25), -- Pacficic Gabz 3+4
			vector4(267.95, 224.24, 106.28, 158.5), -- Pacficic Gabz 5+6
			vector4(263.71, 212.63, 106.28, 337.53), -- Pacficic Gabz 7+8
			vector4(259.02, 214.32, 106.28, 337.82), -- Pacficic Gabz 9+10
			vector4(254.27, 216.06, 106.28, 336.37), -- Pacficic Gabz 11+12
		},
	}
	Config.ATMLocations = {
		vector3(239.02, 212.37, 106.28),
		vector3(239.46, 213.6, 106.28),
		vector3(239.9, 214.82, 106.28),
		vector3(240.35, 216.03, 106.28),
		vector3(241.42, 218.96, 106.28),
		vector3(241.86, 220.16, 106.28),
		vector3(242.3, 221.41, 106.28),
		vector3(242.76, 222.63, 106.28),
		vector3(263.46, 203.86, 106.28),
		vector3(263.96, 205.03, 106.28),
		vector3(264.37, 206.28, 106.28),
		vector3(264.77, 207.51, 106.28),
	}
end

Loc = {}
