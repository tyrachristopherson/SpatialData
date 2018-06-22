#

#  Script: coverChecker.R

#  Purpose: This Rshiny script is a module for the Coverage Checker part of the Exposure Viewing Tool.

#  Instructions: This code cannot be run on its own. It is called by the app.R script for the Exposure
#                Viewing Tool.

#  Author: Tyra Christopherson

#  Date: 5/15/2018

#  Notes: NA

#




#Load libraries
library(shiny)
library(tidyr)
library(dplyr)
library(ggplot2)
library(RODBC)
library(mapdata)
library(DT)
library(ggmap)
library(stringr)
library(shinyBS)
library(RgoogleMaps)

################################################################
################################################################
# UI
################################################################
################################################################

ui <- fluidPage(
  
  tags$br(),
  
    ################################################################
    # Header section: information & selection inputs
    ################################################################
    fluidRow(column(width = 4,
                    tags$br()
                    ),
             
             # Description and instructions for user
             column(width = 8,
                    wellPanel(
                      fluidRow(
                        column(width = 6,
                               tags$p(tags$b("Purpose:")),
                               tags$p("This tool was designed to allow the user to check the total
                                      coverages for the highest-coverage exposures for each state.
                                      The Total Coverage for the exposure can be compared against the
                                      Average Total Coverage for the Zip Code containing the exposure,
                                      and a satellite image centered on the exposure can be obtained
                                      as a further checking mechanism. The histogram at the top of the
                                      page provides information on the distribution of Total Coverage
                                      for each state and policy form.")),
                        column(width = 6,
                               tags$p(tags$b("Instructions:")),
                               tags$p("Use the drop-down menus to the left to select the desired state and policy
                                      form. To view satellite imagery for a given exposure, select the
                                      exposure in the table, then click on the 'View Exposure' button,
                                      located above the table at the bottom of the page.")))))),
    
    tags$hr(),
    tags$br(),
    
    ################################################################
    # Bottom section: Data table and Histogram
    ################################################################
    
    
    wellPanel(
      
      # Button to view satellite imagery of currently selected policy
      actionButton(inputId = ("viewbutton"),
                   label = tags$b("View Exposure"),
                   style = "background-color:  #acbad4"),
      tags$br(),
      tags$br(),
      
      # Table of the policies with highest/lowest coverage for selected state and policy form
      dataTableOutput(outputId = "AddressTable")),
    
    # Modal (the pop-up with satellite imagery)
    bsModal(id = ("satelliteModal"),
            title = "Satellite Imagery",
            trigger = ("viewbutton"),
            "Please be patient while the new imagery loads.",
            plotOutput(outputId = ("satelliteImage"),
                       height = 600),
            size = "large")
    
) #end fluidPage



################################################################
################################################################
# Server logic
################################################################
################################################################

server <- function(input, output, session) {
  
  myTable <- data.frame(Latitude = c(42.356217, 42.328772, 42.331530, 47.512644, 47.784908, 37.792189,
                                     37.994282, 47.139833, 47.198255, 47.158317, 42.228597, 46.935464,
                                     39.755293, 47.479435),
                        Longitude = c(-71.056761, -71.101435, -71.097971, -122.145686, -118.415404, -122.152301,
                                      -121.734614, -122.444385, -122.000416, -122.568270, -71.149317, -121.474654,
                                      -105.223371, -122.117368),
                        Address = c('1 Federal St', '240 Parker Hill Ave', '1 Sewall Street',
                                    '5502 NE 24th Ct', '123 Welsh Creek Rd', '12911 Brookpark Rd',
                                    '4758 Lucchesi Ct', '809 Tule Lake Rd', '2411 Paramount Dr',
                                    '10910 98th Ave Ct SW', '95 Hillsdale Rd', '33914 Crystal Mountain Blvd',
                                    '907 11th St', '16655 SE 136th St'),
                        City = c('Boston', 'Boston', 'Boston', 'Renton', 'Creston', 'Oakland', 'Oakley',
                                 'Tacoma', 'Enumclaw', 'Lakewood', 'Dedham', 'Enumclaw', 'Golden', 'Renton'),
                        State = c('Massachusetts', 'Massachusetts', 'Massachusetts', 'Washington',
                                  'Washington', 'California', 'California', 'Washington', 'Washington',
                                  'Washington', 'Massachusetts', 'Washington', 'Colorado', 'Washington'),
                        Zipcode = c(02110, 02120, 02120, 98059, 12345, 94619, 94561, 98444, 98022, 98498,
                                    02026, 98022, 80401, 98059))
  
  
  ################################################################
  # Satellite Imagery
  ################################################################
  
  bingkey <- "AnConszKB6R0rFefA949ZOcX2RVdyKuqoftADQMdKvcttj7aMFIOenA83lNV-fmT"
  
  #render Plot of satellite imagery
  output$satelliteImage <- renderPlot({
    PlotOnStaticMap(GetBingMap(
      center = c(myTable[input$AddressTable_rows_selected, 'Latitude'],
              myTable[input$AddressTable_rows_selected, 'Longitude']),
      zoom = 19, maptype = "AerialWithLabels", apiKey = bingkey))
  }) # end renderPlot
  
  
  ################################################################
  # Data table
  ################################################################
  
  #Renders datatable of addresses
  output$AddressTable <- renderDataTable({
      
      
      datatable(myTable,
                      options = list(dom = "lt",
                                     ordering = FALSE,
                                     columnDefs = list(list(className = 'dt-right')),
                                     lengthMenu = c(5, 10, 15)),
                      selection = 'single',
                      rownames = TRUE,
                      class = 'row-border hover') %>%
              formatStyle(0,
                          target = "row",
                          backgroundColor = 'transparent')
    
    }) #end renderDT
  
} # end server logic

shinyApp(ui = ui, server = server)