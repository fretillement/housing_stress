********************************************
/*This program does the following:
1. Insheet full IPUMS individual-level dataset by year
2. Clean and reformat variable as needed
3. Identify measures of hh stress on the hh-level
4. Aggregate these measures by msa 
*/ 
*********************************************
**Note: all aggregates at the MSA LEVEL ONLY are weighted by hhwt.** 

forvalues y = 2007(1)2011 {	
	insheet using "M:/IPUMS/hhdata/`y'.csv", clear

***************************************
/*Household-level critera and summing*/	
***************************************
*Prep: clean up string vars
*Age
	*gen agestring = substr("`:type age'" , 1, 3) == "str"
	replace age = "90" if age == "90 (90+ in 1980 and 1990)"
	replace age = "1" if age ==  "Less than 1 year old"
	destring age, replace
	gen crit_agerange = inrange(age, 18, 24) 
	*rename age1 crit_agerange 
	label var crit_agerange "18-24 years old" 
*Subfamilies 
	replace nsubfam = "1" if nsubfam == "1 subfamily"
	replace nsubfam = "2" if nsubfam == "2 subfamilies" 
	replace nsubfam = "0" if nsubfam == "No subfamilies or N/A (GQ/vacant unit)"
	destring nsubfam, replace
	
*1. Identify additional adults in the survey
	gen crit_marital = !inlist(related, "Spouse", "Head/Householder", "Unmarried partner")
	gen crit_age24 = (age > 24) 
	gen crit_age35 = (age >= 35) 
	gen crit_sch = (schltype == "Not enrolled") 
	gen addl = (crit_age24 & crit_marital) | (crit_agerange & crit_sch)
	gen addl_over35 = crit_age35 & crit_marital
	
*2. Count the number of additional adults in each household 
	by serial, sort: egen num_addl = total(addl == 1) 
	by serial, sort: egen num_addl35 = total(addl_over35 == 1) 
	
*3. Identify shared households (i.e. households with at least 1 additional adult)
	by serial, sort: gen sharedhh = (num_addl > 0) 
	by serial, sort: gen sharedhh35 = (num_addl35 > 0) 
	
*Identify owner/ renter households
	gen owned = inlist(ownershpd, "Owned free and clear", "Owned with mortgage or loan") 
	gen rented = !owned
	*gen rented = (ownershpd == "With cash rent")

*Identify SF/ MF households 
	gen singlefam = inlist(unitsstr, "1-family house, detached", "Mobile home or trailer")
	gen multifam = !singlefam
	*gen multifam = !inlist(unitsstr, "Boat, tent, van, other", "Mobile home or trailer", "1-family house, detached") 
	
*4. Keep only the household head level observations
	drop if relate != "Head/Householder"

*************************************
/*MSA-level manipulation and totals*/ 	
*************************************
* Count the total number of households in each MSA, and divide into buckets 
	by metaread, sort: egen numhh = sum(hhwt)
	by metaread, sort: egen numsfr = sum((rented*singlefam)*hhwt)	
	by metaread, sort: egen numsfo = sum((owned*singlefam)*hhwt) 
	by metaread, sort: egen nummfr = sum((rented*multifam)*hhwt) 
	by metaread, sort: egen nummfo = sum((owned*multifam)*hhwt) 
	
* Count the number of households with additional adults in each MSA
	by metaread, sort: egen numhh_shared = sum((sharedhh)*hhwt) 
	by metaread, sort: egen numsfr_shared = sum((rented*singlefam*sharedhh)*hhwt)
	by metaread, sort: egen numsfo_shared = sum((owned*singlefam*sharedhh)*hhwt) 
	by metaread, sort: egen nummfr_shared = sum((rented*multifam*sharedhh)*hhwt) 
	by metaread, sort: egen nummfo_shared = sum((owned*multifam*sharedhh)*hhwt)		
	
* Count the number of households with additional adults and subfamily 
	by metaread, sort: egen numhh_subfam = sum((nsubfam > 0)*hhwt) 
	by metaread, sort: egen numsfr_subfam = sum((rented*singlefam*(nsubfam >0))*hhwt)
	by metaread, sort: egen numsfo_subfam = sum((owned*singlefam*(nsubfam >0))*hhwt)
	by metaread, sort: egen nummfr_subfam = sum((rented*multifam*(nsubfam >0))*hhwt)
	by metaread, sort: egen nummfo_subfam = sum((owned*multifam*(nsubfam >0))*hhwt)	

* Count the number of households with additional adults over age 35
	by metaread, sort: egen numhh_addl35 = sum((sharedhh35)*hhwt) 
	by metaread, sort: egen numsfr_addl35 = sum((rented*singlefam*sharedhh35)*hhwt)
	by metaread, sort: egen numsfo_addl35 = sum((owned*singlefam*sharedhh35)*hhwt)
	by metaread, sort: egen nummfr_addl35 = sum((rented*multifam*sharedhh35)*hhwt)
	by metaread, sort: egen nummfo_addl35 = sum((owned*multifam*sharedhh35)*hhwt)	
	
* Keep only msa-level obs
duplicates drop metaread, force		
	
*5. Outsheet 
	local varlist metaread year numhh_addl35 numsfr_addl35 numsfo_addl35 nummfr_addl35 nummfo_addl35 numhh_subfam numsfr_subfam numsfo_subfam nummfr_subfam nummfo_subfam numhh numsfr numsfo nummfr nummfo numhh_shared numsfr_shared numsfo_shared nummfr_shared nummfo_shared
	export excel `varlist' using "M:/IPUMS/hhstress_data/hhstress_measures_v2.xls", sheet("`y'") firstrow(variables)
	}	
exit, STATA clear 
