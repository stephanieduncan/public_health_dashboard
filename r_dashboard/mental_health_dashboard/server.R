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
      labs(
        y = "Life Expectancy (years)",
        x = "Date",
        colour = "Age"
      ) +
      ggtitle("Life Expectancy by Age Group in Scotland") +
      theme_minimal() +
#      theme(plot.title=element_text(hjust = 0.5, size= 18, face = "bold")) +
      theme(axis.text.x = element_text( angle = 45,  hjust = 1 )) +
      scale_y_continuous(
        breaks = seq(70, 95, by = 10)
      ) +
      #remove legend
      theme(legend.position="none") +
      #add labels for each age group included
      annotate("text", x= 3, y= 93, label="Age 90", 
               size= 3 ) +
      annotate("text", x= 3, y= 85, label="Age 75-79", 
                size= 3) +
      annotate("text", x= 3, y= 78.5, label="Age 50-54",
                size= 3) +
      annotate("text", x= 3, y= 76.5, label="Age 25-29", 
                size= 3) +
      annotate("text", x= 3, y= 74, label="Age 0", 
                size= 3)+
      scale_color_viridis_c(end = 0.8)
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
      theme_minimal() +
      geom_line() +
      geom_point(size=2, shape=21, fill="white") +
      theme(axis.text.x = element_text( angle = 45,  hjust = 1 ),
            legend.position = "bottom",
            legend.title = element_blank()) +
      guides(colour=guide_legend(nrow=2, byrow=TRUE)) +
      labs(
        y = "Life Expectancy (years)",
        x = "Date",
        title = "Life Expectancy for UK Nations"
      ) +
#      theme(plot.title=element_text(hjust = 0.5, family="serif",
  #                                  colour="darkred", size= 18, face = "bold"))+
      scale_color_viridis_d() 
      
    
    
    
    
  })
##################First tab content, longterm conditions plot
  output$longterm_conditions_output <- renderPlot({
    
    longterm_conditions_all %>% 
      ggplot() +
      aes(x = year, y = admissions_count, colour = longterm_condition) +
      geom_line() +
      geom_point(size=2, shape=21, fill="white") +
      labs(title = "Hospital Admissions by Long Term Condition",
           subtitle = "2002 - 2012",
           x = "Year",
           y = "Admissions Count") +
      theme_minimal() +
      scale_x_continuous(breaks = c(2002:2012)) +
      scale_color_manual(name = NULL,
                         labels = c("Cancer", "Cerebrovascular Disease", "Coronary Heart Disease", "Disease Digestive System", "Respiratory Conditions"),
                         values = c("#440154FF", "#3B528BFF", "#21908CFF", "#5DC863FF", "#FDE725FF")) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            legend.position = "bottom") +
      scale_y_continuous(breaks = c(0, 25000, 50000, 75000, 100000, 125000, 150000, 175000))+
      guides(colour=guide_legend(nrow=2,byrow=TRUE))
      
      
    
  })
  
  #Overview of self reported health
  
  filtered_data <- 
    general_health %>% 
      filter(measurement == "Percent") %>%  
      drop_na() %>% 
      #filtering to include "All" in limiting_long_term_physical_or_mental_health_condition column 
      filter(limiting_long_term_physical_or_mental_health_condition == "All") %>% 
      filter(age == "All") %>% 
      filter(gender == "All") %>% 
      filter(type_of_tenure == "All") %>% 
      #filter for Scotland overall data
      filter(feature_code == "S92000003") %>%
      filter(household_type == "All") %>% 
      group_by(date_code, value, self_assessed_general_health) %>% 
      summarise() 
    

