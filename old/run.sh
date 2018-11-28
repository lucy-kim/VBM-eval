#!/bin/bash
#$ -N sasjob01 #$ -j y
#$ -l mem_free=10G

# module load stata/13
module load sas/9.4

cd /ifs/home/kimk13/VBM
# stata-se -q -b do VBManalysis.do

# sas -nodms -noterminal test.sas
# sas -nodms -noterminal crpat_elix.sas

# for ICD-10 codes
# sas -nodms -noterminal comformat_icd10cm_2016_2.sas
# sas -nodms -noterminal comonanaly_icd10cm_2016.sas

# for ICD-9 codes
# sas -nodms -noterminal comformat2012-2015.sas
# sas -nodms -noterminal comoanaly2012-2015.sas

sas -nodms -noterminal crpat_elix_csv.sas
