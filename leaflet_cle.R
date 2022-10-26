library(leaflet)
library(dplyr)

# Gets a view of a water flow monitoring sensor
# Cuyahoga River near Newburg
m <- leaflet() %>%
  setView(lng=-81.681, lat=41.4626, zoom=13) %>%
  addTiles()
