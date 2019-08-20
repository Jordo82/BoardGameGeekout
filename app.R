library(shiny)
library(tidyverse)
library(ggrepel)
library(ggthemes)

#scaffolding of a shiny app to interactively explore the game data
data <- readRDS("Data/data.rds")

ui <- pageWithSidebar(
  headerPanel("Board Game Geekout"),
  sidebarPanel(
    h2("Filters"),
    sliderInput("players", "#of Players", 1, 12, value = c(1, 12)),
    sliderInput("playtime", "Play Time", 0, 360, value = c(0, 360), step = 10),
    sliderInput("usersrated", "Min #of Ratings", 0, 5000, 3000),
    sliderInput("avgrating", "Min Avg Rating", 1, 10, 6, step = 0.1),
    sliderInput("avgweight", "Complexity", 1, 5, value = c(1, 5), step = 0.1)
  ),
  mainPanel(
    plotOutput("plot", height = 800)
  )
)

server <- function(input, output){
  output$plot <- renderPlot({
    data %>% 
      filter(minplayers >= min(input$players),
             maxplayers <= max(input$players),
             minplaytime >= min(input$playtime),
             maxplaytime <= max(input$playtime),
             usersrated >= input$usersrated,
             average >= input$avgrating,
             averageweight >= min(input$avgweight),
             averageweight <= max(input$avgweight)) %>% 
      ggplot(aes(Mechanic_PC1, Mechanic_PC2)) + 
      geom_label_repel(aes(label = name, fill = average, size = log(usersrated)), 
                       fontface = "bold", color = "white", segment.color = "black") + 
      scale_fill_distiller(palette = "Greens", direction = 1) + 
      theme_fivethirtyeight() + 
      theme(legend.position = "none",
            axis.text = element_blank(),
            panel.grid.major = element_blank())
  })
  
}

shinyApp(ui, server)