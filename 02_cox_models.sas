/*******************************************************************************
 02_cox_models.sas
 Time-varying Cox proportional hazards models with attained age as the time
 scale (counting-process input: START_AGE, END_AGE). HRs per 10-day increase.

   Crude   : exposure only
   Model 2 : + sex, income, urbanicity, annual mean temperature and humidity (primary)
   Model 3 : Model 2 + smoking, alcohol consumption, physical activity

 The macro %COX is also used in 03-05.
*******************************************************************************/

libname a "<path to analysis data>";
libname r "<path to results>";

options threads cpucount=actual;
ods graphics off;

%let OUTCOMES = NEX CVD_IHD CVD_CERE CVD_HF RES_COPD RES_PNEU REN_RF
                NEU_DEM NEU_AD NEU_PD CANCER;

%let COV_CRUDE  = ;
%let COV_MODEL2 = SEX_TYPE SES URBANICITY annual_mean_hum annual_mean_temp;
%let COV_MODEL3 = &COV_MODEL2 SMOKE ALCOHOL PA;
%let CLASSVARS  = SEX_TYPE SES URBANICITY SMOKE ALCOHOL PA;

/* data=   input data set           exp=     exposure variable
   covs=   covariates               label=   model label
   extra=  optional PHREG statement (e.g., strata)                            */
%macro cox(data=a.COHORT40, exp=, covs=, label=, extra=, out=);
  %local i outc;
  proc datasets lib=work nolist nowarn; delete _res; quit;
  ods select none;
  %do i = 1 %to %sysfunc(countw(&OUTCOMES));
    %let outc = %scan(&OUTCOMES, &i);
    proc phreg data=&data;
      class &CLASSVARS / param=ref;
      model (START_AGE, END_AGE)*&outc(0) = &exp &covs / ties=breslow;
      &extra;
      ods output ParameterEstimates=_pe;
    run;
    data _pe;
      set _pe;
      where Parameter = "&exp";
      length outcome exposure model $40;
      outcome = "&outc"; exposure = "&exp"; model = "&label";
      HR     = exp(10*Estimate);
      HR_LCL = exp(10*(Estimate - 1.959964*StdErr));
      HR_UCL = exp(10*(Estimate + 1.959964*StdErr));
      keep outcome exposure model HR HR_LCL HR_UCL ProbChiSq;
    run;
    proc append base=_res data=_pe force; run;
  %end;
  ods select all;
  data r.&out; set _res; run;
%mend;

/* Main analysis ------------------------------------------------------------*/
%cox(exp=HW975, covs=&COV_CRUDE,  label=Crude,   out=HW975_CRUDE);
%cox(exp=HW975, covs=&COV_MODEL2, label=Model2,  out=HW975_M2);
%cox(exp=HW975, covs=&COV_MODEL3, label=Model3,  out=HW975_M3);
%cox(exp=CS025, covs=&COV_CRUDE,  label=Crude,   out=CS025_CRUDE);
%cox(exp=CS025, covs=&COV_MODEL2, label=Model2,  out=CS025_M2);
%cox(exp=CS025, covs=&COV_MODEL3, label=Model3,  out=CS025_M3);
