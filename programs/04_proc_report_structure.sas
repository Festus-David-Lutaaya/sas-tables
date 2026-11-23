/* Lesson 4: PROC REPORT structure
   spanning headers, ACROSS, computed columns, COMPUTE blocks,
   LINE statements, NOPRINT helper columns */

/* spanning headers: put a label and the columns in parentheses */
proc report data=sashelp.cars(obs=10);
  column make model ('Engine' enginesize cylinders horsepower)
                    ('Fuel economy (mpg)' mpg_city mpg_highway);
  define make  / display;
  define model / display;
  define mpg_city    / 'City';
  define mpg_highway / 'Highway';
run;

/* spanners can nest */
proc report data=sashelp.cars(obs=10);
  column model ('Specification' ('Engine' enginesize horsepower)
                                ('Size' length weight));
run;

/* ACROSS turns values of a variable into columns */
proc report data=sashelp.cars;
  column type origin;
  define type   / group;
  define origin / across 'Origin';
run;

/* across with a statistic under it */
proc report data=sashelp.cars;
  column type origin,msrp;
  define type   / group;
  define origin / across 'Origin';
  define msrp   / analysis mean 'Mean MSRP' format=dollar10.;
run;

/* computed columns: anything not in the data */
proc report data=sashelp.class;
  column name height weight bmi;
  define name   / display;
  define height / display;
  define weight / display;
  define bmi    / computed 'BMI' format=5.1;
  compute bmi;
    bmi = 703 * weight / height**2;
  endcomp;
run;

/* computed character column */
proc report data=sashelp.class;
  column name age weight status;
  define name   / display;
  define age    / display;
  define weight / display;
  define status / computed length=10 'Status';
  compute status / character length=10;
    if weight > 100 then status = 'Above 100';
    else status = '';
  endcomp;
run;

/* analysis columns inside COMPUTE are named variable.statistic */
proc report data=sashelp.class;
  column sex height weight ratio;
  define sex    / group;
  define height / analysis mean format=5.1;
  define weight / analysis mean format=5.1;
  define ratio  / computed format=5.2 'Weight / height';
  compute ratio;
    ratio = weight.mean / height.mean;
  endcomp;
run;

/* NOPRINT: use a column for sorting, but hide it.
   Make the order variable in a data step, then ORDER NOPRINT */
data class2;
  set sashelp.class;
  sexord = (sex = 'M');
run;

proc report data=class2;
  column sexord sex name age;
  define sexord / order noprint;
  define sex    / order;
  define name   / display;
  define age    / display;
run;

/* LINE writes text between groups or at the top/bottom */
proc format;
  value $sexlab 'F' = 'Girls'
                'M' = 'Boys';
run;

proc report data=class2;
  column sexord sex name age weight;
  define sexord / order noprint;
  define sex    / order noprint;
  define name   / display;
  define age    / display;
  define weight / analysis sum;

  compute before sex / style=[font_weight=bold just=left];
    line sex $sexlab.;
  endcomp;

  compute after sex;
    line ' ';
  endcomp;
run;

/* Try it:
   Show mean msrp by type (rows) and drivetrain (across), with a
   spanning header 'Drive train' and a LINE before the table saying
   'All prices are US dollars'. */
