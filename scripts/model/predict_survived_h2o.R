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
train %<>% select(temp)

# model creation ----------------------------------------------------------

# launching in local file
h2o.init(nthreads=-1)

# transform to h2o object
df <- as.h2o(train)
validation <- as.h2o(validation)
## pick a response for the supervised problem
response <- "Survived"
## the response variable is an integer, we will turn it into a categorical/factor for binary classification
df[[response]] <- as.factor(df[[response]])
# define the predictors
predictors <- setdiff(names(df), c(response, "name"))

# split the data for ml
splits <- h2o.splitFrame(
  data = df,
  ratios = c(0.6,0.2), # only need to specify 2 fractions, the 3rd is implied
  destination_frames = c("train.hex", "valid.hex", "test.hex"), seed = 1234
)
train <- splits[[1]]
valid <- splits[[2]]
test  <- splits[[3]]

## We only provide the required parameters, everything else is default
gbm <- h2o.gbm(x = predictors, y = response, training_frame = train)
## Show a detailed model summary
gbm
## Get the AUC on the validation set
h2o.auc(h2o.performance(gbm, newdata = valid))

gbm <- h2o.gbm(
  ## standard model parameters
  x = predictors,
  y = response,
  training_frame = train,
  validation_frame = valid,
  ## more trees is better if the learning rate is small enough
  ## here, use "more than enough" trees - we have early stopping
  ntrees = 10000,
  ## smaller learning rate is better (this is a good value for most datasets, but see below for annealing)
  learn_rate=0.01,
  ## early stopping once the validation AUC doesn't improve by at least 0.01% for 5 consecutive scoring events
  stopping_rounds = 5, stopping_tolerance = 1e-4, stopping_metric = "AUC",
  ## sample 80% of rows per tree
  sample_rate = 0.8,
  ## sample 80% of columns per split
  col_sample_rate = 0.8,
  ## fix a random number generator seed for reproducibility
  seed = 1234,
  ## score every 10 trees to make early stopping reproducible (it depends on the scoring interval)
  score_tree_interval = 10
)
## Get the AUC on the validation set
h2o.auc(h2o.performance(gbm, valid = TRUE))

## Depth 10 is usually plenty of depth for most datasets, but you never know
hyper_params = list( max_depth = seq(1,29,2) )
#hyper_params = list( max_depth = c(4,6,8,12,16,20) ) ##faster for larger datasets
grid <- h2o.grid(
  ## hyper parameters
  hyper_params = hyper_params,
  ## full Cartesian hyper-parameter search
  search_criteria = list(strategy = "Cartesian"),
  ## which algorithm to run
  algorithm="gbm",
  ## identifier for the grid, to later retrieve it
  grid_id="depth_grid",
  ## standard model parameters
  x = predictors,
  y = response,
  training_frame = train,
  validation_frame = valid,
  ## more trees is better if the learning rate is small enough
  ## here, use "more than enough" trees - we have early stopping
  ntrees = 10000,
  ## smaller learning rate is better
  ## since we have learning_rate_annealing, we can afford to start with a bigger learning rate
  learn_rate = 0.05,
  ## learning rate annealing: learning_rate shrinks by 1% after every tree
  ## (use 1.00 to disable, but then lower the learning_rate)
  learn_rate_annealing = 0.99,
  ## sample 80% of rows per tree
  sample_rate = 0.8,
  ## sample 80% of columns per split
  col_sample_rate = 0.8,
  ## fix a random number generator seed for reproducibility
  seed = 1234,
  ## early stopping once the validation AUC doesn't improve by at least 0.01% for 5 consecutive scoring events
  stopping_rounds = 5,
  stopping_tolerance = 1e-4,
  stopping_metric = "AUC",
  ## score every 10 trees to make early stopping reproducible (it depends on the scoring interval)
  score_tree_interval = 10
)
## by default, display the grid search results sorted by increasing logloss (since this is a classification task)
grid
## sort the grid models by decreasing AUC
sortedGrid <- h2o.getGrid("depth_grid", sort_by="auc", decreasing = TRUE)
sortedGrid
## find the range of max_depth for the top 5 models
topDepths = sortedGrid@summary_table$max_depth[1:5]
minDepth = min(as.numeric(topDepths))
maxDepth = max(as.numeric(topDepths))
sortedGrid
minDepth
maxDepth

