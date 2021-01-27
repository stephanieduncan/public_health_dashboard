#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(tidyverse)
library(sf)
library(here)
library(scales)
library(leaflet)
library(htmltools)
library(janitor)

#read in life expectancy data
life <- read_csv(here("clean_data/le.csv"))
life_da <- read_csv(here("clean_data/le_da.csv"))

#read in mental health data
all_time_mental <-read_csv(here::here("clean_data/all_time_mental.csv"))

#read in temporal mh data
npf_mental_wellbeing <- read_csv(
  here::here("clean_data/npf_mental_health.csv"))

#add labels
all_time_mental <- all_time_mental %>%
  mutate(
    leaflet_lb = paste(
      "<b>",
      la_name,
      "</b>" ,
      br(),
      " WEMWBS Score: ",
      swem_score,
      br(),
      "Change in average score", 
      br(),
      "from 2014 to 2017: ",
      paste0(ifelse(trend >= 0, "<span style=\"color:green\"> +", "<span style=\"color:red\">"), round(trend, digits = 2), "</span>"),
      br(),
      "SIMD Ranking: ",
      ordinal(la_simd_rank),
      " out of 32",
      br(),
      "Suicide deaths per 100,000: ",
      round(total_suicide_deaths, digits = 2),
      br(),
      "Alcohol delated deaths per 100,000: ",
      round(total_alcohol_dealths, digits = 2)
    )
  )

#read in shapefile
scot_la <- st_read(here::here("clean_data/scot_la.shp"))

scot_la_mh <- scot_la %>%
  left_join(all_time_mental, by = c("area_cod_1" = "feature_code"))

# Set pallete for SWEM score
pal_swem <- colorNumeric(palette = "YlGnBu",
                         domain = scot_la_mh$swem_score)

# Set pallete for suicide  deaths
pal_suicide <- colorNumeric(palette = "plasma",
                            domain = scot_la_mh$total_suicide_deaths)

#Set boundaries of scotland
bbox <- st_bbox(scot_la_mh) %>%
  as.vector()





# Define server logic required to draw a histogram




server <- function(input, output) {

  ####### Overview life expectancy plot 
  
  output$le_plot <- renderPlot({
    life %>%
      #filter for Scotland overall data
      filter(feature_code == "S92000003") %>%
      group_by(date_code, age_num_first) %>%
      #filter to include a subset of ages
      filter(age_num_first == 0 | age_num_first == 25
             | age_num_first == 50 | age_num_first == 75 |
               age_num_first == 90) %>%
      #ind the average life expectancy for each age group
      summarise(avg_le = mean(life_expectancy)) %>%
      #plot a line graph, differentiate by age group
      ggplot(aes(x = date_code, y = avg_le, group = age_num_first, colour = age_num_first)) +
      geom_line() +
      #add points
      geom_point(size=2, shape=21, fill="white") +
      theme(axis.text.x = element_text( angle = 90,  hjust = 1 )) +
      labs(
        y = "Life Expectancy (years)",
        x = "Date",
        colour = "Age"
      ) +
      ggtitle("Life Expectancy") +
      theme(plot.title=element_text(hjust = 0.5, family="serif",
                                    colour="darkred", size= 18, face = "bold")) +
      scale_y_continuous(
        breaks = seq(70, 95, by = 1)
      ) +
      #remove legend
      theme(legend.position="none") +
      #add labels for each age group included
      annotate("text", x= 3, y= 93, label="Age 90", family="serif",
               fontface="italic", colour="darkred", size= 3 ) +
      annotate("text", x= 3, y= 85, label="Age 75-79", family="serif",
               fontface="italic", colour="darkred", size= 3) +
      annotate("text", x= 3, y= 78.5, label="Age 50-54", family="serif",
               fontface="italic", colour="darkred", size= 3) +
      annotate("text", x= 3, y= 76.5, label="Age 25-29", family="serif",
               fontface="italic", colour="darkred", size= 3) +
      annotate("text", x= 3, y= 74, label="Age 0", family="serif",
               fontface="italic", colour="darkred", size= 3)
    
  })
  
  output$le_da_plot <- renderPlot({
    life_da %>% 
      group_by(country, year) %>%
      #include overall data for the UK
      filter(country != "United Kingdom") %>% 
      #find average life expectancy
      summarise(life_expectancy = mean(life_expect_4)) %>% 
      #plot a line graph, differentiate by country
      ggplot(aes(x = year, y = life_expectancy, group = country, colour = country)) +
      geom_line() +
      geom_point(size=2, shape=21, fill="white") +
      theme(axis.text.x = element_text( angle = 90,  hjust = 1 )) +
      labs(
        y = "Life Expectancy (years)",
        x = "Date"
      ) +
      ggtitle("Life Expectancy for UK Nations") +
      theme(plot.title=element_text(hjust = 0.5, family="serif",
                                    colour="darkred", size= 18, face = "bold"))
  })
  
  
  
######## Overview: Mental Health Over Time Plot  
  output$mh_time <- renderPlot({
    
    npf_mental_wellbeing %>% 
      filter(characteristic == "Total") %>% 
      ggplot() +
      geom_line(aes(x = year, y = figure)) +
      scale_x_continuous(breaks = seq(min(npf_mental_wellbeing$year), 
                                      max(npf_mental_wellbeing$year)),  
                         labels = seq(min(npf_mental_wellbeing$year), 
                                      max(npf_mental_wellbeing$year))) +
      labs(x = "Year",
           y = "Average WEMWBS Score", 
           title = "Average Mental Wellbeing Score in Scotland",
           subtitle = "Average WEMWBS Score 2006 - 2019") +
      theme_minimal()
    
    
    
  })
  
####### Where: mental health map  
  output$map <- renderLeaflet({
 
    leaflet(scot_la_mh) %>%
      #add base tiles
      addProviderTiles("CartoDB.Positron") %>%
      # add swem score layer
      addPolygons(
        fillColor = ~ pal_swem(swem_score),
        color = "black",
        weight = 0.1,
        smoothFactor = 0.9,
        opacity = 0.8,
        fillOpacity = 0.9,
        label = ~ lapply(leaflet_lb, HTML),
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto"
        ),
        highlightOptions = highlightOptions(
          color = "#0C2C84",
          weight = 1,
          bringToFront = TRUE
        ),
        group = "Mental Health Score"
      ) %>%
      #add suicide layer
      addPolygons(
        fillColor = ~ pal_suicide(total_suicide_deaths),
        color = "black",
        weight = 0.1,
        smoothFactor = 0.9,
        opacity = 0.8,
        fillOpacity = 0.9,
        label =  ~ lapply(leaflet_lb, HTML),
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto"
        ),
        highlightOptions = highlightOptions(
          color = "#0C2C84",
          weight = 1,
          bringToFront = TRUE
        ),
        group = "Deaths due to Suicide"
      ) %>%
      #add legend for swem score
      addLegend(
        "bottomright",
        pal = pal_swem,
        values = ~ swem_score,
        title = "Average WEMWBS Score",
        opacity = 1,
        group = "Mental Health Score"
      ) %>%
      #add legend for suicide
      addLegend(
        "bottomright",
        pal = pal_suicide,
        values = ~ total_suicide_deaths,
        title = "Deaths from Suicide",
        opacity = 1,
        group = "Deaths due to Suicide",
        bins = 6
      ) %>%
      addLayersControl(
        position = c("bottomleft"),
        baseGroups = c("Mental Health Score", "Deaths due to Suicide"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      #set bounds of map
      fitBounds(bbox[1], bbox[2], bbox[3], bbox[4])
    
    
    
  })
  

}