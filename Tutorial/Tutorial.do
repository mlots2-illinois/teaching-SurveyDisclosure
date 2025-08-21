********************************************************************************
* DISCLOSURE AVOIDANCE TUTORIAL
* Using the disclosure_check package with Baylor Religion Survey Wave V (2017)
* 
* Purpose: 	Learn how to identify and prevent disclosure risks in survey data
*
* Author: 	Michael Lotspeich-Yadao, mlots2@illinois.edu
*			Research Assistant Professor
*			College of Applied Health Sciences
*			University of Illinois Urbana-Champaign
*			mlots2@illinois.edu
*
* Date: 	13AUG2025
********************************************************************************

clear all
set more off

* Setup: Tell Stata where your disclosure_check files are located
* USERS: Update this path to where you saved the disclosure_check files
global disclosure_path "/Users/michael_lotspeich_ii/Desktop/SurveyDisclosure"
adopath + "${disclosure_path}"

********************************************************************************
* SECTION 1: INTRODUCTION TO DISCLOSURE RISK
********************************************************************************

/*
WHAT IS DISCLOSURE RISK?
-------------------------
Disclosure risk occurs when individual respondents can be identified in your data,
even without names or IDs. This typically happens when someone has a unique or 
rare combination of characteristics.

Example: If you report that there is only 1 Buddhist person over age 80 in your
sample who has a PhD, that person might be identifiable if someone knows such a
person exists in your sampling frame.
*/

********************************************************************************
* SECTION 2: LOAD AND EXPLORE THE DATA
********************************************************************************

* Load the dataset (adjust path as needed)
cd "/Users/michael_lotspeich_ii/Desktop/SurveyDisclosure/Tutorial"
use "BaylorReligionSurvey_W5_Instructional_Dataset.dta", clear

* Basic information about the dataset
describe, short
display _newline
display "Dataset contains " _N " respondents"

rename (age Q77 race I_EDUC Q95 I_RELIGION SAMPLE_FIPS_CODE) ///
       (new_age new_gender new_race new_educ new_income new_religion new_fips)

display _newline
display "Key demographic variables in BRS:"
display "  - new_age: Respondent age"
display "  - new_gender: Gender (Male/Female)"  
display "  - new_race: Racial/ethnic categories"
display "  - new_educ: Education level"
display "  - new_income: Income categories"
display "  - new_religion: Religious tradition"
display "  - new_fips: FIPS county code"
display "  - new_timezone: Timezone of respondent"

sum new_age new_fips  // summary stats for continuous variables
tab1 new_gender new_race new_educ new_income new_religion  // frequencies for categorical

********************************************************************************
* SECTION 3: ESTABLISH YOUR FINAL 'SAMPLE' OR MODEL
********************************************************************************

* Our research question is, what demographic characteristics motivate someone to be religious?
	gen religious_binary = (new_religion != 6) if !missing(new_religion)
	label define religious_binary 0 "No religion" 1 "Has religion"
	label values religious_binary religious_binary

logistic religious_binary new_age i.new_gender ib(1).new_race ib(2).new_educ ib(5).new_income

* Now that we've picked our model, we need to create a flag for observations used in the logistic model.
gen model_sample = !missing(religious_binary) & !missing(new_age) & !missing(new_gender) & !missing(new_race) & !missing(new_educ) & !missing(new_income)
	label variable model_sample "Included in logistic regression model"
	label define model_sample 0 "Not in model sample" 1 "In model sample"
	label values model_sample model_sample

********************************************************************************
* SECTION 4: BASIC DISCLOSURE CHECK
********************************************************************************

display _newline(3)
display "{hline 80}"
display "SECTION 3: BASIC DISCLOSURE CHECK"
display "{hline 80}"
display _newline
display "Let's check basic demographics for disclosure risk"
display _newline

