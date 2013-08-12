#!/bin/bash
/usr/bin/sqlite3 books.db <<!
.headers on
.mode csv
.output out.csv
select * from data;
!
