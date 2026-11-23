/* Simulated trial data used by the clinical lessons.
   ADSL = one row per subject, ADAE = one row per adverse event.
   Names loosely follow CDISC ADaM. */

data work.adsl;
  call streaminit(2026);
  length usubjid $10 arm $12 site $8 sex $6 hiv $8 agegr1 $5;

  do i = 1 to 240;
    usubjid = cats('STUDY-', put(i, z3.));

    u = rand('uniform');
    if u < 1/3 then do; arm = 'Placebo';    armn = 1; end;
    else if u < 2/3 then do; arm = 'Drug 10 mg'; armn = 2; end;
    else do; arm = 'Drug 20 mg'; armn = 3; end;

    u = rand('uniform');
    if u < 0.4 then site = 'Kampala';
    else if u < 0.6 then site = 'Gulu';
    else if u < 0.8 then site = 'Mbarara';
    else site = 'Mbale';

    age = max(18, round(rand('normal', 42, 13)));
    if age <= 34 then agegr1 = '18-34';
    else if age <= 49 then agegr1 = '35-49';
    else agegr1 = '50+';

    sex = ifc(rand('uniform') < 0.5, 'Female', 'Male');
    weight = round(rand('normal', 66, 11), 0.1);
    height = round(rand('normal', 165, 9), 0.1);
    bmi = round(weight / (height/100)**2, 0.1);
    hiv = ifc(rand('uniform') < 0.15, 'Positive', 'Negative');
    base_vl = round(exp(rand('normal', 8, 1.2)));

    /* a few missing values */
    if rand('uniform') < 0.025 then call missing(weight, bmi);

    /* outcomes */
    eff = choosen(armn, 0, 0.6, 1.0);
    lp = -0.4 + eff - 0.01*(age - 42) - 0.3*(hiv = 'Positive');
    response = rand('bernoulli', logistic(lp));

    tte = round(rand('exponential') / (0.02 * exp(-0.5*eff)), 0.1);
    cnsr = (tte > 52);
    tte = min(tte, 52);

    saffl = 'Y';
    output;
  end;

  label usubjid = 'Subject ID'
        arm     = 'Treatment arm'
        age     = 'Age, years'
        agegr1  = 'Age group'
        sex     = 'Sex'
        weight  = 'Weight, kg'
        height  = 'Height, cm'
        bmi     = 'BMI, kg/m2'
        hiv     = 'HIV status'
        site    = 'Study site'
        base_vl = 'Baseline viral load, copies/mL'
        response = 'Responder at week 12'
        tte     = 'Weeks to clinical failure'
        cnsr    = 'Censored (1=yes)';

  drop i u eff lp;
run;

/* adverse events: each subject gets a chance at every term */
data work.ae_terms;
  length aebodsys $40 aedecod $20;
  infile datalines dlm='|';
  input aebodsys $ aedecod $ rate;
  datalines;
Gastrointestinal disorders|Nausea|0.18
Gastrointestinal disorders|Diarrhoea|0.12
Gastrointestinal disorders|Vomiting|0.06
Nervous system disorders|Headache|0.20
Nervous system disorders|Dizziness|0.08
Skin and subcutaneous tissue disorders|Rash|0.07
Skin and subcutaneous tissue disorders|Pruritus|0.05
General disorders|Fatigue|0.15
General disorders|Pyrexia|0.09
Investigations|ALT increased|0.04
;
run;

proc sql;
  create table work._ae_all as
  select a.usubjid, a.arm, a.armn, t.aebodsys, t.aedecod, t.rate
  from work.adsl as a, work.ae_terms as t;
quit;

data work.adae;
  call streaminit(77);
  set work._ae_all;
  length aesev $8 aeser $1;
  mult = choosen(armn, 1, 1.4, 1.9);
  if rand('uniform') < rate * mult;

  u = rand('uniform');
  if u < 0.6 then do; aesev = 'Mild';     aesevn = 1; end;
  else if u < 0.9 then do; aesev = 'Moderate'; aesevn = 2; end;
  else do; aesev = 'Severe'; aesevn = 3; end;

  aeser = ifc(aesev = 'Severe' and rand('uniform') < 0.4, 'Y', 'N');

  label aebodsys = 'System organ class'
        aedecod  = 'Preferred term'
        aesev    = 'Severity'
        aeser    = 'Serious';
  drop rate mult u;
run;

proc datasets lib=work nolist;
  delete _ae_all ae_terms;
quit;