* Run basic disclosure check on key demographics
disclosure_check new_gender new_race new_educ, samplename(model_sample) threshold(3) ///
    output(tutorial_basic_check.xlsx) replace detail

display _newline
display "INTERPRETATION:"
display "{hline 60}"
display "- Look for any cells marked 'SUPPRESS'"
display "- These have 1-2 observations and could identify individuals"
display "- The Excel file contains detailed results"
display _newline

********************************************************************************
* SECTION 5: CHECKING RELIGIOUS MINORITIES
********************************************************************************

display _newline(3)
display "Religious minorities are often at high disclosure risk"
display _newline

* First, let's see the distribution of religions
tab new_religion

* Check disclosure risk for religion crossed with demographics
disclosure_check new_gender new_race new_educ new_religion, sample(model_sample) threshold(3) ///
    output(tutorial_religion_check.xlsx) replace detail

********************************************************************************
* SECTION 5: CONTINUOUS VARIABLES AND AGE
********************************************************************************

display _newline(3)
display "Continuous variables like AGE need special handling if tabulations released"
display _newline

disclosure_check new_age new_gender new_race, sample(model_sample) threshold(3) ///
    output(tutorial_age_check.xlsx) replace detail

* You might want to create your own age categories
capture drop age_group
gen age_group = .
replace age_group = 1 if new_age >= 18 & new_age <= 29
replace age_group = 2 if new_age >= 30 & new_age <= 44  
replace age_group = 3 if new_age >= 45 & new_age <= 64
replace age_group = 4 if new_age >= 65 & new_age != .
label define age_lbl 1 "18-29" 2 "30-44" 3 "45-64" 4 "65+"
label values age_group age_lbl

disclosure_check age_group new_gender new_race, sample(model_sample) threshold(3) ///
    output(tutorial_age_check_2.xlsx) replace detail

display "Created age groups: 18-29, 30-44, 45-64, 65+"
tab age_group

********************************************************************************
* SECTION 6: CREATING AND CHECKING SUBSAMPLES
********************************************************************************

display _newline(3)
display "Often we analyze subgroups, which creates implicit samples"
display _newline

* Create a subsample: Religious respondents only (within model_sample=1)
capture drop religious
gen religious = 0
	replace religious = 1 if model_sample == 1 & new_religion != 6 & !missing(new_religion)
	replace religious = . if model_sample != 1  // Set to missing for those not in model_sample
	
label define rel_lbl 0 "No religion" 1 "Religious"
label values religious rel_lbl
label var religious "Religious respondents (subsample of model_sample=1)"

display "Created subsample: Religious respondents only (within model_sample=1)"
tab religious, missing
tab religious model_sample, missing

* Check the religious subsample
preserve
keep if religious == 1  // Keep only religious respondents from model_sample
disclosure_check new_race new_gender new_educ, sample(religious) threshold(3) output(tutorial_religious_subsample.xlsx) replace detail
restore

display _newline
display "Now check for implicit sample risk..."
display _newline

* Check implicit sample (non-religious within model_sample)
* Create a non-religious indicator for comparison
gen non_religious = 0
replace non_religious = 1 if model_sample == 1 & new_religion == 6 & !missing(new_religion)
replace non_religious = . if model_sample != 1

check_implicit, sample1(model_sample) sample2(religious) ///
    varlist(new_race new_gender new_educ) threshold(3)
	
check_implicit, sample1(model_sample) sample2(non_religious) ///
    varlist(new_race new_gender new_educ) threshold(3)

display _newline
display "IMPORTANT: When you report on subsamples, you must also"
display "check the implicit sample (those excluded) for disclosure risk!"
display _newline

* Clean up temporary variables
drop non_religious

********************************************************************************
* SECTION 7: SOLUTIONS FOR DISCLOSURE RISK
********************************************************************************

display _newline(3)
display "When you find cells below threshold, you can:"
display _newline
display "1. SUPPRESS: Replace small cells with 'suppressed' or missing"
display _newline
display "2. COLLAPSE CATEGORIES: Combine similar groups"
display _newline

