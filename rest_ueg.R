library(httr)
library(jsonlite)
library(leaflet)
library(dplyr)
library(htmlwidgets)
library(stringr)

# Get data from Cuyahoga County from the past two days.
path <- "https://waterservices.usgs.gov/nwis/iv/?format=json&countyCd=39035&period=P2D&parameterCd=00060,00065&siteStatus=all"
cuyahoga <- GET(url = path)
cuyahoga <- content(cuyahoga, as = "text", encoding = "UTF-8")
cuyahoga <- fromJSON(cuyahoga, flatten = TRUE)
cuyahoga <- as_tibble(cuyahoga)

sites <- cuyahoga$value$timeSeries

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
      mutate(popup = paste("<h2>",site_name, "<br/>",
                           datetime,"<br/>",
                           "Station: ", path, "<br/>",
                           "Lat: ", lat, " ", "Long: ", lng, "ft<br/>",
                           "Flow: ", last_flow, "ft^3/sec<br/>",
                           "Stage: ", last_stage, "ft</h2>"))
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

saveWidget(stations, file="index.html")