output$general_health_plot <- renderPlot({
  ggplot(filtered_data) +
    aes(x = date_code, y = value, colour = self_assessed_general_health)+
    geom_line() +
    geom_point( size=2, shape=21, fill="white") +
    labs(title = "Self Assessed General Health in Scotland",
         subtitle = "2012 - 2019",
         x = "Year",
         y = "Percentage of Respondents",
         colour = "Self Assessed General Health: ") +
    theme_minimal() +
    scale_x_continuous(breaks = c(2012:2019)) +
    scale_y_continuous(limits = c(0, 100)) +
    scale_color_viridis_d() +
    guides(colour=guide_legend(nrow=2,byrow=TRUE)) +
    theme(legend.position = "bottom")
  
})
  
  
  
  
################## Overview: Mental Health Over Time Plot  
  output$mh_time <- renderPlot({
    
    npf_mental_wellbeing %>% 
      filter(characteristic == "Total") %>% 
      ggplot(aes(x = year, y = figure)) +
      geom_line( col = "#440154ff") +
      geom_point(size=2, shape=21, fill="white") +
      scale_x_continuous(breaks = seq(min(npf_mental_wellbeing$year), 
                                      max(npf_mental_wellbeing$year)),  
                         labels = seq(min(npf_mental_wellbeing$year), 
                                      max(npf_mental_wellbeing$year))) +
      labs(x = "Year",
           y = "Average WEMWBS Score", 
           title = "Average Mental Wellbeing Score in Scotland",
           subtitle = "Average WEMWBS Score 2006 - 2019") +
      theme_minimal() +
      theme(axis.text.x = element_text( angle = 45,  hjust = 1 ))
    
    
    
  })
  
  
  ################### Changes Over time: MW related deaths by suicide
  
  output$mw_deaths_s <- renderPlot({
  #plot graph for deaths by suicide split by gender
  death %>% 
    filter(issue == "Suicide") %>% 
    group_by(gender, year) %>% 
    summarise(count = sum(number)) %>% 
    ggplot(aes(x = year, y = count, group = gender, colour = gender)) +
    geom_line() +
    geom_point(size=2, shape=21, fill="white") +
    theme_minimal()+
    theme(axis.text.x = element_text( angle = 45,  hjust = 1 ),
          legend.title = element_blank(),
          legend.position = "bottom") +
    labs(
      y = "Suicide Number",
      x = "Year"
    ) +
    ggtitle("Suicide Rates in Scotland by Gender") +
 #   theme(plot.title=element_text(hjust = 0.5, family="serif",
  #                                colour="darkred", size= 18, face = "bold")) +
      scale_x_continuous(breaks = seq(min(death$year), 
                                      max(death$year))) +
      scale_color_viridis_d(end = 0.8)
  
  })
  
  ################### Changes Over time: MW related deaths by dementia & Alzheimers
  output$mw_deaths_d_a <- renderPlot({
    
    death %>% 
      filter(issue == "Dementia_and_Alzheimers") %>% 
      group_by(gender, year) %>% 
      summarise(count = sum(number)) %>% 
      ggplot(aes(x = year, y = count, group = gender, colour = gender)) +
      geom_line() +
      geom_point(size=2, shape=21, fill="white") +
      theme_minimal() +
      theme(axis.text.x = element_text( angle = 45,  hjust = 1 ),
            legend.title = element_blank(),
            legend.position = "bottom")+
      labs(
        y = "Number of Deaths",
        x = "Year"
      ) +
      ggtitle("Dementia & Alzheimers Deaths in Scotland") +
#      theme(plot.title=element_text(hjust = 0.5, family="serif",
 #                                   colour="darkred", size= 18, face = "bold")) +
      scale_x_continuous(breaks = seq(min(death$year), 
                                      max(death$year))) +
      scale_color_viridis_d(end = 0.8)
    
    
    })
  
  
################## Where: mental health map  
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
      fitBounds(bbox[1], bbox[2], bbox[3], bbox[4]) %>%
      setView(lat = 56.610003, lng = -4.2, zoom = 7)

  })
  
