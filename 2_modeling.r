## Modeling Creation and Testing

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
