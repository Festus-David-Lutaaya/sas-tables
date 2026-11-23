/* Lesson 1: your first table with PROC PRINT
   var, id, by, label, titles and footnotes, noobs, sum */

proc print data=sashelp.class;
run;

/* pick and order the columns */
proc print data=sashelp.class noobs;
  var name sex age height weight;
run;

/* labels instead of variable names */
proc print data=sashelp.class noobs label;
  var name sex age height weight;
  label height = 'Height (in)'
        weight = 'Weight (lb)';
run;

/* titles and footnotes stay on until you change or clear them */
title1 'Students in SASHELP.CLASS';
title2 'Height and weight';
footnote 'Source: SASHELP.CLASS';

proc print data=sashelp.class noobs label;
  var name age height weight;
run;

title;
footnote;

/* ID puts a column on the left and repeats it if the table wraps */
proc print data=sashelp.class;
  id name;
  var sex age height weight;
run;

/* BY groups need sorted data */
proc sort data=sashelp.class out=class;
  by sex name;
run;

proc print data=class noobs;
  by sex;
  var name age height weight;
run;

/* totals per group and overall */
proc print data=class noobs;
  by sex;
  var name age weight;
  sum weight;
run;

/* WHERE filters rows without a separate data step */
proc print data=sashelp.cars noobs;
  where origin = 'Europe' and horsepower > 400;
  var make model horsepower msrp;
run;

/* obs= for a quick look */
proc print data=sashelp.cars(obs=10) noobs;
run;

/* Try it:
   Print the 10 cheapest Asian cars from sashelp.cars
   (sort by msrp first), with make, model and msrp, a title and a footnote. */
