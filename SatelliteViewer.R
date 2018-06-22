#

#  Script: SatelliteViewer.R

#  Purpose: This Rshiny script is a tool for viewing satellite imagery, from Bing.

#  Instructions: Run the app as-is. Further user instructions are made available within the app.

#  Author: Tyra Christopherson

#  Date: 6/22/2018

#  Notes: NA

#



#Load libraries
library(shiny)
library(DT)
library(shinyBS)
library(RgoogleMaps)


################################################################
# UI
################################################################

ui <- fluidPage(
  
  tags$br(),
  
  # Header section: title, purpose, instructions
  ###############################################
  fluidRow(column(width = 4,
                  tags$br(),
                  tags$h1(tags$b('Satellite Imagery Viewer'))),
           
           column(width = 8,
                  wellPanel(fluidRow(column(width = 6,
                                            tags$p(tags$b("Purpose:")),
                                            tags$p("This tool allows the user to check the satellite imagery
                                                   for various latitudes and longitudes across the world. All
                                                   satellite images come from Bing.")),
                                     column(width = 6,
                                            tags$p(tags$b("Instructions:")),
                                            tags$p("To view satellite imagery for a given location, select the
                                                   row in the table, then click on the lavender 'View Imagery'
                                                   button, located above the table.")))))), #end fluidRow
  tags$hr(),
  tags$br(),
  
  # Bottom section: Data table
  #############################
  wellPanel(
    # Button to view satellite imagery of currently selected address
    actionButton(inputId = ("viewbutton"),
                 label = tags$b("View Imagery"),
                 style = "background-color:  #acbad4"),
    tags$br(),
    tags$br(),
    # Table of addresses
    dataTableOutput(outputId = "AddressTable")), #end wellPanel
  
  # Modal (pop-up with satellite imagery)
  ########################################
  bsModal(id = ("satelliteModal"),
          title = "Satellite Imagery",
          trigger = ("viewbutton"),
          "Please be patient while the new imagery loads.",
          plotOutput(outputId = ("satelliteImage"),
                     height = 600),
          size = "large")
    
) #end fluidPage



################################################################
# Server
################################################################

server <- function(input, output, session) {
  
  #define myTable
  myTable <- data.frame(Address = c('1 Federal St', '240 Parker Hill Ave', '1 Sewall Street',
                                    '5502 NE 24th Ct', '123 Welsh Creek Rd', '12911 Brookpark Rd',
                                    '4758 Lucchesi Ct', '809 Tule Lake Rd', '2411 Paramount Dr',
                                    '10910 98th Ave Ct SW', '95 Hillsdale Rd', '33914 Crystal Mountain Blvd',
                                    '907 11th St', '16655 SE 136th St', '3240 35th Ave S'),
                        City = c('Boston', 'Boston', 'Boston', 'Renton', 'Creston', 'Oakland', 'Oakley',
                                 'Tacoma', 'Enumclaw', 'Lakewood', 'Dedham', 'Enumclaw', 'Golden', 'Renton',
                                 'Seattle'),
                        State = c('Massachusetts', 'Massachusetts', 'Massachusetts', 'Washington',
                                  'Washington', 'California', 'California', 'Washington', 'Washington',
                                  'Washington', 'Massachusetts', 'Washington', 'Colorado', 'Washington',
                                  'Washington'),
                        Zipcode = c(02110, 02120, 02120, 98059, 12345, 94619, 94561, 98444, 98022, 98498,
                                    02026, 98022, 80401, 98059, 98144),
                        Latitude = c(42.356217, 42.328772, 42.331530, 47.512644, 47.784908, 37.792189,
                                     37.994282, 47.139833, 47.198255, 47.158317, 42.228597, 46.935464,
                                     39.755293, 47.479435, 47.574024),
                        Longitude = c(-71.056761, -71.101435, -71.097971, -122.145686, -118.415404, -122.152301,
                                      -121.734614, -122.444385, -122.000416, -122.568270, -71.149317, -121.474654,
                                      -105.223371, -122.117368, -122.288568))
  
  # Satellite Imagery
  ####################
  bingkey <- "AnConszKB6R0rFefA949ZOcX2RVdyKuqoftADQMdKvcttj7aMFIOenA83lNV-fmT"
  
  #render plot of satellite imagery
  output$satelliteImage <- renderPlot({
    PlotOnStaticMap(GetBingMap(
      center = c(myTable[input$AddressTable_rows_selected, 'Latitude'],
              myTable[input$AddressTable_rows_selected, 'Longitude']),
      zoom = 19, maptype = "AerialWithLabels", apiKey = bingkey))
  })
  
  # Data table
  #############
  output$AddressTable <- renderDataTable({
    datatable(myTable,
              options = list(dom = "ltf", #keep it simple - only display length input control, table, and search box
                             ordering = TRUE, #allow for sorting columns
                             order = list(list(2, 'asc'), list(1, 'asc')), #initially sort by State, then City
                             columnDefs = list(list(className = 'dt-left', targets = 3)), #align zipcode column left
                             lengthMenu = c(5, 10, 15)),
              selection = 'single',
              rownames = FALSE,
              class = 'row-border hover') %>%
      formatStyle(0,
                  target = "row",
                  backgroundColor = 'transparent')
  })
  
} # end server

shinyApp(ui = ui, server = server)