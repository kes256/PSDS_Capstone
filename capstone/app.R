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
library(plotly)
library(reticulate)

source_python('plots.py')
#world_map <- geojson_read('custom_geo.json',  what = "sp")
#spdf_fortified <- broom::tidy(world_map, region = "name")
#spdf_fortified$code <- countrycode(spdf_fortified$id, origin='country.name', destination='iso3c', custom_match = c('Kosovo' = 'XK', 'S. Sudan' = 'SSD', 'W. Sahara' = 'ESH', 'Dem. Rep. Korea'='PRK', 'Somaliland'='SOM'))

cia_all <- read_csv('factbook.csv')
spdf_cia <- inner_join(spdf_fortified, cia_all)
owid_data <- read.table("https://covid.ourworldindata.org/data/owid-covid-data.csv", header=T, sep=",", quote="")
cia_owid <- left_join(cia_all, owid_data, by=c('code'='iso_code')) %>% drop_na(capital_lat, date) %>%
    mutate_all(funs(ifelse(is.na(.), 0, .)))

# Define UI for application
ui <- fluidPage(

    # Application title
    titlePanel("COVID reporting with supplemental data"),

    # Sidebar with input 
    sidebarLayout(
        sidebarPanel(
            selectInput("col",
                        label = "Background Color",
                        choices = colnames(cia_all)
            ),
        ),
        
        # Show a plot 
        mainPanel(
           htmlOutput("worldMap", height=1000)
        )
    )
)

# Define server logic 
server <- function(input, output) {

    output$worldMap <- reactive({
        plot_3d_data(r_to_py(cia_owid), 'new_cases', input$col, 'map.csv')
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
