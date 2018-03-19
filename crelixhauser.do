* create Elixhauser comorbidity index using the ICD9 & ICD10 codes in the VBM patient discharge level data

cd ~/VBM
capture ssc install elixhauser
set seed 123

loc f "pat_elix_03162018.csv"
insheet using "`f'", clear names

rename patientid PATIENT_ID
rename encprimaryicd10diagnosis icd10
rename encprimaryicd10surgicalprocedure icd10p
rename encprimaryicd9diagnosis icd9
rename encprimaryicd9surgicalprocedure icd9p
drop v1

gen icd9missing = icd9 =="0" | icd9=="NA"
gen icd10missing = icd10=="NA"

*convert to stata date
split dischargedate, p("-")
destring dischargedate?, replace
gen Discharge_Date = mdy(dischargedate2, dischargedate3, dischargedate1)
format Discharge_Date %d
drop dischargedate dischargedate?

gen ym = ym(year(Discharge_Date), month(Discharge_Date))
format ym %tm

tab ym, summarize(icd9missing)
* missing starting from 2015/10
tab ym, summarize(icd10missing)
* missing before 2015/10

keep PATIENT_ID icd* ym
drop *missing

count
loc tot = `r(N)'

foreach v of varlist icd* {
  replace `v' = "" if `v'=="NA"
}

tempfile tmp
save `tmp'

* ICD 9
use `tmp', clear
/*sample 100, count*/
keep if ym < ym(2015,10)
drop icd10*
keep if icd9!="" | icd9p!=""
count
des

foreach v of varlist icd9* {
    replace `v' = subinstr(`v', ".", "",.)
}
rename icd9 DX1
rename icd9p DX2

elixhauser DX1 DX2, index(e) idvar(PATIENT_ID) diagprfx("DX") smelix

tempfile icd9
save `icd9'

*ICD 10
use `tmp', clear
/*sample 100, count*/
keep if ym >= ym(2015,10)
drop icd9*
keep if icd10!="" | icd10p!=""
count
foreach v of varlist icd10 icd10p {
    replace `v' = subinstr(`v', ".", "",.)
}
rename icd10 DX1
rename icd10p DX2

elixhauser DX1 DX2, index(10) idvar(PATIENT_ID) diagprfx("DX") smelix

tempfile icd10
save `icd10'

use `icd9', clear
append using `icd10'

duplicates tag PATIENT_ID, gen(dup)
assert dup==0
drop dup

count
*assert that total obs count for the appended data is the same as original data
count
assert `r(N)'==`tot'

compress
saveold elixhauser, replace
outsheet using elixhauser.csv, comma names replace

*-----------------------
/* * merge with original data to see which patients got dropped
use elixhauser, clear
merge 1:1 PATIENT_ID using `tmp'
*693 obs have _m=2 -- all of these have icd9=="0" & icd9p=="0", i.e. missing, so it's fine to exclude them

*why do rehab patients have mostly 0's in elixhauser dummies?
use pat_1052017, clear
keep if MS_DRG_Type=="REHAB"

gen icd10 = Enc___Primary_ICD10_Diagnosis
gen icd10p = Enc___Primary_ICD10_Surgical_Pro
gen icd9 = Enc___Primary_ICD9_Diagnosis
gen icd9p = Enc___Primary_ICD9_Surgical_Proc

gen icd9missing = icd9 =="0" | icd9==""
gen icd10missing = icd10==""

gen ym = ym(year(Discharge_Date), month(Discharge_Date))
format ym %tm

keep PATIENT_ID icd* ym

tempfile tmp
save `tmp'

* ICD 9
use `tmp', clear
keep if ym < ym(2015,10)
drop icd10*
keep if icd9!="" | icd9p!=.
gen icd9p_s = string(icd9p)
drop icd9p
rename icd9p_s icd9p
count
des

foreach v of varlist icd9 icd9p {
    replace `v' = subinstr(`v', ".", "",.)
}
rename icd9 DX1
rename icd9p DX2

elixhauser DX1, index(e) idvar(PATIENT_ID) diagprfx("DX") smelix





merge 1:1 PATIENT_ID using elixhauser, keep(1 3) */
