library(dplyr)

hs <- "../data/tweets_macbook_sample_hs.txt"
hs <- "../data/tweets_macbook_2016-11-03-15-10-46_hs.txt"

hs <- read.csv(hs)
# hs <-
#   within(hs,
#          date_time <-
#            cut(as.POSIXlt(created_at, format = "%Y-%m-%d %H:%M:%S"), breaks = "hour"))
# hs <-
#   within(hs,
#          date_time <-
#           cut(as.POSIXct(as.POSIXlt(created_at, origin="2016-10-27")), breaks = "hour"))
# hs <- within(hs, date_time <- created_at)

hs <-
  within(hs, date_time <-
           as.integer((created_at - as.numeric(
             as.POSIXct("2016-10-27")
           )) / 3600))
hs$text <- tolower(hs$text)


# map <- "../data/tweets_macbook_sample_map.txt"
map <- "../data/tweets_macbook_2016-11-03-15-10-46_map.txt"
map <-
  read.csv(map,
           colClasses = c(
             'factor',
             'character',
             'double',
             'double',
             'factor',
             rep('character', 2)
           ))
map$layerId <- c(1:nrow(map))

keep_sources <-
  map %>%
  count(source) %>%
  arrange(desc(n)) %>%
  filter(row_number() <= 10) %>%
  .$source

map <- within(map,
              sourceL <-
                ifelse(map$source %in% keep_sources, levels(map$source)[map$source], "Other"))
sl <- unique(map$sourceL)
sources <- as.factor(c("All", sl[sl != 'Other'], "Other"))


# sources <- "../data/tweets_macbook_sample_sources.txt"
# # sources <- "../data/tweets_macbook_2016-11-03-15-10-46_sources.txt"
# sources <- read.csv(sources)
# sources <- sources %>% arrange(desc(count))
#
# sourcesV <- sources$count
# names(sourcesV) <- sources$source


nodes <- "../data/tweets_macbook_sample_nodes.txt"
links <- "../data/tweets_macbook_sample_links.txt"

nodes <- "../data/tweets_macbook_2016-11-03-15-10-46_nodes.txt"
links <- "../data/tweets_macbook_2016-11-03-15-10-46_links.txt"

links_or <- read.csv(links)
colnames(links_or) <- c('value', 'source', 'target')

nodes_or <- read.csv(nodes)
nodes_or$group <- rep(1, nrow(nodes_or))
