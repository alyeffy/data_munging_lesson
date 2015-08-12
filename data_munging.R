
# =============================================================================================== #
#   DATA MUNGING WITH dplyr & plyr
#   Vancouver R Study Group
#   Date/Time: Wednesday, August 12 2015 15:00 PM
#   Location: UBC LSI 1510
#   Author: Alyssa Fegen (Github - @alyeffy | email - alyssa.f2406@gmail.com)
# =============================================================================================== #

# DEPENDENCIES (try to have these installed before the lesson)
install.packages("plyr")
install.packages("dplyr")
install.packages("gapminder")

# LOAD PACKAGES
library(gapminder) # data set package to be used for examples

rm(list=ls()) # clears all existing variables in your workspace (OPTIONAL)
sessionInfo() # useful for checking which packages are currently loaded

# INSPECT RAW DATA
gap <- gapminder
head(gap, 100)
tail(gap)
dim(gap)
names(gap)
str(gap)
summary(gap)
levels(gap$country)



# BASIC PLYR
library(plyr)
# - plyr provides a lot of functions for split-apply-combine data analysis
# - Such tasks can be done by combining several base R functions as well, but using plyr functions allows your code
#   to look simpler and more readable/concise, leading to less bugs, more robustness/reusability etc.
# - Main functions have the format XXply, and are more specific than base functions
#   e.g. ldply, dlply, ddply vs. sapply, lapply
library(help="plyr")

countries <- levels(gap$country)

# Base functions: lapply & sapply

# lapply
# number of characters in each country's name
c_length <- lapply(countries, nchar)
head(c_length)
names(c_length) <- countries
head(c_length)
c_length$Canada



# sapply
# number of characters in each country's name
sapply(countries, nchar)



# A much more complicated example
# mean GDP for each country across all years
mean_gdps1 <- t(sapply(countries, function(c) {
    # Split: break up data into more manageable groups
    c_gap <- gap[with(gap, which(country == c)), c("pop", "gdpPercap")]
    
    # Apply: do something to each group of data
    means <- lapply(c_gap, mean)
    
    # Combine: join the groups back together
    c(unlist(means), with(means, pop * gdpPercap))
}))
mean_gdps1



# Using very very basic R tools
# mean GDP for each country across all years
mean_gdps2 <- data.frame()
for (i in seq(countries)) {
    c <- countries[i]
    c_gap <- gap[with(gap, which(country == c)), c("pop", "gdpPercap")] # Split
    means <- lapply(c_gap, mean) # Apply
    mean_gdps2 <- rbind(mean_gdps2, c(unlist(means), with(means, pop * gdpPercap))) # Combine
}
mean_gdps2



# plyr functions: ldply, dlply & ddply


# ldply is similar to using sapply to create matrices (except ldply creates data frames)
# mean GDP for each country across all years
ldply(countries, function(c) {
    c_gap <- with(gap, subset(gap, (country == c), c("pop", "gdpPercap")))
    means <- llply(c_gap, mean)
    c(unlist(means), with(means, pop * gdpPercap))
})



# dlply is the opposite of ldply, but with a useful .variable parameter that allows you to subset the input data frame
# list of countries in each continent
args(dlply)
bycont <- dlply(gap, .(continent), function(g) unique(gap$country))
bycont$Africa
bycont$Asia



# ddply also has a .variable parameter to split the input data frame and combines results into a final data frame
# mean life expectancy for each continent each year
ddply(gap, .(continent, year), function(g) with(g, mean(lifeExp)))



# Bells & Whistles
# - Some plyr functions have built-in progress bars
happy <- ldply(1:100000, function(x) rep(":)", 10), .progress="text")
head(happy)





# BASIC DPLYR
library(dplyr)
# - dplyr offers a lot of similar functions to plyr, but is more catered to data frames
# - Provides an easier way of using the most vital data manipulation techniques needed for data analysis in R
# - Functions have also more intuitive syntax than base functions
# - Some key functions tend to be faster than base ones because they are coded in C++
# - Allows for piping/chaining functions
library(help="dplyr")



# Piping/Chaining (%>% operator)
# - More intuitive way of chaining several functions to carry out in a specific sequence
# - Keyboard shortcut: Ctrl+Shift+M (Windows) / Cmd+Shift+M (Mac)
# - Automatically uses data as first argument for each function; use a . to use it as another argument

letters %>% sample(size=5) %>% sort(decreasing=TRUE) %>% rep(times=5)
# vs below (both do the same thing)
rep(sort(sample(letters, size=5), decreasing=TRUE), times=5)

letters %>% toupper %>% gsub("[ASDFGHJKL]", ":)", .)



# Data Tbls vs. Data Frames
# - Tbls are generally easier to work with especially when you're looking at raw data, but not a necessary
#   data structure to use with most dplyr functions

# General viewing of data tbls in the console is nicer than with data frames
gap2 <- cbind(gap, gap)

gap2 <- tbl_df(gap2)
gap2
str(gap2)
# vs. base functions:
gap2 <- data.frame(gap2)
gap2
str(gap2)
#utils::View(gap2)

# Data tbls don't coerce strings into factors like data frames do by default
letter_tbl <- data_frame(1:length(letters), letters)
str(lettertbl)
lettertbl
lettertbl[1, ] <- c(100, ":)")
lettertbl
# vs. base functions:
letter_df <- data.frame(1:length(letters), letters)
str(letter_df)
letter_df
letter_df[1, ] <- c(100, ":)")
letter_df
letter_df[27, ] <- c(7, "g")
letter_df



# 5 Main Data Manipulation "Verbs" and Their Functions
# select, filter, arrange, mutate, summarize



# 1. select
# Subset data frame by specified columns

select(gap, continent, lifeExp) %>% head(25)
# equivalent to base functions:
gap[c("continent", "lifeExp")] %>% head(25)



# 2. filter
# Extract rows of a data frame that meet certain criteria
# - only works with AND conditions; no OR conditions

filter(gap, year > 1965, country == "Singapore")
# equivalent to base functions:
gap[with(gap, which((year > 1965) & (country == "Singapore"))), ]



# 3. arrange
# Order data frame by certain columns

arrange(gap, year, desc(gdpPercap)) %>% head(25)
# equivalent to base functions:
gap[with(gap, order(year, -gdpPercap)), ] %>% head(25)



# Arrange also makes it possible to arrange data frames by descending order of non-numeric columns
arrange(gap, year, desc(country)) %>% head(25)
# vs. base functions:
gap[with(gap, order(year, -country)), ] %>% head(25)
gap[with(gap, order(year, country, decreasing=TRUE)), ] %>% head(25)



# 4. mutate
# Adds new columns to existing data frames

mutate(gap, gdp = gdpPercap * pop) %>% head(25)
# equivalent to base functions:
gap$gdp <- with(gap, gdpPercap * pop)
head(gap, 25)



# 5. summarize
# Reduces grouped data to a smaller number of summary statistics to focus on
# - best used with group_by function
gap %>% 
    group_by(continent, country) %>% 
    summarize(mean_gdp = mean(gdpPercap * pop)) %>% 
    summarize(mean_cont_gdp = mean(mean_gdp))





# More Functions
# Look up vignettes on CRAN for any package to find out what functions they offer and documentation
# on each function

browseURL("https://cran.r-project.org/web/packages/plyr")
browseURL("https://cran.r-project.org/web/packages/dplyr")



# END - THANK YOU! :)


