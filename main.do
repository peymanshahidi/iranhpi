********************************************************************************
* Title:		main.do
* Description:	
* Author:  		Peyman Shahidi
* Date:			2020-10-10
				
********************************************************************************

* Peyman's Laptop
global root "/Users/Peyman/Dropbox/Stata Codes/iranhpi"
global data "/Users/Peyman/Documents/raw_housing_data"

cd "$root"
adopath + "${root}" 

*===============================================================================
*do createSample // for creating random sample from main dataset
do test_iranhpi
