# -------------------------------------------------------------------------
# GOAL: data quality
# DEFINITION: check inconsistency of the data
# - missing values
# - duplicated passangers
# -------------------------------------------------------------------------


# libraries ---------------------------------------------------------------

if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr)


# load the data -----------------------------------------------------------

source("scripts/data_import/import_format.R")


# data clean --------------------------------------------------------------

data %>% 
  select(-Cabin) %>% 
  filter_all(any_vars(is.na(.)))

data %>% 
  