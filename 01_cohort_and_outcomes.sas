/*******************************************************************************
 01_cohort_and_outcomes.sas
 Build the analytic cohort (ages 40-100), attach causes of death, and define
 cause-specific death indicators, deprivation groups, and exposure variables.

 Input  : COHORT      - annual person-year records (one row per person-year) with
                        START_AGE, END_AGE, STD_YYYY_N (follow-up year), ALL_DEATH,
                        covariates, area deprivation score (sum_z), and annual
                        exposures assigned from the preceding year (t-1)
          DTH         - death records (INDI_DSCM_NO, DTH_ASSMD_DT)
          COD         - causes of death (INDI_DSCM_NO, DTH_CODE1, DTH_CODE2)
 Output : a.COHORT40
*******************************************************************************/

libname src "<path to NHIS input data>";
libname a   "<path to analysis data>";

/* 1. Attach causes of death ------------------------------------------------*/
proc sql;
  create table work.death as
  select d.INDI_DSCM_NO, d.DTH_ASSMD_DT, c.DTH_CODE1, c.DTH_CODE2
  from src.DTH as d left join src.COD as c
    on d.INDI_DSCM_NO = c.INDI_DSCM_NO;

  create table work.cohort_cod as
  select a.*, b.DTH_CODE1, b.DTH_CODE2
  from src.COHORT as a left join work.death as b
    on a.INDI_DSCM_NO = b.INDI_DSCM_NO;
quit;

proc sort data=work.cohort_cod; by INDI_DSCM_NO STD_YYYY_N; run;

/* 2. Cause-specific death indicators (DTH_CODE1 or DTH_CODE2) ---------------
   Death and cause indicators are assigned only to the final person-year
   interval of decedents; all earlier intervals are coded 0.                   */
data work.cohort_cod;
  set work.cohort_cod;
  by INDI_DSCM_NO;
  DEATH = (last.INDI_DSCM_NO and ALL_DEATH = 1);
  ALL_DEATH = DEATH;

  NEX=0; EXT=0; CVD_IHD=0; CVD_CERE=0; CVD_HF=0; RES_COPD=0; RES_PNEU=0;
  REN_RF=0; NEU_DEM=0; NEU_AD=0; NEU_PD=0; CANCER=0;

  if DEATH = 1 then do;
    array cods[2] $4 _temporary_;
    cods[1] = DTH_CODE1; cods[2] = DTH_CODE2;
    do i = 1 to 2;
      c3 = substr(cods[i], 1, 3);
      if c3 = '' then continue;
      if 'I20' <= c3 <= 'I25' then CVD_IHD  = 1;   /* ischemic heart disease  */
      if 'I60' <= c3 <= 'I69' then CVD_CERE = 1;   /* cerebrovascular disease */
      if c3 = 'I50'            then CVD_HF   = 1;   /* heart failure           */
      if 'J40' <= c3 <= 'J44' then RES_COPD = 1;   /* COPD                    */
      if 'J12' <= c3 <= 'J18' then RES_PNEU = 1;   /* pneumonia               */
      if 'N17' <= c3 <= 'N19' then REN_RF   = 1;   /* renal failure           */
      if 'F00' <= c3 <= 'F03' then NEU_DEM  = 1;   /* dementia                */
      if c3 = 'G30'            then NEU_AD   = 1;   /* Alzheimer's disease     */
      if c3 = 'G20'            then NEU_PD   = 1;   /* Parkinson's disease     */
      if 'C00' <= c3 <= 'C97' then CANCER   = 1;   /* cancer                  */
      if 'V01' <= c3 <= 'Y98' then EXT      = 1;   /* external causes         */
      if 'A00' <= c3 <= 'R99' then NEX      = 1;   /* non-accidental          */
    end;
    if EXT = 1 then NEX = 0;
  end;
  drop i c3 DEATH;
run;

/* 3. Analytic cohort: person-time at ages 40-100 ----------------------------*/
data a.COHORT40;
  set work.cohort_cod;
  if START_AGE > 100 or END_AGE > 101 then delete;
  if START_AGE >= 40 and END_AGE >= 41 and END_AGE > START_AGE;
run;

/* 4. Area deprivation groups: lowest vs highest quartile of person-years ----*/
proc univariate data=a.COHORT40 noprint;
  var sum_z;
  output out=work.cut P25=P25 P75=P75;
run;

data a.COHORT40;
  if _n_ = 1 then set work.cut;
  set a.COHORT40;
  if      sum_z <= P25 then DEPR_GRP = 0;   /* low deprivation  */
  else if sum_z >= P75 then DEPR_GRP = 1;   /* high deprivation */
  else DEPR_GRP = .;                         /* middle half excluded from comparison */
  drop P25 P75;
run;

/* 5. Exposure variables (annual counts assigned from year t-1) ---------------
   HW975 : extreme high temperature days (>= 97.5th percentile, Jun-Aug)
   CS025 : extreme low temperature days  (<= 2.5th percentile, Dec-Feb)        */
data a.COHORT40;
  set a.COHORT40;
  HW975      = heatwave_days_975;
  CS025      = coldspell_days_025;
  /* alternative thresholds */
  HW95       = heatwave_days_95;
  HW99       = heatwave_days_99;
  CS05       = coldspell_days_05;
  CS01       = coldspell_days_01;
  /* cumulative exposure over the preceding 2 and 3 years */
  HW975_2YR  = sum(heatwave_days_975, heatwave_days_975_lag1);
  HW975_3YR  = sum(heatwave_days_975, heatwave_days_975_lag1, heatwave_days_975_lag2);
  CS025_2YR  = sum(coldspell_days_025, coldspell_days_025_lag1);
  CS025_3YR  = sum(coldspell_days_025, coldspell_days_025_lag1, coldspell_days_025_lag2);
  /* duration-based definitions: days within runs of >= 2 or >= 3 consecutive days */
  HW975_DUR2 = heatwave_days_975_dur2;
  HW975_DUR3 = heatwave_days_975_dur3;
  CS025_DUR2 = coldspell_days_025_dur2;
  CS025_DUR3 = coldspell_days_025_dur3;
run;

/* 6. Check: persons, person-years, and deaths -------------------------------*/
proc sql;
  select count(distinct INDI_DSCM_NO) as N_persons,
         sum(PY) format=comma14.      as Person_years,
         sum(ALL_DEATH)               as Deaths,
         sum(NEX)                     as NEX_deaths
  from a.COHORT40;
quit;
