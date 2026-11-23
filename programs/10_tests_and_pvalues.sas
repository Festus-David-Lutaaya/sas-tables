/* Lesson 10: tests and p-values into datasets
   PROC TTEST, PROC NPAR1WAY, PROC FREQ chi-square and Fisher,
   collecting p-values for a summary table */

/* t-test, keep the p-value */
ods output ttests = tt equality = eq;
proc ttest data=sashelp.class;
  class sex;
  var height weight;
run;

proc print data=tt noobs; run;

/* pooled or Satterthwaite: pick by method */
data tt_p;
  set tt;
  where method = 'Satterthwaite';
  keep variable probt;
run;

/* Wilcoxon rank sum */
ods output wilcoxontest = wil;
proc npar1way data=sashelp.class wilcoxon;
  class sex;
  var height weight;
run;

proc print data=wil noobs; run;
/* the two-sided p-value: name1 = 'P2_WIL' in older releases,
   column Prob2 in newer ones. Check your dataset with PROC PRINT. */

/* chi-square and Fisher exact */
ods output chisq = chi fishersexact = fish;
proc freq data=sashelp.heart;
  tables sex*status / chisq;
run;

proc print data=chi noobs; run;

data chi_p;
  set chi;
  where statistic = 'Chi-Square';
  keep table prob;
run;

/* exact test on a small table */
ods output fishersexact = fish2;
proc freq data=sashelp.class;
  tables sex*age / fisher;
run;

/* several variables at once and one tidy p-value dataset */
%macro pval_cont(data=, var=, by=);
  ods output ttests = _tt;
  proc ttest data=&data;
    class &by;
    var &var;
  run;
  data _p_&var;
    set _tt;
    where method = 'Satterthwaite';
    length test $20;
    test = 't-test';
    keep variable test probt;
    rename probt = pvalue;
  run;
%mend;

%pval_cont(data=sashelp.heart, var=cholesterol, by=sex)
%pval_cont(data=sashelp.heart, var=systolic, by=sex)
%pval_cont(data=sashelp.heart, var=diastolic, by=sex)

data pvalues;
  set _p_cholesterol _p_systolic _p_diastolic;
run;

proc format;
  picture pvalf (round)
          low -< 0.001 = '<0.001' (noedit)
          0.001 - high = '9.999';
run;

proc print data=pvalues noobs;
  format pvalue pvalf.;
run;

/* Try it:
   Add a chi-square p-value for smoking_status by sex to the
   pvalues dataset, with test = 'Chi-square'. */
