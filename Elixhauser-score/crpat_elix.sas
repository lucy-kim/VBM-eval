* create SAS data of the discharge level data;

LIBNAME OUT1    '/ifs/home/kimk13/VBM';

data OUT1.pat_elix_03162018;
     infile "/ifs/home/kimk13/VBM/pat_elix_03162018.csv" dlm='2C0D'x dsd missover lrecl=10000 firstobs=2;
     input patid icd10 $ icd9 $ dischargedate $11. DRG $;
     dischargedt = input(dischargedate, yymmdd10.);
     DRG_new = put(input(DRG, 3.), z3.);
     format dischargedt date10.;
run;

data OUT1.pat_elix_03162018;
     length icd10 $8. icd9 $6.;
     set OUT1.pat_elix_03162018 (drop=dischargedate DRG);
     if icd10 = "NA" | icd10 = "0" then icd10 = "";
     if icd9 = "NA" | icd9 = "0" then icd9 = "";
     icd10 = compress( icd10, '.' );
     icd9 = compress( icd9, '.' );
     rename DRG_new = DRG;
run;

proc contents data = OUT1.pat_elix_03162018;
proc print data = OUT1.pat_elix_03162018 (obs=10);
proc freq data = OUT1.pat_elix_03162018;
     table DRG icd10 icd9;
run;
