/* Lesson 12: building a summary table from pieces
   one "long" reporting dataset, macros for continuous and categorical
   rows, transpose to columns, PROC REPORT to finish

   This is the SAS way to get what gtsummary's tbl_summary() gives you.
   Every company has its own version of these macros. */

/* example data: sashelp.heart by sex */
data heart;
  set sashelp.heart;
  where not missing(smoking_status);
run;

/* group sizes for the column headers */
proc sql noprint;
  select count(*) into :n_f trimmed from heart where sex = 'Female';
  select count(*) into :n_m trimmed from heart where sex = 'Male';
  select count(*) into :n_t trimmed from heart;
quit;
%put Female=&n_f Male=&n_m Total=&n_t;

/* add a Total group by stacking the data on itself */
data heart2;
  set heart;
  output;
  sex = 'Total';
  output;
run;

/* continuous variable -> rows "n", "Mean (SD)", "Median (Q1, Q3)", "Min, Max" */
%macro cont(var=, label=, ord=, dec=1);
  proc means data=heart2 noprint nway;
    class sex;
    var &var;
    output out=_s n=n mean=mean std=sd median=med q1=q1 q3=q3 min=min max=max;
  run;

  %let d1 = %eval(&dec + 1);
  data _c_&ord;
    set _s;
    length label $60 stat $20 value $30;
    ord = &ord;
    label = "&label";
    stat = 'n';               sub = 1; value = strip(put(n, 8.));                                                     output;
    stat = 'Mean (SD)';       sub = 2; value = catx(' ', put(mean, 8.&d1), cats('(', put(sd, 8.&d1), ')'));   output;
    stat = 'Median (Q1, Q3)'; sub = 3; value = catx(' ', put(med, 8.&dec), cats('(', put(q1, 8.&dec), ',')), cats(put(q3, 8.&dec), ')')); output;
    stat = 'Min, Max';        sub = 4; value = catx(', ', put(min, 8.&dec), put(max, 8.&dec));              output;
    keep ord sub label stat sex value;
  run;
%mend;

/* categorical variable -> one row per level, "n (%)" */
%macro cat(var=, label=, ord=);
  proc freq data=heart2 noprint;
    tables sex * &var / outpct out=_f;
  run;

  data _c_&ord;
    set _f;
    length label $60 stat $20 value $30;
    ord = &ord;
    label = "&label";
    stat = &var;
    value = catx(' ', put(count, 5.), cats('(', put(pct_row, 5.1), '%)'));
    keep ord label stat sex value;
  run;

  /* keep the level order from the data */
  proc sort data=_c_&ord; by stat; run;
  data _c_&ord;
    set _c_&ord;
    by stat;
    retain sub 0;
    if first.stat then sub + 1;
  run;
%mend;

%cont(var=ageatstart,  label=%str(Age at start, years), ord=1, dec=0)
%cat (var=smoking_status, label=Smoking status, ord=2)
%cont(var=cholesterol, label=%str(Cholesterol, mg/dL), ord=3, dec=0)
%cat (var=weight_status, label=Weight status, ord=4)
%cont(var=systolic,    label=%str(Systolic BP, mmHg), ord=5, dec=0)

/* stack and turn sex into columns */
data long;
  set _c_:;
run;

proc sort data=long; by ord label sub stat; run;

proc transpose data=long out=wide(drop=_name_);
  by ord label sub stat;
  id sex;
  var value;
run;

/* finish with PROC REPORT */
proc report data=wide split='|'
    style(report)=[frame=hsides rules=groups]
    style(header)=[font_weight=bold];
  column ord label sub stat female male total;
  define ord    / order noprint;
  define label  / order noprint;
  define sub    / order noprint;
  define stat   / display '';
  define female / display "Female|N = &n_f" style(column)=[just=c cellwidth=1.3in];
  define male   / display "Male|N = &n_m"   style(column)=[just=c cellwidth=1.3in];
  define total  / display "Total|N = &n_t"  style(column)=[just=c cellwidth=1.3in];

  compute before label / style=[just=left font_weight=bold];
    line label $60.;
  endcomp;

  compute stat;
    call define(_col_, 'style', 'style=[leftmargin=12pt]');
  endcomp;
  title 'Characteristics by sex, Framingham heart study';
  footnote 'n (%) = number and percent of each column.';
run;
title; footnote;

/* Try it:
   Add bp_status as a categorical row block (ord=6) and diastolic BP as
   a continuous block (ord=7), then rerun the stack/transpose/report. */
