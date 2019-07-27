# -------------------------------------------------------------------------
# GOAL: feature engineering: age groups
# DEFINITION: create a representative groups for the age
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------
if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(stringr, magrittr)

# load data ---------------------------------------------------------------
source("scripts/data_quality/2_NA_age.R")

# age clusters ------------------------------------------------------------
# define groups of age in relation to 
#   0  - 13
#   14 - 25
#   26 - 35
#   36 - 45
#   46 - Max
data %<>% 
  mutate(age_cl = if_else(
    Age <= 13, "0 - 13", if_else(
      Age > 13 & Age <= 25, "14 -25", if_else(
        Age > 25 & Age <= 35, "25 - 35", if_else(
          Age > 35 & Age <= 45, "36 - 45", if_else(
            Age > 45, "46 - Max", "Unknown"))))))