library(osmdata)
library(tidyverse)
library(sf)

coords <- matrix(c(-81.7,-81.67,41.5,41.52),
                 byrow = TRUE,
                 nrow = 2,
                 ncol = 2,
                 dimnames = list(c('x','y'),c('min','max')))
location <- coords %>% opq()

water <- location %>%
  add_osm_feature(key = "natural",
                  value = c("water")) %>%
  osmdata_sf()

ggplot() +
  geom_sf(data = water$osm_multipolygons,
          fill = 'light blue') +
  theme_minimal()