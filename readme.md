# Instructions for Using "iranhpi" Stata Command 
### Author: Peyman Shahidi
#### Last update: Jan 14, 2023

The "iranhpi" command calculates the Bailey-Muth-Nourse (1963) and Case-Shiller (1987) house price indices for Iran. This command has been developed to be compatible with the publicly available data published by the Ministry of Roads and Urban Development (MRUD).

<br>

To test the "iranhpi" command follow these steps:
1. Move "iranhpi.ado" to your personal adopath directory (or adjust the "main.do" script to specify your personal settings).
2. Run the "test_iranhpi.do" script. The code provided in this script allows you to test different options of the command.

P.S.: the "createSample.do" script creates a random sample for Tehran from MRUD's public transactions dataset. The data file "iranhpi_test.dta" is the output generated by "createSample.do". You may run "test_iranhpi.do" directly without generating the random sample yourself.

<br>

For questions, comments, or feedbacks please contact me at: shahidi.peyman96@gmail.com 

<br>

#### References:
1. Bailey, M. J., Muth, R. F., & Nourse, H. O. (1963). A Regression Method for Real Estate Price Index Construction. *Journal of the American Statistical Association*, 58(304), 933-942.
2. Case, K.E., Shiller, R.J. (1987). Prices of Single-family Homes Since 1970: New Indexes for Four Cities. *New England Economic Review*. Sept./Oct. 45-56.




Let's say I updated some of the stuff I'd written here. Let's see how I can work with this.