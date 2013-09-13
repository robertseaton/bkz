#!/usr/bin/env Rscript

library("sqldf")
library("caret")
library("doMC")

# Register multiple cores.
registerDoMC(cores = 2)

# FIXME
#
# This is a hack to get the db into csv format, because if I import from the db directly
# R complains about factor levels when calling predict() and errors out, which seem to be
# some kind of type error.
#
# If I convert the db to csv first, it works fine, which is gross, but whatever.
system("sh db_to_csv.sh")
mydata = read.csv("out.csv")

# In general, the syntax "X <- NULL" removes unused columns.
mydata$X__Recommendations <- NULL
mydata$Pages <- NULL
mydata$Subjective_Rating <- NULL
mydata$Prediction <- NULL
mydata$Confidence <- NULL
mydata$Author <- NULL
mydata$Topic <- NULL
mydata$User_Topic <- NULL
mydata$Title <- NULL

vdata <- mydata

# This converts the Rating from int type to factor.
vdata$Rating <- as.factor(vdata$Rating)

mydata$Rating <- NULL

logitboost = train(vdata$Rating ~ ., data = vdata, 'logitBoost', metric="Kappa", trControl=trainControl(method='repeatedcv',number=10, repeats=10))
predictions <- predict(logitboost$finalModel, mydata)

# Insert the new predictions into the database.
db <- dbConnect(SQLite(), dbname="books.db")
books_db <- dbReadTable(db, "data")
books_db$Prediction <- predictions
books_db$Confidence <- NULL

# Replace old table with new table with predicted values. This would be prettier if it didn't destroy
# the entire table each time.
sqldf("DROP TABLE data",      stringsAsFactors=FALSE,      dbname="books.db")
sqldf("create table data as select * from books_db",      stringsAsFactors=FALSE,      dbname="books.db")
