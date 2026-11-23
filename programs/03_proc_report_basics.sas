/* Lesson 3: PROC REPORT basics
   column, define (display, order, group, analysis), rbreak, break

   PROC REPORT is the SAS tool for building finished tables.
   Almost every clinical TLF you will see is made with it. */

/* with no statements it behaves like PROC PRINT */
proc report data=sashelp.class;
run;

/* COLUMN picks and orders, DEFINE says how each one behaves */
proc report data=sashelp.class;
  column name sex age height weight;
  define name   / display 'Name';
  define sex    / display 'Sex';
  define age    / display 'Age';
  define height / display 'Height (in)' format=5.1;
  define weight / display 'Weight (lb)' format=5.1;
run;

/* ORDER sorts and only prints a value when it changes */
proc report data=sashelp.class;
  column sex name age weight;
  define sex  / order 'Sex';
  define name / order 'Name';
  define age  / display;
  define weight / display format=5.1;
run;

/* GROUP collapses rows, ANALYSIS summarises numbers within the group */
proc report data=sashelp.class;
  column sex age height weight;
  define sex    / group 'Sex';
  define age    / analysis mean 'Mean age' format=5.1;
  define height / analysis mean 'Mean height' format=5.1;
  define weight / analysis mean 'Mean weight' format=5.1;
run;

/* N and several statistics for one variable: use aliases */
proc report data=sashelp.class;
  column sex n weight=wmean weight=wsd weight=wmax;
  define sex   / group 'Sex';
  define n     / 'N';
  define wmean / analysis mean 'Mean' format=5.1;
  define wsd   / analysis std  'SD'   format=5.2;
  define wmax  / analysis max  'Max'  format=5.1;
run;

/* or put statistics in the column statement directly */
proc report data=sashelp.class;
  column sex weight,(n mean std min max);
  define sex    / group;
  define weight / 'Weight (lb)';
  define mean   / format=5.1;
  define std    / format=5.2;
run;

/* totals: RBREAK at the end of the report, BREAK after each group */
proc report data=sashelp.cars;
  where origin = 'Europe';
  column make type msrp;
  define make / group;
  define type / group;
  define msrp / analysis sum format=dollar14.;
  break after make / summarize;
  rbreak after / summarize;
run;

/* a labelled total line. The group column must be long enough to
   hold the word 'Total' (origin is $6, so it fits; sex is $1, it would not) */
proc report data=sashelp.cars;
  column origin n horsepower;
  define origin     / group 'Origin';
  define n          / 'N';
  define horsepower / analysis mean format=5.0 'Mean HP';
  rbreak after / summarize style=[font_weight=bold];
  compute after;
    origin = 'Total';
  endcomp;
run;

/* Try it:
   From sashelp.cars show, for each origin, the number of cars and the
   mean horsepower and mean msrp, with a total row at the bottom. */
