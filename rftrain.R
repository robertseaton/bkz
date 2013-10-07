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
#mydata$User_Topic <- NULL
#mydata$Title <- NULL
#mydata$CitesPerYear <- mydata$Citations / (2014 - mydata$Published)
#mydata$AmReviewsPerYear <- mydata$Amazon_Reviews / (2014 - mydata$Published)
#mydata$GdReviewsPerYear <- mydata$Goodreads_Reviews / (2014 - mydata$Published)
#mydata$CitationPrice <- mydata$Citations / mydata$Price
## mydata$AGDiff <- mydata$Amazon_Rating - mydata$Goodreads_Rating
## mydata$Goodreads_RR <- log(mydata$Goodreads_Reviews) + mydata$Goodreads_Rating
## mydata$Amazon_RR <- log(mydata$Amazon_Reviews) + mydata$Amazon_Rating
## mydata$RRRR <- mydata$Amazon_RR + mydata$Goodreads_RR
mydata$WR <- (mydata$Goodreads_Reviews/(mydata$Goodreads_Reviews + 5)) * mydata$Goodreads_Rating + (10 / (mydata$Goodreads_Reviews + 5)) * mean(mydata$Goodreads_Rating)
#mydata$Pop <- mydata$Price * mydata$Goodreads_Reviews * mydata$Amazon_Reviews * mydata$Amazon_Book_Rank
mydata$Characters_in_Title <- nchar(as.character(mydata$Title))
mydata$WordsInTitle <- sapply(gregexpr("\\b\\W+\\b", as.character(mydata$Title), perl=TRUE), function(x) sum(x>0) ) + 1
mydata$AvgWordLengthTitle <- mydata$Characters_in_Title / mydata$WordsInTitle
mydata$Title <- NULL
#mydata$Price <- NULL
vdata <- mydata

# This converts the Rating from int type to factor.
vdata$Rating <- as.ordered(vdata$Rating)
vdata <- vdata[complete.cases(vdata),]
mydata$Rating <- NULL

ctrl = rfeControl(functions = rfFuncs, method = "repeatedcv", repeats = 3, returnResamp="final", verbose = FALSE)
rfProfile = rfe(vdata$Rating ~ vdata$Amazon_Book_Rank * vdata$Amazon_Reviews * vdata$Characters_in_Title * vdata$Goodreads_Rating * vdata$GoogBooks_Rating * vdata$Google_Results * vdata$Google_Results_LW
* vdata$Amazon_Rating * vdata$AvgWordLengthTitle * vdata$Citations * vdata$Goodreads_Reviews * vdata$GoogBooks_Reviews * vdata$Google_Results_HN * vdata$Published * vdata$WordsInTitle * vdata$Price *
vdata$User_Topic * vdata$WR, rfeControl = ctrl)
