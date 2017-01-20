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
# library(shinyCustom)
# library(visNetwork)




clusterAlg <- c('No cluster' = 'default',
                'WalkTrap' = 'walktrap',
                'InfoMap' = 'infomap')

weightAlg <- c('Number of tweets' = 'default',
               'PageRank' = 'page_rank')

hsChoices <- c('', sort(unique(
  hs %>% 
    group_by(text) %>%
    count() %>% 
    arrange(desc(n)) %>%
    filter(row_number() <= 25) %>%
    arrange(text) %>%
    .$text
)))


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
    
    
    tabPanel("HashtagsFlow",
             div(
               sidebarLayout(sidebarPanel(
                 sliderInput(
                   inputId = "hashtags",
                   label = "Number of hashtags:",
                   min = 1,
                   max = 50,
                   value = 20
                 )
               ),
               mainPanel(streamgraphOutput(
                 "hsStreamGraphPlot"
               )))
             )),
    
    
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