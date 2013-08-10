#!/usr/bin/env Rscript

# load the data
mydata <- read.csv("~/data.txt")
colnames(mydata)

# split data into training and testing sets
smp_size <- floor(0.75 * nrow(mydata))
train_ind <- sample(seq_len(nrow(mydata)), size = smp_size)
train <- mydata[train_ind, ]
test <- mydata[-train_ind, ]

# TODO: Figure out a way to compare the results.

display_results <- function(){
train_AUC <- colAUC(train_pred,trainTarget)
test_AUC <- colAUC(test_pred,testTarget)
cat("\n\n***",what,"***\ntraining:",train_AUC,"\ntesting:",test_AUC,"\n*****************************\n")
}
library(caTools) #requireed for AUC calc

what <- "Linear Regression"
LINEAR_model <- lm(Rating ~ Goodreads.Rating * Goodreads.Reviews * Amazon.Rating * Amazon.Reviews * Citations, data=trainset)
train_pred <- predict(LINEAR_model, type="response", trainset)
test_pred <- predict(LINEAR_model, type="response", testset)

display_results()