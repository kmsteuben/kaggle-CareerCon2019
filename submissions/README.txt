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
Results: .41 in Kaggle Public Dataset

## 2019_04_05 Submission 2

Data: Each measurement is summarized with mean, sd, median, IQR, and mad by series_id
Model: xgboost
            Paramters: objective   = multi:softprob
                       eval_metric = mlogloss
                       nround      = 50
Results: .64 in Kaggle Public Dataset

## 2019_04_05 Submission 3

Data: Each measurement is summarized with mean, sd, median, IQR, and mad by series_id
Model: xgboost
            Paramters: objective   = multi:softprob
                       eval_metric = mlogloss
                       nround      = 200
Results: .64 in Kaggle Public Dataset
