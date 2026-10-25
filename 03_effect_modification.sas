/*******************************************************************************
 03_effect_modification.sas
 Effect modification by area deprivation and urbanicity (and, in subgroup
 analyses, sex and age group). For each modifier, the modifier and its product
 term with the exposure were added to the primary model (Model 2).
 Group-specific HRs per 10-day increase were obtained from the product-term
 model, and the product term was tested with a Wald test.
*******************************************************************************/

libname a "<path to analysis data>";
libname r "<path to results>";

%let OUTCOMES = NEX CVD_IHD CVD_CERE CVD_HF RES_COPD RES_PNEU REN_RF
                NEU_DEM NEU_AD NEU_PD CANCER;

/* exp=      exposure variable
   modifier= effect modifier (class variable)
   mclass=   other class covariates
   mcov=     Model 2 covariates excluding the modifier                        */
%macro em(exp=, modifier=, mclass=, mcov=);
  %local i outc;
  proc datasets lib=work nolist nowarn; delete _res; quit;
  ods select none;
  %do i = 1 %to %sysfunc(countw(&OUTCOMES));
    %let outc = %scan(&OUTCOMES, &i);
    proc phreg data=a.COHORT40(where=(&modifier is not missing));
      class &mclass &modifier / param=ref;
      model (START_AGE, END_AGE)*&outc(0) =
            &exp &modifier &exp*&modifier &mcov / ties=breslow;
      hazardratio "&exp" &exp / at(&modifier=ALL) units=10 cl=wald;
      ods output HazardRatios=_hr Type3=_t3;
    run;
    data _p; set _t3; where upcase(Effect) = upcase("&exp*&modifier");
      P_INT = ProbChiSq; keep P_INT; run;
    data _hr;
      if _n_ = 1 then set _p;
      set _hr;
      length outcome exposure modifier $40;
      outcome = "&outc"; exposure = "&exp"; modifier = "&modifier";
      HR = HazardRatio; HR_LCL = WaldLower; HR_UCL = WaldUpper;
      keep outcome exposure modifier Description HR HR_LCL HR_UCL P_INT;
    run;
    proc append base=_res data=_hr force; run;
  %end;
  ods select all;
  data r.EM_&modifier._&exp; set _res; run;
%mend;

%macro em_all(exp=);
  /* area deprivation: 0 = lowest quartile, 1 = highest quartile */
  %em(exp=&exp, modifier=DEPR_GRP,   mclass=SEX_TYPE SES URBANICITY,
      mcov=SEX_TYPE SES URBANICITY annual_mean_hum annual_mean_temp);
  /* urbanicity */
  %em(exp=&exp, modifier=URBANICITY, mclass=SEX_TYPE SES,
      mcov=SEX_TYPE SES annual_mean_hum annual_mean_temp);
  /* subgroup analyses */
  %em(exp=&exp, modifier=SEX_TYPE,   mclass=SES URBANICITY,
      mcov=SES URBANICITY annual_mean_hum annual_mean_temp);
  %em(exp=&exp, modifier=AGE_GRP,    mclass=SEX_TYPE SES URBANICITY,
      mcov=SEX_TYPE SES URBANICITY annual_mean_hum annual_mean_temp);
%mend;

%em_all(exp=HW975);
%em_all(exp=CS025);