hyper_params = list(
  ## restrict the search to the range of max_depth established above
  max_depth = seq(minDepth,maxDepth,1),
  ## search a large space of row sampling rates per tree
  sample_rate = seq(0.2,1,0.01),
  ## search a large space of column sampling rates per split
  col_sample_rate = seq(0.2,1,0.01),
  ## search a large space of column sampling rates per tree
  col_sample_rate_per_tree = seq(0.2,1,0.01),
  ## search a large space of how column sampling per split should change as a function of the depth of the split
  col_sample_rate_change_per_level = seq(0.9,1.1,0.01),
  ## search a large space of the number of min rows in a terminal node
  min_rows = 2^seq(0,log2(nrow(train))-1,1),
  ## search a large space of the number of bins for split-finding for continuous and integer columns
  nbins = 2^seq(4,10,1),
  ## search a large space of the number of bins for split-finding for categorical columns
  nbins_cats = 2^seq(4,12,1),
  ## search a few minimum required relative error improvement thresholds for a split to happen
  min_split_improvement = c(0,1e-8,1e-6,1e-4),
  ## try all histogram types (QuantilesGlobal and RoundRobin are good for numeric columns with outliers)
  histogram_type = c("UniformAdaptive","QuantilesGlobal","RoundRobin")
)
search_criteria = list(
  ## Random grid search
  strategy = "RandomDiscrete",
  ## limit the runtime to 60 minutes
  max_runtime_secs = 3600,
  ## build no more than 100 models
  max_models = 100,
  ## random number generator seed to make sampling of parameter combinations reproducible
  seed = 1234,
  ## early stopping once the leaderboard of the top 5 models is converged to 0.1% relative difference
  stopping_rounds = 5,
  stopping_metric = "AUC",
  stopping_tolerance = 1e-3
)
grid <- h2o.grid(
  ## hyper parameters
  hyper_params = hyper_params,
  ## hyper-parameter search configuration (see above)
  search_criteria = search_criteria,
  ## which algorithm to run
  algorithm = "gbm",
  ## identifier for the grid, to later retrieve it
  grid_id = "final_grid",
  ## standard model parameters
  x = predictors,
  y = response,
  training_frame = train,
  validation_frame = valid,
  ## more trees is better if the learning rate is small enough
  ## use "more than enough" trees - we have early stopping
  ntrees = 10000,
  ## smaller learning rate is better
  ## since we have learning_rate_annealing, we can afford to start with a bigger learning rate
  learn_rate = 0.05,
  ## learning rate annealing: learning_rate shrinks by 1% after every tree
  ## (use 1.00 to disable, but then lower the learning_rate)
  learn_rate_annealing = 0.99,
  ## early stopping based on timeout (no model should take more than 1 hour - modify as needed)
  max_runtime_secs = 3600,
  ## early stopping once the validation AUC doesn't improve by at least 0.01% for 5 consecutive scoring events
  stopping_rounds = 5, stopping_tolerance = 1e-4, stopping_metric = "AUC",
  ## score every 10 trees to make early stopping reproducible (it depends on the scoring interval)
  score_tree_interval = 10,
  ## base random number generator seed for each model (automatically gets incremented internally for each model)
  seed = 1234
)
## Sort the grid models by AUC
sortedGrid <- h2o.getGrid("final_grid", sort_by = "auc", decreasing = TRUE)
sortedGrid

model <- do.call(h2o.gbm,
                 ## update parameters in place
                 {
                   p <- gbm@parameters
                   p$model_id = NULL          ## do not overwrite the original grid model
                   p$training_frame = df      ## use the full dataset
                   p$validation_frame = NULL  ## no validation frame
                   p$nfolds = 5               ## cross-validation
                   p
                 }
)
model@model$cross_validation_metrics_summary


for (i in 1:5) {
  gbm <- h2o.getModel(sortedGrid@model_ids[[i]])
  cvgbm <- do.call(h2o.gbm,
                   ## update parameters in place
                   {
                     p <- gbm@parameters
                     p$model_id = NULL          ## do not overwrite the original grid model
                     p$training_frame = df      ## use the full dataset
                     p$validation_frame = NULL  ## no validation frame
                     p$nfolds = 5               ## cross-validation
                     p
                   }
  )
  print(gbm@model_id)
  print(cvgbm@model$cross_validation_metrics_summary[5,]) ## Pick out the "AUC" row
}
gbm <- h2o.getModel(sortedGrid@model_ids[[1]])
preds <- h2o.predict(gbm, test)
head(preds)
gbm@model$validation_metrics@metrics$max_criteria_and_metric_scores

h2o.saveModel(gbm, "models/bestModel_h2o.csv", force=TRUE)
h2o.exportFile(preds, "models/bestPreds_h2o.csv", force=TRUE)

# apply to validation
preds <- h2o.predict(gbm, validation)

test_valid <- as_tibble(preds)
  
  
test_valid %<>% 
  bind_cols(validation %>% select(PassengerId)) %>% 
  select(PassengerId, Survived = predict) %>% 
  write_csv("data/final_results.csv")
