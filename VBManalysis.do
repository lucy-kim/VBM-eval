* estimate other models using cluster SE & two-part model

cd ~/VBM
capture ssc install estout
set seed 39103

insheet using patUse3.csv, comma nonames clear
replace v48 = "dept" if v48=="NYU Reporting Department â€“ Most Recent_Desc" & _n==1

foreach var of varlist * {
  capture replace `var' = trim(`var')
  capture rename `var' `=strtoname(`var'[1])'
}
rename t Time
rename v45 Intervention

drop in 1/1

gen yr = substr(DischargeDateMonth,1,4)
gen mo = substr(DischargeDateMonth,5,2)
destring yr mo, replace
gen ym = ym(yr, mo)
format ym %tm

/* *manually change long var names
foreach v of varlist * {
replace `v' = subinstr(`v', "Enc - ", "",.) in 1/1
*replace `v' = subinstr(`v', "NYU Finance - ", "",.) in 1/1
}
replace v27 = "NYU report dept Most Recent" in 1/1
replace v28 = "NYU report dept Most Recent_Desc" in 1/1
replace v29 = "NYU report div Most Recent" in 1/1
replace v30 = "NYU report div Most Recent_Desc" in 1/1
replace v31 = "NYU report dept at_time_disch" in 1/1
replace v32 = "NYU report div at_time_disch" in 1/1
replace v83 = "ICD10 i.surgical proc" in 1/1
replace v84 = "ICD10 i.surgical proc_desc" in 1/1
replace v141 = "Time" in 1/1
replace v142 = "Intervention" in 1/1