################### Demographics
  
  mental_wb_to_plot <- reactive({
    mental_wb %>% 
      filter(la_name == input$area,
             date_code == input$year)
  })
  
  
  output$gender_mh <- renderPlot({
    
    mental_wb_to_plot() %>%
      filter(gender != "All") %>%
      ggplot() +
      aes(x = gender, y = mean) +
      geom_pointrange(aes(ymin = lower_ci, ymax = upper_ci), col = "#95D840FF") +
      theme_bw() +
      labs(x = NULL,
           y = "Mean SWEMWBS Score")
    
  })
  
  output$age_mh <- renderPlot({
    
    mental_wb_to_plot() %>%
      filter(age != "All") %>%
      ggplot() +
      aes(x = age, y = mean) +
      geom_pointrange(aes(ymin = lower_ci, ymax = upper_ci), col = "#482677FF") +
      theme_bw() +
      labs(x = NULL,
           y = "Mean SWEMWBS Score")
    
  })
  
  output$limiting_hc <- renderPlot({
    
    mental_wb_to_plot() %>%
      filter(limiting_cond != "All") %>%
      ggplot() +
      aes(x = limiting_cond, y = mean) +
      geom_pointrange(aes(ymin = lower_ci, ymax = upper_ci), col = "#2D708EFF") +
      theme_bw() +
      labs(x = NULL,
           y = "Mean SWEMWBS Score") 
    
  })
  
  output$tenure_mh <- renderPlot({
    mental_wb_to_plot() %>%
      filter(type_of_tenure != "All") %>%
      ggplot() +
      aes(x = type_of_tenure, y = mean) +
      geom_pointrange(aes(ymin = lower_ci, ymax = upper_ci), col = "#1F989BFF") +
      theme_bw() +
      labs(x = NULL,
           y = "Mean SWEMWBS Score")
    
  })
  
  ################### MH Indicators
  
  
  
  shs_to_plot <- reactive({
    shs_nopivot %>% 
      filter(la_name == input$area_shs,
             sex == input$sex)
  })
  
  
  output$al_shs <- renderPlot({
    
    
      shs_to_plot()%>% 
      filter(str_detect(scottish_health_survey_indicator, "^Alcohol consumption*")) %>% 
      ggplot(aes(x = date_code, y = value, fill = scottish_health_survey_indicator)) +
      geom_bar(stat="identity", position = position_dodge()) +
      geom_text(aes(y=value, label = ""),
                position = position_stack(vjust = 0.5), colour="white") +
      scale_fill_viridis_d() +
      theme_bw()+
      labs(x = "Years",
           y = "Percentage") +
      scale_fill_manual(name = "Alcohol consumption",
                        labels = c("Hazardous/Harmful", 
                            "Moderate", 
                            "Non-Drinker"), 
                        values = c("#440154FF", "#21908CFF" ,"#FDE725FF")) 
      
    
  })
  
  output$lifesat_shs <- renderPlot({
    
    shs_to_plot()%>% 
      filter(str_detect(scottish_health_survey_indicator, "^Life satisfaction*")) %>% 
      ggplot(aes(x = scottish_health_survey_indicator, 
                 y = value, 
                 fill = scottish_health_survey_indicator)) +
      geom_col(stat="identity") +
      geom_text(aes(y=value, label = ""),
                position = position_stack(vjust = 0.5), colour="white") +
      scale_fill_viridis_d() +
      theme_bw() +
      labs(x = NULL,
           y = "Percentage") +
      theme(legend.position = "none") +
      scale_x_discrete(labels = c("Extremely \n Satisfied", 
                                  "Extremely \n Dissatisfied", 
                                  "Average Satisfaction"))

    
    
    
  })
  
  output$actlevels_shs <- renderPlot({
    
    shs_to_plot()%>% 
      filter(str_detect(scottish_health_survey_indicator, "^Summary activity levels*")) %>% 
      ggplot(aes(x = date_code, y = value, fill = scottish_health_survey_indicator)) +
      geom_bar(stat="identity", position = position_dodge()) +
      geom_text(aes(y=value, label = ""),
                position = position_stack(vjust = 0.5), colour="white") +
      scale_fill_viridis_d() +
      theme_bw() +
      labs(x = "Years",
           y = "Percentage") +
      scale_fill_manual(name = "Activity Level",
                        labels = c("Low Activity", 
                                   "Meets Recommendations", 
                                   "Some Activity",
                                   "Very Low Activity"), 
                        values = c("#440154FF", 
                                   "#31688EFF", 
                                   "#35B779FF", 
                                   "#FDE725FF")) 

  })

  
############Fourth tab content - Self Assessed & Longterm Conditions
  output$longterm_conditions_mental_health_plot <- renderPlot({
    
      general_health %>% 
      drop_na() %>% 
      filter(measurement == "Percent") %>%  
      #filtering to remove "All" in limiting_long_term_physical_or_mental_health_condition column 
      filter(!limiting_long_term_physical_or_mental_health_condition == "All") %>% 
      select(-household_type, -type_of_tenure, -units) %>% 
      group_by(value, self_assessed_general_health, limiting_long_term_physical_or_mental_health_condition, date_code) %>% 
      summarise() %>% 
      group_by(self_assessed_general_health, limiting_long_term_physical_or_mental_health_condition) %>% 
      summarise(n = n()) %>%
      ungroup() %>% 
      group_by(limiting_long_term_physical_or_mental_health_condition) %>% 
      mutate(proportion = n / sum(n)) %>% 
      ggplot() +
      geom_col(aes(x = limiting_long_term_physical_or_mental_health_condition, y = proportion, fill = self_assessed_general_health )) +
      labs(title = NULL,
           x = NULL,
           y = "Proportion of Respondents",
           fill = "Self Assessed General Health") +
      scale_fill_viridis_d() +
      theme_bw() +
      theme(legend.position = "bottom")
    
})
  
}