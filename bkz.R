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
mydata$AmReviewsPerYear <- mydata$Amazon_Reviews / (2014 - mydata$Published)
mydata$GdReviewsPerYear <- mydata$Goodreads_Reviews / (2014 - mydata$Published)
mydata$CitationPrice <- mydata$Citations / mydata$Price
mydata$AGDiff <- mydata$Amazon_Rating - mydata$Goodreads_Rating
mydata$CitationPrice <- mydata$Citations / mydata$Price
mydata$GdReviewsPerYear <- mydata$Goodreads_Reviews / (2014 - mydata$Published)
mydata$AmReviewsPerYear <- mydata$Amazon_Reviews / (2014 - mydata$Published)
mydata$Goodreads_RR <- log(mydata$Goodreads_Reviews) + mydata$Goodreads_Rating
mydata$Amazon_RR <- log(mydata$Amazon_Reviews) + mydata$Amazon_Rating
mydata$RRRR <- mydata$Amazon_RR + mydata$Goodreads_RR
vdata$WR <- (vdata$Goodreads_Reviews/(vdata$Goodreads_Reviews + 5)) * vdata$Goodreads_Rating + (10 / (vdata$Goodreads_Reviews + 5)) * mean(vdata$Goodreads_Rating)
mydata$Pop <- mydata$Price * mydata$Goodreads_Reviews * mydata$Amazon_Reviews * mydata$Amazon_Book_Rank
mydata$Characters_in_Title <- nchar(as.character(mydata$Title))
mydata$WordsInTitle <- sapply(gregexpr("\\b\\W+\\b", as.character(mydata$Title), perl=TRUE), function(x) sum(x>0) ) + 1
mydata$AvgWordLengthTitle <- mydata$Characters_in_Title / mydata$WordsInTitle
vdata <- mydata

# This converts the Rating from int type to factor.
vdata$Rating <- as.ordered(vdata$Rating)

mydata$Rating <- NULL

model = train(vdata$Rating ~ ., data = vdata, 'rf', metric="Kappa", trControl=trainControl(method='repeatedcv',number=10, repeats=10))#, preProcess=("knnImpute"))
#svm = train(vdata$Rating ~ ., data = vdata, 'logitBoost', metric="Kappa", trControl=trainControl(method='repeatedcv',number=10, repeats=10))
predictions <- predict(model$finalModel, mydata)
confidences <- predict(model$finalModel, mydata, type="raw")

# Insert the new predictions into the database.
db <- dbConnect(SQLite(), dbname="books.db")
books_db <- dbReadTable(db, "data")
books_db$Prediction <- predictions
books_db$Confidence <- NULL

# Replace old table with new table with predicted values. This would be prettier if it didn't destroy
# the entire table each time.
sqldf("DROP TABLE data",      stringsAsFactors=FALSE,      dbname="books.db")
sqldf("create table data as select * from books_db",      stringsAsFactors=FALSE,      dbname="books.db")
