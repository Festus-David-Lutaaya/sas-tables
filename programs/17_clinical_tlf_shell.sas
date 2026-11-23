/* Lesson 17 (clinical 4): a reusable TLF shell
   standard titles, "Page x of y", program name and run date,
   small macros to open, footnote and close every output.
   Uses work.adsl from 00_setup.sas. */

%let out = &root/output;

/* house style: Courier 9pt, lines above and below the header only */
proc template;
  define style styles.tlf;
    parent = styles.rtf;
    class fonts /
      'TitleFont'   = ('Courier New', 9pt)
      'TitleFont2'  = ('Courier New', 9pt)
      'headingFont' = ('Courier New', 9pt)
      'docFont'     = ('Courier New', 9pt)
      'footFont'    = ('Courier New', 8pt);
    class header / backgroundcolor = white font_weight = medium;
    class systemtitle / backgroundcolor = white;
    class systemfooter / backgroundcolor = white;
    class table / frame = hsides rules = groups cellpadding = 1pt cellspacing = 0;
    class body / topmargin = 1in bottommargin = 1in leftmargin = 1in rightmargin = 1in;
  end;
run;

/* open: titles, footnotes and the RTF file */
%macro tlf_open(file=, num=, title=, pop=, prog=, orient=portrait);
  options orientation=&orient nodate nonumber;
  ods escapechar = '^';
  ods listing close;
  ods rtf file="&out/&file..rtf" style=styles.tlf;   /* titles go in the page header so Page x of y works */

  title1 j=l "STUDY-001 (simulated)" j=r "Page ^{thispage} of ^{lastpage}";
  title2 j=l "Table &num";
  title3 j=l "&title";
  title4 j=l "&pop";

  %global _tlf_prog;
  %let _tlf_prog = &prog;
%mend;

/* footnotes: up to two lines of your own, then the program line */
%macro tlf_foot(foot1=, foot2=);
  %local fn;
  %let fn = 1;
  %if %length(&foot1) %then %do;
    footnote&fn j=l "&foot1";
    %let fn = %eval(&fn + 1);
  %end;
  %if %length(&foot2) %then %do;
    footnote&fn j=l "&foot2";
    %let fn = %eval(&fn + 1);
  %end;
  footnote&fn j=l "Program: &_tlf_prog" j=r "Run: %sysfunc(today(), yymmdd10.) %sysfunc(time(), tod5.)";
%mend;

/* footnotes must be set before the procedure runs, so the order is:
   %tlf_open, %tlf_foot, the PROC, %tlf_end */

%macro tlf_end;
  ods rtf close;
  ods listing;
  title; footnote;
%mend;

/* Table 14.1.2: age and sex by arm, using PROC TABULATE inside the shell */
%tlf_open(file=t_14_1_2_age_sex, num=14.1.2, title=%str(Age and sex by treatment arm),
          pop=Safety population, prog=t_age_sex.sas)
%tlf_foot(foot1=%str(Age: mean (SD). Sex: n and column percent.))

proc tabulate data=work.adsl;
  class arm sex;
  var age;
  table age = 'Age, years' * (mean = 'Mean' * f = 5.1 std = 'SD' * f = 5.2)
        sex = 'Sex' * (n = 'n' * f = 4. colpctn = '%' * f = 5.1),
        arm = '' all = 'Total'
        / box = ' ' misstext = '0';
run;

%tlf_end

/* Listing 16.2.1: subject listing over many pages, landscape */
%tlf_open(file=l_16_2_1_subjects, num=16.2.1, title=%str(Subject listing),
          pop=All randomised subjects, prog=l_subjects.sas, orient=landscape)
%tlf_foot(foot1=%str(BMI = weight (kg) / height (m) squared.))

proc report data=work.adsl split='|' style(report)=[width=100%];
  column armn arm usubjid site age sex weight height bmi hiv;
  define armn    / order noprint;
  define arm     / order 'Arm';
  define usubjid / order 'Subject';
  define site    / display 'Site';
  define age     / display 'Age';
  define sex     / display 'Sex';
  define weight  / display 'Weight|(kg)' format=5.1;
  define height  / display 'Height|(cm)' format=5.1;
  define bmi     / display 'BMI' format=5.1;
  define hiv     / display 'HIV';
  break after armn / page;
run;

%tlf_end

/* Running a whole set of outputs:
   keep one program per table (t_demo.sas, t_ae.sas, ...) that all
   %include a common setup and use these macros, then a driver program:

   %include "&root/programs/14_clinical_demographics.sas";
   %include "&root/programs/15_clinical_adverse_events.sas";
   %include "&root/programs/16_clinical_efficacy_subgroups.sas";

   Check the log for ERROR and WARNING after every run. */

/* Try it:
   Put lesson 14's demographics table inside %tlf_open / %tlf_foot /
   %tlf_end so it gets the page numbers and program footer. */
