********************************************************************************
** title: 	  	 BMN (Bailey, Muth, Nourse) and CS (Case, Shiller) 
**								House Price Index
**									for Iran

** by:							 Peyman Shahidi

** ado-file name:				  iranhpi.ado

** version date:	  	     1399/07/17 - 2020/10/08
********************************************************************************

********************************************************************************
** Definition:  This command calculates monthly BMN and CS house price indices
**				using the repeated transactions method for Iran's data.
**				If only 10-digit postal codes are provided, all calculations
**				will be based on 10-digit postal codes. If 6-digit postal codes 
**				are provided, calculations will be based only on 6-digit postal 
**				codes (10-digit postal codes will be converted to 6-digits).
**
**				Filters considered in order to find houses whose characteristics 
**				does not change in consecutive transations are as follows (same 
**				house in repeated transactions). In consecutive transactions
**				for the same house:
**				1. construction year must be constant. (+11 month error max)
**				2. area must be constant.
**				3. after a sale, no transaction of the same house is allowed for 
**				   a certain period. (default = 1 period)
**				4. change in house prices can not exceed a specified limit 
**				   compared to monthly average of all transcations occurred in 
**				   the data. (default = 10000 :no limit)


** -----------------------------------------------------------------------------
** Inputs:  area(numeric):			house area specified in contract
**			--------------------------------------------------------------------
**			price(numeric):		transaction price specified in contract
**			--------------------------------------------------------------------
**			age(numeric):			house age specified in contract
**			--------------------------------------------------------------------
**			postalCode(numeric):	house postal code specified in contract
**			--------------------------------------------------------------------
**			+dateShamsi(string):	Solar Jalali transaction date in xxxx/xx/xx
**									format (e.g. 1398/12/01)
**			--------------------------------------------------------------------
**			-yearJalali(numeric):	Solar Jalali year of transcation in 4-digits
**			-monthJalali(numeric):	Solar Jalali month of transcation
**			-yearJalali(numeric): 	Solar Jalali day of transcation
**			--------------------------------------------------------------------
**			freq(string character):	frequency of index calculation (m/q/y)
**			--------------------------------------------------------------------		
**			**	only one of the date formats is allowed: (+) or (-)

** -----------------------------------------------------------------------------
** Outputs: monthVariable (numeric):	month indicator of corresponding indices
**			--------------------------------------------------------------------
**			CSindex (numeric):			Case-Shiller monthly index
**			--------------------------------------------------------------------
**			BMNindex (numeric):			Bailey-Muth-Nourse monthly index
**			--------------------------------------------------------------------
**			**	(name of time indicator variable is same as the date variable  
**				 name in one-variable format and same as the month variable in 
**				 three-variables format)
**			**	(output name for desired index must be specified by the user)
**			**	(both indices are normalized to their respective 96m01 values)

