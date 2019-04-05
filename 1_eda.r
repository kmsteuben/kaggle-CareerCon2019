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

## To do:
# Create features from orientation, angular velocity, and linear acceleration


## Feature Extraction by series (should get this into just orientation, angular velocity, and linear acceleration first)
cols <- c("orientation_X", "orientation_Y", "orientation_Z", "orientation_W",
          "angular_velocity_X", "angular_velocity_Y", "angular_velocity_Z",
          "linear_acceleration_X", "linear_acceleration_Y", "linear_acceleration_Z")

x_train_mean <- x_train[, lapply(.SD, mean),
                   by = series_id,
                .SDcols = cols][, setnames(.SD, cols, paste(cols, "mean", sep = "_"))]
x_train_sd <- x_train[, lapply(.SD, sd),
                        by = series_id,
                        .SDcols = cols][, setnames(.SD, cols, paste(cols, "sd", sep = "_"))]
x_train_median <- x_train[, lapply(.SD, median),
                      by = series_id,
                      .SDcols = cols][, setnames(.SD, cols, paste(cols, "median", sep = "_"))]
x_train_IQR <- x_train[, lapply(.SD, IQR),
                          by = series_id,
                          .SDcols = cols][, setnames(.SD, cols, paste(cols, "IQR", sep = "_"))]
x_train_mad <- x_train[, lapply(.SD, mad),
                       by = series_id,
                       .SDcols = cols][, setnames(.SD, cols, paste(cols, "mad", sep = "_"))]
y_train <- y_train[, .(series_id, surface)]

xy_train <- merge(x_train_mean,  x_train_sd, by = "series_id")
xy_train <- merge(xy_train, x_train_median, by = "series_id")
xy_train <- merge(xy_train, x_train_IQR, by = "series_id")
xy_train <- merge(xy_train, x_train_mad, by = "series_id")
xy_train <- merge(xy_train, y_train, by = "series_id")

rm(x_train_mean, x_train_sd, x_train_median, x_train_IQR, x_train_mad)

# Create corresponding x_test
x_test_mean <- x_test[, lapply(.SD, mean),
                        by = series_id,
                        .SDcols = cols][, setnames(.SD, cols, paste(cols, "mean", sep = "_"))]
x_test_sd <- x_test[, lapply(.SD, sd),
                      by = series_id,
                      .SDcols = cols][, setnames(.SD, cols, paste(cols, "sd", sep = "_"))]
x_test_median <- x_test[, lapply(.SD, median),
                          by = series_id,
                          .SDcols = cols][, setnames(.SD, cols, paste(cols, "median", sep = "_"))]
x_test_IQR <- x_test[, lapply(.SD, IQR),
                       by = series_id,
                       .SDcols = cols][, setnames(.SD, cols, paste(cols, "IQR", sep = "_"))]
x_test_mad <- x_test[, lapply(.SD, mad),
                       by = series_id,
                       .SDcols = cols][, setnames(.SD, cols, paste(cols, "mad", sep = "_"))]


xy_test <- merge(x_test_mean,  x_test_sd, by = "series_id")
xy_test <- merge(xy_test, x_test_median, by = "series_id")
xy_test <- merge(xy_test, x_test_IQR, by = "series_id")
xy_test <- merge(xy_test, x_test_mad, by = "series_id")

rm(x_test_mean, x_test_sd, x_test_median, x_test_IQR, x_test_mad)

#train_data 70%
#validation_data 15%
#test_data 15%

set.seed(314567)
size_train <- as.integer(.7 * nrow(xy_train))
size_validation <- as.integer(.15 * nrow(xy_train))
size_test <- nrow(xy_train) - size_train - size_validation

train <- sample(1:nrow(xy_train), size_train)
not_train <- setdiff(1:nrow(xy_train), train)
validation <- sample(not_train, size_validation)
test <- setdiff(not_train, validation)


