# -------------------------------------------------------------------------
# GOAL: feature engineering
# DEFINITION: define new variables like:
# - married or not
# - name of the family
# - total number of familiars on board
# -------------------------------------------------------------------------

# libraries ---------------------------------------------------------------
if (require(pacman) == FALSE) {
  install.packages("pacman")
}
pacman::p_load(stringr)

# load data ---------------------------------------------------------------
source("scripts/data_import/import_format.R")

# exploration -------------------------------------------------------------

# thanks to previous exploraiton, we know that there are feature with relevance
# to know who has survived into the accident: 
#   > Sex (male to die)
#   > Age (> 13 to die) 
#   > Pclass (woman --> Class of Travel)
#   > SibSp (Number of Sibling/Spouse aboard)

#  Maybe we can know more information inside the name of the passangers
data %<>% 
  mutate(
    # create a variable with the status of each passanger
    status = str_extract(Name, pattern = " ([A-Za-z]+)\\."),
    status = str_replace(status, pattern = ".*, ", replacement = ""),
    status = str_remove_all(status, pattern = "\\s"), 
    status = str_replace_all(
      status, 
      c("Dona" = "Mrs", "Martin\\(ElizabethL." = "", "Mlle." = "Miss",
        "Mme." = "Mrs", "Don" = "Mr", "\\."="", "Ms" = "Miss",
        "Lady|Countess|Capt|Col|Dr|Major|Rev|Sir|Jonkheer" = "Unkown")),
    status = as.factor(status),
    # columns with the family name of each passanger
    family_name = str_extract(Name, pattern = "\\..*$"),
    family_name = str_replace_all(
      family_name,
      c("\\.\\s" = "","\\s\\(.*\\)" = "",'".*"' = "", '\\s"' = "",
        '"' = "")),
    # column with the sum of siblings/spouses and parents/sons aborad + the own
    # passanger
    total_family = SibSp + Parch + 1
    )

