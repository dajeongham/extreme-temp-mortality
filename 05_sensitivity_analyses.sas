/*******************************************************************************
 05_sensitivity_analyses.sas
 Sensitivity analyses based on Model 2. Run 02_cox_models.sas first
 (defines %COX and the covariate lists).

   1. Alternative percentile thresholds (95th/99th; 5th/1st)
   2. Cumulative (2- and 3-year) and duration-based (>= 2 or 3 consecutive days)
      exposure definitions
   3. Additional adjustment for calendar year (cubic term, centered at 2015)
   4. Additional adjustment for PM2.5 (2008-2020)
   5. Stratification by province
   6. Exclusion of follow-up during 2020-2022 (COVID-19 period)
*******************************************************************************/

libname a "<path to analysis data>";
libname r "<path to results>";

/* 1-2. Alternative exposure definitions ------------------------------------*/
%macro alt_exposures;
  %local k ex;
  %let EXLIST = HW95 HW99 CS05 CS01
                HW975_2YR HW975_3YR CS025_2YR CS025_3YR
                HW975_DUR2 HW975_DUR3 CS025_DUR2 CS025_DUR3;
  %do k = 1 %to %sysfunc(countw(&EXLIST));
    %let ex = %scan(&EXLIST, &k);
    %cox(exp=&ex, covs=&COV_MODEL2, label=Model2, out=SENS_&ex);
  %end;
%mend;
%alt_exposures;

/* 3. Calendar year (cubic polynomial centered at 2015) ----------------------*/
data work.cy;
  set a.COHORT40;
  yrc  = STD_YYYY_N - 2015;
  yrc2 = yrc**2;
  yrc3 = yrc**3;
run;
%cox(data=work.cy, exp=HW975, covs=&COV_MODEL2 yrc yrc2 yrc3, label=Model2+year, out=CY_HW975);
%cox(data=work.cy, exp=CS025, covs=&COV_MODEL2 yrc yrc2 yrc3, label=Model2+year, out=CY_CS025);

/* 4. PM2.5 (years with available estimates) ---------------------------------*/
data work.pm;
  set a.COHORT40;
  if 2008 <= STD_YYYY_N <= 2020 and not missing(PM25);
run;
%cox(data=work.pm, exp=HW975, covs=&COV_MODEL2 PM25, label=Model2+PM25, out=PM_HW975);
%cox(data=work.pm, exp=CS025, covs=&COV_MODEL2 PM25, label=Model2+PM25, out=PM_CS025);

/* 5. Stratification by province (urbanicity removed from covariates) ---------*/
%let COV_STRATA = SEX_TYPE SES annual_mean_hum annual_mean_temp;
%cox(exp=HW975, covs=&COV_STRATA, label=Province-strata, extra=strata SIDO, out=ST_HW975);
%cox(exp=CS025, covs=&COV_STRATA, label=Province-strata, extra=strata SIDO, out=ST_CS025);

/* 6. Exclusion of 2020-2022 --------------------------------------------------*/
data work.nocovid;
  set a.COHORT40;
  if 2020 <= STD_YYYY_N <= 2022 then delete;
run;
%cox(data=work.nocovid, exp=HW975, covs=&COV_MODEL2, label=Excl2020-2022, out=NC_HW975);
%cox(data=work.nocovid, exp=CS025, covs=&COV_MODEL2, label=Excl2020-2022, out=NC_CS025);
