# functions.R

source("global.R")

update_range_select_ui <- function(df, output) {
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
}


filter_data <- function(df, input) {
  df %>%
    filter(Prix >= input$prix[1] & Prix <= input$prix[2],
           emission >= input$emission[1] & emission <= input$emission[2],
           Conductivity >= input$conductivity[1] & Conductivity <= input$conductivity[2],
           Massevolumique >= input$massevolumique[1] & Massevolumique <= input$massevolumique[2],
           Chaleurmassique >= input$chaleurmassique[1] & Chaleurmassique <= input$chaleurmassique[2])
}

calculate_scores <- function(df, maxPrix, maxEmission, input) {
  df %>%
    mutate(score = ((maxPrix - Prix) / maxPrix * input$weightPrix) + 
                     ((maxEmission - emission) / maxEmission * input$weightEmission) + 
                     (Conductivity / max(df$Conductivity, na.rm = TRUE) * input$weightConductivity) +
                     (Massevolumique / max(df$Massevolumique, na.rm = TRUE) * input$weightMassevolumique) +
                     (Chaleurmassique / max(df$Chaleurmassique, na.rm = TRUE) * input$weightChaleurmassique))
}

select_top_solutions <- function(df) {
  df %>%
    arrange(desc(score)) %>%
    slice(1:3)
}
