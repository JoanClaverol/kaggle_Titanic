# -------------------------------------------------------------------------
# GOAL: detect outliers from relevant variables and extract them
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------

if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr, magrittr)


# load the data -----------------------------------------------------------
# load from previous data quality
source("scripts/data_quality/2_NA_age.R")

# select only the data we will use to train the model
train <- data %>% filter(id == "train")
validation <- data %>% filter(id == "validation")

# exploration -------------------------------------------------------------

# Fare; exploration thorugh plotly
# train %>%
#   ggplot() +
#     geom_boxplot(aes(y = Fare, x = Pclass)) -> p1
# plotly::ggplotly(p1)
# We consider that outliers are the ones bigger than 300
train %<>% 
  filter(Fare <= 300)
# total_family
# train %>% 
#   ggplot() +
#   geom_boxplot(aes(y = total_family, x = Pclass)) -> p1
# plotly::ggplotly(p1)
# We consifer to exclude the one that has a family bigger than 8
train %<>% 
  filter(total_family <= 8)


# join the information again ----------------------------------------------
# join the data again
data <- train %>% 
  bind_rows(validation)


# clean envirionment ------------------------------------------------------
rm(train, validation)

