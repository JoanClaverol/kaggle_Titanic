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

source("scripts/pre_process/2_age_clusters.R")


# deal NAs fare + embarked ------------------------------------------------

# Fare missing values 
df_miss_fare <- data %>% 
  filter(is.na(Fare))
# he is from the third class. He is an old man, and without any declared 
# family on board. 
df_male_class3 <- data %>% 
  filter(Sex == "male", Pclass == "3")
plot(x = df_male_class3$Fare, y = df_male_class3$total_family)
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
dummy_data <- data 

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
set.seed(666)
train_id <- createDataPartition(
  y = df_known_age$Age, 
  p = 0.70, 
  list = F
)
train <- df_known_age[train_id,]
test <- df_known_age[-train_id,]
# create a cross validation
ctrl <- trainControl(method = "repeatedcv",
                     repeats = 5, number = 3)
library(doParallel)
cl <- makeCluster(detectCores() - 1)
registerDoParallel(cores = cl)
system.time({mod <- train(
  age_cl ~ .,
  data = train %>% select(status, Pclass, SibSp, age_cl, Survived, Fare), 
  method = "rf"
)})
stopCluster(cl)
# predictions
results <- predict(object = mod, newdata = train)
postResample(pred = results, obs = train$age_cl)
results <- predict(object = mod, newdata = test) 
postResample(pred = results, obs = test$age_cl)
confusionMatrix(data = results, reference = test$age_cl, dnn = c("pred","obs"))

test$pred <- round(results,0)
test %>% 
  mutate(error = Age - pred) %>% 
  ggplot() +
    geom_density(aes(x = error, fill = factor(Sex)), alpha = 0.3) -> p1
plotly::ggplotly(p1)

