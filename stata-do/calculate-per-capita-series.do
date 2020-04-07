use "$work_data/calculate-wealth-income-ratio-output.dta", clear

// Data with adult population
keep if inlist(widcode, "npopul999i", "npopul992i")
replace p="pall" if p=="p0p100"
reshape wide value, i(iso year p) j(widcode) string
keep iso year p valuenpopul992i valuenpopul999i
tempfile pop
save "`pop'"

// Calculate per capita series
use "$work_data/calculate-wealth-income-ratio-output.dta", clear

keep if substr(widcode, 1, 1) == "m"

// Drop Tobin's Q
drop if substr(widcode, 4, 3) == "toq"
// Drop fiscal income
drop if substr(widcode, 1, 6) == "mfiinc"

merge n:1 iso year using "`pop'", nogenerate keep(match)

generate value999i = value/valuenpopul999i
generate value992i = value/valuenpopul992i

keep iso year widcode p currency value999i value992i

reshape long value, i(iso year p widcode) j(pop) string
replace widcode = "a" + substr(widcode, 2, 5) + pop

drop pop
drop if missing(value)

append using "$work_data/calculate-wealth-income-ratio-output.dta"

duplicates drop iso year p widcode, force

compress
label data "Generated by calculate-per-capita-series.do"
save "$work_data/calculate-per-capita-series-output.dta", replace
