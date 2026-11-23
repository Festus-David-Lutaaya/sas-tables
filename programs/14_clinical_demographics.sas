/* Lesson 14 (clinical 1): demographics and baseline table
   Uses work.adsl from 00_setup.sas.
   Same idea as lesson 12, written the way a TLF program usually is. */

%let out = &root/output;

/* treatment columns: 1-3 = arms, 4 = total */
data adsl2;
  set work.adsl;
  output;
  armn = 4; arm = 'Total';
  output;
run;

/* big N for the headers */
proc sql noprint;
  select count(*) into :n1 trimmed from adsl2 where armn = 1;
  select count(*) into :n2 trimmed from adsl2 where armn = 2;
  select count(*) into :n3 trimmed from adsl2 where armn = 3;
  select count(*) into :n4 trimmed from adsl2 where armn = 4;
quit;

%macro cont(var=, label=, ord=, dec=1);
  %local d1;
  %let d1 = %eval(&dec + 1);

  proc means data=adsl2 noprint nway;
    class armn;
    var &var;
    output out=_s n=n nmiss=nmiss mean=mean std=sd median=med q1=q1 q3=q3 min=min max=max;
  run;

  data _r&ord;
    set _s;
    length label $60 stat $20 value $30;
    ord = &ord; label = "&label";
    sub = 1; stat = 'n';               value = strip(put(n, 8.)); output;
    sub = 2; stat = 'Mean (SD)';       value = catx(' ', put(mean, 8.&d1), cats('(', put(sd, 8.&d1), ')')); output;
    sub = 3; stat = 'Median';          value = strip(put(med, 8.&d1)); output;
    sub = 4; stat = 'Q1, Q3';          value = catx(', ', put(q1, 8.&d1), put(q3, 8.&d1)); output;
    sub = 5; stat = 'Min, Max';        value = catx(', ', put(min, 8.&dec), put(max, 8.&dec)); output;
    if nmiss > 0 then do;
      sub = 6; stat = 'Missing';       value = strip(put(nmiss, 8.)); output;
    end;
    keep ord sub label stat armn value;
  run;
%mend;

%macro cat(var=, label=, ord=);
  proc freq data=adsl2 noprint;
    tables armn * &var / missing outpct out=_f;
  run;

  data _r&ord;
    set _f;
    length label $60 stat $20 value $30;
    ord = &ord; label = "&label";
    stat = coalescec(&var, 'Missing');
    value = catx(' ', put(count, 5.), cats('(', put(pct_row, 5.1), ')'));
    keep ord label stat armn value;
  run;

  proc sort data=_r&ord; by stat armn; run;
  data _r&ord;
    set _r&ord;
    by stat;
    if first.stat then sub + 1;
  run;
%mend;

%cont(var=age,     label=%str(Age, years),     ord=1, dec=0)
%cat (var=agegr1,  label=Age group, ord=2)
%cat (var=sex,     label=Sex,     ord=3)
%cont(var=weight,  label=%str(Weight, kg),     ord=4, dec=1)
%cont(var=bmi,     label=%str(BMI, kg/m^{super 2}), ord=5, dec=1)
%cat (var=hiv,     label=HIV status, ord=6)
%cat (var=site,    label=Study site, ord=7)

data long;
  set _r1-_r7;
run;

proc sort data=long; by ord label sub stat; run;

proc transpose data=long out=t_demo(drop=_name_) prefix=trt;
  by ord label sub stat;
  id armn;
  var value;
run;

/* empty cells should read 0 rather than blank */
data t_demo;
  set t_demo;
  array t trt1-trt4;
  do over t;
    if missing(t) then t = '0';
  end;
run;

ods rtf file="&out/t_14_1_1_demo.rtf" style=journal bodytitle;

title1 j=l 'Table 14.1.1';
title2 j=l 'Demographic and baseline characteristics';
title3 j=l 'Safety population';
footnote1 j=l 'Categorical rows: n (%), using the number of subjects in each column as the denominator.';
footnote2 j=l 'Simulated data for teaching.';

proc report data=t_demo split='|' missing
    style(report)=[width=100% frame=hsides rules=groups]
    style(header)=[font_weight=bold];
  column ord label sub stat trt1 ('Active treatment' trt2 trt3) trt4;
  define ord   / order noprint;
  define label / order noprint;
  define sub   / order noprint;
  define stat  / display '' style(column)=[leftmargin=12pt cellwidth=2.2in];
  define trt1  / display "Placebo|N = &n1"    style(column)=[just=c];
  define trt2  / display "Drug 10 mg|N = &n2" style(column)=[just=c];
  define trt3  / display "Drug 20 mg|N = &n3" style(column)=[just=c];
  define trt4  / display "Total|N = &n4"      style(column)=[just=c];

  compute before label / style=[just=left font_weight=bold];
    line label $60.;
  endcomp;
run;

ods rtf close;
title; footnote;

/* Try it:
   Add baseline viral load (base_vl) as a continuous block that shows
   only n and median (Q1, Q3), with no decimals. */
