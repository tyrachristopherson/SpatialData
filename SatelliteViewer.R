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
      dataTableOutput(outputId = "TopCoverage")),
    
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
  
  myTable <- data.frame(PropertyLatitude = c(42.356217),
                        PropertyLongitude = c(-71.056761),
                        Address = c('1 Federal St, Boston, MA'))
  
  
  ################################################################
  # Satellite Imagery
  ################################################################
  
  bingkey <- "AnConszKB6R0rFefA949ZOcX2RVdyKuqoftADQMdKvcttj7aMFIOenA83lNV-fmT"
  
  #render Plot of satellite imagery
  output$satelliteImage <- renderPlot({
    PlotOnStaticMap(GetBingMap(
      center = c(myTable[input$TopCoverage_rows_selected, "PropertyLatitude"],
              myTable[input$TopCoverage_rows_selected, "PropertyLongtitude"]),
      zoom = 19, maptype = "AerialWithLabels", apiKey = bingkey))
  }) # end renderPlot
  
  
  ################################################################
  # Data table
  ################################################################
  
  #Renders datatable of top/bottom coverages for the selected inputs & changes with data selection
  output$TopCoverage <- renderDataTable({
      
      
      datatable(myTable,
                      options = list(dom = "lt",
                                     ordering = FALSE,
                                     columnDefs = list(list(className = 'dt-right')),
                                     lengthMenu = c(10, 25, 50)),
                      selection = 'single',
                      rownames = TRUE,
                      class = 'row-border hover') %>%
              formatStyle(0,
                          target = "row",
                          backgroundColor = 'transparent')
    
    }) #end renderDT
  
} # end server logic

shinyApp(ui = ui, server = server)