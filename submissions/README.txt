# Submission Documentation

## 2019_03_28 Submission 1

Data: Naive dataset, no pre-processing done on data
Model: xgboost
            Paramters: objective   = multi:softprob
                       eval_metric = mlogloss
                       nround      = 50
       all measurements for a given series are treated as individuals in xgboost model 
       each individual is assigned label based on highest probability given from model predicitons
       each series_id is assigned the mode label of each of its individuals
