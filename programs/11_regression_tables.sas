/* Lesson 11: regression tables
   PROC GLM / REG, PROC LOGISTIC, PROC PHREG with ODS OUTPUT,
   building "estimate (95% CI)" tables with PROC REPORT */

/* linear regression */
ods output parameterestimates = lm_pe;
proc glm data=sashelp.class;
  class sex;
  model weight = height sex / solution clparm;
run;
quit;

proc print data=lm_pe noobs; run;

/* logistic regression: odds ratios come in their own table */
data heart;
  set sashelp.heart;
  dead = (status = 'Dead');
run;

ods output oddsratios = lr_or parameterestimates = lr_pe;
proc logistic data=heart;
  class sex (ref='Female') smoking_status (ref='Non-smoker') / param=ref;
  model dead (event='1') = ageatstart sex smoking_status cholesterol;
run;

proc print data=lr_or noobs; run;

/* build the display column */
data lr_tab;
  set lr_or;
  length or_ci $30;
  or_ci = cats(put(oddsratioest, 5.2), ' (', put(lowercl, 5.2), ', ', put(uppercl, 5.2), ')');
run;

proc report data=lr_tab;
  column effect or_ci;
  define effect / display 'Effect';
  define or_ci  / display 'Odds ratio (95% CI)' style(column)=[just=c];
  title 'Logistic regression for death';
run;
title;

/* p-values are in the parameter estimates table (lr_pe, column probchisq).
   Their rows are named by variable and classval0, so match them yourself
   when you need both in one table. */
proc print data=lr_pe noobs;
  var variable classval0 estimate probchisq;
run;

proc format;
  picture pvalf (round)
          low -< 0.001 = '<0.001' (noedit)
          0.001 - high = '9.999';
run;

/* Cox model: hazard ratios.
   sashelp.heart has no follow-up time, so use the simulated trial data
   from 00_setup.sas (work.adsl): tte = weeks, cnsr = 1 if censored */
ods output parameterestimates = cox_pe;
proc phreg data=work.adsl;
  class arm (ref='Placebo') hiv (ref='Negative') / param=ref;
  model tte*cnsr(1) = arm age hiv / risklimits;
run;

data cox_tab;
  set cox_pe;
  length term $40 hr_ci $30;
  term = catx(' ', parameter, classval0);
  hr_ci = cats(put(hazardratio, 5.2), ' (', put(hrlowercl, 5.2), ', ', put(hruppercl, 5.2), ')');
run;

proc report data=cox_tab;
  column term hr_ci probchisq;
  define term      / display 'Term';
  define hr_ci     / display 'HR (95% CI)' style(column)=[just=c];
  define probchisq / display 'P' format=pvalf. style(column)=[just=c];
  title 'Cox model';
run;
title;

/* univariable models in a loop */
%macro uni(var, class=);
  ods output oddsratios = _or_&var;
  proc logistic data=heart;
    %if &class ne %then %do; class &var / param=ref; %end;
    model dead (event='1') = &var;
  run;
%mend;

%uni(ageatstart)
%uni(cholesterol)
%uni(sex, class=yes)

data uni_or;
  length effect $60;
  set _or_ageatstart _or_cholesterol _or_sex;
  length or_ci $30;
  or_ci = cats(put(oddsratioest, 5.2), ' (', put(lowercl, 5.2), ', ', put(uppercl, 5.2), ')');
run;

proc print data=uni_or noobs;
  var effect or_ci;
run;

/* Try it:
   Fit a Cox model on work.adsl with arm and sex, and build the
   HR (95% CI) table with p-values. */
