## Modeling Creation and Testing

## Using Xgboost (see https://rpubs.com/mharris/multiclass_xgboost)
library("xgboost")  # the main algorithm
library("caret")    # for the confusionmatrix() function (also needs e1071 package)
library("e1071")
library("dplyr")    # for some data preperation
library("Ckmeans.1d.dp") # for xgb.ggplot.importance


summary(xy_train)
xy_train$surface_string <- xy_train$surface
xy_train$surface <- as.numeric(as.factor(xy_train$surface)) - 1L # for xgboost, label must be ascending integers starting at 0

# Create Test/Train split in datasets and prepare for input into xgboost
data <-  xy_train[, .(orientation_X, orientation_Y, orientation_Z, orientation_W,
                      angular_velocity_X, angular_velocity_Y, angular_velocity_Z,
                      linear_acceleration_X, linear_acceleration_Y, linear_acceleration_Z,
                      surface)]
data_variables <- as.matrix(xy_train[, .(orientation_X, orientation_Y, orientation_Z, orientation_W,
                              angular_velocity_X, angular_velocity_Y, angular_velocity_Z,
                              linear_acceleration_X, linear_acceleration_Y, linear_acceleration_Z)])
data_label <- as.matrix(xy_train[,"surface"])
data_matrix <- xgb.DMatrix(data = as.matrix(data), label = data_label)

train_data <- data_variables[train, ]
train_label <- data_label[train, ]
train_matrix <- xgb.DMatrix(data = train_data, label = train_label)

test_data <- data_variables[validation, ]
test_label <- data_label[validation, ]
test_matrix <- xgb.DMatrix(data = test_data, label = test_label)

final_variables <- as.matrix(x_test[, .(orientation_X, orientation_Y, orientation_Z, orientation_W,
                                        angular_velocity_X, angular_velocity_Y, angular_velocity_Z,
                                        linear_acceleration_X, linear_acceleration_Y, linear_acceleration_Z)])
final_matrix <- xgb.DMatrix(data = final_variables) 


# Cross-validation to Estimate Error
number_of_classes <- length(unique(data$surface))
xgb_params <- list("objective" = "multi:softprob",
                   "eval_metric" = "mlogloss",
                   "num_class" = number_of_classes)
nround <- 50
cv.nfold <- 5

# Use this code to do model selection
cv_model <- xgb.cv(params = xgb_params,
                   data = train_matrix,
                   nrounds = nround,
                   nfold = cv.nfold,
                   verbose = FALSE,
                   prediction = TRUE)

OOF_prediction <- data.frame(cv_model$pred) %>%
  mutate(max_prob = max.col(., ties.method = "last"),
         label = train_label + 1)
head(OOF_prediction)

confusionMatrix(factor(OOF_prediction$max_prob),
                factor(OOF_prediction$label),
                mode = "everything")

# Once model model selection is complete, use this model to make the final model
bst_model <- xgb.train(params = xgb_params,
                       data = train_matrix,
                       nrounds = nround)

# Predict hold-out test set
test_pred <- predict(bst_model, newdata = test_matrix)
test_prediction <- matrix(test_pred, nrow = number_of_classes,
                          ncol = length(test_pred)/ number_of_classes) %>%
  t() %>%
  data.frame() %>%
  mutate(max_prob = max.col(., "last"))

## Importance plots
names <- colnames(data[, -1])

importance_matrix = xgb.importance(feature_names = names, model = bst_model)
head(importance_matrix)
gp = xgb.ggplot.importance(importance_matrix)
print(gp)


final_pred <- predict(bst_model, newdata = final_matrix)
final_prediction <- matrix(final_pred, nrow = number_of_classes,
                          ncol = length(final_pred)/ number_of_classes) %>%
  t() %>%
  data.frame() %>%
  mutate(max_prob = max.col(., "last"))

link <- unique(xy_train[, .(surface, surface_string)])
link$surface <- link$surface + 1

submission <- data.table(series_id = x_test$series_id, max_prob = final_prediction$max_prob)
View(submission[, .N, by = 'series_id,max_prob'])
getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}
submission <- submission[, .(best_guess = getmode(max_prob)), by = 'series_id']
table(submission$best_guess)
submission <- merge(submission, link, by.x = "best_guess", by.y = "surface")
submission$best_guess <- NULL
names(submission) <- c("series_id", "surface")
submission <- submission[order(series_id),]
write.csv(submission, file = "xgboost_submission.csv", row.names = FALSE)

## Using a SVM
library(kernlab)
rbf <- rbfdot(sigma = 0.1)
rm(y_train)
modelSVM <- ksvm(surface~., data = xy_train[train,], type = "C-bsvc", kernel = rbf, C = 1, prob.model = TRUE)
fitted(modelSVM)
predict(modelSVM, data[validation,], type = "probabilities")

xy_train$surface <- as.factor(xy_train$surface)
## Using ANN
library(nnet)
ideal <- class.ind(xy_train$surface)
modelANN = nnet(surface~linear_acceleration_X + linear_acceleration_Y + linear_acceleration_Z,
                xy_train[train,], ideal[train,], size = 2, na.action = na.omit, softmax = TRUE)
predictions <- predict(modelANN, xy_train[validation, ], type = "class")
table(xy_train[validation,]$surface == predictions)

modelANN = nnet(surface~linear_acceleration_X + linear_acceleration_Y + linear_acceleration_Z,
                data = xy_train, subset = train, size = 2)

cm <- table(xy_train$surface[validation], predict(modelANN, xy_train[validation, ]))
cat("\nConfusion matrix for resulting nn model is: \n")
print(cm)


install.packages("neuralnet")
library(neuralnet)

nn <- neuralnet(surface~linear_acceleration_X + linear_acceleration_Y + linear_acceleration_Z,
                data = xy_train[train,],
                hidden = 3,
                #act.fct = "logistic",
                linear.output = FALSE)
plot(nn)

predict <- compute(nn, xy_train[validation,])

head(predict)

predictions <- predict(modelANN, x_test, type ="class")
