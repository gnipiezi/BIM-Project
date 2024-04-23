source("global.R")
# Define the user interface
ui <- fluidPage(
  useShinyjs(),  # Use shinyjs
  titlePanel("Analysis Dashboard - Interactive Data Plotting and Solution Finder"),

  # Create a main tab panel with two tabs
  tabsetPanel(
    id = "mainTabset",
    selected = "evaluationTab",
    tabPanel("Data Input and Visualization", 
    

      sidebarLayout(
        sidebarPanel(
          fileInput('file1', 'Choose Excel File'),
          fileInput('file2', 'Choose an IFC File'),
          selectInput("xvar", "Choose X-axis variable", 
                      choices = c("Prix", "emission", "Conductivity", "Massevolumique", "Chaleurmassique"), selected = "Conductivity"),
          selectInput("yvar", "Choose Y-axis variable", 
                      choices = c("Prix", "emission", "Conductivity", "Massevolumique", "Chaleurmassique"), selected = "Chaleurmassique"),
          h4("Define Ranges for Each Criterion"),
          numericInput("minPrix", "Minimum Prix", value = 0),
          numericInput("maxPrix", "Maximum Prix", value = 0),
          numericInput("minEmission", "Minimum Emission", value = 0),
          numericInput("maxEmission", "Maximum Emission", value = 0),
          numericInput("minConductivity", "Minimum Conductivity", value = 0),
          numericInput("maxConductivity", "Maximum Conductivity", value = 0),
          numericInput("minMassevolumique", "Minimum Massevolumique", value = 0),
          numericInput("maxMassevolumique", "Maximum Massevolumique", value = 0),
          numericInput("minChaleurmassique", "Minimum Chaleurmassique", value = 0),
          numericInput("maxChaleurmassique", "Maximum Chaleurmassique", value = 0),
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
    ),
    tabPanel("Criteria Evaluation", value="evaluationTab", 
      fluidPage(
          h3("Evaluate the Importance of Each Criterion"),
        radioButtons("weightPrice", 
                     "How important is the cost factor in your overall assessment of the building?",
                     choices = c("Medium" = 2, "High" = 3, "Very High" = 4, "Excellent" = 5),
                    selected = 2),
        
        radioButtons("weightEmission", 
                     "How important are emission levels for assessing the building's environmental impact?",
                     choices = c("Medium" = 2, "High" = 3, "Very High" = 4, "Excellent" = 5),
                    selected = 2),
        
        radioButtons("weightConductivity", 
                     "How critical is thermal conductivity in the efficiency assessment of the building?",
                     choices = c("Medium" = 2, "High" = 3, "Very High" = 4, "Excellent" = 5),
                    selected = 2),
        
        radioButtons("weightDensity", 
                     "What is the significance of material density in the construction quality of the building?",
                     choices = c("Medium" = 2, "High" = 3, "Very High" = 4, "Excellent" = 5),
                    selected = 2),
        
        radioButtons("weightSpecificHeat", 
                     "How important is the specific heat capacity of materials in the building’s energy efficiency?",
                     choices = c("Medium" = 2, "High" = 3, "Very High" = 4, "Excellent" = 5),
                    selected = 2),
        actionButton("submit", "Submit")

      )
    )
  )
)
