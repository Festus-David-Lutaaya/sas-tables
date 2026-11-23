/* Lesson 13: advanced PROC REPORT and automation
   page breaks, dynamic headers from data, BY-group tables in a loop,
   CALL EXECUTE, dataset-driven reports, ODS TEXT, inline formatting */

%let out = &root/output;

/* page break after each group in RTF/PDF */
proc sort data=sashelp.cars out=cars; by origin make; run;

ods rtf file="&out/13_pages.rtf";
proc report data=cars(where=(msrp > 60000));
  column origin make model msrp;
  define origin / order noprint;
  define make   / order;
  define model  / display;
  define msrp   / display format=dollar10.;
  break after origin / page;
  compute before _page_ / style=[just=left font_weight=bold];
    line 'Origin: ' origin $6.;
  endcomp;
run;
ods rtf close;

/* #byval in titles: one table per BY group, title changes with the group */
options nobyline;
title 'Expensive cars from #byval(origin)';
proc report data=cars(where=(msrp > 60000));
  by origin;
  column make model msrp;
  define msrp / format=dollar10.;
run;
options byline;
title;

/* headers from data: counts go into macro variables with SQL */
proc sql noprint;
  select origin, count(*)
    into :org1-, :cnt1-
    from sashelp.cars
    group by origin;
  %let n_org = &sqlobs;
quit;
%put &n_org groups: &org1 (&cnt1), &org2 (&cnt2), &org3 (&cnt3);

/* a macro loop that writes one table per type into one file */
%macro by_type;
  proc sql noprint;
    select distinct type into :t1- from sashelp.cars;
    %let nt = &sqlobs;
  quit;

  ods rtf file="&out/13_by_type.rtf" startpage=no;
  %do i = 1 %to &nt;
    title "Type: &&t&i";
    proc report data=sashelp.cars(where=(type = "&&t&i"));
      column origin msrp=n msrp;
      define origin / group;
      define n      / analysis n 'N';
      define msrp   / analysis mean 'Mean MSRP' format=dollar10.;
    run;
  %end;
  ods rtf close;
  title;
%mend;
%by_type

/* CALL EXECUTE: let a dataset drive the code */
data _null_;
  set sashelp.class(where=(age = 15));
  call execute('title "Student: ' || strip(name) || '";');
  call execute('proc print data=sashelp.class(where=(name="' || strip(name) || '")) noobs; run;');
run;
title;

/* inline formatting with the escape character ^ (set in 00_setup) */
proc report data=sashelp.class(obs=4);
  column name height;
  define height / 'Height^{super a}';
  compute after;
    line '^{super a} Inches, measured at enrolment.';
  endcomp;
run;

/* ODS TEXT adds paragraphs between tables in RTF/PDF */
ods pdf file="&out/13_text.pdf";
ods text = '^{style [font_weight=bold font_size=12pt]Section 1. Cars}';
ods text = 'The table below lists European cars over $80,000.';
proc report data=sashelp.cars(where=(origin='Europe' and msrp > 80000));
  column make model msrp;
  define msrp / format=dollar10.;
run;
ods pdf close;

/* Try it:
   Write a macro %one_table(origin=) that prints mean horsepower and
   msrp by type for that origin, then call it for all three origins
   using CALL EXECUTE from a dataset of distinct origins. */
