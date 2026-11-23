/* Lesson 6: ODS styles and your own style template
   built-in styles, PROC TEMPLATE, a reusable journal look */

%let out = &root/output;

/* see what styles exist */
proc template;
  list styles;
run;

/* the same table in three built-in styles */
%macro show(style);
  ods html5 file="&out/06_style_&style..html" style=&style;
  title "Style: &style";
  proc report data=sashelp.class(obs=6);
    column name sex age height weight;
  run;
  ods html5 close;
%mend;

%show(htmlblue)
%show(journal)
%show(pearl)
title;

/* your own style: start from one and change a few things */
proc template;
  define style styles.labtable;
    parent = styles.journal;

    class fonts /
      'TitleFont'   = ('Arial', 11pt, bold)
      'TitleFont2'  = ('Arial', 10pt)
      'headingFont' = ('Arial', 9pt, bold)
      'docFont'     = ('Arial', 9pt)
      'footFont'    = ('Arial', 8pt);

    class header /
      backgroundcolor = cxEEF2F7
      color = black;

    class table /
      frame = hsides
      rules = groups
      cellpadding = 3pt
      borderwidth = 1pt;

    class systemtitle /
      just = left;
  end;
run;

ods html5 file="&out/06_style_labtable.html" style=styles.labtable;
title 'Students';
footnote 'Source: SASHELP.CLASS';
proc report data=sashelp.class;
  column name sex age height weight;
run;
ods html5 close;
title; footnote;

/* Templates are saved in SASUSER by default. To keep them with the project:
   libname tpl "&root/templates";
   ods path (prepend) tpl.templat(update);
   then run PROC TEMPLATE once. */

/* a style for RTF output used in clinical work: Courier 9pt, no shading */
proc template;
  define style styles.tlf;
    parent = styles.rtf;
    class fonts /
      'TitleFont'   = ('Courier New', 9pt)
      'TitleFont2'  = ('Courier New', 9pt)
      'headingFont' = ('Courier New', 9pt)
      'docFont'     = ('Courier New', 9pt)
      'footFont'    = ('Courier New', 8pt);
    class header / backgroundcolor = white;
    class table / frame = hsides rules = groups cellpadding = 1pt;
    class body / topmargin = 1in bottommargin = 1in leftmargin = 1in rightmargin = 1in;
  end;
run;

/* Try it:
   Make a style called styles.darkhead with a navy header and white
   header text, and use it for one table in HTML5 and one in RTF. */
