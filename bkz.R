#!/usr/bin/env Rscript

library("sqldf")
library("caret")
library("doMC")

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
#mydata$Title <- NULL
mydata$CitesPerYear <- mydata$Citations / (2014 - mydata$Published)
#mydata$AmReviewsPerYear <- mydata$Amazon_Reviews / (2014 - mydata$Published)
#mydata$GdReviewsPerYear <- mydata$Goodreads_Reviews / (2014 - mydata$Published)
#mydata$CitationPrice <- mydata$Citations / mydata$Price
#mydata$WR <- (mydata$Goodreads_Reviews/(mydata$Goodreads_Reviews + 5)) * mydata$Goodreads_Rating + (10 / (mydata$Goodreads_Reviews + 5)) * mean(mydata$Goodreads_Rating)
#mydata$Pop <- mydata$Price * mydata$Goodreads_Reviews * mydata$Amazon_Reviews * mydata$Amazon_Book_Rank
mydata$Characters_in_Title <- nchar(as.character(mydata$Title))
mydata$WordsInTitle <- sapply(gregexpr("\\b\\W+\\b", as.character(mydata$Title), perl=TRUE), function(x) sum(x>0) ) + 1
mydata$AvgWordLengthTitle <- mydata$Characters_in_Title / mydata$WordsInTitle
mydata$Title <- NULL
mydata$Price <- NULL
vdata <- mydata

# This converts the Rating from int type to factor.
vdata$Rating <- as.ordered(vdata$Rating)
vdata <- vdata[complete.cases(vdata),]
mydata$Rating <- NULL

model = train(vdata$Rating ~ ., data = vdata, 'svmPoly', metric="Kappa", trControl=trainControl(method='repeatedcv',number=10, repeats=10, classProbs = TRUE))#, preProcess=("knnImpute"))
#svm = train(vdata$Rating ~ ., data = vdata, 'logitBoost', metric="Kappa", trControl=trainControl(method='repeatedcv',number=10, repeats=10))

predictions <- predict(model$finalModel, mydata)

confidences <- predict(model$finalModel, mydata, type="prob")
#confidences <- apply(confidences, 1, FUN = max)
# Insert the new predictions into the database.
db <- dbConnect(SQLite(), dbname="books.db")
books_db <- dbReadTable(db, "data")
books_db$Prediction <- predictions
books_db$Confidence <- confidences

# Replace old table with new table with predicted values. This would be prettier if it didn't destroy
# the entire table each time.
sqldf("DROP TABLE data",      stringsAsFactors=FALSE,      dbname="books.db")
sqldf("create table data as select * from books_db",      stringsAsFactors=FALSE,      dbname="books.db")
