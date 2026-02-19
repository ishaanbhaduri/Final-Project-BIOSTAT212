* purpose: import, merge, clean, analyze, and export analysis of the 2017-2018 NHANES Data regarding Food, Sleep, Demographics, and Hypertension
* Hypertension STATA Project
* initially created by Ishaan Bhaduri 8/27/2025
* input: BPX_J_2017-2018_Feb2020.xpt, DEMO_J_2017-2018_Feb2020.xpt, FSQ_J_2017-2018_Feb2022.xpt, SLQ_J_2017-2018_Feb2020.xpt
* output: Hypertension_Analysis.docx, Hypertension_Prevalence_Figure.png, NHANES_2017-2018_cleaned.dta, NHANES_2017-2018_merged_dropped.dta, NHANES_2017-2018_merged.dta, NHANES2017-2018merge_clean_analysis.smcl, NHANES2017-2018merge_clean_analysis.smcl

cls
capture log close
clear
version 19.5

//-------------------------------------------------------------------------------------------------
// SECTION 1: SAVE DATA FROM .XPT FILES
//-------------------------------------------------------------------------------------------------

//Go to https://wwwn.cdc.gov/nchs/nhanes/continuousnhanes/default.aspx?BeginYear=2017 and download the necessary data
//Download Demographics Data
//Download Blood Pressure data from Examination
//Download Food Security and Sleep Disorders data from Questionaire Data
//Rename the .xpt files to have more clear names

/*Set Working Directory*/
cd "/Users/ishaanbhaduri/Library/Mobile Documents/com~apple~CloudDocs/03 Research/Stata/BIOSTAT 212/Lecture 7 BIOSTAT 212/Homework"

/*Set Log File*/
log using "output/NHANES2017-2018merge_clean_analysis.smcl", replace

/*Convert raw data into STATA .dta files*/

//Import Blood Pressure raw data
import sasxport5 "data/BPX_J_2017-2018_Feb2020.xpt", clear
save "data/BPX_J_2017-2018_Feb2020.dta", replace

//Import Demographics raw data
clear
import sasxport5 "data/DEMO_J_2017-2018_Feb2020.xpt", clear
save "data/DEMO_J_2017-2018_Feb2020.dta", replace

//Import Food Security raw data
clear
import sasxport5 "data/FSQ_J_2017-2018_Feb2022.xpt", clear
save "data/FSQ_J_2017-2018_Feb2022.dta", replace

//Import Sleep Disorders raw data
clear
import sasxport5 "data/SLQ_J_2017-2018_Feb2020.xpt", clear
save "data/SLQ_J_2017-2018_Feb2020.dta", replace

clear

// -------------------------------------------------------------------------------------------------
// SECTION 2: MERGING DATA
// -------------------------------------------------------------------------------------------------

/*Merge all four .dta files by the `seqn` identifier*/

//Load the first dataset as the master file
use "data/DEMO_J_2017-2018_Feb2020.dta", clear
sort seqn

//Merge the second dataset (Blood Pressure)
merge 1:1 seqn using "data/BPX_J_2017-2018_Feb2020.dta"
tabulate _merge
drop _merge

//Merge the third dataset (Food Security)
sort seqn
merge 1:1 seqn using "data/FSQ_J_2017-2018_Feb2022.dta"
tabulate _merge
drop _merge

//Merge the fourth dataset (Sleep Disorders)
sort seqn
merge 1:1 seqn using "data/SLQ_J_2017-2018_Feb2020.dta"
tabulate _merge
drop _merge

//Save the final merged file
save "output/NHANES_2017-2018_merged.dta", replace

//-------------------------------------------------------------------------------------------------
// SECTION 3: DATA CLEANING AND VARIABLE CREATION
// -------------------------------------------------------------------------------------------------

/*Keep only the variables needed for the final analysis*/
keep seqn fsdad sld012 slq120 ridageyr riagendr ridreth3 indhhin2 dmdhhsiz dmdeduc2 bpxsy1 bpxdi1 bpxsy2 bpxdi2 bpxsy3 bpxdi3 wtint2yr sdmvpsu sdmvstra

