BankLocations = {
    ["legion"] = {
        vec4(149.5, -1042.08, 29.37, 342.74), -- Legion Fleeca
    },
    ["hawick"] = {
        vec4(313.81, -280.43, 54.16, 342.29), -- Hawick Fleeca
    },
    ["vinewood"] = {
        vec4(-351.4, -51.24, 49.04, 338.4), -- Vinewood Fleeca
    },
    ["delperro"] = {
        vec4(-1212.11, -332.01, 37.78, 25.33), -- Del Perro Fleeca
    },
    ["route1"] = {
        vec4(-2961.17, 482.9, 15.7, 84.68), -- Route 1 Fleeca
    },
    ["route68"] = {
        vec4(1175.03, 2708.2, 38.09, 180.0), -- Route 68 Fleeca
    },
    ["paleto"] = {
        vec4(-111.22, 6470.03, 31.63, 133.86), -- Paleto Bank
    },
    ["pacific"] = {
        vec4(243.58, 226.25, 106.29, 169.06), -- Pacific Bank Window 1
        vec4(247.08, 224.98, 106.29, 157.75), -- Pacific Bank Window 2
    },
}

if Config.General.Gabz then
	Config.Receipts.CashInLocations = {
		vec4(269.28, 217.24, 106.28, 69.0)
	}
	BankLocations = {
		["legion"] = {
			vec4(149.5, -1042.08, 29.37, 342.74), -- Legion Fleeca
		},
		["hawick"] = {
			vec4(313.81, -280.43, 54.16, 342.29), -- Hawick Fleeca
		},
		["vinewood"] = {
			vec4(-351.4, -51.24, 49.04, 338.4), -- Vinewood Fleeca
		},
		["delperro"] = {
			vec4(-1212.11, -332.01, 37.78, 25.33), -- Del Perro Fleeca
		},
		["route1"] = {
			vec4(-2961.17, 482.9, 15.7, 84.68), -- Route 1 Fleeca
		},
		["route68"] = {
			vec4(1175.03, 2708.2, 38.09, 180.0), -- Route 68 Fleeca
		},
		["paleto"] = {
			vec4(-110.72, 6469.82, 31.63, 222.94), -- Paleto Bank (GABZ) - 1
			vec4(-108.98, 6471.56, 31.63, 222.92), -- Paleto Bank (GABZ) - 2
		},
		["pacific"] = {
			vec4(258.55, 227.63, 106.28, 160.96), -- Pacficic Gabz 1+2
			vec4(263.21, 225.93, 106.28, 158.25), -- Pacficic Gabz 3+4
			vec4(267.95, 224.24, 106.28, 158.5), -- Pacficic Gabz 5+6
			vec4(263.71, 212.63, 106.28, 337.53), -- Pacficic Gabz 7+8
			vec4(259.02, 214.32, 106.28, 337.82), -- Pacficic Gabz 9+10
			vec4(254.27, 216.06, 106.28, 336.37), -- Pacficic Gabz 11+12
		},
	}
end