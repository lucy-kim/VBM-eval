#!/bin/bash
#$ -l mem_free=10G

module load stata/13
# module load sas/9.4

cd /ifs/home/kimk13/VBM
stata-se -q -b do VBManalysis.do

# sas -nodms -noterminal download_oes.sas

#$ -N sasjob01 #$ -j y
