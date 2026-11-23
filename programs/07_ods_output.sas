/* Lesson 7: getting tables out of SAS
   ODS HTML5, RTF, PDF, EXCEL, several destinations at once,
   ODS SELECT/EXCLUDE, ODS TRACE */

%let out = &root/output;
options orientation=portrait;

/* RTF: Word-compatible, what most clinical submissions use */
ods rtf file="&out/07_class.rtf" style=journal bodytitle;
title 'Students';
proc report data=sashelp.class;
  column name sex age height weight;
run;
ods rtf close;

/* PDF */
ods pdf file="&out/07_class.pdf" style=journal;
proc report data=sashelp.class;
  column name sex age height weight;
run;
ods pdf close;

/* Excel: one sheet per table, sheet names you choose */
ods excel file="&out/07_cars.xlsx" options(sheet_name='Europe' embedded_titles='yes');
title 'European cars';
proc report data=sashelp.cars;
  where origin = 'Europe';
  column make model msrp;
run;

ods excel options(sheet_name='Asia');
title 'Asian cars';
proc report data=sashelp.cars;
  where origin = 'Asia';
  column make model msrp;
run;
ods excel close;
title;

/* several destinations at once */
ods html5 file="&out/07_both.html";
ods rtf   file="&out/07_both.rtf";
proc report data=sashelp.class;
  column name age weight;
run;
ods _all_ close;
ods html5;   /* turn your normal results viewer back on (or ods html; in SAS Studio) */

/* landscape pages */
options orientation=landscape;
ods rtf file="&out/07_landscape.rtf";
proc report data=sashelp.cars(obs=30);
  column make model type origin drivetrain msrp invoice enginesize horsepower;
run;
ods rtf close;
options orientation=portrait;

/* statistical procedures print many tables. ODS TRACE gives their names */
ods trace on;
proc means data=sashelp.class;
  var height weight;
run;
proc ttest data=sashelp.class;
  class sex;
  var weight;
run;
ods trace off;

/* then keep only the ones you want */
ods select ttests;
proc ttest data=sashelp.class;
  class sex;
  var weight;
run;

ods exclude conflimits equality;
proc ttest data=sashelp.class;
  class sex;
  var weight;
run;

/* ODS NOPROCTITLE drops 'The TTEST Procedure' headings */
ods noproctitle;

/* Try it:
   Write one Excel file with three sheets: mean msrp by origin,
   by type, and by drivetrain. */
