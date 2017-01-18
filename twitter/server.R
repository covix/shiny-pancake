#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(streamgraph)
library(lazyeval)


# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  hs <- "../data/tweets_macbook_sample_hs.txt"
  # hs <- "../data/tweets_macbook_2016-11-03-15-10-46_hs.txt"
  
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
  
  hs <- within(hs, date_time <- (created_at - as.numeric(as.POSIXct("2016-10-27"))) / 3600)
  hs$text <- tolower(hs$text)

  output$distPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    x    <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    
    # draw the histogram with the specified number of bins
    hist(x,
         breaks = bins,
         col = 'darkgray',
         border = 'white')
  })
  
  output$hsStreamGraphPlot <- renderStreamgraph({
    toplist <- hs %>% 
      count(text) %>% 
      arrange(n) %>% 
      filter(row_number() > n() - input$hashtags)
    
    toplist <- toplist$text
    
    data <- hs %>%
      group_by(date_time, text) %>%
      count() %>%
      arrange(n) %>%
      filter(text %in% toplist)

    
    eval(call_new(streamgraph, data, "text", "n", "date_time", scale = "continuous"))
  })
  
})
