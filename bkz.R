#!/usr/bin/env Rscript

library("sqldf")
library("klaR")
library("caret")

# FIXME
#
# This is a hack to get the db into csv format, because if I import from the db directly
# R complains about factor levels when calling predict() and errors out, which seem to be
# some kind of type error.
#
# If I convert the db to csv first, it works fine, which is gross, but whatever.

system("sh db_to_csv.sh")
mydata = read.csv("out.csv")

vdata <- mydata

# Remove unused columns.
vdata$X__Recommendations <- NULL
vdata$Citations <- NULL
vdata$Pages <- NULL
vdata$Subjective_Rating <- NULL
vdata$Prediction <- NULL
vdata$Confidence <- NULL
vdata$Topic <- NULL

# This converts the Rating from int type to factor.
vdata$Rating <- as.factor(vdata$Rating)

# On how this works: http://joshwalters.github.io/2012/11/27/naive-bayes-classification-in-r.html
model = train(vdata,vdata$Rating,'nb',trControl=trainControl(method='cv',number=3))
predictions <- predict(model$finalModel,vdata)$class

# Naive bayes' returns a matrix of the confidence value for its predicted value and
# for all other classes. For example, it might predict 5 with 90 percent probability,
# and 4 with 5 percent probability, etc.
#
# This code grabs the max of each row of the matrix, which is the same as the confidence
# of the predicted vale.
confidences <- apply(predict(model$finalModel,vdata)$posterior, 1, max)


# Insert the new predictions into the database.
db <- dbConnect(SQLite(), dbname="books.db")
books_db <- dbReadTable(db, "data")
books_db$Prediction <- predictions
books_db$Confidence <- confidences

# Replace old table with new table with predicted values. This would be prettier if it didn't destroy
# the entire table each time.
sqldf("DROP TABLE data",      stringsAsFactors=FALSE,      dbname="books.db")
sqldf("create table data as select * from books_db",      stringsAsFactors=FALSE,      dbname="books.db")
