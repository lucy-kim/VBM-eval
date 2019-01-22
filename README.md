# Evaluation of VBM

The NYU Langone Health has been consistently ranked high in terms of quality but also high in terms of costs per case among academic medical centers nationally even after the adjustment for the case mix and wage indices. Thus, starting May 2014, the NYU Langone Health implemented value-based management (VBM) program to reduce costs and improve value of healthcare which can be defined as quality achieved per dollar spent. We aim to evaluate the impact of this program in terms of variable direct cost per case and quality, and estimate cost savings to date.

## Main sample construction and analysis code
Run this main code in *R* :
`VBManalysis_postMay2014.Rmd`

This code requires the following two steps to complete the whole analyses. They were run in _SAS_ and _Stata_, respectively.

### 1. Construct the elixhauser comorbidity index

All the code files below are contained in the directory `Elixhauser-score`.

1. Import CSV file into SAS
  - `crpat_elix.sas`
2. ICD-10 to Elixhauser: Use [Version 2016.2](https://www.hcup-us.ahrq.gov/toolssoftware/comorbidityicd10/comorbidity_icd10.jsp)
(for discharges with ICD 10 codes during 2015/10 - later)
  - `comformat_icd10cm_2016_2.sas`
  - `comoanaly_icd10cm_2016.sas`
3. ICD-9 to Elixhauser: Use [Version 3.7](https://www.hcup-us.ahrq.gov/toolssoftware/comorbidity/comorbidity.jsp#download)
(for discharges with ICD 9 codes during start - 2015/9)
  - `comformat2012-2015.sas`
  - `comoanaly2012-2015.sas`
4. Export SAS data to CSV file
  - `crpat_elix_csv.sas`

### 2. Create monthly risk-adjusted total costs
`VBManalysis.do`

Obtain month fixed effect coefficients estimated with patient characteristics controls using the discharge-level data in Stata
