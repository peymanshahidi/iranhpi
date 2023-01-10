********************************************************************************
** title: 	  	 creates transactions sample for peymanshahidi.github.io

** by:							 Peyman Shahidi

** file name:				 	createSample.do

** version date:	  	     1399/07/17 - 2020/10/08
********************************************************************************
use "${data}/housesTransactionData/tehran", clear
format postalCode %12.0g
drop if age == . | area == . | price == . | postalCode == .
duplicates drop

keep area price age postalCode yearJalali monthJalali dayJalali dateJalali 
tostring yearJalali, replace
gen m = string(monthJalali,"%02.0f")
gen d = string(dayJalali,"%02.0f")
gen dateShamsi = yearJalali + "/" + m + "/" + d
destring yearJalali, replace


// filter outliers
replace price = price *1e-4
bysort dateJalali (price): egen priceP08  = pctile(price),p(.8)
bysort dateJalali (price): egen priceP995 = pctile(price),p(99.5)

egen areaP025  = pctile(area),p(.25)
egen areaP99  = pctile(area),p(99)

drop if price 	< priceP08 	| price > priceP995
drop if area 	> areaP99 	| area	< areaP025

drop priceP* areaP* dateJalali m d
rename dateShamsi dateJalali


// keep 7.14% random sample of data
sample 7.14
sort yearJalali monthJalali dayJalali

gen transactionId = _n
label variable price "Price per Square Meter (in Million Tomans)"
label variable yearJalali "Solar Jalali Year"
label variable monthJalali "Solar Jalali Month"
label variable dayJalali "Solar Jalali Day"
label variable dateJalali "Solar Jalali Date"
label variable transactionId "Trancaction ID"
order transactionId dateJalali yearJalali monthJalali dayJalali ///
		area price age postalCode
save "iranhpi_test.dta",replace
