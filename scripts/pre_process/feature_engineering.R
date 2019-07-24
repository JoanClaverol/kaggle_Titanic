# -------------------------------------------------------------------------
# GOAL: feature engineering
# DEFINITION: define new variables like:
# - married or not
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
    status = str_extract(Name, pattern = "\\s.*\\."),
    status = str_replace(status, pattern = ".*, ", replacement = ""),
    status = str_remove_all(status, pattern = "\\s"), 
    status = str_replace_all(
      status, 
      c("Dona" = "Mrs.", "Martin\\(ElizabethL." = "", "Mlle." = "Miss.",
        "Mme." = "Mrs.")),
    # columns with the family name of each passanger
    family_name = str_extract(Name, pattern = "\\..*$"),
    family_name = str_replace_all(
      family_name,
      c("\\.\\s" = "","\\s\\(.*\\)" = "",'".*"' = "", '\\s"' = "",
        '"' = "")),
    # column with the sum of siblings/spouses and parents/sons aborad 
    total_family = SibSp + Parch
    )
# 
# # family in relation 
# library(ggplot2)
# data %>% 
#   group_by(family_name) %>% 
#   summarise(official_n_family = sum(SibSp), 
#             same_famly_name = n(),
#             check = official_n_family - same_famly_name) %>% 
#   arrange(desc(check)) -> temp
# 
# temp %>% 
#   ggplot() + 
#     geom_histogram(aes(x = check), bins = 30) -> p1
# 
# plotly::ggplotly(p1)
