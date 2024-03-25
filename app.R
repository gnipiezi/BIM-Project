library(shiny)
library(readxl)
library(DT)
library(ggplot2)
library(plotly)
library(dplyr)
library(websocket)
# if (file.exists("renv/activate.R")) {
#   source("renv/activate.R")
# }



# Define UI

ui <- fluidPage(


  titlePanel("Analysis Dashboard - Interactive Data Plotting and Solution Finder"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Data Input and Criteria Settings"),
      fileInput('file1', 'Choose Excel File'),
      
      selectInput("xvar", "Choose X-axis variable", 
                  choices = c("Prix", "emission", "Conductivity", "Massevolumique", "Chaleurmassique"), selected = "Conductivity"),
      selectInput("yvar", "Choose Y-axis variable", 
                  choices = c("Prix", "emission", "Conductivity", "Massevolumique", "Chaleurmassique"), selected = "Chaleurmassique"),
      
      h4("Define Ranges for Each Criterion"),
      numericInput("minPrix", "Minimum Prix", value = 12),
      numericInput("maxPrix", "Maximum Prix", value = 48),
      numericInput("minEmission", "Minimum Emission", value = 50),
      numericInput("maxEmission", "Maximum Emission", value = 600),
      numericInput("minConductivity", "Minimum Conductivity", value = 1),
      numericInput("maxConductivity", "Maximum Conductivity", value = 10),
      numericInput("minMassevolumique", "Minimum Massevolumique", value = 100),
      numericInput("maxMassevolumique", "Maximum Massevolumique", value = 900),
      numericInput("minChaleurmassique", "Minimum Chaleurmassique", value = 1000),
      numericInput("maxChaleurmassique", "Maximum Chaleurmassique", value = 2800),
      
      h4("Set Weights for Each Criterion"),
      numericInput("weightPrix", "Weight for Prix", value = 1, min = 1, max = 5),
      numericInput("weightEmission", "Weight for Emission", value = 1, min = 1, max = 5),
      numericInput("weightConductivity", "Weight for Conductivity", value = 1, min = 1, max = 5),
      numericInput("weightMassevolumique", "Weight for Massevolumique", value = 1, min = 1, max = 5),
      numericInput("weightChaleurmassique", "Weight for Chaleurmassique", value = 1, min = 1, max = 5),
      
      actionButton("calc", "Calculate Top 3 Solutions")
    ),
    
    mainPanel(

      h3("IFC Data Overview"),
      DTOutput("materialTable"),
      h3("Data Overview"),
      DTOutput("table"),
      
      h3("Interactive Plot"),
      plotlyOutput("plot"),
      
      h3("Selected Points from Plot"),
      DTOutput("selected_table"),
      
      h3("Top 3 Calculated Solutions"),
      DTOutput("best_solutions_table")
    )
  )
)
# Define Server
server <- function(input, output, session) {
  
  materiaux_isolants_df <- reactiveFileReader(intervalMillis = 1000, session, './/materiaux_et_isolants.xlsx', read_excel)
  materiaux_isolants <- reactivePoll(1000, session,
  checkFunc = function() {
    if (file.exists('./materiaux_et_isolants.xlsx')) {
      file.info('./materiaux_et_isolants.xlsx')$mtime
    }
  },
  valueFunc = function() {
    read_excel('./materiaux_et_isolants.xlsx')
  }
)
output$materialTable <- renderDataTable({
  materiaux_isolants()
})
# 
# 
# 
  data <- reactive({
    req(input$file1)  # Require that the file input is present
    inFile <- input$file1
    
    # Read the file with read_excel from the readxl package
    df <- read_excel(inFile$datapath)

    # Return the dataframe
    return(df)
    
  })
  
  # Generate the table output
  output$table <- renderDT({
    data()
  })
  
  # Generate the interactive plot output
  output$plot <- renderPlotly({
    req(input$xvar, input$yvar)
    df <- data()
    
    p <- ggplot(df, aes_string(x = input$xvar, y = input$yvar)) +
      geom_point() +
      labs(x = input$xvar, y = input$yvar, title = paste("Plot of", input$xvar, "vs", input$yvar))
    
    ggplotly(p, tooltip = c("text")) %>% layout(dragmode = "select")
  })
  
  # Reactive values for selected points and best solutions
  points_selected <- reactiveVal(data.frame())
  best_solutions <- reactiveVal(data.frame())
  
  # Observe selection event on plot and update points_selected
  observe({
    event_data <- event_data("plotly_selected")
    
    if(!is.null(event_data)){
      points <- data()
      selected_points <- points[event_data$pointNumber + 1, ]
      points_selected(selected_points)
    }
  })
  
  # Observe calculation button event
  observeEvent(input$calc, {
    df <- data()
    
    if (!is.null(df) && nrow(df) > 0) {
      # Filter and score calculation
      filtered_df <- df %>%
        filter(Prix >= input$minPrix & Prix <= input$maxPrix,
               emission >= input$minEmission & emission <= input$maxEmission,
               Conductivity >= input$minConductivity & Conductivity <= input$maxConductivity,
               Massevolumique >= input$minMassevolumique & Massevolumique <= input$maxMassevolumique,
               Chaleurmassique >= input$minChaleurmassique & Chaleurmassique <= input$maxChaleurmassique)
      
      maxPrix <- max(df$Prix, na.rm = TRUE)
      maxEmission <- max(df$emission, na.rm = TRUE)
      
      filtered_df <- filtered_df %>%
        mutate(score = ((maxPrix - Prix) / maxPrix * input$weightPrix) + 
                 ((maxEmission - emission) / maxEmission * input$weightEmission) + 
                 (Conductivity / max(df$Conductivity, na.rm = TRUE) * input$weightConductivity) +
                 (Massevolumique / max(df$Massevolumique, na.rm = TRUE) * input$weightMassevolumique) +
                 (Chaleurmassique / max(df$Chaleurmassique, na.rm = TRUE) * input$weightChaleurmassique))
      
      best_solution_data <- filtered_df %>%
        arrange(desc(score)) %>%
        slice(1:3)
      
      best_solutions(best_solution_data)
    }
  })
  
  # Render the selected points data table
  output$selected_table <- renderDT({
    points_selected()
  })
  
  # Render the best solutions data table
  output$best_solutions_table <- renderDT({
    best_solutions()
  })
 
}

# Run the application 
shinyApp(ui = ui, server = server, options = list(port = 3000))