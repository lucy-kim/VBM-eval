# VBM-eval

## Construct the elixhauser comorbidity index
import CSV file into SAS
`crpat_elix.sas`

ICD-10 to Elixhauser: Use [Version 2016.2](https://www.hcup-us.ahrq.gov/toolssoftware/comorbidityicd10/comorbidity_icd10.jsp)
(for discharges with ICD 10 codes during 2015/10 - later)
- `comformat_icd10cm_2016_2.sas`
- `comoanaly_icd10cm_2016.sas`

ICD-9 to Elixhauser: Use [Version 3.7](https://www.hcup-us.ahrq.gov/toolssoftware/comorbidity/comorbidity.jsp#download)
(for discharges with ICD 9 codes during start - 2015/9)
- `comformat2012-2015.sas`
- `comoanaly2012-2015.sas`

export SAS data to CSV file
`crpat_elix_csv.sas`
