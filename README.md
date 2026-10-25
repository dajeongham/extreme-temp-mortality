# Analysis code

Analysis code for a nationwide cohort study of annual extreme high and low temperature days and cause-specific mortality among adults aged 40 years or older in Korea (National Health Insurance Service 5% random sample, 2007–2023).

## Data availability

The National Health Insurance Service (NHIS) data cannot be shared because of NHIS data-sharing restrictions. All analyses were performed in the NHIS secure analysis environment. Meteorological data are publicly available from the Korea Meteorological Administration (https://data.kma.go.kr).

## Software

SAS 9.4

## Files

| File | Description |
|---|---|
| `01_cohort_and_outcomes.sas` | Builds the analytic cohort (ages 40–100), links causes of death (DTH_CODE1 or DTH_CODE2), defines cause-specific death indicators, area deprivation groups (lowest vs highest quartile), and exposure variables assigned from the preceding year |
| `02_cox_models.sas` | Time-varying Cox proportional hazards models with attained age as the time scale (crude, Model 2, Model 3); hazard ratios per 10-day increase |
| `03_effect_modification.sas` | Effect modification by area deprivation and urbanicity, and subgroup analyses by sex and age group; group-specific HRs from product-term models and P for interaction from Wald tests |
| `04_fine_gray.sas` | Fine–Gray subdistribution hazard models treating death from other causes as a competing event |
| `05_sensitivity_analyses.sas` | Alternative thresholds, cumulative and duration-based exposures, calendar-year adjustment, PM2.5 adjustment (2008–2020), province stratification, and exclusion of 2020–2022 |

## Exposure definitions

- Extreme high temperature days: days from June to August with daily mean temperature at or above the district-specific 97.5th percentile
- Extreme low temperature days: days from December of the preceding year to February with daily mean temperature at or below the district-specific 2.5th percentile
- Each follow-up year *t* was assigned exposure from year *t* − 1

## Outcomes (ICD-10)

| Outcome | Variable | Codes |
|---|---|---|
| Non-accidental death | `NEX` | A00–R99 |
| Ischemic heart disease | `CVD_IHD` | I20–I25 |
| Cerebrovascular disease | `CVD_CERE` | I60–I69 |
| Heart failure | `CVD_HF` | I50 |
| Chronic obstructive pulmonary disease | `RES_COPD` | J40–J44 |
| Pneumonia | `RES_PNEU` | J12–J18 |
| Renal failure | `REN_RF` | N17–N19 |
| Dementia | `NEU_DEM` | F00–F03 |
| Alzheimer's disease | `NEU_AD` | G30 |
| Parkinson's disease | `NEU_PD` | G20 |
| Cancer | `CANCER` | C00–C97 |

Files should be run in order. Library paths (`<path ...>`) must be set to the local environment.
