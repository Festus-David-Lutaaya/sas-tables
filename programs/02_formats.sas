/* Lesson 2: formats
   built-in formats, PROC FORMAT value and picture formats,
   formats for grouping, dates, missing values */

/* formats change how a value is shown, not the value */
proc print data=sashelp.cars(obs=8) noobs;
  var make model msrp invoice mpg_city;
  format msrp invoice dollar10. mpg_city 4.1;
run;

/* common ones
   8.2        number with 2 decimals
   comma10.   thousands separators
   dollar10.2 currency
   percent8.1 0.256 -> 25.6%
   z3.        leading zeros: 7 -> 007
   date9.     16NOV2026
   yymmdd10.  2026-11-16  (ISO, what most clinical outputs use) */

data demo;
  x = 1234567.891; p = 0.2564; d = '16NOV2026'd; id = 7;
run;

proc print data=demo noobs;
  format x comma15.2 p percent8.1 d yymmdd10. id z3.;
run;

/* your own value formats */
proc format;
  value $sexf  'F' = 'Female'
               'M' = 'Male';

  value agegrp low -< 13 = 'Under 13'
               13 - 14   = '13 to 14'
               15 - high = '15 and over';

  value yn 0 = 'No'
           1 = 'Yes'
           . = 'Missing';
run;

proc print data=sashelp.class noobs;
  var name sex age;
  format sex $sexf. age agegrp.;
run;

/* formats group data in summary procedures for free */
proc freq data=sashelp.class;
  tables age;
  format age agegrp.;
run;

/* picture formats build text around numbers */
proc format;
  picture pctf (round) low - high = '009.9%';
  picture pvalf (round)
          low -< 0.001 = '<0.001' (noedit)
          0.001 - high = '9.999';
run;

data p;
  input pct pval;
  datalines;
12.34 0.0004
50    0.0321
7.05  0.4
;
run;

proc print data=p noobs;
  format pct pctf. pval pvalf.;
run;

/* the format catalogue is in WORK by default.
   To keep formats between sessions:
   libname fmt "&root/formats";
   proc format library=fmt; ... run;
   options fmtsearch=(fmt work); */

/* see what is in a format */
proc format fmtlib;
  select agegrp yn;
run;

/* Try it:
   Make a format that groups msrp in sashelp.cars into
   'Under $25k', '$25k-$50k', 'Over $50k' and use it in PROC FREQ. */
