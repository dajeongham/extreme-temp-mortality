/*******************************************************************************
 04_fine_gray.sas
 Fine-Gray subdistribution hazard models treating death from other causes as a
 competing event (Model 2 covariates, attained age as the time scale).
*******************************************************************************/

libname a "<path to analysis data>";
libname r "<path to results>";

%let OUTCOMES = NEX CVD_IHD CVD_CERE CVD_HF RES_COPD RES_PNEU REN_RF
                NEU_DEM NEU_AD NEU_PD CANCER;

%macro fg(exp=);
  %local i outc conv;
  proc datasets lib=work nolist nowarn; delete _res; quit;
  %do i = 1 %to %sysfunc(countw(&OUTCOMES));
    %let outc = %scan(&OUTCOMES, &i);
    /* FG_EVENT: 1 = cause of interest, 2 = death from other causes, 0 = censored */
    data _fg;
      set a.COHORT40;
      if      &outc = 1     then FG_EVENT = 1;
      else if ALL_DEATH = 1 then FG_EVENT = 2;
      else                       FG_EVENT = 0;
    run;
    proc phreg data=_fg;
      class SEX_TYPE SES URBANICITY / param=ref;
      model (START_AGE, END_AGE)*FG_EVENT(0) =
            &exp SEX_TYPE SES URBANICITY annual_mean_hum annual_mean_temp
            / eventcode=1 ties=breslow;
      ods output ParameterEstimates=_pe ConvergenceStatus=_cs;
    run;
    %let conv = 1;
    data _null_; set _cs; call symputx('conv', Status); run;
    %if &conv = 0 %then %do;
      data _pe;
        set _pe; where Parameter = "&exp";
        length outcome exposure $40;
        outcome = "&outc"; exposure = "&exp";
        sHR     = exp(10*Estimate);
        sHR_LCL = exp(10*(Estimate - 1.959964*StdErr));
        sHR_UCL = exp(10*(Estimate + 1.959964*StdErr));
        keep outcome exposure sHR sHR_LCL sHR_UCL ProbChiSq;
      run;
      proc append base=_res data=_pe force; run;
    %end;
    %else %put WARNING: Fine-Gray model for &exp / &outc did not converge.;
  %end;
  data r.FG_&exp; set _res; run;
%mend;

%fg(exp=HW975);
%fg(exp=CS025);
