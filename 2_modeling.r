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
data <-  xy_train[, -c("series_id", "surface_string")]
data_variables <- as.matrix(xy_train[, -c("series_id", "surface_string", "surface")])
data_label <- as.matrix(xy_train[,"surface"])
data_matrix <- xgb.DMatrix(data = as.matrix(data), label = data_label)

train_data <- data_variables[train, ]
train_label <- data_label[train, ]
train_matrix <- xgb.DMatrix(data = train_data, label = train_label)

test_data <- data_variables[validation, ]
test_label <- data_label[validation, ]
test_matrix <- xgb.DMatrix(data = test_data, label = test_label)

final_variables <- as.matrix(xy_test[, -c("series_id")])
final_matrix <- xgb.DMatrix(data = final_variables) 


# Cross-validation to Estimate Error
number_of_classes <- length(unique(data$surface))
xgb_params <- list("objective" = "multi:softprob",
                   "eval_metric" = "mlogloss",
                   "num_class" = number_of_classes)
nround <- 200
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
#final_prediction <- matrix(final_pred, nrow = number_of_classes,
 #                         ncol = length(final_pred)/ number_of_classes) %>%
  #t() %>%
  #data.frame() %>%
  #mutate(max_prob = max.col(., "last"))

link <- unique(xy_train[, .(surface, surface_string)])
link$surface <- link$surface + 1

submission <- data.table(series_id = xy_test$series_id, max_prob = final_prediction$max_prob)
View(submission[, .N, by = 'series_id,max_prob'])
table(submission$max_prob)
submission <- merge(submission, link, by.x = "max_prob", by.y = "surface")
submission$max_prob <- NULL
names(submission) <- c("series_id", "surface")
submission <- submission[order(series_id),]
write.csv(submission, file = "xgboost_submission_3.csv", row.names = FALSE)
