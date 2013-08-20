# Installing dependencies
Install R, Ruby, SQLite, and Python from the repository:

```bash
$ pacman -S r ruby sqlite python
```

On debian based distributions, you will need the dev pacakges, too. (e.g. ruby-dev)

Install Ruby libraries:
```bash
$ gem install sequel trollop nokogiri sqlite3
```

Next, you will need to install the necessary R libraries. Boot up the R REPL like so:
```bash
$ R
R version 3.0.0 (2013-04-03) -- "Masked Marvel"
Copyright (C) 2013 The R Foundation for Statistical Computing
Platform: x86_64-unknown-linux-gnu (64-bit)
...
> install.packages("sqldf")
...
> install.packages("klaR")
...
> install.packages("caret")
...
> install.packages("e1071")
```

Then, if it works you should be able to do things like:
```bash
$ ruby bkz.rb --title "Information Theory, Inference, and Learning Algorithm
{:title=>"Information Theory, Inference, and Learning Algorithms", :source=>nil, :citations=>nil, :tags=>nil, :print=>false, :help=>false, :title_given=>true}
Is this the title of your book: Information theory, inference and learning algorithms? [y/n]
y
$ Rscript bkz.R 
NULL
NULL
...
```

# Components

To add books:
```bash
ruby bkz.rb --title "BOOK_TITLE"
```

To update predictions:
```bash
Rscript bkz.R
```

The predictions and book data are stored in books.db, a SQLite table, which can be view inside of one of the many GUI-based SQLite managers. Firefox users can use [this plugin](https://addons.mozilla.org/en-us/firefox/addon/sqlite-manager/).
# scholar.py credit

The scholar.py code is the work of Christian Kreibich and contributors. The project page can be found [here](http://www.icir.org/christian/scholar.html).
