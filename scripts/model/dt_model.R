# -------------------------------------------------------------------------
# GOAL: modalization with normal decision trees
# DEFINITION: use decision tree to detect the most relevant variables to 
# predict if someone is alive or not
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------
if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(caret, rpart, rpart.plot)


# load data ---------------------------------------------------------------
source("scripts/pre_process/feature_engineering.R")

# define validation and training
train_all <- data %>% 
  filter(id == "train")
validation <- data %>% 
  filter(id == "validation")

# variables to includo on the model
rel_var <- c("Pclass","Sex","Age",
             "SibSp","Parch"       "Ticket"      "Fare"        "Cabin"       "Embarked"   
             "Survived"    "status"      "family_name")


# data partion + cross validation -----------------------------------------

# data partition
set.seed(123)
train_id <- createDataPartition(
  y = data$Survived,
  p = 0.75,
  list = F
)
# train + test
train <- data[train_id,]
test <- data[-train_id,]

# cross validation
ctrl <- trainControl(
  method = "repeatedcv",
  repeats = 5
)

# model -------------------------------------------------------------------

# model creation 
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

results <- predict(object = mod, newdata = test)
confusionMatrix(
  data = results, 
  reference = as.factor(test$Survived),
  dnn = c("results", "reference"))

