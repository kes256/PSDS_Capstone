library(tidyverse)
library(geojsonio)
library(mapproj)
library(viridis)
library(countrycode)
library(plotly)

world_map <- geojson_read('../data/custom_geo.json',  what = "sp")
spdf_fortified <- broom::tidy(world_map, region = "name")
spdf_fortified$code <- countrycode(spdf_fortified$id, origin='country.name', destination='iso3c', custom_match = c('Kosovo' = 'XK', 'S. Sudan' = 'SSD', 'W. Sahara' = 'ESH', 'Dem. Rep. Korea'='PRK', 'Somaliland'='SOM'))

cia_all <- read_csv('../data/factbook.csv')
spdf_cia <- inner_join(spdf_fortified, cia_all)

owid_data <- read.table("https://covid.ourworldindata.org/data/owid-covid-data.csv", header=T, sep=",", quote="")
date_filter = "2020-07-04"

owid_date <- filter(owid_data, owid_data$date == date_filter)
spdf_all <- left_join(spdf_cia, owid_date, by=c('code'='iso_code'))

p <- ggplot() + 
  geom_polygon(data = spdf_all, aes( x = long, y = lat, group=group, fill=human_development_index), color="white") + 
  geom_point(data = spdf_all, aes(capital_long, capital_lat, size=total_cases), color='red') +
  geom_point(data = spdf_all, aes(capital_long, capital_lat, size=new_cases), color='yellow') +
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
  scale_fill_viridis(name='human_development_index', guide = guide_legend( keyheight = unit(3, units = "mm"), keywidth=unit(12, units = "mm"), label.position = "bottom", title.position = 'top', nrow=1) ) +
  coord_map()

cia_owid <- left_join(cia_all, owid_data, by=c('code'='iso_code')) %>% drop_na(capital_lat, date) %>%
  mutate_all(funs(ifelse(is.na(.), 0, .)))

fig <- cia_owid %>%
  plot_ly(
    x = ~date, 
    y = ~reproduction_rate, 
    #size = ~new_deaths_smoothed_per_million, 
    color = ~continent, 
    #frame = ~date, 
    text = ~location, 
    hoverinfo = "text",
    type = 'scatter',
    mode = 'lines'
  )
fig <- fig %>% layout(
  yaxis = list(
    type = "log"
  )
)



fig <- cia_owid %>%
  plot_ly(
    x = ~date, 
    y = ~reproduction_rate, 
    #size = ~new_deaths_smoothed_per_million, 
    color = ~continent, 
    #frame = ~date, 
    text = ~location, 
    hoverinfo = "text",
    type = 'scatter',
    mode = 'lines'
  )
fig <- fig %>% layout(
  yaxis = list(
    type = "log"
  )
)



fig <- cia_owid %>%
  plot_ly(
    x = ~stringency_index, 
    y = ~reproduction_rate, 
    size = ~new_deaths_smoothed_per_million, 
    color = ~continent, 
    #frame = ~date, 
    text = ~location, 
    hoverinfo = "text",
    type = 'scatter',
    mode = 'markers'
  )
fig

