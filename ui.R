# ui.R

source("functions.R")

ui <- fluidPage(

  titlePanel("Analysis Dashboard - Interactive Data Plotting and Solution Finder"),
  
  sidebarLayout(
    sidebarPanel(
      # Modal Dialog
      modalDialog(
        id = "modal",
        title = "Répondez aux questions",
        sliderInput("question1", "What is the ecological impact of the building?:", min = 1, max = 5, value = 3, step = 1),
        sliderInput("question2", "How would you rate the efficiency of the building?", min = 1, max = 5, value = 3, step = 1),
        sliderInput("question3", "What is the thermal mass of the building?", min = 1, max = 5, value = 3, step = 1),
        actionButton("submit", "Soumettre")
      ),
      h3("Data Input and Criteria Settings"),
      fileInput('file1', 'Choose Excel File'),
      fileInput('file2', 'Choisir un fichier IFC'),
      
      selectInput("xvar", "Choose X-axis variable", 
                  choices = c("Prix", "emission", "Conductivity", "Massevolumique", "Chaleurmassique"), selected = "Conductivity"),
      selectInput("yvar", "Choose Y-axis variable", 
                  choices = c("Prix", "emission", "Conductivity", "Massevolumique", "Chaleurmassique"), selected = "Chaleurmassique"),
      h4("Define Ranges for Each Criterion"),
      uiOutput("selectPrix"),
      uiOutput("selectEmission"),
      uiOutput("selectConductivity"),
      uiOutput("selectMassevolumique"),
      uiOutput("selectChaleurmassique"),
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
