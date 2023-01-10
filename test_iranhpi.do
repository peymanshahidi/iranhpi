********************************************************************************
** title: 	  test run for iranhpi command using a random sample of Tehran's
**							house transacitions data

** by:							 Peyman Shahidi

** file name:				 	test_iranhpi.do

** version date:	  	     1399/07/17 - 2020/10/08
********************************************************************************
clear all
set scheme s1color

******************************** Monthly Index *********************************
use "iranhpi_test.dta",clear
// create avgerage month price variable
bysort dateJalali: egen priceAvgMonth = mean(price)
label variable priceAvgMonth "Average Transaction Price in Month"

cap program drop iranhpi
**iranhpi area price age postalCode yearJalali monthJalali dayJalali, freq(m) ///
**			genCS(CS) genBMN(BMN) combination(0) period(1) proportion(10) compvar(priceAvgMonth)
iranhpi area price age postalCode dateJalali, freq(m) genCS(CS) genBMN(BMN) ///
		combination(0) period(1) proportion(10)

// plot Case-Shiller index
quietly sum dateJalali
scalar length = `r(max)'
quietly sum CS
scalar index_max = `r(max)'

gr tw connected BMN CS dateJalali ,msize(vsmall vsmall) msymbol(O O) lp(. .) ///
xlabel(1(12)`=scalar(length)',value labsize(small) grid glw(.2) glp(dash)) xtitle("") ///
ytitle("Month Price Index (1395 = 100)") ylabel(50(50)`=scalar(index_max)',angle(0) ///
grid glw(.2) glp(dash)) ymtick(50(50)`=scalar(index_max)',grid glw(.2) glp(dash)) ///
title("Tehran's House Price Indices") ///
legend(order(1 "BMN" 2 "Case-Shiller" ) cols(1) ring(0) position(11) size(vsmall))

******************************** Quartely Index *********************************
use "iranhpi_test.dta",clear
cap program drop iranhpi
iranhpi area price age postalCode dateJalali, freq(q) genCS(CS) genBMN(BMN) ///
		combination(0) period(1) proportion(10)

// plot Case-Shiller index
quietly sum dateJalali
scalar length = `r(max)'
quietly sum CS
scalar index_max = `r(max)'

gr tw connected BMN CS dateJalali ,msize(vsmall vsmall) msymbol(O O) lp(. .) ///
xlabel(1(4)`=scalar(length)',value labsize(small) grid glw(.2) glp(dash)) xtitle("") ///
ytitle("Quarter Price Index (1395 = 100)") ylabel(50(50)`=scalar(index_max)',angle(0) ///
grid glw(.2) glp(dash)) ymtick(50(50)`=scalar(index_max)',grid glw(.2) glp(dash)) ///
title("Tehran's Quarterly House Price Indices") ///
legend(order(1 "BMN" 2 "Case-Shiller" ) cols(1) ring(0) position(11) size(vsmall))

******************************** Yearly Index *********************************
use "iranhpi_test.dta",clear
cap program drop iranhpi
iranhpi area price age postalCode dateJalali, freq(y) genCS(CS) genBMN(BMN) ///
		combination(0) period(1) proportion(10)

// plot Case-Shiller index
quietly sum dateJalali
scalar length = `r(max)'
quietly sum CS
scalar index_max = `r(max)'

gr tw connected BMN CS dateJalali ,msize(vsmall vsmall) msymbol(O O) lp(. .) ///
xlabel(1(1)`=scalar(length)',value labsize(small) grid glw(.2) glp(dash)) xtitle("") ///
ytitle("Year Price Index (1395 = 100)") ylabel(50(50)`=scalar(index_max)',angle(0) ///
grid glw(.2) glp(dash)) ymtick(50(50)`=scalar(index_max)',grid glw(.2) glp(dash)) ///
title("Tehran's Yearly House Price Indices") ///
legend(order(1 "BMN" 2 "Case-Shiller" ) cols(1) ring(0) position(11) size(vsmall))
