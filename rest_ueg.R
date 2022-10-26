library(httr)
library(jsonlite)
library(leaflet)
library(dplyr)

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
# long: 81.7215 W
# path: 04208502
# per its GLDW entry
big_creek <- sites %>%
  filter(sourceInfo.siteName=="Big Creek at Cleveland OH")

# Big Creek at Cleveland OH
site_name <- big_creek$sourceInfo.siteName[1]
path <- str_split(big_creek$name[1], ":")[[1]][2]

# Latitude and longitude
lat <- big_creek$sourceInfo.geoLocation.geogLocation.latitude[1]
lon <- big_creek$sourceInfo.geoLocation.geogLocation.longitude[1]

flow_list <- big_creek[[1]][[1]][[1]][[1]]
stage_list <- big_creek[[1]][[2]][[1]][[1]]
most_recent_flow <- flow_list[nrow(flow_list),]$value
most_recent_stage <- stage_list[nrow(stage_list),]$value

timestamp <- most_recent_flow$dateTime

# Reduce to a tibble with only the most recent information
site <- tibble(site_name = site_name,
               path = path,
               lat = lat,
               lng = lon,
               last_flow = most_recent_flow,
               last_stage = most_recent_stage,
               datetime = timestamp)

# Add popup info to site
site <- site %>%
  mutate(popup = paste(site_name, "<br/>",
                       "Station: ", path, "<br/>",
                       "Lat: ", lat, " ", "Long: ", lng, "<br/>",
                       "Flow: ", last_flow, "<br/>",
                       "Stage: ", last_stage))

# Add to map
stations <- leaflet() %>%
  setView(lng=-81.681, lat=41.4626, zoom=13) %>%
  addTiles() %>%
  addCircleMarkers(data = site, lat = ~lat, lng = ~lng, radius = 3, popup = ~popup)

process_sites <- function(sites) {
  all_sites <- tibble(site_name = character(),
                     path = character(),
                     lat = double(),
                     lng = double(),
                     last_flow = character(),
                     last_stage = character(),
                     datetime = character(),
                     popup = character())
  
  for (i in 1:nrow(sites)) {
    # Sorry.
    # Feature of how the USGS structures its REST output; each value gets its
    # own row.
    site_name <- sites[i,]$sourceInfo.siteName
    site <- sites %>% filter(sourceInfo.siteName==site_name)
    path <- str_split(site$name[1], ":")[[1]][2]

    # Latitude and longitude
    lat <- site$sourceInfo.geoLocation.geogLocation.latitude[1]
    lon <- site$sourceInfo.geoLocation.geogLocation.longitude[1]
    
    # For demo purposes, we're only looking at the most recent flow and stage
    flow_list <- site[[1]][[1]][[1]][[1]]
    stage_list <- site[[1]][[2]][[1]][[1]]
    most_recent_flow <- flow_list[nrow(flow_list),]
    most_recent_stage <- stage_list[nrow(stage_list),]
    
    # Full date and time
    timestamp <- most_recent_flow$dateTime
    
    most_recent_flow <- most_recent_flow$value
    most_recent_stage <- most_recent_stage$value
    
    
    site <- tibble(site_name = site_name,
                   path = path,
                   lat = lat,
                   lng = lon,
                   last_flow = most_recent_flow,
                   last_stage = most_recent_stage,
                   datetime = timestamp)
    
    # Add popup info to site
    site <- site %>%
      mutate(popup = paste(site_name, "<br/>",
                           "Station: ", path, "<br/>",
                           "Lat: ", lat, " ", "Long: ", lng, "ft<br/>",
                           "Flow: ", last_flow, "ft^3/sec<br/>",
                           "Stage: ", last_stage, "ft"))
    all_sites <- all_sites %>% add_row(site)
  }
  
  # Remove duplicate rows
  # TODO: clean up duplicate rows upstream
  all_sites <- all_sites %>%
    group_by(site_name) %>%
    filter(row_number(site_name) == 1)
  
  return (all_sites)
}

test <- sites %>%
  group_by(sourceInfo.siteName) %>%
  filter(n() == 2)
  
all_sites <- process_sites(test)
View(all_sites)

stations <- leaflet() %>%
  setView(lng=-81.681, lat=41.4626, zoom=13) %>%
  addTiles() %>%
  addCircleMarkers(data = all_sites, lat = ~lat, lng = ~lng, radius = 18, popup = ~popup)
