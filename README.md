# Tables in SAS

Lesson programs for building publication and clinical tables in SAS,
from PROC PRINT to submission-style TLFs with PROC REPORT and ODS.

New to SAS? Start with
[base-sas-foundations](https://github.com/Festus-David-Lutaaya/base-sas-foundations)
(DATA step, SQL, macros, debugging), then come back here.

This is the SAS companion to
[gt-tables-in-r](https://github.com/Festus-David-Lutaaya/gt-tables-in-r).
PROC REPORT + ODS plays the role of gt; the statistics procedures
(MEANS, FREQ, TTEST, LOGISTIC, PHREG) play the role of gtsummary.

## Learning order

| # | Program | What you learn | R lesson |
|---|---------|----------------|----------|
| 00 | `00_setup.sas` | paths, options, simulated trial data | 00 |
| **Part 1: building tables** | | | |
| 01 | `01_proc_print_basics.sas` | PROC PRINT, titles, footnotes, BY, SUM | 01 |
| 02 | `02_formats.sas` | built-in formats, PROC FORMAT, picture formats | 03 |
| 03 | `03_proc_report_basics.sas` | COLUMN, DEFINE, display/order/group/analysis, totals | 01-02 |
| 04 | `04_proc_report_structure.sas` | spanning headers, ACROSS, computed columns, LINE | 02, 04 |
| 05 | `05_proc_report_styling.sas` | STYLE(), CALL DEFINE, traffic lighting | 05 |
| 06 | `06_ods_styles_templates.sas` | ODS styles, PROC TEMPLATE | 06 |
| 07 | `07_ods_output.sas` | RTF, PDF, Excel, ODS SELECT, ODS TRACE | 07 |
| **Part 2: statistics into tables** | | | |
| 08 | `08_means_freq_output.sas` | MEANS / FREQ / UNIVARIATE into datasets, ODS OUTPUT | 08 |
| 09 | `09_proc_tabulate.sas` | PROC TABULATE | 10 |
| 10 | `10_tests_and_pvalues.sas` | t-test, Wilcoxon, chi-square, collecting p-values | 09 |
| 11 | `11_regression_tables.sas` | GLM, LOGISTIC, PHREG estimate tables | 11 |
| **Part 3: putting it together** | | | |
| 12 | `12_summary_table_macros.sas` | macro-built "Table 1": stack, transpose, report | 14 |
| 13 | `13_advanced_report.sas` | page breaks, #byval, macro loops, CALL EXECUTE | 15 |
| **Part 4: clinical case studies** | | | |
| 14 | `14_clinical_demographics.sas` | demographics table, RTF | 16 |
| 15 | `15_clinical_adverse_events.sas` | AE overview and SOC/PT table | 17 |
| 16 | `16_clinical_efficacy_subgroups.sas` | response rates, ORs, subgroup forest plot | 18 |
| 17 | `17_clinical_tlf_shell.sas` | TLF macros, Page x of y, listings | 19 |

### Why this order

PROC REPORT first, on SASHELP data, because every finished table ends
there. Then the statistics procedures, focused on getting their numbers
into datasets with OUTPUT and ODS OUTPUT. Part 3 joins the two: compute,
reshape, report. The clinical programs use all of it.

## How to use

1. Put this folder somewhere SAS can see it. On SAS OnDemand for Academics
   (free) upload it to your home folder.
2. Open `programs/00_setup.sas`, change `%let root =` to that folder,
   and run it. It creates `output/` and the simulated datasets
   `work.adsl` and `work.adae`.
3. Run the lessons in order. Re-run `00_setup.sas` in each new session.

Each program ends with a short "Try it" exercise.

The simulated trial data are made by `macros/clinical_data.sas`.
