world_map <- geojson_read('custom_geo.json',  what = "sp")
spdf_fortified <- broom::tidy(world_map, region = "name")
spdf_fortified$code <- countrycode(spdf_fortified$id, origin='country.name', destination='iso3c', custom_match = c('Kosovo' = 'XK', 'S. Sudan' = 'SSD', 'W. Sahara' = 'ESH', 'Dem. Rep. Korea'='PRK', 'Somaliland'='SOM'))

cia_all <- read_csv('factbook.csv')
spdf_cia <- inner_join(spdf_fortified, cia_all)

owid_data <- read.table("https://covid.ourworldindata.org/data/owid-covid-data.csv", header=T, sep=",")
date = "2020-07-04"


ggplot() + 
  geom_polygon(data = spdf_cia, aes( x = long, y = lat, group=group, fill=data.people.major_infectious_diseases.count), color="white") + 
  theme(legend.position = c(0.2, 0)) + 
  scale_fill_viridis(name= 'Disease Count', guide = guide_legend( keyheight = unit(3, units = "mm"), keywidth=unit(12, units = "mm"), label.position = "bottom", title.position = 'top', nrow=1) ) +
  coord_map()

