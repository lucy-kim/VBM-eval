/******************************************************************/
/* Title:       CREATION OF ELIXHAUSER COMORBIDITY VARIABLES      */
/*              ICD-10-CM ELIXHAUSER COMORBIDITY SOFTWARE,        */
/*                       VERSION 2018                             */
/*                                                                */
/* PROGRAM:     COMOANALY2018                                     */
/*                                                                */
/* Description: Creates comorbidity variables based on the        */
/*              presence of secondary diagnoses and redefines     */
/*              comorbidity group by eliminating DRGs directly    */
/*              related to them. Valid through FY2018 (09/30/18). */
/******************************************************************/


/***********************************************************/
/*  Define subdirectory for data files and format library. */
/*  Input files:    C:\DATA\                               */
/*  Output files:   C:\DATA\                               */
/*  Format library: C:\COMORB\FMTLIB\                      */
/***********************************************************/
proc options option=fmtsearch;run;

LIBNAME IN1     '/ifs/home/kimk13/VBM';
LIBNAME OUT1    '/ifs/home/kimk13/VBM';
LIBNAME LIBRARY '/ifs/home/kimk13/VBM';
options fmtsearch=(WORK LIBRARY) ;
proc options option=fmtsearch;run;

TITLE1 'CREATION AND VALIDATION OF COMORBIDITY MEASURES FOR';
TITLE2 'USE WITH DISCHARGE ADMINISTRATIVE DATA';

/* data IN1.pat_elix_03162018_pre201510 ;
   set IN1.pat_elix_03162018 (drop=icd10);
   rename icd9 =DX1;
   if dischargedt >= '01OCT2015'd then delete;
   DRG_new = input (DRG, best.);
   format DRG_new z3.;
run;

data IN1.pat_elix_03162018_pre201510 ;
   set IN1.pat_elix_03162018_pre201510 (drop=DRG);
   rename DRG_new = DRG;
run;

data IN1.pat_elix_03162018_pre201510 ;
  length DX1 $5. DRG 3.;
  set IN1.pat_elix_03162018_pre201510;
run; */

proc freq data = IN1.pat_elix_03162018_pre201510;
   tables DX1;
   /* format DX1 $RCOMFMT.;
   tables DRG; */
run;

/* proc contents data = IN1.pat_elix_03162018_pre201510;
   proc print data = IN1.pat_elix_03162018_pre201510 (obs=10);
run; */
