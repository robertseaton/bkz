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

# Remove columns not used in naive bayes'.
vdata$X__Recommendations <- NULL
vdata$Citations <- NULL
vdata$Pages <- NULL
vdata$Subjective_Rating <- NULL
vdata$Prediction <- NULL
vdata$Topic <- NULL

# This convert the Rating from int type to factor.
vdata$Rating <- as.factor(vdata$Rating)

model = train(vdata,vdata$Rating,'nb',trControl=trainControl(method='cv',number=3))
predictions <- predict(model$finalModel,vdata)$class
# Insert the new predictions into the database.
db <- dbConnect(SQLite(), dbname="books.db")
books_db <- dbReadTable(db, "data")
books_db$Prediction <- predictions

# Replace old table with new table with predicted values. This would be prettier if it didn't destroy
# the entire table each time.
sqldf("DROP TABLE data",      stringsAsFactors=FALSE,      dbname="books.db")
sqldf("create table data as select * from books_db",      stringsAsFactors=FALSE,      dbname="books.db")
