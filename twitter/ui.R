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

shinyUI(tagList(
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
                   "hashtags",
                   "Number of hashtags:",
                   min = 1,
                   max = 50,
                   value = 20
                 )
               ), mainPanel(streamgraphOutput(
                 "hsStreamGraphPlot"
               )))
             )),
    
    tabPanel("Map",
             div(
               class = "outer",
               leafletOutput("map", width = "100%", height = "100%"),
               
               # Shiny versions prior to 0.11 should use class="modal" instead.
               absolutePanel(
                 id = "controls",
                 class = "panel panel-default",
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
    
    
    theme = shinytheme("united")
  )
  ))