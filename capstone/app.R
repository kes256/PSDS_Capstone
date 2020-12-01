#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(geojsonio)
library(mapproj)
library(viridis)
library(countrycode)

world_map <- geojson_read('custom_geo.json',  what = "sp")
spdf_fortified <- broom::tidy(world_map, region = "name")
spdf_fortified$code <- countrycode(spdf_fortified$id, origin='country.name', destination='iso3c', custom_match = c('Kosovo' = 'XK', 'S. Sudan' = 'SSD', 'W. Sahara' = 'ESH', 'Dem. Rep. Korea'='PRK', 'Somaliland'='SOM'))

cia_all <- read_csv('factbook.csv')
spdf_cia <- inner_join(spdf_fortified, cia_all)


# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel(""),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput("col",
                        label = "Background Color",
                        choices = colnames(cia_all)
            ),
            sliderInput("date", "Date (by week)",
                        min = 0, max = 364, step = 7, value = 500, animate = TRUE
            ),
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("worldMap")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$worldMap <- renderPlot({
        ggplot() + 
            geom_polygon(data = spdf_cia, aes( x = long, y = lat, group=group, fill=get(input$col)), color="white") + 
            theme_void() + 
            labs(
                title = "World Coronavirus Map",
                subtitle = "COVID reporting with supplemental data",
                caption = "Creation: K. Smith | https://github.com/kes256/PSDS_Capstone") +
            theme(
                text = element_text(color = "#22211d"),
                plot.background = element_rect(fill = "#f5f5f2", color = NA),
                panel.background = element_rect(fill = "#f5f5f2", color = NA),
                legend.background = element_rect(fill = "#f5f5f2", color = NA),
                
                plot.title = element_text(size= 22, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
                plot.subtitle = element_text(size= 17, hjust=0.05, color = "#4e4d47", margin = margin(b = 0.1, t = 0.43, l = 2, unit = "cm")),
                plot.caption = element_text( size=12, color = "#4e4d47", margin = margin(b = 0.3, r=0.3, unit = "cm") ),
                legend.position = c(0.2, 0),
            ) +
            scale_fill_viridis(name=input$col, guide = guide_legend( keyheight = unit(3, units = "mm"), keywidth=unit(12, units = "mm"), label.position = "bottom", title.position = 'top', nrow=1) ) +
            coord_map()
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
