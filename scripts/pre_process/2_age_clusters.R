# -------------------------------------------------------------------------
# GOAL: feature engineering: age groups
# DEFINITION: create a representative groups for the age
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------
if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(stringr)

# load data ---------------------------------------------------------------
source("scripts/pre_process/1_name_features.R")


# exploration -------------------------------------------------------------
# strange values smaller than 1 for age, don't know what to do with them. 
# I am assuming that they are wrong, so I am going to replace them by NAs 
# and try to predict cluster where they are
data %<>% 
  mutate(Age = replace(Age, Age < 1, NA))

# age clusters ------------------------------------------------------------
# create a vector with the know values of age
df_age_clean <- data %>% 
  filter(!is.na(Age)) %>% select(PassengerId, Age)
age <- df_age_clean$Age
# decide the size of k
k <- 3
# then we creat the differente clusters and we add them into the dataframe
df_age_clean$age_cl <- cut(age, breaks = k, right = T, include.lowest = T)
# now we can add them into our data
data %<>% 
  left_join(df_age_clean %>% select(-Age), by = 'PassengerId')


# remove environment ------------------------------------------------------

rm(df_age_clean, age, k)
