pivoted <- 'clean_factbook.json' %>%
  read_file() %>%
  parse_json() %>%
  unlist() %>%
  enframe() %>%
  separate(name, into = c(paste0("x", 1:3)), sep = "[.]", extra="merge", fill = "right") %>%
  pivot_wider(names_from = x3, values_from = value, id_cols = x2) %>%
  head(-3)

cia_extras <- c('Kosovo' = 'XK', 'European Union' = 'EU', 'Saint Martin' = 'MAF', 'Virgin Islands' = 'VIR')  
pivoted$code <- countrycode(unlist(pivoted$data.name), origin='country.name', destination='iso3c', custom_match=cia_extras)
pivoted <- pivoted %>%
  drop_na(code)

names_to_keep <- read_lines('env_cols.txt')
names_to_keep <- c(names_to_keep, read_lines('econ_cols.txt'))
names_to_keep <- c(names_to_keep, read_lines('health_cols.txt'))
names_to_keep <- c(names_to_keep, read_lines('edu_cols.txt'))
names_to_keep <- c(names_to_keep, read_lines('demographic_cols.txt'))

cia_all <- pivoted[,which(colnames(pivoted) %in% names_to_keep)]
cia_all <- unnest(cia_all, colnames(cia_all))

world_map <- geojson_read('custom_geo.json',  what = "sp")
spdf_fortified <- broom::tidy(world_map, region = "name")
spdf_fortified$code <- countrycode(spdf_fortified$id, origin='country.name', destination='iso3c', custom_match = c('Kosovo' = 'XK', 'S. Sudan' = 'SSD', 'W. Sahara' = 'ESH', 'Dem. Rep. Korea'='PRK', 'Somaliland'='SOM'))

spdf_cia <- inner_join(spdf_fortified, cia_all)

write_csv(spdf_cia, 'map_factbook.csv')