** -----------------------------------------------------------------------------
** Options: period(integer):	minimum interval of no sales allowed for  
**								consecutive transactions of the the same house.
**								(default = 1 :#period)
**			--------------------------------------------------------------------
**			proportion(real):	allowed limits for ratio of consecutive sale
**								prices in repeated transactions with respect
**								to monthly average of all transactions. (e.g., 
**								proportion=5 forces price changes ratio, p2/p1, 
**								to be between 0.2 and 5 times the average price  
**								changes considering all transactions, i2/i1, in 
**								the corresponding months of 1st and 2nd sales)
**								(default = 10000 :no limit)
**			--------------------------------------------------------------------
**			combination(binary):indicates whether overlapping combinations of
**								sales in different periods should be considered.
**								(default = 1 :consider all combinations)
**			--------------------------------------------------------------------
**			compvar(numeric):	name of variable to which the proportion option 
**								will be applied. If not specified, average of 
**								monthly transactions in the current dataset  
**								will be used.
********************************************************************************

********************************************************************************
** Note 1:	Solar Jalali date of transactions must be provided in either one
**			string variable or three numeric variables in the following order:
*			Year/Month/Day

** Note 2:	Solar Jalali year of transactions must be a 4-digit number in either 
**			one-variable or three-variables format. 

** Note 3:	For the desired index to be calculated, its variable name must be
**			specified by the user.

** Note 4:	At least one index should be requested by the user. Otherwise, the 
**			following error message will be displayed:
**			"Please specify at least one index name (genCS or genBMN)"

** Note 5:	Option [proportion] is required if [compvar] option is specified. 
**			Otherwise, the following error message will be displayed:
**			"Proportion must be specified when compvar option is used"

** Note 5:	All area, price, age, and postal code variables must be in numeric 
**			formats. Otherwise, the following error message will be displayed:
**			"All area, price, age, and postal code variables must be numeric"

** Note 6:	Option [combination] indicates the weight of houses with multiple
**			transactions in the calculated index. [for a house sold in 3 
**			different periods 10, 20, and 30, combination=1 provides all pairwise  
**			transactions (10-20, 10-30, 20-30) whereas combination=0 consideres
**			only the consecutive transactions (10-20, 20-30).]
********************************************************************************

program iranhpi
	version 14.1
	syntax varlist(min=5 max=7), freq(name) [genCS(name) genBMN(name) ///
									period(integer 1) proportion(real 10000) ///
									combination(integer 1) compvar(name)]		// order: area price age postal-code [date variable(s)]

	quietly {
		set sortseed 1
		tokenize `varlist'
		local area `1'
		local price `2'
		local age `3'
		local postalCode `4'
		
		*********************** Handling Syntax Errors *************************
		******************** And Creating Main Variables ***********************
		
	// exit if neither output indices is requested
		if "`genCS'" == "" & "`genBMN'" == "" {
			disp as error
					"Please specify at least one index name (genCS or genBMN)"
			exit
		}
	
	// exit if option [combination] is wrongly specified
		if  `combination' > 1 | `combination' < 0 {
			disp as error ///
					"combination must be either 1 (all combinations) or " ///
						"0 (consecutive combinations)"
			exit
		}
	
	// exit if one of area, price, age, postalCode variables are not numeric
		ds `area' `price' `age' `postalCode', has(type string)
		di "`r(varlist)'"
		if "`r(varlist)'" != "" {
			disp as error ///
				"All of area, price, age, and postal code variables " ///
				"must be numeric"
			exit
		}
		
	// exit if comvar option is used but proportion value is not specified
		if "`compvar'" != "" & "`proportion'" == "10000" {
			disp as error "Proportion option value must be specified "
							"when compvar option is used"
			exit 
		}

	// exit if date variable does not satisfy the required format conditions
		if "`6'" == "" {
			ds `5', has(type string)
			if "`r(varlist)'" != "`5'" {
				disp as error "Date must be provided in either one string " ///
						"variable (xxxx/xx/xx) or three numeric variables "///
						"(with order: year month day)"
				exit 
			}

			local dateShamsi `5'
			tempvar yearJalali monthJalali dayJalali dateJalali
			gen `yearJalali' 	= substr(`dateShamsi',3,2) 
			gen `monthJalali'	= substr(`dateShamsi',6,2)
			gen `dayJalali' 	= substr(`dateShamsi',9,2)

			if "`freq'" == "m" {
				tempvar dateJalaliTemp
				gen `dateJalaliTemp' = substr(`dateShamsi',3,2)+"m"+`monthJalali'
				encode `dateJalaliTemp',gen(`dateJalali') 
				drop `dateJalaliTemp'
			}
			
			
			if "`freq'" == "q" {
				tempvar quarterJalali qTemp mTemp
				destring `monthJalali',gen(`mTemp')
				gen `quarterJalali' = floor( (`mTemp' - 1) / 3 ) + 1
				tostring `quarterJalali',replace
				gen `qTemp' = substr(`dateShamsi',3,2)+"q"+`quarterJalali'
				encode `qTemp',gen(`dateJalali') 
				drop `quarterJalali' `qTemp' `mTemp'
			}
			
			
			if "`freq'" == "y" {
				encode `yearJalali',gen(`dateJalali') 
			}
			
			drop `dateShamsi'
			destring `yearJalali' `monthJalali' `dayJalali',replace
			sum `dateJalali'
			replace `dateJalali' = `dateJalali' - r(min) + 1
			
		}

		else if "`6'" != "" & "`7'" == "" {
			disp as error "Date must be provided in either one string " ///
						"variable (xxxx/xx/xx) or three numeric variables "///
						"(with order: year month day)"
			exit 
		}

		else if "`6'" != "" & "`7'" != "" {
			ds `varlist', has(type string)
			if "`r(varlist)'" != "" {
				disp as error "Date must be provided in either one string " ///
						"variable (xxxx/xx/xx) or three numeric variables "///
						"(with order: year month day)"
				exit 
			}

		local yearJalali `5'
		local monthJalali `6'
		local dayJalali `7'
		
		sum `yearJalali'
		replace `yearJalali' = `yearJalali' - 1300 if r(min) > 1300

		tempvar dateJalali
		
		if "`freq'" == "m" {
			tempvar gp
			egen `gp' = concat(`yearJalali' `monthJalali'),format(%02.0f) p(m)
			encode `gp',gen(`dateJalali')
			drop `gp'
			local dateShamsi `6'
		}
		
		
		if "`freq'" == "q" {
			tempvar gp quarterJalali
			gen `quarterJalali' = floor( (`monthJalali' - 1) / 3 ) + 1
			egen `gp' = concat(`yearJalali' `quarterJalali'),format(%01.0f) p(q)
			encode `gp',gen(`dateJalali')
			drop `gp' `quarterJalali'
			local dateShamsi `6'
		}
		
		
		if "`freq'" == "y" {
			tempvar yTemp
			tostring `yearJalali',gen(`yTemp')
			encode `yTemp',gen(`dateJalali')
			drop `yTemp' 
			local dateShamsi `5'
		}


		sum `dateJalali'
		replace `dateJalali' = `dateJalali' - r(min) + 1
		}

		************************	Repeated Transactions	********************
		************************	   Data Preparation		********************

		preserve
		keep `dateJalali'
		duplicates drop 
		sort `dateJalali'
		save "date.dta",replace
		restore
	
	// calculate average price of all transactions in minimum 
	// calculation period if compvar is not specified by the user
		if `proportion' < 10000 {
			if "`compvar'" != "" {
				local avgPrice `compvar'
			} 
		
			else {
				tempvar avgPrice
				bysort `dateJalali': egen `avgPrice' = mean(`price')
			}
		}
				
	// drop outliers in terms of age and postal codes
	// postal codes containing less than 6 digits are dropped.
		drop if `age' == . | `age' >= 100
		drop if `postalCode' == . | `postalCode' < 1e+5

	// create 6-digit postal codes if at least one 6-digit postal code is given 
	// in the provided dataset. If only 10-digit postal codes are given, work  
	// with 10-digit postal codes.
		sum `postalCode'
		if r(min) < 1e+9 & r(max) >= 1e+9 {
			replace `postalCode' = floor(`postalCode' / 1e+4) ///
										if `postalCode' > 1e+9
			drop if `postalCode' >= 1e+6
		}
		sort `postalCode' `area' `yearJalali' `monthJalali' `dayJalali',stable
	
	// create construction year based on age variable (+11 months error	max)
		tempvar constYear repeat
		gen `constYear' = `yearJalali' - `age'
		bysort `postalCode' `constYear' (`area' `yearJalali' `monthJalali' `dayJalali'): ///				// observations with only 1 occurance in each postalCode-constYear
												egen `repeat' = count(`price')	// subcategories will certainly not entail any repeated transactions. 
		drop if `repeat' < 2													// Therefore, they will be deleted for a more efficient performance.
		
		duplicates drop `postalCode' `constYear' `area' ///						// multiple observations with similar transaction dates definitely 
						`yearJalali' `monthJalali' `dayJalali',force			// do not correspond to the same house. Transaction dates more than
																				
		tempvar repeat
		bysort `postalCode' `constYear' `area' (`yearJalali' `monthJalali' `dayJalali'): ///
												egen `repeat' = count(`price')	// observations with only 1 occurance in each postalCode-constYear-area
		drop if `repeat' < 2													// subcategories will certainly not entail any repeated transactions. 
		drop `repeat'															// Therefore, they will be deleted for a more efficient performance.
			
	// create mean price for observations with 
	// same characteristics and id in each month
		local meanPrice meanPrice
		bysort `postalCode' `constYear' `area' `dateJalali': ///
												egen `meanPrice' = mean(`price')
		duplicates drop `postalCode' `constYear' ///
							`area' `dateJalali' `meanPrice', force
		drop `price'
		rename `meanPrice' `price'

	// apply proportion filter if it is specified by the user
	// consider compvar if provided by the user
		local noTransactionAllowedPeriod = `period'
		
		tempvar freq numId t tprime pricePrime avgPricePrime
		bysort `postalCode' `constYear' `area' (`yearJalali' `monthJalali' `dayJalali'): gen `freq' = _N
		expand `freq'
		bysort `postalCode' `constYear' `area' `dateJalali': gen `numId' = _n
		gen `t' = `dateJalali'
		by `postalCode' `constYear' `area': gen `tprime' = `dateJalali'[`freq' * `numId']
		by `postalCode' `constYear' `area': gen `pricePrime' = `price'[`freq' * `numId']
		by `postalCode' `constYear' `area': gen `avgPricePrime' = `avgPrice'[`freq' * `numId']
		drop if `t' == `tprime'
		
		tempvar priceChange indexChange flag
		drop if `tprime' <= `t'
		if `combination' == 0 {
			bysort `postalCode' `constYear' `area' `t' (`tprime'): keep if _n == 1
		}
		keep if `tprime' - `t' >= `noTransactionAllowedPeriod'
		gen `priceChange' = log(`pricePrime') - log(`price')
		gen `indexChange' = log(`avgPricePrime') - log(`avgPrice')
		gen `flag' = 1 if abs(`priceChange' - `indexChange') < log(`proportion')
		keep if `flag' == 1
		drop `flag'
		sort `postalCode' `constYear' `area' `t' `tprime', stable
		
		tempvar transactionId
		gen `transactionId' = _n
				
		drop `yearJalali' `monthJalali' `dayJalali'	
		
		order `transactionId' `dateJalali' `t' `tprime' `priceChange'
		save "RepeatedTransactionsLong",replace

		********************** Store Returns for Merge *************************
		
		keep `transactionId' `priceChange'
		save "RepeatedTransactionsReturns",replace
	
		******************** Prepare Data for Regression ***********************
		
		use "RepeatedTransactionsLong",clear

	// creating a dummy entry to use for time variable
		local addEntry = _N + 1													// start here
		set obs `addEntry'
		sum `t'
		replace `tprime' = r(min) if _n == _N 
		sum `transactionId'
		replace `transactionId' = r(max) + 1 if _n == _N 						// end here

		xtset `transactionId' `tprime'
		keep `transactionId' `t' `tprime'
		tsfill,full

	// creating categorical variables T for regression
		tempvar T
		bysort `transactionId': egen `T' = max(`t')
		drop if `T' == . 
		bysort `transactionId': replace `T' = -1 if _n == `T'
		bysort `transactionId': replace `T' = 0 if `T' > 0
		bysort `transactionId': replace `T' = 1 if `t' != .
		drop `t'

		reshape wide `T', i(`transactionId') j(`tprime')
		save "RepeatedTransactionsWide",replace

		****************************** BMN Index *******************************
		
		merge 1:1 `transactionId' using "RepeatedTransactionsReturns",nogen

		reg `priceChange' `T'*
		matrix coeff = e(b)
		local dim = colsof(coeff)-1
		mata: st_matrix("BMN", exp(st_matrix("coeff")))
		tempvar BMN
		gen `BMN' = BMN[1,_n] in 1/`dim'
		drop if `BMN' == .
		keep `BMN'
		save "BMN",replace
		
	// exit if only BMN index is requested
		if "`genCS'" == "" {
			use "date",clear
			append using "BMN"
			replace `BMN' = `BMN'[_n+`dim']
			keep in 1/`dim'
			drop if `dateJalali' == .

			tempvar date
			decode `dateJalali', gen(`date')
				
			ds `dateJalali' `date', not 
			foreach index in `r(varlist)' {
				tempvar `index'Norm
				egen ``index'Norm' = mean(`index') if substr(`date',1,2) == "95"
				sum ``index'Norm'
				replace ``index'Norm' = r(min)
				replace `index' = `index' / ``index'Norm' * 100
			}	
			drop `date'

			tempvar date
			decode `dateJalali',gen(`date')
			encode `date',gen(`dateShamsi')
			drop `date' `dateJalali'
			rename `BMN' `genBMN'

		//clear saved working files from disk
			foreach dataset in RepeatedTransactionsLong RepeatedTransactionsWide ///
										RepeatedTransactionsReturns BMN date {
				erase "`dataset'.dta"
			}

			order `dateShamsi' `genBMN'
			exit
		}

		*************************** Case-Shiller index *************************
		
		use "RepeatedTransactionsWide",clear
		merge 1:1 `transactionId' using "RepeatedTransactionsReturns",nogen
		
	// calculate weights for CS index regression using BMN residuals
		tempvar bmnResSquared
		reg `priceChange' `T'*
		predict `bmnResSquared', residuals
		replace `bmnResSquared' = `bmnResSquared'^2
		keep `transactionId' `bmnResSquared'
		save "RepeatedTransactionsResiduals", replace

		
		use "RepeatedTransactionsLong",clear
		keep `transactionId' `dateJalali' `t' `tprime' `priceChange'
		merge 1:1 `transactionId' using "RepeatedTransactionsResiduals",nogen
		tempvar tdiff weight
		gen `tdiff' = `tprime' - `t' 
		reg `bmnResSquared' `tdiff'
		predict `weight'
		replace `weight' = sqrt(`weight')													
		keep `transactionId' `priceChange' `weight'
		save "RepeatedTransactionsReturnsWeighted",replace
		
	// recalculate BMN coefficients with CS weights
		use "RepeatedTransactionsWide",clear
		merge 1:1 `transactionId' using "RepeatedTransactionsReturnsWeighted",nogen
		
	// divide all variables by corresponding weights for WLS regression of CS
		ds `transactionId' `weight', not 
		foreach var in `r(varlist)' {
			replace `var' = `var' / `weight'
		}
		reg `priceChange' `T'* 
		matrix coeff = e(b)
		local dim = colsof(coeff)-1
		mata: st_matrix("CS", exp(st_matrix("coeff")))
		tempvar CS
		gen `CS' = CS[1,_n] in 1/`dim'
		drop if `CS' == .
		keep `CS'
		
	// merge results of CS and BMN indices
		append using "BMN"
		replace `BMN' = `BMN'[_n+`dim'] in 1/`dim'
		keep if _n <= `dim'
		save "CaseShiller",replace

		use "date",clear
		append using "CaseShiller"
		replace `CS' = `CS'[_n+`dim']
		replace `BMN' = `BMN'[_n+`dim']
		keep in 1/`dim'
		drop if `dateJalali' == .
		
	// normalize indices
		tempvar date
		decode `dateJalali', gen(`date')
				
		ds `dateJalali' `date', not 
		foreach index in `r(varlist)' {
			tempvar `index'Norm
			egen ``index'Norm' = mean(`index') if substr(`date',1,2) == "95"
			sum ``index'Norm'
			replace ``index'Norm' = r(min)
			replace `index' = `index' / ``index'Norm' * 100
		}	
		drop `date'

		tempvar date
		decode `dateJalali',gen(`date')
		encode `date',gen(`dateShamsi')
		drop `date' `dateJalali'
		
		if "`genCS'" != "" {
			rename `CS' `genCS'
		}
		if "`genBMN'" != "" {
				rename `BMN' `genBMN'
		}

	//clear saved files from disk
		foreach dataset in RepeatedTransactionsLong RepeatedTransactionsReturns ///
					RepeatedTransactionsResiduals RepeatedTransactionsReturnsWeighted ///
					RepeatedTransactionsWide BMN CaseShiller date {
			erase "`dataset'.dta"
		}

		order `dateShamsi' `genCS' `genBMN'
	}
	
end
