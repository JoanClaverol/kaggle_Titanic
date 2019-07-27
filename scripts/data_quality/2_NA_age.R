# -------------------------------------------------------------------------
# GOAL: deal with miss values in emarked and fare
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------

if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr, readr, fastDummies, modelr, magrittr)


# load the data -----------------------------------------------------------
# load from previous data quality
source("scripts/data_quality/1_NA_embarked_fare.R")

# load the model to predict age
mod <- read_rds("models/model_NA_age.rds")


# data exploration --------------------------------------------------------
# strange values smaller than 1 for age, don't know what to do with them. 
# I am assuming that they are wrong, so I am going to replace them by NAs 
# and try to predict cluster where they are
data %<>% 
  mutate(Age = replace(Age, Age < 1, NA))

# apply the model ---------------------------------------------------------
# dummify the data to apply the model
data %<>% 
  dummy_cols(select_columns = c("Pclass", "status")) %>% 
  add_predictions(model = mod, var = "pred") %>% 
  mutate(Age = if_else(is.na(Age), as.integer(round(pred,0)), 
                       as.integer(Age))) %>% 
  select(-starts_with("status"), status, 
         -starts_with("Pclass"), Pclass, -pred)

# clean environment -------------------------------------------------------
rm(mod)
