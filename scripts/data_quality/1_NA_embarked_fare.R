# -------------------------------------------------------------------------
# GOAL: deal with miss values in emarked and fare
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------

if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr, caret, fastDummies, doParallel)


# load the data -----------------------------------------------------------

source("scripts/pre_process/1_name_features.R")


# deal NAs fare + embarked ------------------------------------------------

# embarked


# cabin


# Fare missing values 
df_miss_fare <- data %>% 
  filter(is.na(Fare))
# he is from the third class. He is an old man, and without any declared 
# family on board. 
df_male_class3 <- data %>% 
  filter(Sex == "male", Pclass == "3")
# plot(x = df_male_class3$Fare, y = df_male_class3$total_family)
# there is a strong relation between the number of family that was on board 
# with the fare that a passanger paid. We are going to create a linear model 
# to predict the missing value and replace into the data
mod_fare_NA <- lm(formula = Fare ~ total_family, 
                  data = df_male_class3)
miss_fare <- predict(object = mod_fare_NA, newdata = df_miss_fare)
data %<>% 
  mutate(Fare = replace(Fare, is.na(Fare), miss_fare))

# Emarked missing values
# both are from 1st class, female, young and old. After some exploration, I can
# conclude that, next to the cabin, the embarked variable is not representative
# enough to predict if someone has survived or not. 


# clean environment -------------------------------------------------------

rm(df_male_class3, df_miss_fare, mod_fare_NA, miss_fare)


