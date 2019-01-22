* create CSV data from the SAS discharge level data containing the elixhauser comorbidities;

LIBNAME OUT1    '/ifs/home/kimk13/VBM';

/* %ds2csv (
   data=OUT1.analysis,
   runmode=b,
   csvfile=/ifs/home/kimk13/VBM/pat_elix_03162018_post201510.csv
 ); */

 %ds2csv (
    data=OUT1.analysis,
    runmode=b,
    csvfile=/ifs/home/kimk13/VBM/pat_elix_03162018_pre201510.csv
  );
