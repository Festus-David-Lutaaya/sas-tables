/* Lesson 5: styling PROC REPORT
   style(report|header|column|summary|lines)=, CALL DEFINE,
   traffic lighting with formats

   Styles show up in ODS destinations (HTML, RTF, PDF, Excel),
   not in the old LISTING output. */

/* whole-table styles on the PROC statement */
proc report data=sashelp.class
    style(report)=[frame=hsides rules=groups cellpadding=4]
    style(header)=[background=cxD9E2F3 font_weight=bold]
    style(column)=[font_size=10pt];
  column name sex age height weight;
run;

/* one column */
proc report data=sashelp.class;
  column name sex age height weight;
  define name   / display style(column)=[font_weight=bold];
  define height / display style(column)=[just=c cellwidth=1in];
  define weight / display style(header)=[color=darkred];
run;

/* conditional styling with CALL DEFINE in a COMPUTE block */
proc report data=sashelp.class;
  column name age height weight;
  define name   / display;
  define age    / display;
  define height / display;
  define weight / display;

  compute weight;
    if weight > 110 then
      call define(_col_, 'style', 'style=[background=cxFFF3CD font_weight=bold]');
  endcomp;
run;

/* highlight the whole row: use _row_ */
proc report data=sashelp.class;
  column name sex age weight;
  define name   / display;
  define sex    / display;
  define age    / display;
  define weight / display;

  compute weight;
    if weight > 110 then
      call define(_row_, 'style', 'style=[background=cxFDECEA]');
  endcomp;
run;

/* compute blocks run left to right, so to style one column using a
   value further right, attach the block to the rightmost one */
proc report data=sashelp.class;
  column name age weight;
  define name   / display;
  define age    / display;
  define weight / display;

  compute weight;
    if age >= 15 then call define('name', 'style', 'style=[color=navy font_style=italic]');
  endcomp;
run;

/* traffic lighting with a format: no compute block needed */
proc format;
  value hbcol low -< 11 = 'cxF8D7DA'
              11 - high = 'white';
  value wbccol low -< 4  = 'cxF8D7DA'
               4 - 11    = 'white'
               11 <- high = 'cxF8D7DA';
run;

data labs;
  input id $ hb wbc;
  datalines;
P01 13.1 6.2
P02 9.8 12.4
P03 14.2 5.1
P04 12.0 3.2
P05 8.9 7.7
P06 15.1 4.8
;
run;

proc report data=labs;
  column id hb wbc;
  define id  / display 'Patient';
  define hb  / display 'Hb (g/dL)' format=5.1 style(column)=[background=hbcol.];
  define wbc / display 'WBC (x10^{super 9}/L)' format=5.1 style(column)=[background=wbccol.];
  footnote 'Shaded values are outside the reference range.';
run;
footnote;

/* summary rows have their own style location */
proc report data=sashelp.cars style(summary)=[font_weight=bold background=cxEEEEEE];
  where origin = 'Asia';
  column make msrp;
  define make / group;
  define msrp / analysis mean format=dollar10.;
  rbreak after / summarize;
run;

/* Try it:
   Show sashelp.cars European models with horsepower > 300.
   Make msrp red when it is over 100000, and bold the whole row for Porsche. */