* Example: Collapse detailed race categories
gen race_collapsed = .
replace race_collapsed = 1 if new_race == 1  // White
replace race_collapsed = 2 if new_race == 2  // Black/African American
replace race_collapsed = 3 if new_race == 3  // Asian
replace race_collapsed = 3 if new_race >= 4 & new_race != .  // Other/Multiple (combines Asian, Native American, Other, Multiple)
label define race_coll_lbl 1 "White" 2 "Black/African American" ///
    3 "Something else"
label values race_collapsed race_coll_lbl

display "Original race categories:"
tab new_race
display _newline
display "Collapsed race categories:"
tab race_collapsed

* Check if collapsing helped
disclosure_check race_collapsed new_gender new_educ, sample(model_sample) threshold(3) ///
    output(tutorial_collapsed_check.xlsx) replace detail

display _newline
display "3. TOP/BOTTOM CODING: For continuous variables, group extremes"
display _newline

* Example: Top-code age
gen age_topcoded = new_age
replace age_topcoded = 80 if new_age >= 80 & new_age != .
label var age_topcoded "Age (top-coded at 80)"

display "4. REPORT RANGES: Instead of exact values"
display "   Example: 'fewer than 5' instead of exact count"
display _newline

********************************************************************************
* SECTION 8: BEST PRACTICES AND FINAL CHECKS
********************************************************************************

display _newline(3)
display "{hline 80}"
display "SECTION 8: BEST PRACTICES CHECKLIST"
display "{hline 80}"
display _newline

display "BEFORE RELEASING DATA OR RESULTS:"
display _newline
display "☐ 1. Check all variables that will be reported"
display _newline
display "☐ 2. Check all relevant cross-tabulations"
display _newline
display "☐ 3. Consider implicit samples from any subsetting"
display _newline
display "☐ 4. Use threshold of 3 minimum (higher for sensitive data)"
display _newline
display "☐ 5. Document all suppression/collapsing decisions"
display _newline
display "☐ 6. Consider if combinations of published tables could"
display "     be used to deduce suppressed values"
display _newline
display "☐ 7. When in doubt, aggregate or suppress"
display _newline

********************************************************************************
* CONCLUSION
********************************************************************************

display _newline(3)
display "{hline 80}"
display "TUTORIAL COMPLETE!"
display "{hline 80}"
display _newline
display "You have learned how to:"
display "  ✓ Identify disclosure risks in survey data"
display "  ✓ Use disclosure_check to systematically review variables"
display "  ✓ Handle continuous and categorical variables"
display "  ✓ Check cross-tabulations for risk"
display "  ✓ Work with subsamples and implicit samples"
display "  ✓ Implement solutions for small cells"
display "  ✓ Document your disclosure avoidance process"
display _newline
display "Files created in this tutorial:"
display "  - tutorial_*.xlsx (various disclosure check results)"
display "  - FINAL_disclosure_report.xlsx (comprehensive final check)"
display "  - disclosure_decisions_log.txt (documentation)"
display _newline
display "Thank you for completing the disclosure avoidance tutorial!"
display "{hline 80}"

********************************************************************************
* EXERCISES FOR PRACTICE
********************************************************************************

/* 
PRACTICE EXERCISES:

1. Check disclosure risk for religious attendance (ATTEND) by demographics
   Hint: disclosure_check ATTEND GENDER RACE, sample(exercise1) threshold(3)

2. Create a subsample of college-educated respondents and check for 
   implicit sample risks

3. Find the combination of variables that creates the smallest cell in 
   the dataset and determine how to handle it

4. Create a publication-ready table of religious affiliation by region
   that properly handles all disclosure risks

5. Write a do-file that automates disclosure checking for a standard
   set of demographic tables you plan to publish
*/

********************************************************************************
* END OF TUTORIAL
********************************************************************************
