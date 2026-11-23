/* Lesson 15 (clinical 2): adverse event tables
   overview table, then SOC / PT table with subject counts.
   Uses work.adsl and work.adae from 00_setup.sas. */

%let out = &root/output;

/* denominators */
proc sql noprint;
  select count(*) into :n1 trimmed from work.adsl where armn = 1;
  select count(*) into :n2 trimmed from work.adsl where armn = 2;
  select count(*) into :n3 trimmed from work.adsl where armn = 3;
quit;

data bign;
  armn = 1; bign = &n1; output;
  armn = 2; bign = &n2; output;
  armn = 3; bign = &n3; output;
run;

/* Overview: any AE, any serious, any severe ---------------------- */

proc sql;
  create table subj_flags as
  select a.usubjid, a.armn,
         max(e.usubjid is not null)    as any_ae,
         max(coalesce(e.aeser = 'Y', 0)) as any_sae,
         max(coalesce(e.aesevn = 3, 0))  as any_sev
  from work.adsl as a
       left join work.adae as e
       on a.usubjid = e.usubjid
  group by a.usubjid, a.armn;
quit;

proc sql;
  create table overview as
  select 1 as ord, 'Any adverse event' as label length=40, armn, sum(any_ae) as n
    from subj_flags group by armn
  union all
  select 2, 'Any serious adverse event', armn, sum(any_sae)
    from subj_flags group by armn
  union all
  select 3, 'Any severe adverse event', armn, sum(any_sev)
    from subj_flags group by armn;
quit;

/* SOC / PT counts ----------------------------------------------- */
/* count each subject once per term and once per SOC */

proc sql;
  create table pt as
  select aebodsys, aedecod, armn, count(distinct usubjid) as n
  from work.adae
  group by aebodsys, aedecod, armn;

  create table soc as
  select aebodsys, 'Any event' as aedecod length=20, armn, count(distinct usubjid) as n
  from work.adae
  group by aebodsys, armn;

  create table anyae as
  select 'Any adverse event' as aebodsys length=40, '' as aedecod length=20,
         armn, count(distinct usubjid) as n
  from work.adae
  group by armn;
quit;

data soc_pt;
  set anyae(in=a) soc(in=s) pt;
  length level 8;
  if a then level = 0;
  else if s then level = 1;
  else level = 2;
run;

/* n (%) text, with the arm denominator */
%macro npct(in=);
  proc sql;
    create table _np as
    select x.*, b.bign
    from &in as x left join bign as b on x.armn = b.armn;
  quit;

  data _np;
    set _np;
    length value $20;
    value = catx(' ', put(n, 4.), cats('(', put(100*n/bign, 5.1), ')'));
  run;
%mend;

%npct(in=soc_pt)

proc sort data=_np; by level aebodsys aedecod armn; run;

proc transpose data=_np out=ae_wide(drop=_name_) prefix=trt;
  by level aebodsys aedecod;
  id armn;
  var value;
run;

data ae_wide;
  set ae_wide;
  array t trt1-trt3;
  do over t;
    if missing(t) then t = '0';
  end;
  /* sort: the "any" row first, then each SOC with its own summary row first */
  socord = (level > 0);
  ptord  = (level = 2);
  length rowlab $60;
  if level = 0 then rowlab = aebodsys;
  else if level = 1 then rowlab = aebodsys;
  else rowlab = aedecod;
run;

proc sort data=ae_wide; by socord aebodsys ptord aedecod; run;

/* the same for the overview table */
%npct(in=overview)
proc sort data=_np; by ord label armn; run;
proc transpose data=_np out=ov_wide(drop=_name_) prefix=trt;
  by ord label;
  id armn;
  var value;
run;

/* output ---------------------------------------------------------- */

ods rtf file="&out/t_14_3_ae.rtf" style=journal bodytitle;
footnote1 j=l 'Subjects are counted once per row. Percentages use the arm N.';
footnote2 j=l 'Simulated data for teaching.';

title1 j=l 'Table 14.3.0';
title2 j=l 'Overview of adverse events';
title3 j=l 'Safety population';

proc report data=ov_wide split='|' style(report)=[width=100%];
  column ord label trt1-trt3;
  define ord   / order noprint;
  define label / display '';
  define trt1  / display "Placebo|N = &n1"    style(column)=[just=c];
  define trt2  / display "Drug 10 mg|N = &n2" style(column)=[just=c];
  define trt3  / display "Drug 20 mg|N = &n3" style(column)=[just=c];
run;

title1 j=l 'Table 14.3.1';
title2 j=l 'Adverse events by system organ class and preferred term';
title3 j=l 'Safety population';

proc report data=ae_wide split='|' style(report)=[width=100%];
  column socord aebodsys ptord aedecod rowlab level trt1-trt3;
  define socord   / order noprint;
  define aebodsys / order noprint;
  define ptord    / order noprint;
  define aedecod  / order noprint;
  define rowlab   / display 'System organ class|  Preferred term' style(column)=[cellwidth=3in];
  define level    / display noprint;
  define trt1     / display "Placebo|N = &n1"    style(column)=[just=c];
  define trt2     / display "Drug 10 mg|N = &n2" style(column)=[just=c];
  define trt3     / display "Drug 20 mg|N = &n3" style(column)=[just=c];

  compute level;
    if level < 2 then call define(_row_, 'style', 'style=[font_weight=bold]');
    else call define('rowlab', 'style', 'style=[leftmargin=14pt]');
  endcomp;

  compute after aebodsys;
    line ' ';
  endcomp;
run;

ods rtf close;
title; footnote;

/* Try it:
   Make a version for serious events only (aeser = 'Y') and sort the
   preferred terms within each SOC by descending frequency in Drug 20 mg. */
