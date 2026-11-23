/* Lesson 16 (clinical 3): efficacy table and subgroup forest plot
   response rates with exact CIs, logistic odds ratios,
   subgroup analysis with BY processing, forest plot with SGPLOT.
   Uses work.adsl from 00_setup.sas. */

%let out = &root/output;

/* response rate with 95% CI by arm --------------------------------- */

proc sort data=work.adsl out=adsl; by armn; run;

ods output binomialcls = bin;
proc freq data=adsl;
  by armn arm;
  tables response / binomial(level='1' cl=wilson);
run;

proc freq data=adsl noprint;
  by armn arm;
  tables response / out=resp_n;
run;

data resp_rate;
  merge resp_n(where=(response = 1)) bin;
  by armn arm;
  length rate_ci $40;
  rate_ci = cats(count, ' (', put(percent, 5.1), '%) [',
                 put(100*lowercl, 5.1), ', ', put(100*uppercl, 5.1), ']');
  keep armn arm rate_ci;
run;

/* odds ratios vs placebo. The Effect column reads "arm Drug 10 mg vs Placebo" */
ods output oddsratios = or_arm;
proc logistic data=adsl;
  class arm (ref='Placebo') / param=ref;
  model response (event='1') = arm;
run;

data or_arm2;
  set or_arm;
  length arm $12 or_ci $30;
  arm = substr(effect, 5, index(effect, ' vs ') - 5);
  or_ci = cats(put(oddsratioest, 5.2), ' (', put(lowercl, 5.2), ', ', put(uppercl, 5.2), ')');
  keep arm or_ci;
run;

proc sql;
  create table eff as
  select r.armn, r.arm, r.rate_ci, coalescec(o.or_ci, '') as or_ci
  from resp_rate as r left join or_arm2 as o
       on r.arm = o.arm
  order by r.armn;
quit;

/* subgroups: Drug 20 mg vs placebo ------------------------------------ */

data two;
  set work.adsl;
  where armn in (1, 3);
  trt = (armn = 3);
run;

%macro subgroup(var=, label=, ord=);
  proc sort data=two out=_t; by &var; run;

  ods output oddsratios = _o;
  proc logistic data=_t;
    by &var;
    model response (event='1') = trt;
  run;

  /* interaction p-value from the full data */
  ods output type3 = _t3;
  proc logistic data=two;
    class &var / param=ref;
    model response (event='1') = trt &var trt*&var;
  run;

  data _null_;
    set _t3;
    where upcase(effect) = upcase("trt*&var");
    call symputx('pint', probchisq);
  run;

  proc freq data=_t noprint;
    by &var;
    tables trt / out=_n;
  run;
  proc means data=_n noprint nway;
    by &var;
    var count;
    output out=_nn sum=n;
  run;

  data _sg&ord;
    merge _o _nn(keep=&var n);
    by &var;
    length group $20 level $20;
    ord = &ord;
    group = "&label";
    level = &var;
    pint = ifn(_n_ = 1, &pint, .);
    keep ord group level n oddsratioest lowercl uppercl pint;
  run;
%mend;

%subgroup(var=sex,    label=Sex,        ord=1)
%subgroup(var=agegr1, label=Age group,  ord=2)
%subgroup(var=hiv,    label=HIV status, ord=3)
%subgroup(var=site,   label=Site,       ord=4)

/* overall row */
proc sql noprint;
  select count(*) into :ntwo trimmed from two;
quit;

ods output oddsratios = _all;
proc logistic data=two;
  model response (event='1') = trt;
run;

data _sg0;
  set _all;
  length group $20 level $20;
  ord = 0; group = 'Overall'; level = 'All patients';
  n = &ntwo;
  keep ord group level n oddsratioest lowercl uppercl;
run;

data forest_plot;
  set _sg0 _sg1-_sg4;
  length or_ci $30 ylab $50 pint_c $8;
  or_ci = cats(put(oddsratioest, 5.2), ' (', put(lowercl, 5.2), ', ', put(uppercl, 5.2), ')');
  if ord = 0 then ylab = 'All patients';
  else ylab = catx(': ', group, level);
  if not missing(pint) then pint_c = put(pint, 5.3);
run;

/* table version */
ods rtf file="&out/t_14_2_eff.rtf" style=journal bodytitle;

title1 j=l 'Table 14.2.1';
title2 j=l 'Week 12 response';
title3 j=l 'Intent-to-treat population';
footnote1 j=l 'n (%) [95% Wilson CI]. Odds ratios from logistic regression, placebo as reference.';

proc report data=eff split='|' style(report)=[width=100%];
  column armn arm rate_ci or_ci;
  define armn    / order noprint;
  define arm     / display 'Arm';
  define rate_ci / display 'Responders|n (%) [95% CI]' style(column)=[just=c];
  define or_ci   / display 'Odds ratio vs placebo|(95% CI)' style(column)=[just=c];
run;

title1 j=l 'Figure 14.2.2';
title2 j=l 'Week 12 response by subgroup, Drug 20 mg vs placebo';
footnote1 j=l 'Odds ratios > 1 favour Drug 20 mg. P = treatment-by-subgroup interaction.';

ods graphics on / width=7in height=5in;
proc sgplot data=forest_plot noautolegend;
  scatter y=ylab x=oddsratioest / xerrorlower=lowercl xerrorupper=uppercl
          markerattrs=(symbol=squarefilled color=cx1F4E79);
  refline 1 / axis=x lineattrs=(pattern=shortdash color=grey);
  yaxistable n      / location=inside position=left label='N';
  yaxistable or_ci  / location=inside position=right label='OR (95% CI)';
  yaxistable pint_c / location=inside position=right label='P';
  xaxis type=log logbase=10 min=0.1 max=20 label='Odds ratio (log scale)';
  yaxis discreteorder=data reverse display=(nolabel);
run;

ods rtf close;
title; footnote;

/* Try it:
   Redo the subgroup analysis with PROC PHREG on tte*cnsr(1) and plot
   hazard ratios instead of odds ratios. */
