## Kaggle CareerCon 2019 Exploratory Data Analysis

setwd("H:/repos/kaggle-CareerCon2019/")
library(data.table)

# 1. Load Data --------------------------------------

#  X test/train: the input data, covering 10 sensor channels and 128 measurements per time series plus three ID columns:
## row_id: The ID for this row.
## series_id: ID number for the measurement series. Foreign key to y_train/sample_submission.
## measurement_number: Measurement number within the series.

# Y: the surfaces for the training set
x_test <- fread("data/X_test.csv")
x_train <- fread("data/X_train.csv")
y_train <- fread("data/y_train.csv")

summary(y_train)
summary(x_train)

#table(x_train$series_id) 
# Note: 128 measurements for each series_id

#length(unique(x_train$row_id)) == length(x_train$row_id) 
# Note: row_id is a unique identifier

table(y_train$surface)
# Classification with 9 possible classes
# Note: variable sizes of outputs in training set

head(x_train)

## To do:
# Create features from orientation, angular velocity, and linear acceleration
# Use those features to train classification model (try random forests, multi-class logistic regression, etc.)
# Evaluate models
# Run predictions and submit


