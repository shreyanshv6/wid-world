// -----------------------------------------------------------------------------------------------------------------
// IMPORT ALL FILES
// -----------------------------------------------------------------------------------------------------------------

// France inequality 2017 (GGP2017)
use "$wid_dir/Country-Updates/France/france-data/france-ggp2017.dta", clear

// UK wealth 2017 (Alvaredo2017)
append using "$uk_data/uk-wealth-alvaredo2017.dta"

// US inequality 2017 (PSZ2017)
*append using "$wid_dir/Country-Updates/US/2017/September/PSZ2017-AppendixII.dta"

// World and World Regions 2018 (ChancelGethin2018 from World Inequality Report)
append using "$wid_dir/Country-Updates/World/2018/January/world-chancelgethin2018.dta"
drop if inlist(iso,"QE","QE-MER")

// Germany and subregions
append using "$wid_dir/Country-Updates/Germany/2018/May/bartels2018.dta"

// Korea 2018 (Kim2018), only gdp and nni (rest is in current LCU)
append using "$wid_dir/Country-Updates/Korea/2018_10/korea-kim2018-constant.dta"

// Europe 2020 - bcg2020
append using "$wid_dir/Country-Updates/Europe/2020_03/europe-bcg2020.dta"
// Add bcg2020 source next to GGP2017
* Source
replace source = `"Before 2014, [URL][URL_LINK]http://wid.world/document/b-garbinti-j-goupille-and-t-piketty-inequality-dynamics-in-france-1900-2014-evidence-from-distributional-national-accounts-2016/[/URL_LINK][URL_TEXT]Garbinti, Goupille-Lebret and Piketty (2018), Income inequality in France, 1900-2014: Evidence from Distributional National Accounts (DINA), Journal of Public Economics.[/URL_TEXT][/URL]"' +  ///
`" After 2014, Blanchet, Chancel and Gethin (2020), “Why is Europe more Equal than the United States?”."' ///
if (source == "[URL][URL_LINK]http://wid.world/document/b-garbinti-j-goupille-and-t-piketty-inequality-dynamics-in-france-1900-2014-evidence-from-distributional-national-accounts-2016/[/URL_LINK][URL_TEXT]Garbinti, Goupille-Lebret and Piketty (2018), Income inequality in France, 1900-2014: Evidence from Distributional National Accounts (DINA), Journal of Public Economics[/URL_TEXT][/URL]" | source == "Blanchet, Chancel and Gethin (2020), “Why is Europe more Equal than the United States?”") & strpos(widcode, "ptinc") & (iso == "FR")

tempfile researchers
save "`researchers'"

// ----------------------------------------------------------------------------------------------------------------
// CREATE METADATA
// -----------------------------------------------------------------------------------------------------------------
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet source method data_quality data_imputation data_points extrapolation
order iso sixlet source method
gduplicates drop

drop if iso == "FR" & method == "" & strpos(sixlet, "ptinc")
gduplicates tag iso sixlet, gen(dup)
assert dup==0
drop dup

replace method = " " if method == ""
tempfile meta
save "`meta'"
// ----------------------------------------------------------------------------------------------------------------
// ADD DATA TO WID
// -----------------------------------------------------------------------------------------------------------------

use iso year p widcode value author using "`researchers'", clear
append using "$work_data/aggregate-regions-wir2018-output.dta", generate(oldobs)

// Germany: drop old fiscal income series
drop if strpos(widcode, "fiinc") & (iso == "DE") & (oldobs == 1)

// France 2017: drop specific widcodes
drop if (inlist(widcode,"ahwbol992j","ahwbus992j","ahwcud992j","ahwdeb992j","ahweal992j") ///
	| inlist(widcode,"ahwequ992j","ahwfie992j","ahwfin992j","ahwfix992j","ahwhou992j") ///
	| inlist(widcode,"ahwnfa992j","ahwpen992j","bhweal992j","ohweal992j","shweal992j","thweal992j") ///
	| substr(widcode, 2, 2) == "fi") ///
	& (iso == "FR") & (oldobs==1)
