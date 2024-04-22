library(shiny)
library(readxl)
library(ggplot2)
library(plotly)
library(DT)

source("functions.R")

server <- function(input, output, session) {

  ifc_uploaded <- reactiveVal(FALSE)
  excel_uploaded <- reactiveVal(FALSE)

  # Reactive pour stocker les données Excel une fois chargées
  excel_data <- reactive({
    req(input$file1)
    read_excel(input$file1$datapath)
  })

  points_selected <- reactiveVal(data.frame())
  best_solutions <- reactiveVal(data.frame())
  criteriaValues <- reactiveValues()

  isolants_classified_df <- read_excel("./Construction_Isolants_classified.xlsx")

  materiaux_isolants_df <- reactiveFileReader(intervalMillis = 1000, session, "./output/materiaux_et_isolants.xlsx", read_excel)

  session$onFlushed(once = TRUE, function() {
    shinyjs::runjs('$("#openModal").click();')
  })

  process_data <- function() {
    req(excel_uploaded(), ifc_uploaded())  
    construction_model <- materiaux_isolants_df()$`Matériaux de Construction`[1]
    compatible_isolants <- get_compatible_isolants(isolants_classified_df, construction_model)
    df_filtered <- excel_data() %>%
      dplyr::filter(Nom_Matériau %in% compatible_isolants)
    return(df_filtered)
  }

  output$materialTable <- renderDataTable({
    req(input$file2)
    materiaux_isolants_df()
  })

  observe({
    req(input$file1)
    excel_uploaded(TRUE)
    df <- read_excel(input$file1$datapath)
    update_range_select_ui(df, output, session)
  })

  observeEvent(input$file2, {
    ifc_uploaded(TRUE)
  }, ignoreInit = TRUE)

  output$table <- renderDataTable({
    process_data()
  })


  output$plot <- renderPlotly({
    req(excel_uploaded() && ifc_uploaded())
    df <- excel_data()
    p <- ggplot(df, aes_string(x = input$xvar, y = input$yvar)) +
      geom_point() +
      labs(x = input$xvar, y = input$yvar, title = paste("Plot of", input$xvar, "vs", input$yvar))
    ggplotly(p, tooltip = c("text")) %>% layout(dragmode = "select")
  })

  
  # Observe selection event on plot and update points_selected
  observe({
    event_data <- event_data("plotly_selected")
    if (!is.null(event_data)) {
      points <- excel_data()
      selected_points <- points[event_data$pointNumber + 1, ]
      points_selected(selected_points)
    }
  })
  
observeEvent(input$calc, {
    df <- excel_data()
    if (!is.null(df) && nrow(df) > 0) {
      filtered_df <- filter_data(df, input)
      maxPrix <- max(df$Prix, na.rm = TRUE)
      maxEmission <- max(df$emission, na.rm = TRUE)
      filtered_df <- calculate_scores(filtered_df, maxPrix, maxEmission, input, criteriaValues)
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
  observeEvent(input$file1, {
    req(input$file1)
    tryCatch({
      read_excel(input$file1$datapath)
      excel_uploaded(TRUE)  
    }, error = function(e) {
      excel_uploaded(FALSE)  
      shinyjs::alert("Le fichier Excel n'a pas pu être lu. Assurez-vous que c'est un fichier .xlsx valide.")
    })
  }, ignoreInit = TRUE)

  observeEvent(input$file2, {
    req(input$file2)
    ifc_uploaded(TRUE)
    copy_ifc_file(input , output)
    }, ignoreInit = TRUE)
}
