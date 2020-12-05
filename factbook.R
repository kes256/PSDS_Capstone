library(jsonlite)
library(geojsonio)
library(countrycode)
library(tidyverse)

pivoted <- 'clean_factbook.json' %>%
  read_file() %>%
  parse_json() %>%
  unlist() %>%
  enframe() %>%
  separate(name, into = c(paste0("x", 1:3)), sep = "[.]", extra="merge", fill = "right") %>%
  pivot_wider(names_from = x3, values_from = value, id_cols = x2) %>%
  head(-3)

cia_extras <- c('Kosovo' = 'OWID_KOS', 'European Union' = 'EU', 'Saint Martin' = 'MAF', 'Virgin Islands' = 'VIR', 'World' = 'OWID_WRL')  
pivoted$code <- countrycode(unlist(pivoted$data.name), origin='country.name', destination='iso3c', custom_match=cia_extras)
pivoted <- pivoted %>%
  drop_na(code)

names_to_keep <- read_lines('columns_by_subject/env_cols.txt')
names_to_keep <- c(names_to_keep, read_lines('columns_by_subject/econ_cols.txt'))
names_to_keep <- c(names_to_keep, read_lines('columns_by_subject/health_cols.txt'))
names_to_keep <- c(names_to_keep, read_lines('columns_by_subject/edu_cols.txt'))
names_to_keep <- c(names_to_keep, read_lines('columns_by_subject/demographic_cols.txt'))
names_to_keep <- c(names_to_keep, read_lines('columns_by_subject/geo_cols.txt'))

cia_all <- pivoted[,which(colnames(pivoted) %in% names_to_keep)]
cia_all <- unnest(cia_all, colnames(cia_all))

cia_all$capital_lat <- with(cia_all, ifelse(is.na(data.government.capital.geographic_coordinates.latitude.minutes), NA, as.numeric(data.government.capital.geographic_coordinates.latitude.minutes)/60 + as.numeric(data.government.capital.geographic_coordinates.latitude.degrees)))
cia_all <- transform(cia_all, capital_lat=ifelse(data.government.capital.geographic_coordinates.latitude.hemisphere=='S', -capital_lat, capital_lat))

cia_all$capital_long <- with(cia_all, ifelse(is.na(data.government.capital.geographic_coordinates.longitude.minutes), NA, as.numeric(data.government.capital.geographic_coordinates.longitude.minutes)/60 + as.numeric(data.government.capital.geographic_coordinates.longitude.degrees)))
cia_all <- transform(cia_all, capital_long=ifelse(data.government.capital.geographic_coordinates.longitude.hemisphere=='W', -capital_long, capital_long))

world_map <- geojson_read('custom_geo.json',  what = "sp")
spdf_fortified <- broom::tidy(world_map, region = "name")
spdf_fortified$code <- countrycode(spdf_fortified$id, origin='country.name', destination='iso3c', custom_match = c('Kosovo' = 'XK', 'S. Sudan' = 'SSD', 'W. Sahara' = 'ESH', 'Dem. Rep. Korea'='PRK', 'Somaliland'='SOM'))

spdf_cia <- inner_join(spdf_fortified, cia_all)

write_csv(cia_all, 'factbook.csv')
#write_csv(spdf_cia, 'map_factbook.csv')
