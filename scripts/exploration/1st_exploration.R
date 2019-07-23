# -------------------------------------------------------------------------
# GOAL: kaggle competition to practice ML skills
# DESCRIPTION: In this challenge, we ask you to complete the analysis of what 
# sorts of people were likely to survive. In particular, we ask you to apply 
# the tools of machine learning to predict which passengers survived the 
# tragedy
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------
if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr, readr, magrittr, caret)

# data --------------------------------------------------------------------
data <- read_csv("data/raw_data/train.csv")
validation <- read_csv("data/raw_data/test.csv")
# data types
data %<>% 
  mutate(Survived = as.character(Survived),
         Parch = as.character(Parch),
         Pclass = as.character(Pclass)) %>% 
  select(-Name, -PassengerId, -Ticket, -Cabin)
  

# exploration -------------------------------------------------------------

# extract all missing values
data %<>% 
  filter_all(all_vars(!is.na(.)))

# modalization ------------------------------------------------------------

# create data partiotion + cross validation
train_id <- createDataPartition(
  y = data$Survived,
  p = 0.75,
  list = F
)
train <- data[train_id,]
test <- data[-train_id,]

set.seed(123)
ctrl <- trainControl(
  method = "repeatedcv",
  repeats = 5
)

mod <- train(
  Survived ~ .,
  data = train,
  method = "rpart",
  trControl = ctrl
)

results <- predict(object = mod, newdata = test)
confusionMatrix(
  data = results, 
  reference = as.factor(test$Survived),
  dnn = c("results", "reference"))

# run a decion tree to find relevant variables predict survived
library(rpart)
library(rpart.plot)
mod_rpart <- rpart::rpart(
  formula = Survived ~ .,
  data = train,
  method = "class"
)
summary(mod_rpart)
rpart.plot(mod_rpart)

prp(mod_rpart, type = 2, extra = 104, nn = TRUE,
    fallen.leaves = TRUE, faclen = 4, varlen = 8, 
    shadow.col = "gray", roundint=FALSE)