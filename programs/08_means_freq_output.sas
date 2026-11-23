/* Lesson 8: summary statistics as datasets
   PROC MEANS / SUMMARY, PROC FREQ, OUTPUT and ODS OUTPUT

   For custom tables the pattern is always:
   1. compute the numbers into a dataset
   2. shape it (data step / transpose)
   3. print it with PROC REPORT */

/* PROC MEANS to the screen */
proc means data=sashelp.heart n mean std median q1 q3 min max maxdec=1;
  class sex;
  var ageatstart cholesterol;
run;

/* the same numbers into a dataset */
proc means data=sashelp.heart noprint nway;
  class sex;
  var cholesterol;
  output out=chol_stats n=n mean=mean std=sd median=median q1=q1 q3=q3 min=min max=max;
run;

proc print data=chol_stats noobs; run;

/* _TYPE_ tells you the level of summary when you leave out NWAY */
proc means data=sashelp.heart noprint;
  class sex;
  var cholesterol;
  output out=chol_all mean=mean;
run;

proc print data=chol_all noobs; run;   /* _type_ 0 = overall, 1 = by sex */

/* build display text from the numbers: "mean (sd)" */
data chol_text;
  set chol_stats;
  length meansd $20 medq $30;
  meansd = cats(put(mean, 5.1), ' (', put(sd, 5.1), ')');
  medq   = cats(put(median, 5.1), ' (', put(q1, 5.1), ', ', put(q3, 5.1), ')');
run;

proc print data=chol_text noobs;
  var sex n meansd medq;
run;

/* PROC FREQ counts and percents */
proc freq data=sashelp.heart;
  tables status sex*status;
run;

/* into a dataset */
proc freq data=sashelp.heart noprint;
  tables sex*status / outpct out=freq_out;
run;

proc print data=freq_out noobs; run;   /* pct_row and pct_col are there too */

/* "n (%)" text */
data freq_text;
  set freq_out;
  length npct $20;
  npct = cats(count, ' (', put(pct_col, 5.1), '%)');
run;

/* ODS OUTPUT grabs any printed table as a dataset */
ods output summary = means_ods;
proc means data=sashelp.heart n mean std;
  class sex;
  var cholesterol diastolic systolic;
run;

proc print data=means_ods noobs; run;

/* STACKODSOUTPUT gives one row per variable, which is easier to work with */
ods output summary = means_long;
proc means data=sashelp.heart n mean std stackodsoutput;
  class sex;
  var cholesterol diastolic systolic;
run;

proc print data=means_long noobs; run;

/* PROC UNIVARIATE: the full picture of one variable, including
   extreme observations, normality tests and percentiles */
proc univariate data=sashelp.heart normal;
  var cholesterol;
  histogram cholesterol / normal;
  id sex;
run;

proc univariate data=sashelp.heart noprint;
  class sex;
  var cholesterol;
  output out=pctl pctlpts=5 10 90 95 pctlpre=p;
run;

proc print data=pctl noobs; run;

/* PROC SUMMARY = PROC MEANS that does not print by default */
proc summary data=sashelp.heart nway;
  class sex status;
  var weight;
  output out=wt mean=;
run;

/* Try it:
   From sashelp.heart make a dataset with one row per smoking_status
   showing N and "mean (sd)" of systolic blood pressure. */
