# server.R

source("functions.R")

server <- function(input, output, session) {
  
  materiaux_isolants_df <- reactiveFileReader(intervalMillis = 1000, session, excel_path, read_excel)
  
  output$materialTable <- renderDataTable({
    materiaux_isolants_df()
  })

  observe({
    req(input$file1)  

    df <- read_excel(input$file1$datapath)  

    update_range_select_ui(df, output)
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
    df <- data()  
    
    if (!is.null(df) && nrow(df) > 0) {
        filtered_df <- filter_data(df, input)
   
         maxPrix <- max(df$Prix, na.rm = TRUE)
         maxEmission <- max(df$emission, na.rm = TRUE)
        
        filtered_df <- calculate_scores(filtered_df, maxPrix, maxEmission,input)
        
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
