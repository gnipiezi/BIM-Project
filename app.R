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
# Define Server
server <- function(input, output, session) {
  
  materiaux_isolants_df <- reactiveFileReader(intervalMillis = 1000, session, './output/materiaux_et_isolants.xlsx', read_excel)
  materiaux_isolants <- reactivePoll(1000, session,
  checkFunc = function() {
    if (file.exists('./output/materiaux_et_isolants.xlsx')) {
      file.info('./output/materiaux_et_isolants.xlsx')$mtime
    }
  },
  valueFunc = function() {
    read_excel('./output/materiaux_et_isolants.xlsx')
  }
)
output$materialTable <- renderDataTable({
  materiaux_isolants()
})
# 
# 
# 
observe({
    req(input$file1)  # S'assurer qu'un fichier est bien chargé

    df <- read_excel(input$file1$datapath)  # Lire le fichier

    # Créer les sélections dynamiques basées sur les données chargées
    output$selectPrix <- renderUI({
      selectInput("prix", "Prix", choices = range(df$Prix, na.rm = TRUE))
    })

    output$selectEmission <- renderUI({
      selectInput("emission", "Emission", choices = range(df$emission, na.rm = TRUE))
    })

    output$selectConductivity <- renderUI({
      selectInput("conductivity", "Conductivity", choices = range(df$Conductivity, na.rm = TRUE))
    })

    output$selectMassevolumique <- renderUI({
      selectInput("massevolumique", "Massevolumique", choices = range(df$Massevolumique, na.rm = TRUE))
    })

    output$selectChaleurmassique <- renderUI({
      selectInput("chaleurmassique", "Chaleurmassique", choices = range(df$Chaleurmassique, na.rm = TRUE))
    })
})
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
    
    ggplotly(p, tooltip = c("text")) %>% layout(dragmode = "select") %>%
        event_register('plotly_selected')
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
    df <- data()  # Récupérer les données chargées
    
    if (!is.null(df) && nrow(df) > 0) {
        # Filtrer et calculer les scores en utilisant les valeurs sélectionnées dans les selectInput
        filtered_df <- df %>%
            filter(Prix >= input$prix[1] & Prix <= input$prix[2],
                   emission >= input$emission[1] & emission <= input$emission[2],
                   Conductivity >= input$conductivity[1] & Conductivity <= input$conductivity[2],
                   Massevolumique >= input$massevolumique[1] & Massevolumique <= input$massevolumique[2],
                   Chaleurmassique >= input$chaleurmassique[1] & Chaleurmassique <= input$chaleurmassique[2])
        print(nrow(filtered_df))  
   
        # Si non, vous devrez les calculer ici comme précédemment
         maxPrix <- max(df$Prix, na.rm = TRUE)
         maxEmission <- max(df$emission, na.rm = TRUE)
        # Calculer le score en utilisant les poids
        filtered_df <- filtered_df %>%
            mutate(score = ((maxPrix - Prix) / maxPrix * input$weightPrix) + 
                     ((maxEmission - emission) / maxEmission * input$weightEmission) + 
                     (Conductivity / max(df$Conductivity, na.rm = TRUE) * input$weightConductivity) +
                     (Massevolumique / max(df$Massevolumique, na.rm = TRUE) * input$weightMassevolumique) +
                     (Chaleurmassique / max(df$Chaleurmassique, na.rm = TRUE) * input$weightChaleurmassique))

        # Sélectionner les 3 meilleures solutions
        best_solution_data <- filtered_df %>%
            arrange(desc(score)) %>%
            slice(1:3)

        best_solutions(best_solution_data)  # Mettre à jour les meilleures solutions
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

  #  Event triggered when we upload ifc file and copy it 

 observeEvent(input$file2, {
    req(input$file2)  
    chemin_fichier_ifc <- input$file2$datapath
    
    dossier_destination <- "inputs"
    
    if (!dir.exists(dossier_destination)) {
      dir.create(dossier_destination, recursive = TRUE)
    }
    
    nom_fichier <- basename(input$file2$name)  
    chemin_copie_ifc <- file.path(dossier_destination, nom_fichier)
    
    result <- file.copy(chemin_fichier_ifc, chemin_copie_ifc)
    
    output$copyStatus <- renderText({
      if (result) {
        paste("Le fichier IFC a été copié avec succès dans :", chemin_copie_ifc)
      } else {
        "Erreur lors de la copie du fichier."
      }
    })
  })
}

# Run the application 
shinyApp(ui = ui, server = server, options = list(port = 3000))