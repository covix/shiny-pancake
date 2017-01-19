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
library(leaflet)
library(networkD3)

data(MisLinks)
data(MisNodes)


# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  output$hsStreamGraphPlot <- renderStreamgraph({
    toplist <- hs %>%
      count(text) %>%
      arrange(desc(n)) %>%
      filter(row_number() <= input$hashtags)
    
    toplist <- toplist$text
    
    data <- hs %>%
      group_by(date_time, text) %>%
      count() %>%
      arrange(n) %>%
      filter(text %in% toplist)
    
    eval(call_new(streamgraph, data, "text", "n", "date_time", scale = "continuous"))
  })
  
  
  output$map <- renderLeaflet({
    pal <- colorFactor("Spectral", map$sourceL)
    
    if (input$source == "All") {
      data <- map
    } else {
      data <- map %>% filter(sourceL == input$source)
    }
    
    leaflet() %>%
      addTiles(urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
               attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>') %>%
      addCircleMarkers(data = data[c("long", "lat")], color = pal(data$sourceL)) %>%
      addLegend(
        "bottomleft",
        pal = pal,
        values = data$sourceL,
        title = 'Source',
        layerId = "colorLegend"
      )
  })
  
  
  output$force <- renderForceNetwork({
    forceNetwork(
      Links = MisLinks,
      Nodes = MisNodes,
      Source = "source",
      Target = "target",
      Value = "value",
      NodeID = "name",
      Group = "group",
      opacity = .8,
      fontSize = 15
    )
  })
  
})
