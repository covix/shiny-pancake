#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(shinythemes)
library(networkD3)
library(streamgraph)
# library(shinyCustom)
# library(visNetwork)




clusterAlg <- c('No cluster' = 'default',
                'WalkTrap' = 'walktrap',
                'InfoMap' = 'infomap')

weightAlg <- c('Number of tweets' = 'default',
               'PageRank' = 'page_rank')

hsChoices <- c('', sort(
  unique(
    hs %>%
      group_by(text) %>%
      count() %>%
      arrange(desc(n)) %>%
      filter(row_number() <= 20) %>%
      arrange(text) %>%
      .$text
  )
))


shinyUI(tagList(
  # useShinyCustom(triggered_event = 'mouseup'),
  
  tags$head(tags$style(HTML(
    "
    svg text {
    font-size: 15px;
    }
    "
  )), includeCSS("styles.css")),
  
  navbarPage(
    "Shiny Tweets",
    
    
    tabPanel(
      "HashtagsFlow",
      
      streamgraphOutput("hsStreamGraphPlot"),
      
      fluidRow(
        column(
          width = 3,
          offset = 3,
          class="col-md-push-0",
        
          sliderInput(
            inputId = "hashtags",
            label = h3("Min hashtag count / hour"),
            min = 1,
            max = 50,
            value = 20
          ),
          
          helpText(
            "If set to ",
            em("x"),
            ", hashtags that were not",
            "retweetd at least ",
            em("x"),
            " times in all the considered hour,", 
            "will be filtered out",
            "in the selected time interval"
          )
          
        ),
        
        column(
          width = 3,
          offset = 0,
          
          sliderInput(
            inputId = "hsTime",
            label = h3("Time Interval"),
            min = 0,
            max = 200,
            value = c(0, 50)
          ),
          
          helpText(
            "Time is expressend in hours spent from the first tweet collected."
          )
          
        )
      )
    ),
    
    
    tabPanel("Map",
             div(
               class = "outer",
               
               leafletOutput("map", width = "100%", height = "100%"),
               
               # Shiny versions prior to 0.11 should use class="modal" instead.
               absolutePanel(
                 class = "controls panel panel-default",
                 fixed = TRUE,
                 draggable = TRUE,
                 top = 60,
                 left = "auto",
                 right = 20,
                 bottom = "auto",
                 width = 330,
                 height = "auto",
                 
                 h2("Source selector"),
                 
                 selectInput("source", "Source", sources)
               )
             )),
    
    
    tabPanel(
      "Network",
      
      div(
        class = "outer",
        forceNetworkOutput("force",  width = "100%", height = "100%"),
        # visNetworkOutput("force",  width = "100%", height = "100%"),
        absolutePanel(
          class = "controls panel panel-default",
          fixed = TRUE,
          draggable = TRUE,
          top = 60,
          left = "auto",
          right = 20,
          bottom = "auto",
          width = 330,
          height = "auto",
          
          h2("Source selector"),
          
          numericInput(
            "degreeInput",
            "Mininum inbound degree",
            min = 0,
            max = 1000,
            value = 200
          ),
          
          selectInput("weightAlg", "Weighting Algorithm", weightAlg),
          selectInput("clusterAlg", "Clustering Algorithm", clusterAlg),
          
          # show at most 5 options in the list
          selectizeInput(
            "netHashtag",
            'Show network for hashtag',
            choices = hsChoices,
            options = list(maxItems = 1)
          )
        )
      )
    ),
    
    
    theme = shinytheme("united")
  )
  ))