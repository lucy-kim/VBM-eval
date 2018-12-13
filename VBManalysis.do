* estimate other models using cluster SE & two-part model

cd
cd "~/Box Sync/VBM/Data/"
capture ssc install estout
set seed 39103
loc saveDir "~/Dropbox/Research/VBM/results"

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
// saveold patUse3, replace
tempfile an
save `an'
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
esttab using `y'_me.tex, booktabs replace label f starlevels( * 0.10 ** 0.05 *** 0.010) cells(b(star fmt(2)) p(par fmt(2)) ci(par fmt(2))) stats(N, fmt(0))
eststo clear
}*/
*----------------------------
*patient-level analysis: replicate the GLM estimation using R
// use patUse3, clear
use `an', clear

loc xvar Time Intervention tpostInt _Iseason* _IcmiD* _Isurgical* dx1 dx2 dx3 dx4 dx5 dx6 dx7 dx8 dx9 dx10 dx11 dx12 dx13 dx14 dx15 dx16 dx17 dx18 dx19 dx20 dx21 dx22 dx23 dx24 dx25 dx26 dx27 dx28 dx29 _Ifemale* _IAgeGroup* _IraceGroup* _Iins*

* cost outcomes
loc yv tvdc_cpi
glm `yv' `xvar', fam(gamma) link(log)
estimates store m1
glm `yv' `xvar' if surgical==0, fam(gamma) link(log)
estimates store m2
glm `yv' `xvar' if surgical==1, fam(gamma) link(log)
estimates store m3

estout m1 m2 m3 using `saveDir'/glm_cost.xls, cells(b(star fmt(2)) ci(fmt(2)) p(fmt(2))) transform(100*(exp(@)-1)) keep(Time Intervention tpostInt) starlevels(* 0.1 ** 0.05 *** 0.01) replace stats(N)

* LOS outcomes
loc yv los
glm `yv' `xvar', fam(gamma) link(log)
estimates store m1

*for expected LOS, use months in and after 2013/09
preserve
keep if ym >= ym(2013,9)

tab ym, summarize(Time)
replace Time = Time - 24
tab ym, summarize(tpostInt)
tab ym, summarize(Intervention)

loc yv oelos
glm `yv' `xvar' , fam(gamma) link(log)
estimates store m2

loc yv oelos_gt15
glm `yv' `xvar' if e(sample), fam(binomial) link(logit)
estimates store m3
restore

estout m1 m2 m3 using glm_los.xls, cells(b(star fmt(2)) ci(fmt(2)) p(fmt(2))) transform(100*(exp(@)-1)) keep(Time Intervention tpostInt) starlevels(* 0.1 ** 0.05 *** 0.01) replace stats(N)

*health outcomes
*for readmission outcome, use months in or after 2012/01
preserve
keep if ym >= ym(2012,1) & ym < ym(2017,12)

tab ym, summarize(Time)
replace Time = Time - 4
tab ym, summarize(Time)

loc yv readmit
glm `yv' `xvar', fam(binomial) link(logit)
estimates store m1
restore

loc yv death
glm `yv' `xvar', fam(binomial) link(logit)
estimates store m2

estout m1 m2 using glm_health.xls, cells(b(star fmt(2)) ci(fmt(2)) p(fmt(2))) transform(100*(exp(@)-1)) keep(Time Intervention tpostInt) starlevels(* 0.1 ** 0.05 *** 0.01) replace stats(N)

*----------------------------
*estimate total savings: subtract the (fully adjusted) predicted cost from actual cost per case in the intervention period and sum them

use patUse3, clear

loc xvar Time Intervention tpostInt _Iseason* _IcmiD* _Isurgical* dx1 dx2 dx3 dx4 dx5 dx6 dx7 dx8 dx9 dx10 dx11 dx12 dx13 dx14 dx15 dx16 dx17 dx18 dx19 dx20 dx21 dx22 dx23 dx24 dx25 dx26 dx27 dx28 dx29 _Ifemale* _IAgeGroup* _IraceGroup* _Iins*

* cost outcomes
loc yv tvdc_cpi
glm `yv' `xvar' if Intervention==0, fam(gamma) link(log)
predict cost

*graph the predicted vs observed costs just so we can visually see what the model is doing
preserve
collapse (mean) tvdc_cpi cost, by(ym surgical)

lab var tvdc_cpi "Actual"
lab var cost "Predicted"

tw (line tvdc_cpi ym if surgical==1 ) (line cost ym if surgical==1, xline(651.5) tlab(2011m9(6)2017m12, angle(45)) title(Actual vs predicted total variable direct cost) subti(Surgery patients))
graph export saving_surg1.eps, replace

tw (line tvdc_cpi ym if surgical==0 ) (line cost ym if surgical==0, xline(651.5) tlab(2011m9(6)2017m12, angle(45)) title(Actual vs predicted total variable direct cost) subti(Medicine patients))
graph export saving_surg0.eps, replace

restore

preserve
collapse (mean) tvdc_cpi cost, by(ym)

lab var tvdc_cpi "Actual"
lab var cost "Predicted"

tw (line tvdc_cpi ym ) (line cost ym, xline(651.5) tlab(2011m9(6)2017m12, angle(45)) title(Actual vs predicted total variable direct cost) subti(All patients))
graph export saving.eps, replace
restore