/*
// US inequality (PSZ 2017 Appendix II): drop g-percentiles except for wealth data (DINA imported before), drop new duplicated wid data
replace p=p+"p100" if iso=="US" & (strpos(widcode,"ptinc") | strpos(widcode,"hweal") | strpos(widcode, "fiinc") | strpos(widcode, "diinc"))>0 & year<1962 ///
	& inlist(p,"p90","p95","p99","p99.9","p99.99","p99.999")
drop if (iso=="US") & (oldobs==0) & (length(p)-length(subinstr(p,"p","",.))==1) & (p!="pall") ///
	& !inlist(widcode,"shweal992j","ahweal992j")
drop if (iso=="US") & (oldobs==0) & inlist(widcode,"shweal992j","ahweal992j") // dropping appendix data for share and average wealth bcz they exist in psz2017 nominal & diff year of ref
drop if (iso=="US") & (oldobs==0) & (p == "p0p90") & (year<1962) & (author == "psz2017") & (inlist(widcode, "aptinc992j", "sptinc992j")) //MFP2020's p0p90 was calibrated to match psz2017
gduplicates tag iso year p widcode, gen(dupus)
drop if dupus & oldobs==0 & iso=="US"
*/
// Korea: drop old widcodes
drop if iso=="KR" & oldobs==1 & inlist(substr(widcode,2,5),"gdpro","nninc")

replace p="pall" if p=="p0p100"

// Drop old duplicated wid data
*duplicates tag iso year p widcode, gen(dup)
*drop if dup & oldobs==1

gduplicates tag iso year p widcode if iso == "CZ", gen(duplicate)
drop if duplicate == 1 & iso == "CZ" & oldobs == 1 & author != "bcg2020"
drop duplicate

keep iso year p widcode currency value 

compress
label data "Generated by add-researchers-data-real.do"
save "$work_data/add-researchers-data-real-output.dta", replace

// ----------------------------------------------------------------------------------------------------------------
// COMBINE NA AND DISTRIBUTIONAL METADATAS
// -----------------------------------------------------------------------------------------------------------------

use "$work_data/metadata-no-duplicates.dta", clear
append using "$work_data/na-metadata.dta"
drop if iso=="CN" & mi(source) & inlist(sixlet,"xlcusx","xlcyux")

merge 1:1 iso sixlet using "`meta'", nogenerate update replace 
replace method = "" if method == " "
replace method = "" if iso == "FR" & substr(sixlet, 2, 5) == "ptinc"
 
replace source = `"After 1962, [URL][URL_LINK]http://wid.world/document/t-piketty-e-saez-g-zucman-data-appendix-to-distributional-national-accounts-methods-and-estimates-for-the-united-states-2016/[/URL_LINK]"' + ///
	`"[URL_TEXT]Piketty, Thomas; Saez, Emmanuel and Zucman, Gabriel (2016). Distributional National Accounts: Methods and Estimates for the United States.[/URL_TEXT][/URL]"' + ///
    `" Before 1962, [URL][URL_LINK]https://wid.world/document/examining-the-great-leveling-new-evidence-on-midcentury-american-inequality/[/URL_LINK]"' + ///
	`"[URL_TEXT] Fisher-Post, Matthew (2020). Examining the Great Leveling: New Evidence on Midcentury American Inequality.[/URL_TEXT][/URL]"' ///
	if source == "[URL][URL_LINK]http://wid.world/document/t-piketty-e-saez-g-zucman-data-appendix-to-distributional-national-accounts-methods-and-estimates-for-the-united-states-2016/[/URL_LINK][URL_TEXT]Piketty, Thomas; Saez, Emmanuel and Zucman, Gabriel (2016). Distributional National Accounts: Methods and Estimates for the United States.[/URL_TEXT][/URL]"
 
gduplicates tag iso sixlet, gen(duplicate)
assert duplicate==0
drop duplicate

label data "Generated by add-researchers-data-real.do"
save "$work_data/add-researchers-data-real-metadata.dta", replace