gen init = 0
foreach var of varlist * {
replace init = init + 1
capture replace `var' = trim(`var')
capture rename `var' `=strtoname(`var'[1])'
}
drop init
drop in 1/1

keep if big=="FALSE"
drop big _0 */

destring patid, replace

*destring cost & other variables
replace oelos = "" if oelos=="Inf"

foreach v of varlist Time Intervention tpostInt dx* tvdc_cpi los oelos* readmit death surgical {
  destring `v', replace
}

egen dp = group(dept)

xi i.season i.surgical i.female i.AgeGroup i.raceGroup i.ins i.cmiD

lab var tpostInt "Time after Intervention"
lab var Time "Time"
lab var Intervention "Intervention"

compress
saveold patUse3, replace

*----------------------------
*check if data correct monthly - yes
/*preserve
use patUse2, clear
keep ym Time Intervention tpostInt
duplicates drop
sort ym
list
restore*/

*----------------------------
/* Two-part model

use patUse2, clear

loc elix ynel2 ynel3 ynel4 ynel5 ynel6 ynel7 ynel8 ynel9 ynel10 ynel11 ynel12 ynel13 ynel14 ynel15 ynel16 ynel17 ynel18 ynel19 ynel20 ynel21 ynel22 ynel23 ynel24 ynel25 ynel26 ynel27 ynel28 ynel29 ynel30 ynel31
loc sp1 Time Intervention tpostInt _Iseason*
loc sp2 Time Intervention tpostInt _Iseason* CMI
loc sp3 Time Intervention tpostInt _Iseason* CMI _Isurgical_2
loc sp4 Time Intervention tpostInt _Iseason* CMI _Isurgical_2 `elix'
loc sp5 Time Intervention tpostInt _Iseason* CMI _Isurgical_2 `elix' _Ifemale_2 _IAgeGroup* _IraceGroup*
loc sp6 Time Intervention tpostInt _Iseason* CMI _Isurgical_2 `elix' _Ifemale_2 _IAgeGroup* _IraceGroup* _Iins*

*Pharmacy_cpi Laboratory_cpi Radiology_cpi MRI_cpi Implants_cpi Blood_cpi ICU_cpi
foreach y of varlist ICU_cpi {
forval n=1/6 {
reg `y' `sp`n'' if `y' > 0
matrix bb = e(b)
matrix list bb

twopm `y' `sp`n'', firstpart(logit) secondpart(glm, family(gamma) link(log)) search from(bb) iterate(50)
eststo : margins, dydx(Time Intervention tpostInt) post
*mat pr`n' = r(table)
}
esttab using `y'_me.tex, booktabs replace label f starlevels( * 0.10 ** 0.05 *** 0.010) cells(b(star fmt(3)) p(par fmt(3)) ci(par fmt(3))) stats(N, fmt(0))
eststo clear
}*/
*----------------------------
*patient-level analysis: replicate the GLM estimation using R
use patUse3, clear

loc xvar Time Intervention tpostInt _Iseason* _IcmiD* _Isurgical* dx1 dx2 dx3 dx4 dx5 dx6 dx7 dx8 dx9 dx10 dx11 dx12 dx13 dx14 dx15 dx16 dx17 dx18 dx19 dx20 dx21 dx22 dx23 dx24 dx25 dx26 dx27 dx28 dx29 _Ifemale* _IAgeGroup* _IraceGroup* _Iins*

* cost outcomes
loc yv tvdc_cpi
glm `yv' `xvar', fam(gamma) link(log) vce(cluster dp)
estimates store m1
glm `yv' `xvar' if surgical==0, fam(gamma) link(log) vce(cluster dp)
estimates store m2
glm `yv' `xvar' if surgical==1, fam(gamma) link(log) vce(cluster dp)
estimates store m3

estout m1 m2 m3 using glm_cost.xls, cells(b(star fmt(3)) ci(fmt(3)) p(fmt(3))) transform(100*(exp(@)-1)) keep(Time Intervention tpostInt) starlevels(* 0.1 ** 0.05 *** 0.01) replace stats(N)

* LOS outcomes
loc yv los
glm `yv' `xvar', fam(gamma) link(log) vce(cluster dp)
estimates store m1

*for expected LOS, use months in and after 2013/09
preserve
keep if ym >= ym(2013,9)

tab ym, summarize(Time)
replace Time = Time - 24
tab ym, summarize(tpostInt)
tab ym, summarize(Intervention)

loc yv oelos
glm `yv' `xvar' , fam(gamma) link(log) vce(cluster dp)
estimates store m2

loc yv oelos_gt15
glm `yv' `xvar' if e(sample), fam(binomial) link(logit) vce(cluster dp)
estimates store m3
restore

estout m1 m2 m3 using glm_los.xls, cells(b(star fmt(3)) ci(fmt(3)) p(fmt(3))) transform(100*(exp(@)-1)) keep(Time Intervention tpostInt) starlevels(* 0.1 ** 0.05 *** 0.01) replace stats(N)

*health outcomes
*for readmission outcome, use months in or after 2012/01
preserve
keep if ym >= ym(2012,1) & ym < ym(2017,12)

tab ym, summarize(Time)
replace Time = Time - 4
tab ym, summarize(Time)

loc yv readmit
glm `yv' `xvar', fam(binomial) link(logit) vce(cluster dp)
estimates store m1
restore

loc yv death
glm `yv' `xvar', fam(binomial) link(logit) vce(cluster dp)
estimates store m2

estout m1 m2 using glm_health.xls, cells(b(star fmt(3)) ci(fmt(3)) p(fmt(3))) transform(100*(exp(@)-1)) keep(Time Intervention tpostInt) starlevels(* 0.1 ** 0.05 *** 0.01) replace stats(N)


*----------------------------
*for aggregate ITS, create Monthly total costs after adjusting for the patient characteristics using coefficient on month dummies

use patUse3, clear

sum ym
loc min `r(min)'
gen _Iym_`min' = ym==`min'

loc y tvdc_cpi
capture destring `y', replace

loc elix dx1 dx2 dx3 dx4 dx5 dx6 dx7 dx8 dx9 dx10 dx11 dx12 dx13 dx14 dx15 dx16 dx17 dx18 dx19 dx20 dx21 dx22 dx23 dx24 dx25 dx26 dx27 dx28 dx29
loc sp _IcmiD* _Isurgical_2 `elix' _Ifemale_2 _IAgeGroup* _IraceGroup* _Iins*

*all patients
*reg `y' _Iym* `sp', nocons
glm `y' _Iym* `sp', family(gamma) link(log) search nocons

*save coefficients on month dummies & other risk adjusters
matrix betas = e(b)
local names: colnames betas
local subset "_Iym*"
unab subset : `subset'
scalar LLL=wordcount("`subset'")
loc colnum `= colsof(betas)'

* exp(coefficient on each monthly dummy) = (predicted y for the month)/exp(linear combination using the coefficients on all non-month dummy variables, i.e. risk adjusters)

*create a month variable and save coefficient on each month dummy in the corresponding month row
preserve
gen monthv = "_Iym_" + string(ym)
gen ra_month = .
foreach v of varlist _Iym* {
  loc n colnumb(betas, "`v'")
  replace ra_month = exp(betas[1,`n']) if monthv=="`v'"
}
keep ym ra_month
duplicates drop
tempfile racost_all
save `racost_all'
restore

*surgical and medical patients separately
destring surgical, replace
loc sp _IcmiD* `elix' _Ifemale_2 _IAgeGroup* _IraceGroup* _Iins*
forval k = 0/1 {
  glm `y' _Iym* `sp' if surgical==`k', family(gamma) link(log) search nocons

  *save coefficients on month dummies & other risk adjusters
  matrix betas = e(b)
  local names: colnames betas
  local subset "_Iym*"
  unab subset : `subset'
  scalar LLL=wordcount("`subset'")
  loc colnum `= colsof(betas)'

  *create a month variable and save coefficient on each month dummy in the corresponding month row
  preserve
  gen monthv = "_Iym_" + string(ym)
  gen ra_month = .
  foreach v of varlist _Iym* {
    loc n colnumb(betas, "`v'")
    replace ra_month = exp(betas[1,`n']) if monthv=="`v'"
  }
  keep ym ra_month
  duplicates drop
  list
  rename ra_month ra_month_surg`k'
  tempfile racost_surgical`k'
  save `racost_surgical`k''
  restore
}

use `racost_all', clear
forval k = 0/1 {
  merge 1:1 ym using `racost_surgical`k'', nogen
}
*convert ym to dates
gen date = dofm(ym)
format date %d
gen month=month(date)
gen yr=year(date)
compress
outsheet using ra_tvdc_cpi_monthly.csv, comma names replace


/*mat risk_betas =betas[1,LLL+1..`colnum']
mat score yhat=risk_betas if e(sample)
gen exp_yhat = exp(yhat)

foreach v of varlist _Iym_621 _Iym_622 {
di "`v'"
loc n colnumb(betas, "`v'")
capture drop racost_`v'
gen racost_`v' = exp(yhat)* ( exp(betas[1,`n']) - 1)
}*/


/*foreach y of varlist Pharmacy_cpi Laboratory_cpi Radiology_cpi  MRI_cpi Implants_cpi Blood_cpi ICU_cpi OR_cpi supplies_cpi inhalation_cpi POT_cpi postop_cpi routine_cpi {
sum `y'
}*/


/*forval i=1/3 {
scalar x = pr[6,`i']
loc ub`i': di %9.3f x
scalar x = pr[5,`i']
loc lb`i': di %9.3f x

loc ci`i' "(`lb`i'', `ub`i'')"
di "`ci`i''"
}

esttab
outreg2 using Blood_cpi_me.xls, replace append nocons keep(Time Intervention tpostInt) label dec(3) addtext(95% CI for Time, "`ci1'", 95% CI for Intervention, "`ci2'", 95% CI for Time after Intervention, "`ci3'", Observations for first-part model, `e(N_logit)', Observations for second-part model, `e(N_glm)', First-part model log likelihood, `e(ll_logit)', Second-part model log likelihood, `e(ll_glm)', Second-part model AIC, `e(aic_glm)')

*/