preserve
keep if Intervention==1
gen diff = cost - tvdc_cpi
egen tsaving = sum(diff)
bys surgical: egen tsaving_surg = sum(diff)

foreach v of varlist tsavi* {
  replace `v' = `v' / 1000000
}
bys surgical: sum tsavi*

foreach v of varlist cost tvdc_cpi {
  egen t`v' = sum(`v')
  bys surgical: egen t`v'_surg = sum(`v')
  replace  t`v' =  t`v'/1000000
  replace  t`v'_surg =  t`v'_surg/1000000
}
bys surgical: sum tsavi* tcost ttvdc_cpi tcost_surg ttvdc_cpi_surg


*----------------------------
*for aggregate ITS, create Monthly total costs after adjusting for the patient characteristics using coefficient on month dummies

use `an', clear

xi i.ym i.season i.surgical i.female i.AgeGroup i.raceGroup i.ins i.cmiD

tab ym
sum ym
loc min `r(min)'
gen _Iym_`min' = ym==`min'

loc y tvdc_cpi
capture destring `y', replace

loc elix dx1 dx2 dx3 dx4 dx5 dx6 dx7 dx8 dx9 dx10 dx11 dx12 dx13 dx14 dx15 dx16 dx17 dx18 dx19 dx20 dx21 dx22 dx23 dx24 dx25 dx26 dx27 dx28 dx29
loc sp _IcmiD* _Isurgical* `elix' _Ifemale* _IAgeGroup* _IraceGroup* _Iins*

*all patients
*reg `y' _Iym* `sp', nocons
glm `y' _Iym* `sp', family(gamma) link(log) nocons

tempfile all
parmest,format(estimate min95 max95 %8.4f p %8.3f) saving(`all', replace)

forval x=0/1 {
  glm `y' _Iym* `sp' if surgical==`x', family(gamma) link(log) nocons

  tempfile surg`x'
  parmest,format(estimate min95 max95 %8.4f p %8.3f) saving(`surg`x'', replace)
}

use `all', clear
gen gp = "all"
foreach f in "surg0" "surg1" {
  append using ``f''
  replace gp = "`f'" if gp==""
}
assert gp!=""

keep if regexm(parm, "_Iym")

gen ym = substr(parm, -3,3)
destring ym, replace
format ym %tm

*convert ym to dates
gen date = dofm(ym)
format date %d
gen month=month(date)
gen yr=year(date)

keep estimate gp date month yr
rename estimate ra_month_
reshape wide ra_month_, i(month yr date) j(gp) string

foreach v of varlist ra_month* {
  replace `v' = exp(`v')
}

format ra_month* %20.03fc
compress
outsheet using ra_tvdc_cpi_monthly_050918.csv, comma names replace

*----------------------------
*create unadjusted monthly costs

use `an', clear

xi i.ym

tab ym
sum ym
loc min `r(min)'
gen _Iym_`min' = ym==`min'

loc y tvdc_cpi
capture destring `y', replace
loc sp

*all patients
*reg `y' _Iym* `sp', nocons
glm `y' _Iym* `sp', family(gamma) link(log) nocons

tempfile all
parmest,format(estimate min95 max95 %8.4f p %8.3f) saving(`all', replace)

forval x=0/1 {
  glm `y' _Iym* `sp' if surgical==`x', family(gamma) link(log) nocons

  tempfile surg`x'
  parmest,format(estimate min95 max95 %8.4f p %8.3f) saving(`surg`x'', replace)
}

use `all', clear
gen gp = "all"
foreach f in "surg0" "surg1" {
  append using ``f''
  replace gp = "`f'" if gp==""
}
assert gp!=""

keep if regexm(parm, "_Iym")

gen ym = substr(parm, -3,3)
destring ym, replace
format ym %tm

*convert ym to dates
gen date = dofm(ym)
format date %d
gen month=month(date)
gen yr=year(date)

keep estimate gp date month yr
rename estimate unadj_month_
reshape wide unadj_month_, i(month yr date) j(gp) string

foreach v of varlist unadj_month* {
  replace `v' = exp(`v')
}

format unadj_month* %20.03fc
compress

outsheet using "~/Dropbox/Research/VBM/data/unadj_tvdc_cpi_monthly_050918.csv", comma names replace
*----------------------------
* test for the difference in proportion

egen race = group(raceGroup)
forval x = 1/4 {
    gen race`x' = race==`x'
}


gen insur = 1 if ins=="Commercial/Other ins"
replace insur = 2 if ins=="Medicaid FFS" | ins=="Medicaid MC"
replace insur = 3 if ins=="Medicare FFS" | ins=="Medicare MC"
replace insur = 4 if ins=="Self-pay"
assert insur!=.


forval x = 1/4 {
    gen insur`x' = insur==`x'
}


foreach v of varlist female race? insur? {
  di "`v'--------------"
  prtest `v', by(Int)
  di ""
}

* test for the difference in means
egen DXcount = rowtotal(dx1-dx29)
foreach v of varlist DXcount {
    di "`v'--------------"
  ttest `v', by(Int)
  di ""
}
