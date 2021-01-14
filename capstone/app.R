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

requirements = c('numpy', 'pandas', 'plotly_express', 'plotly')
reticulate::virtualenv_create(envname='python3_env', python='python3')
reticulate::virtualenv_install('python3_env', packages=requirements)
reticulate::use_virtualenv('python3_env', required=T)
reticulate::source_python('plots.py')

weekly_dates <- append(seq(as.Date('2020-01-23'), lubridate::today() - 1, 'weeks'), lubridate::today() - 1)
cia_all <- read_csv('factbook.csv')
owid_data <- read.table("https://covid.ourworldindata.org/data/owid-covid-data.csv", header=T, sep=",", quote="")
owid_data <- dplyr::filter(owid_data, date %in% format(weekly_dates, "%Y-%m-%d"))
cia_owid <- left_join(cia_all, owid_data, by=c('code'='iso_code')) %>% drop_na(capital_lat, date) %>%
    mutate_all(funs(ifelse(is.na(.), 0, .))) %>% dplyr::arrange(date)
python_df <- reticulate::r_to_py(cia_owid)
# Define UI for application
ui <- fluidPage(

    # Application title
    titlePanel("COVID reporting with supplemental data"),

    verticalLayout(
        selectInput("data",
                    label = "COVID Data Selection",
                    choices = c('*total_cases',
                                '*total_deaths',
                                '*new_cases_smoothed',
                                '*new_deaths_smoothed',
                                '*total_cases_per_million',
                                '*new_cases_smoothed_per_million',
                                '*total_deaths_per_million',
                                '*new_deaths_smoothed_per_million',
                                '*tests_per_case')
        ),
        selectInput("color",
                    label = "Color Selection",
                    choices = c('*stringency_index',
                                '*population',
                                '*population_density',
                                '*median_age',
                                '*aged_65_older',
                                '*aged_70_older',
                                '*gdp_per_capita',
                                '*extreme_poverty',
                                '*cardiovasc_death_rate',
                                '*diabetes_prevalence',
                                '*female_smokers',
                                '*male_smokers',
                                '*handwashing_facilities',
                                '*hospital_beds_per_thousand',
                                '*life_expectancy',
                                '*human_development_index',
                                "**Percent_Urban_Population",
                                "**Infant_Mortality_Rate",
                                "**Access_to_Improved_Drinking_Water",
                                "**Access_to_Improved_Sanitation_Facility",
                                "**Literacy_Rate",
                                "**School_Life_Expectancy",
                                "**Education_Expenditure",
                                "**Access_to_Internet")
        ),
        htmlOutput("worldMap"),
        textOutput("caption"),
        textOutput('owid_credit'),
        textOutput('factbook_credit')
    )
)

# Define server logic 
server <- function(input, output) {

    output$worldMap <- reactive({
        plot_3d_data(python_df, input$data, input$color, 'map.csv')
    })
    output$caption <- renderText({"Plot created by K. Smith | https://github.com/kes256/PSDS_Capstone"})
    output$owid_credit <- renderText({"* data from https://covid.ourworldindata.org/data/owid-covid-data.csv, collected, aggregated, and documented by Cameron Appel, Diana Beltekian, Daniel Gavrilov, Charlie Giattino, Joe Hasell, Bobbie Macdonald, Edouard Mathieu, Esteban Ortiz-Ospina, Hannah Ritchie, Max Roser."})
    output$factbook_credit <- renderText({"** data from the CIA World Factbook, compiled by Ian Coleman at https://github.com/iancoleman/cia_world_factbook_api."})
}

# Run the application 
shinyApp(ui = ui, server = server)
