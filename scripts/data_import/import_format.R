# -------------------------------------------------------------------------
# GOAL: load data and give the right format
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------
if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(dplyr, readr, magrittr)

# data --------------------------------------------------------------------

train <- read_csv("data/raw_data/train.csv")
validation <- read_csv("data/raw_data/test.csv")
gender_submission <- read_csv("data/raw_data/gender_submission.csv")

# add on test the expected predictions if alls girl had survived
data <- validation %>% 
  left_join(gender_submission, by = "PassengerId") %>% 
  bind_rows(train, .id = "id") %>% 
  mutate(
    Survived = as.factor(Survived),
    Parch = as.integer(Parch),
    Pclass = as.factor(Pclass),
    PassengerId = as.integer(PassengerId),
    SibSp = as.integer(SibSp),
    id = if_else(id == 1, "validation","train"),
    Sex = as.factor(Sex),
    Embarked = as.factor(Embarked), 
  ) 


# clean environment -------------------------------------------------------

rm(gender_submission, train, validation)


