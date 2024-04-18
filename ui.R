# ui.R

source("functions.R")

ui <- fluidPage(
  useShinyjs(),
  titlePanel("Analysis Dashboard - Interactive Data Plotting and Solution Finder"),
  
  sidebarLayout(
    sidebarPanel(
    hidden(div(id = "launcher", actionButton("openModal", "Open Criteria Evaluation", style = "display: none;"))),
      h3("Data Input and Criteria Settings"),
      fileInput('file1', 'Choose Excel File'),
      fileInput('file2', 'Choisir un fichier IFC'),
      
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
      h4("Set Weights for Each Criterion"),

      
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
