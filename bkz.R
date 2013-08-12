#!/usr/bin/env Rscript

library("sqldf")

# FIXME
#
# This is a hack to get the db into csv format, because if I import from the db directly
# R complains about factor levels when calling predict() and errors out, which seem to be
# some kind of type error.
#
# If I convert the db to csv first, it works fine, which is gross, but whatever.
# db <- dbConnect(SQLite(), dbname="books.db")
# mydata <- dbReadTable(db, "data")

system("sh db_to_csv.sh")
mydata = read.csv("out.csv")
books.lm <- lm(Rating ~ (Goodreads_Rating * Goodreads_Reviews + Amazon_Rating * Amazon_Reviews) * Citations, data=mydata)

# I can significantly improve the fit of the model by changing it to:
# Rating ~ Goodreads.Rating * Goodreads.Reviews * Amazon.Rating * Amazon.Reviews * Citations
#
# The difference between this model and the current model is that this expects an interaction between Goodreads
# data and Amazon data, hence the asterisk. Given that there is no theoretical explanation for such a relationship as far as I can see, I
# believe such a model would be overfitting.
#
# FURTHER, on inspecting the output predictions of both models, the output of the first strikes me as more plausible than that of the second.
#
# Possible interaction: might Goodreads appeal to a different base of users such that differences in Amazon and Goodread's data give non-zero
# information about the quality of a book? I think this is likely, but not enough to double the predictive power of the models, which is what
# the ANOVA output suggests. 

predictions <- predict(books.lm, mydata)

# Insert the new predictions into the database.

db <- dbConnect(SQLite(), dbname="books.db")
books_db <- dbReadTable(db, "data")
books_db$Prediction <- predictions

# Replace new table with predicted values.
sqldf("DROP TABLE data",      stringsAsFactors=FALSE,      dbname="books.db")
sqldf("create table data as select * from books_db",      stringsAsFactors=FALSE,      dbname="books.db")