//Save the dropped file
save "output/NHANES_2017-2018_merged_dropped.dta", replace

/*Rename and relabel variables for clarity*/
rename ridageyr age
rename riagendr gender
rename dmdeduc2 education
rename ridreth3 race
rename dmdhhsiz householdsize
rename indhhin2 householdincome
rename sld012 sleephours
rename slq120 sleepyday
rename fsdad foodsecurity

// Drop individuals too young for hypertension analysis
drop if age < 18

/*Label and recode categorical variables: gender, race, education, household income, food security, and day sleepiness*/

// Label and recode gender
label define gender_labels 1 "Male" 2 "Female"
label values gender gender_labels
tabulate gender

// Label and recode race
label define race_labels 1 "Mexican American" 2 "Other Hispanic" 3 "Non-Hispanic White" 4 "Non-Hispanic Black" 6 "Non-Hispanic Asian" 7 "Other Race"
label values race race_labels
tabulate race

// Label and recode education level
label define education_labels 1 "Less than 9th grade" 2 "9-11th grade" 3 "High school graduate" 4 "Some college or AA" 5 "College graduate or above"
label values education education_labels
recode education (7 9 = .)
tabulate education

// Label and recode household income
label define householdincome_labels 1 "$ 0-4,999" 2 "$ 5,000-9,999" 3 "$10,000-14,999" 4 "$15,000-19,999" 5 "$20,000-24,999" 6 "$25,000-34,999" 7 "$35,000-44,999" 8 "$45,000-54,999" 9 "$55,000-64,999" 10 "$65,000-74,999" 12 "$20,000 and Over" 13 "Under $20,000" 14 "$75,000-99,999" 15 "$100,000 and Over"
label values householdincome householdincome_labels
recode householdincome (77 99 = .)
tabulate householdincome

// Label and recode food security
label define foodsecurity_labels 1 "Full food security" 2 "Marginal food security" 3 "Low food security" 4 "Very low food security"
label values foodsecurity foodsecurity_labels
tabulate foodsecurity

// Label and recode day sleepiness
label define sleepyday_labels 0 "Never" 1 "Rarely" 2 "Sometimes" 3 "Often" 4 "Almost always"
label values sleepyday sleepyday_labels
recode sleepyday (7 9 = .)
tabulate sleepyday

// Create derived outcome and exposure variables

// Calculate the mean of the three available blood pressure readings
egen mean_sys_bp = rowmean(bpxsy1 bpxsy2 bpxsy3)
egen mean_dia_bp = rowmean(bpxdi1 bpxdi2 bpxdi3)

// Create the hypertension variable based on AHA 2017 guidelines
gen hypertension = 0
replace hypertension = 1 if mean_sys_bp >= 130 | mean_dia_bp >= 80
label variable hypertension "Hypertension Status"
label define hypertension_labels 0 "No Hypertension" 1 "Hypertension"
label values hypertension hypertension_labels
tabulate hypertension

// Create a binary variable for poor sleep (Sometimes, Often, or Almost Always)
gen poor_sleep = 0
replace poor_sleep = 1 if sleepyday >= 2 & sleepyday <= 4
label variable poor_sleep "Poor Sleep"
label define poor_sleep_labels 0 "No Poor Sleep" 1 "Poor Sleep"
label values poor_sleep poor_sleep_labels
tabulate poor_sleep

// Create a binary variable for food insecurity (Marginal, Low, or Very Low food security)
gen food_insecurity = 0
replace food_insecurity = 1 if foodsecurity >= 2 & foodsecurity <= 4
label variable food_insecurity "Food Insecurity"
label define food_insecurity_labels 0 "No Food Insecurity" 1 "Food Insecurity"
label values food_insecurity food_insecurity_labels
tabulate food_insecurity

