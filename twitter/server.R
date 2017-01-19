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
  # StreaGraph
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
  
  
  # Map
  output$sourceBarPlot <- renderChart2({
    # barplot(
    #   sourcesV[c(1:10)],
    #   main = 'Application of all tweets',
    #   # ylab = "Number of tweets",
    #   ylab = "Number of tweets",
    #   las = 2
    # )
    return(rPlot(x = "source", y = "count", data = sources, type = 'bar'))
  })
  
  
  output$map <- renderLeaflet({
    pal <- colorFactor("Spectral", map$sourceL)
    
    data <- map
    
    leaflet() %>%
      addTiles(urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
               attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>') %>%
      addCircleMarkers(
        data = data[c("long", "lat")],
        color = pal(data$sourceL),
        layerId = data$layerId
      ) %>%
      addLegend(
        "bottomleft",
        pal = pal,
        values = data$sourceL,
        title = 'Source',
        layerId = "colorLegend"
      )
  })
  
  observe ({
    colorSource <- input$source
    
    pal <- colorFactor("Spectral", map$sourceL)
    if (colorSource == "All") {
      data <- map
    } else {
      data <- map %>% filter(sourceL == colorSource)
    }
    
    leafletProxy("map", data = data) %>%
      clearMarkers() %>%
      addCircleMarkers(
        data = data[c("long", "lat")],
        color = pal(data$sourceL),
        layerId = data$layerId
      )
  })
  
  # Show a popup at the given location
  showTweetPopup <- function(layerId, lat, lng) {
    tweet <- map[map$layerId == layerId,]
    content <-
      as.character(tagList(
        HTML(tweet$text),
        "-",
        tags$a(
          href = sprintf("https://twitter.com/%s", tweet$user),
          sprintf("@%s", tweet$user),
          target = "_blank"
        ),
        tags$a(
          href = sprintf("https://twitter.com/%s/status/%s", tweet$user, tweet$id),
          icon("new-window", lib = "glyphicon"),
          target = "_blank"
        )
      ))
    leafletProxy("map") %>% addPopups(lng, lat, content, layerId = layerId)
  }
  
  # When map is clicked, show a popup with city info
  observe({
    leafletProxy("map") %>% clearPopups()
    event <- input$map_marker_click
    
    if (is.null(event))
      return()
    
    isolate({
      showTweetPopup(event$id, event$lat, event$lng)
    })
  })
  
  
  # Network
  output$force <- renderForceNetwork({
    forceNetwork(
      Links = MisLinks,
      Nodes = MisNodes,
      Source = "source",
      Target = "target",
      Value = "value",
      NodeID = "name",
      Group = "group",
      Nodesize = "size",
      opacity = .8,
      fontSize = 15,
      zoom = TRUE
    )
  })
  
})
