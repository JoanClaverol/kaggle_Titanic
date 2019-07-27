# -------------------------------------------------------------------------
# GOAL: create a model to predict age  
# DEFINITION: based in previous analysis, we are going to use svmLinear with
# feateures like status, pclass, Sibs, Fare and age
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------
if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr, fastDummies, caret, doParallel)

# load data ---------------------------------------------------------------
source("scripts/data_quality/1_NA_embarked_fare.R")


# fill missing age --------------------------------------------------------

# dummification for the variables to choose
dummy_data <- data %>% 
  dummy_cols(select_columns = c("Pclass", "status"))


# split between known data and unknown, and select the variables which are 
# relevant to define the age: 
df_unknown_age <- dummy_data %>% 
  filter(is.na(Age))
df_known_age <- dummy_data %>% 
  filter(!is.na(Age), id == "train") 
# they maintain the proportion of male and female, so there is no bias in that
# aspect. After looking at the main metrics, We can consider that our known 
# data is representative enough to use it to apply a logistic regression: 
# data partition
source("scripts/model/fun_model_creation.R")
dummy_data %>% select(starts_with("status"),-status, 
                 starts_with("Pclass"),-Pclass, 
                 SibSp, Fare, Age) -> temp
mod <- modalization(data = df_known_age, 
             p_partition = 0.8,
             cv_repeats = 5, cv_number = 3, 
             x = "Age", y = names(temp), 
             model_name = "svmLinear", set_seed = 666)

# plot the errors
results <- predict(object = mod, newdata = df_known_age)
df_known_age$pred <- round(results,0)
df_known_age %>% 
  mutate(error = Age - pred) %>% 
  ggplot() +
  geom_density(aes(x = pred), fill = "blue", alpha = 0.3) +
  geom_density(aes(x = Age), fill = "green", alpha = 0.3)-> p1
plotly::ggplotly(p1)


# save the model ----------------------------------------------------------

write_rds(mod, path = "models/svmLinear_NA_age.rds")
