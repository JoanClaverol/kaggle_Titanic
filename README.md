## Titanic: Machine Learning from Disaster

Data science competition from **kaggle** ([link](https://www.kaggle.com/c/titanic)).

Steps to create the model:

Data import
-----------
Join the *train.csv* and *test.csv* to apply the right  formats to the data: 

Data quality
------------
Missing values replacmente: 

* **Cabin**: 77.5 % of the data is missing. 
* **Fare**: only one missing value. Predicted with a linear model using two variables: *Pclasse* and *total_family = SibSp + Parch*.
* **Age**: 20 % of the data is missing. 

Pre process
-----------
Creation of new features to improve our model: 

* **Status**: detect the status of the passenger (Mr, Miss, Mrs, ...) from the variable *name*.
* **Family name**: extract the family name from the variable *name*.
* **total family**: detect how many members of your family where aboard. 

Model
-----
Prediction of missing values for the Age column, function to automatize the model creation through caret and construction of the final model to predict survived or not. 