// Create the combined exposure variable with four clear categories
gen exposure = .
replace exposure = 1 if food_insecurity == 0 & poor_sleep == 0 // Neither
replace exposure = 2 if food_insecurity == 1 & poor_sleep == 0 // Food Insecurity Only
replace exposure = 3 if food_insecurity == 0 & poor_sleep == 1 // Poor Sleep Only
replace exposure = 4 if food_insecurity == 1 & poor_sleep == 1 // Both
label variable exposure "Combined Exposure to Food Insecurity and Poor Sleep"
label define exposure_labels 1 "Neither" 2 "Food Insecurity Only" 3 "Poor Sleep Only" 4 "Both"
label values exposure exposure_labels
tabulate exposure

// Save cleaned and merged data
save "output/NHANES_2017-2018_cleaned.dta", replace

/// -------------------------------------------------------------------------------------------------
// SECTION 4: MAIN ANALYSIS & OUTPUT GENERATION
// -------------------------------------------------------------------------------------------------

// Set the survey design for correct variance estimation
svyset [pweight=wtint2yr], psu(sdmvpsu) strata(sdmvstra)

// Table 1: Logistic Regression Results
// The purpose is to show the independent association of each exposure group with hypertension, after accounting for demographic confounders.
collect clear
// Run the survey logistic regression and collect the results
collect: svy: logit hypertension i.exposure i.gender i.race i.education householdincome age, or

// The intercept represents the odds of hypertension when all other variables in the model are at their reference level. It corresponds to a male, Non-Hispanic White, college graduate or above with full food security and no poor sleep.

// Format the collected table for a clean output
collect style showbase off // Hide the base levels of categorical variables
collect style cell _r_b, nformat(%5.2f) // Format odds ratios to 2 decimal places
collect style cell _r_ci, nformat(%5.2f) cidelimiter(,) // Format CIs in parentheses with a comma
collect style cell _r_p, nformat(%5.3f) // Format p-value to 3 decimal places
collect style cell _r_z, nformat(%5.2f) // Format Z-statistic to 2 decimal places
collect style cell _r_se, nformat(%5.4f) // Format Standard Error to 4 decimal places

// Create a single column for OR and CI to remove the vertical gap
collect layout (colname) (result[_r_b _r_ci])

// Create shorter labels for the variables in the table
collect label levels colname "1.exposure" "Exposure"
collect label levels colname "2.gender" "Gender"
collect label levels colname "3.race" "Race"
collect label levels colname "4.education" "Education"
collect label levels colname "householdincome" "Hshld Inc"
collect label levels colname "age" "Age"

// Rename the result columns with user-friendly names
collect label levels result _r_b "OR", modify
collect label levels result _r_p "p-value", modify
collect label levels result _r_z "Z-stat", modify
collect label levels result _r_se "Std. Err.", modify

// Explicitly define the table layout to avoid the "layout does not identify any items" error
// Specify exactly what we want to see: the odds ratio, confidence interval, p-value, Z-stat, and standard error
collect layout (colname) (result[_r_b _r_ci _r_p _r_z _r_se])

// Add a title and note for the table
collect title "Table 1. Logistic Regression Model of the Odds of Hypertension"
collect notes 1: "OR: Odds Ratio; 95% CI: 95% Confidence Interval. Reference groups are: full food security, no poor sleep, male, Non-Hispanic White, and college graduate or above."

// Export Table 1 as a separate Excel spreadsheet
collect export "output/Table1.xlsx", replace

// Figure 1: Prevalence of Hypertension by Exposure Group
// The purpose is to visually represent the prevalence of hypertension across the four exposure groups, with confidence intervals.
svy: proportion hypertension, over(exposure)

// Store the results in a matrix to prepare for graphing
matrix prop = e(b)
matrix V = e(V)
matrix list prop
matrix list V

// Create a temporary dataset from the matrix for graphing purposes
clear
set obs 4
gen group = _n
gen prop = prop[1, _n]
gen ci_lower = prop[1, _n] - invt(e(df_r),0.975) * sqrt(V[_n, _n])
gen ci_upper = prop[1, _n] + invt(e(df_r),0.975) * sqrt(V[_n, _n])

