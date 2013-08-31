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
vdata$Pages <- NULL
vdata$Subjective_Rating <- NULL
vdata$Prediction <- NULL
vdata$Confidence <- NULL
vdata$Topic <- NULL
mydata <- vdata

#vdata <- mydata[!is.na(mydata$Rating),]
vdata$Title <- NULL

# This converts the Rating from int type to factor.
vdata$Rating <- as.factor(vdata$Rating)
mydata$Rating <- as.factor(mydata$Rating)

mydata$Rating <- NULL

model = train(vdata$Rating ~ ., data = vdata, 'rf', trControl=trainControl(method='repeatedcv',number=3, repeats=10))
predictions <- predict(model$finalModel,mydata)

# Insert the new predictions into the database.
db <- dbConnect(SQLite(), dbname="books.db")
books_db <- dbReadTable(db, "data")
books_db$Prediction <- predictions
books_db$Confidence <- NULL

# Replace old table with new table with predicted values. This would be prettier if it didn't destroy
# the entire table each time.
sqldf("DROP TABLE data",      stringsAsFactors=FALSE,      dbname="books.db")
sqldf("create table data as select * from books_db",      stringsAsFactors=FALSE,      dbname="books.db")
