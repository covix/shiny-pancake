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
library(igraph)
# library(visNetwork)
library(networkD3)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  # StreaGraph
  output$hsStreamGraphPlot <- renderStreamgraph({
    nHs <- input$hashtags
    nHours <- min(hs$created_at) + input$hsTime * 3600
    
    toplistc <- hs %>%
      filter(created_at >= nHours[[1]] & created_at <= nHours[[2]]) %>%
      group_by(created_at, text) %>%
      summarise(n = n())
    
    toplist <- c()
    for (h in unique(toplistc$created_at)) {
      tmp <- toplistc %>%
        filter(created_at == h & n > nHs) %>%
        arrange(desc(n)) %>%
        filter(row_number() < 15) %>%
        .$text

      toplist <- c(
        toplist,
        tmp
      )
    }
    
    toplist <- unique(toplist)
    
    data <- hs %>%
      filter(created_at >= nHours[[1]] & created_at <= nHours[[2]]) %>%
      group_by(date_time, text) %>%
      count() %>%
      arrange(n) %>%
      filter(text %in% toplist)
    
    eval(call_new(streamgraph, data, "text", "n", "date_time", scale = "continuous"))
  })
  
  
  # Map
  # output$sourceBarPlot <- renderChart({
  # barplot(
  #   sourcesV[c(1:10)],
  #   main = 'Application of all tweets',
  #   # ylab = "Number of tweets",
  #   ylab = "Number of tweets",
  #   las = 2
  # )
  # })
  
  
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
    # output$force <- renderVisNetwork({
    min_degree <- input$degreeInput
    weigthAlg <- input$weightAlg
    clusterAlg <- input$clusterAlg
    hashtag <- tolower(input$netHashtag)
    
    users <- links_or
    
    if (hashtag != '') {
      ht_users <-
        as.character(hs %>% filter(text == hashtag) %>% .$screen_name)
      nodes <- nodes_or %>%
        filter(name %in% ht_users)
      
      users <- users %>%
        filter(source %in% nodes$idx & target %in% nodes$idx)
    }
    
    users <- users %>%
      group_by(target) %>%
      summarise(rt = sum(value)) %>%
      filter(rt > min_degree) %>%
      .$target
    
    links <-
      links_or %>%
      filter(source %in% users & target %in% users)
    
    nodes <- nodes_or %>% filter(idx %in% users)
    
    if (nrow(nodes) == 0 | nrow(links) == 0) {
      validate(need(
        input$min_degree > 1,
        tags$h1("The real error is: degree to high")
      ))
      return()
    }
    
    #with igraph
    dict <- as.vector(as.character(nodes$name), mode = "list")
    
    
    names(dict) <- as.character(nodes$idx)
    
    # with igraph
    links$source <-
      unlist(dict[as.character(links$source)])
    links$target <-
      unlist(dict[as.character(links$target)])
    
    links <- links[c('source', 'target', 'value')]
    
    g <-
      graph_from_data_frame(links, directed = TRUE, vertices = nodes[, c(2:4)])
    
    if (clusterAlg != 'default') {
      wc <- get(paste('cluster', clusterAlg, sep = '_'))(g)
      members <- membership(wc)
    } else {
      members <- rep(1, nrow(nodes))
    }
    
    net <- networkD3::igraph_to_networkD3(g, members)
    
    wgs <- c()
    if (weigthAlg == 'page_rank') {
      pr <- page_rank(g)
      wgs <- (10 * (pr$vector / min(pr$vector))) ^ (3/2)
    } else if (weigthAlg == 'default') {
      wgs <- 10 * nodes$size
    }
    
    net$nodes$size <- wgs
    
    forceNetwork(
      Links = net$links,
      Nodes = net$nodes,
      Source = "source",
      Target = "target",
      Value = "value",
      NodeID = "name",
      Group = "group",
      Nodesize = "size",
      opacity = .8,
      fontSize = 25,
      zoom = TRUE
    )
  })
  
})
