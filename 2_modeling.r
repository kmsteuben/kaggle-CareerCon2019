## Modeling Creation and Testing

## Using a SVM
library(kernlab)
rbf <- rbfdot(sigma = 0.1)
modelSVM <- ksvm(output~., data = data[train,], type = "C-bsvc", kernel = rbf, C = 10, prob.model = TRUE)
fitted(modelSVM)
predict(modelSVM, data[validation,], type = "probabilities")

## Using ANN
library(nnet)
ideal <- class.ind(data$output)
modelANN = nnet(data[train, -5], ideal[train], size = 10, softmax = TRUE)
predict(modelANN, data[validation, -5], type = "class")