source("scripts/data_quality/3_outliers.R")
source("scripts/model/fun_model_creation.R")

# select train
train <- data %>% 
  filter(id == "train")
validation <- data %>% 
  filter(id == "validation")

# run the model to predict survived or not
temp <- c("Sex","Fare","Survived","total_family","status","Pclass","Age")
mod <- modalization(data = train, p_partition = 0.8, 
                    cv_repeats = 5, cv_number = 3,
                    x = "Survived", y = temp, 
                    model_name = "gbm", set_seed = 666)

# apply to the validation test
validation$Survived<- predict(object = mod, newdata = validation)
# postResample(results, validation$Survived)

# read csv from gender submission
submissiion <- read_csv("data/raw_data/gender_submission.csv")
submissiion %>% 
  select(-Survived) %>% 
  left_join(validation %>% select(PassengerId, Survived)) %>% 
  write_csv("data/final_results.csv")
