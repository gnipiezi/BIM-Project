library(shiny)
library(readxl)
library(ggplot2)
library(plotly)
library(DT)

source("functions.R")

server <- function(input, output, session) {
  session$onFlushed(once = TRUE, function() {
    shinyjs::runjs('$("#openModal").click();')
  })
  ifc_uploaded <- reactiveVal(FALSE)
  # Example reactive file reader (modify the path and read function accordingly)
  materiaux_isolants_df <- reactiveFileReader(intervalMillis = 1000, session, "./output/materiaux_et_isolants.xlsx", read_excel)
  
  output$materialTable <- renderDataTable({
     if(ifc_uploaded()) {
    materiaux_isolants_df()
     }
  })

  observe({
    req(input$file1)  
    df <- read_excel(input$file1$datapath)  
    # Example function call, ensure to define or modify this function
    update_range_select_ui(df, output, session)
  })
  
  data <- reactive({
    req(input$file1)
    inFile <- input$file1
    df <- read_excel(inFile$datapath)
    return(df)
  })
  
  output$table <- renderDT({
    data()
  })

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
  criteriaValues <- reactiveValues()
  
  # Observe selection event on plot and update points_selected
  observe({
    event_data <- event_data("plotly_selected")
    if (!is.null(event_data)) {
      points <- data()
      selected_points <- points[event_data$pointNumber + 1, ]
      points_selected(selected_points)
    }
  })
  
  observeEvent(input$calc, {
    df <- data()
    if (!is.null(df) && nrow(df) > 0) {
      filtered_df <- filter_data(df, input)
      maxPrix <- max(df$Prix, na.rm = TRUE)
      maxEmission <- max(df$emission, na.rm = TRUE)
      filtered_df <- calculate_scores(filtered_df, maxPrix, maxEmission, input,criteriaValues )
      best_solution_data <- select_top_solutions(filtered_df)
      best_solutions(best_solution_data)
    }
  })
  
  output$selected_table <- renderDT({
    points_selected()
  })
  
  output$best_solutions_table <- renderDT({
    best_solutions()
  })

observe({
        shinyjs::runjs('$("#openModal").click();')
  })
  
observeEvent(input$openModal, {
    showModal(modalDialog(
        title = "Evaluate the Importance of Each Criterion",
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
        footer = tagList(
            modalButton("Close"),
            actionButton("submit", "Submit")
        )
    ))
})


observeEvent(input$submit, {
    criteriaValues$weightPrice <- getWeightValue(input$weightPrice)
    criteriaValues$weightEmission <- getWeightValue(input$weightEmission)
    criteriaValues$weightConductivity <- getWeightValue(input$weightConductivity)
    criteriaValues$weightDensity <- getWeightValue(input$weightDensity)
    criteriaValues$weightSpecificHeat <- getWeightValue(input$weightSpecificHeat)
    removeModal() 
})

  observeEvent(input$file2, {
    req(input$file2)
    ifc_uploaded(TRUE)
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