// Label the new variables for the graph
label define group_labels 1 "Neither" 2 "Food Insecurity Only" 3 "Poor Sleep Only" 4 "Both"
label values group group_labels

// Create the bar graph with confidence intervals
twoway (bar prop group, fcolor(gs15) lcolor(black) barwidth(0.6)) (rcap ci_lower ci_upper group, lcolor(black)), ///
   legend(off) ///
   xtitle("Combined Exposure to Food Insecurity and Poor Sleep") ///
   ytitle("Prevalence of Hypertension (%)") ///
   ylabel(0(0.05)0.6, format(%5.2f) labsize(small)) ///
   xlabel(1 2 3 4, valuelabel angle(horizontal) labsize(small)) ///
   title("Prevalence of Hypertension by Exposure Group") ///
   subtitle("2017-2018 NHANES Data")

// Export the bar graph as a high-quality PNG image
graph export "output/Hypertension_Prevalence_Figure.png", replace

// -------------------------------------------------------------------------------------------------
// SECTION 5: FINAL WORD DOCUMENT EXPORT
// -------------------------------------------------------------------------------------------------

// Header, Name, Class, Date
capture putdocx clear
putdocx begin, footer(foot) header(head) pagesize(letter)
putdocx paragraph, halign(center)
putdocx text ("Final Project: The Relationship Between Food Insecurity, Poor Sleep, and Hypertension in the US"), font("",14)
putdocx paragraph, halign(center)
putdocx text ("Ishaan Bhaduri")
putdocx paragraph, halign(center)
putdocx text ("UCSF BIOSTAT 212")
putdocx paragraph, halign(center)
putdocx text ("`c(current_date)' `c(current_time)'")

// Introduction paragraph
putdocx paragraph, style(Heading1) halign(center)
putdocx text ("Introduction")
putdocx paragraph
putdocx text ("The purpose of this study is to examine the association between a combination of food insecurity and poor sleep and the prevalence of hypertension in US adult population. Hypertension is a significant public health burden, and while various risk factors have been identified, the combined impact of socioeconomic and behavioral factors is not fully understood. This analysis will investigate how two factors together contribute to a heightened risk of hypertension, using data from the 2017-2018 National Health and Nutrition Examination Survey (NHANES)."), font("Times New Roman",12)

// Put Figure 1 (bar graph) into Word with subtitle
putdocx paragraph, style(Heading1) halign(center)
putdocx text ("Figure 1")

// Put Figure 1 in the Word doc
putdocx image "output/Hypertension_Prevalence_Figure.png"

// Add subtitle to Figure 1
putdocx paragraph
putdocx text ("Figure 1. Prevalence of Hypertension by Combined Exposure to Food Insecurity and Poor Sleep. The prevalence and 95% confidence intervals were calculated using survey weights from the 2017-2018 NHANES data. The four exposure groups are defined as: Neither, Food Insecurity Only, Poor Sleep Only, and Both."), font("Times New Roman",12)

// Add Table 1 heading
putdocx paragraph, style(Heading1) halign(center)
putdocx text ("Table 1")

// Put Table 1 in the Word doc using the `collect` command
collect style putdocx, layout(autofitcontents)
putdocx collect

// Add subtitle to Table 1
putdocx paragraph
putdocx text ("Table 1. Logistic Regression Model of the Odds of Hypertension. The model uses a combined exposure variable for food insecurity and poor sleep, adjusted for demographic factors. OR: Odds Ratio; 95% CI: 95% Confidence Interval. Reference groups are: full food security, no poor sleep, male, Non-Hispanic White, and college graduate or above."), font("Times New Roman",12)
putdocx paragraph
putdocx text ("The intercept represents the odds of hypertension when all other variables in the model are at their reference level. It corresponds to a male, Non-Hispanic White, college graduate or above with full food security and no poor sleep."), font("Times New Roman",12)

// Save the Word document
putdocx save "output/Bhaduri_Hypertension_Analysis.docx", replace

// Closing the analysis

log close

exit
