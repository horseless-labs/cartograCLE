library(httr)
library(jsonlite)

# Get data from Cuyahoga County from the past two days.
path <- "https://waterservices.usgs.gov/nwis/iv/?format=json&countyCd=39035&period=P2D&parameterCd=00060,00065&siteStatus=all"
cuyahoga <- GET(url = path)
cuyahoga <- content(cuyahoga, as = "text", encoding = "UTF-8")
cuyahoga <- fromJSON(cuyahoga, flatten = TRUE)
cuyahoga <- as_tibble(cuyahoga)

sites <- cuyahoga$value$timeSeries
# Demo using just one site
# Values should be something like
# stage: 2.51 feet
# flow: 7.99 cfs
# lat: 41.4503 N
# lon: 81.7215 W
# per its GLDW entry
big_creek <- sites %>%
  filter(sourceInfo.siteName=="Big Creek at Cleveland OH")
flow_list <- big_creek[[1]][[1]][[1]][[1]]
stage_list <- big_creek[[1]][[2]][[1]][[1]]
lat <- big_creek$sourceInfo.geoLocation.geogLocation.latitude
lon <- big_creek$sourceInfo.geoLocation.geogLocation.longitude
