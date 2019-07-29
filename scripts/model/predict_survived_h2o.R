# -------------------------------------------------------------------------
# GOAL: create a model to predict age with H2O package
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------
if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr, h2o)

# load data ---------------------------------------------------------------
source("scripts/data_quality/1_NA_embarked_fare.R")


# load data ---------------------------------------------------------------
# source data
source("scripts/data_quality/3_outliers.R")

# select train
train <- data %>% 
  filter(id == "train")
validation <- data %>% 
  filter(id == "validation")

# select the variable we will use
temp <- c("Sex","Fare","Survived","total_family","status","Pclass","Age")


# model creation ----------------------------------------------------------

# launching in local file
h2o.init(nthreads=-1)

