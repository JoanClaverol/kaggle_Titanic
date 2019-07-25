# -------------------------------------------------------------------------
# GOAL: data quality
# DEFINITION: check inconsistency of the data
# - missing values
# - duplicated passangers
# -------------------------------------------------------------------------


# libraries ---------------------------------------------------------------

if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr)


# load the data -----------------------------------------------------------

source("scripts/data_import/import_format.R")


# data clean --------------------------------------------------------------

# find where are the missing values
data %>% 
  group_by(id) %>% 
  summarise_all( ~ sum(is.na(.)))
# most of them are placed on Cabin, but we don't think is a relevant variable 
# for our predictions. we can use age to decide what to do with it. 

miss_data <- data %>% 
  filter(is.na(Age)) 
miss_data %>% 
  group_by(Pclass) %>% 
  summarise(n = n()) %>% 
  mutate(freq = n/sum(n))

hist(miss_data$Fare)

library(ggplot2)
miss_data %>% 
  ggplot() +
    geom_density(aes(x = Fare, col = Sex))

# predict miss values -----------------------------------------------------

# select the know data to predict the missing values
known_data <- data %>% 
  filter(!is.na(Age))

known_data %>% 
  select(-id, -PassengerId, -Survived, -Ticket, -Cabin) %>% 
  summarise_all(~sum(is.na(.)))

# substitut the fare values by the mean of the fare
known_data %>% 
  filter(Pclass == 3, Sex == "male") %>% 
  summarise(mean = mean(Fare, na.rm = T))
