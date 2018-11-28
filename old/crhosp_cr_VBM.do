*create balanced panel data containing hospital characteristics from the Cost Report for 2014-2017 (raw data available up to 2016)

cd /ifs/home/kimk13/VI/data/costreport

loc fy 2010

use hosp_chars_cr, clear
keep provid
duplicates drop
expand 2017-`fy' + 1
bys provid: gen fy = `fy' + _n -1
tab fy
tempfile base
save `base'

use hosp_chars_cr, clear
keep if fy >= `fy'

merge 1:1 provid fy using `base'

loc vars teaching own_np own_fp own_gv uncomp1 dissh beds size urban
sort provid fy
keep provid fy `vars'

foreach v of varlist `vars' {
  bys provid: replace `v' = `v'[_n-1] if `v'>=.
}
gsort provid -fy
foreach v of varlist `vars' {
  bys provid: replace `v' = `v'[_n-1] if `v'>=.
  di "`v'---------------"
  count if `v'==.
}
drop if beds==.
drop if fy < 2014

compress
outsheet using hosp_cr_VBM.csv, comma names replace
