# -------------------------------------------------------------------------
# GOAL: data quality, missing values
# DEFINITION: predicti the missing values from age 
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------

if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr, caret, fastDummies)


# load the data -----------------------------------------------------------

source("scripts/pre_process/name_features.R")


# deal NAs fare + embarked ------------------------------------------------

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


# fill missing age --------------------------------------------------------

# dummification for the variables to choose
dummy_data <- data %>% 
  dummy_cols(select_columns = c("status", "Pclass"))

# split between known data and unknown
df_unknown_age <- dummy_data %>% 
  filter(is.na(Age))
df_known_age <- dummy_data %>% 
  filter(!is.na(Age)) %>% 
  select(starts_with("status"), starts_with("Pclass"), 
         -status, -Pclass, SibSp, Age)
# they maintain the proportion of male and female, so there is no bias in that
# aspect. After looking at the main metrics, We can consider that our known 
# data is representative enough to use it to apply a logistic regression: 
mod_age <- lm(formula = Age ~ SibSp + status + Pclass,
               data = train)
summary(mod_age)
# let's test the model 
results <- predict(mod_age, newdata = test)
postResample(pred = results, obs = test$Age)
# once we have detected the main variable that can berepresentative, let's see
# if we can use other algoritms to find relations
# data partition
train_id <- createDataPartition(
  y = df_known_age$Age, 
  p = 0.75, 
  list = F
)
train <- df_known_age[train_id,]
test <- df_known_age[-train_id,]
# create a cross validation
ctrl <- trainControl(method = "repeatedcv",
                     repeats = 3)
# create the mdoel to predict the age
mod_dt <- rpart::rpart(Age ~ SibSp + status + Pclass,
             data = df_known_age)
rpart.plot::prp(mod_dt,, type = 2, nn = TRUE,
                fallen.leaves = TRUE, faclen = 4, varlen = 8, 
                shadow.col = "gray", roundint=FALSE)

                