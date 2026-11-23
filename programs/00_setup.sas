/* Run this first in every session.
   Change root to wherever you put this folder.
   SAS OnDemand for Academics: something like /home/u12345678/sas-tables */

%let root = D:/SCRIPTS/SAS/sas-tables;
%let out  = &root/output;

/* create the output folder if it is not there */
options dlcreatedir;
libname outdir "&out";
libname outdir clear;

options nodate nonumber validvarname=v7 nofmterr msglevel=i;
ods escapechar = '^';

/* the datasets we use from SASHELP */
proc contents data=sashelp.class short; run;
proc contents data=sashelp.cars  short; run;
proc contents data=sashelp.heart short; run;

/* simulated trial data for the clinical lessons (14-17) */
%include "&root/macros/clinical_data.sas";

proc print data=work.adsl(obs=5); run;
proc print data=work.adae(obs=5); run;
