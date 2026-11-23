/* Lesson 9: PROC TABULATE
   class, var, table, nesting with *, side by side with space, ALL,
   statistics and formats, labels, styles

   TABULATE is the quickest way to a cross-tab with statistics.
   For fully controlled TLFs you will usually go back to PROC REPORT. */

/* one dimension */
proc tabulate data=sashelp.cars;
  class origin;
  table origin;
run;

/* rows, columns */
proc tabulate data=sashelp.cars;
  class origin type;
  table type, origin;
run;

/* totals with ALL */
proc tabulate data=sashelp.cars;
  class origin type;
  table type all, origin all;
run;

/* an analysis variable and statistics: * means "crossed with" */
proc tabulate data=sashelp.cars;
  class origin;
  var msrp;
  table origin, msrp*(n mean std);
run;

/* formats and labels inside the table statement */
proc tabulate data=sashelp.cars;
  class origin type;
  var msrp horsepower;
  table type = 'Vehicle type' all = 'All types',
        origin = '' * msrp = 'MSRP' * mean = 'Mean' * f = dollar10.
        horsepower = 'Horsepower' * mean = 'Mean' * f = 6.0;
run;

/* percents: pctn, rowpctn, colpctn */
proc tabulate data=sashelp.heart;
  class sex status;
  table sex all, status * (n colpctn = '%' * f = 5.1);
run;

/* nesting on rows */
proc tabulate data=sashelp.cars;
  class origin type;
  var msrp;
  table origin * type, msrp * mean * f = dollar10.;
run;

/* missing class values are dropped unless you ask for them */
proc tabulate data=sashelp.heart missing;
  class smoking_status;
  table smoking_status all, n pctn;
run;

/* tidier look */
proc tabulate data=sashelp.cars style=[font_size=9pt];
  class origin type / style=[font_weight=bold];
  classlev type / style=[just=left];
  var msrp;
  table type = '' all = 'Total', origin = '' * msrp = '' * mean = '' * f = dollar10.
        / box = 'Mean MSRP by type and origin' misstext = '-';
run;

/* output as a dataset */
proc tabulate data=sashelp.cars out=tab_out;
  class origin type;
  var msrp;
  table type, origin * msrp * mean;
run;

proc print data=tab_out(obs=10) noobs; run;

/* Try it:
   From sashelp.heart, tabulate status (columns) against
   weight_status (rows) with n and column percent, plus totals both ways. */
