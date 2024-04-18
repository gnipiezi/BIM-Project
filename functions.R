# functions.R

source("global.R")
isolants_classified_df <- read_excel("./Construction_Isolants_classified.xlsx")
update_range_select_ui <- function(df, output,session) {
     updateNumericInput(session, "minPrix", value = min(df$Prix, na.rm = TRUE))
      updateNumericInput(session, "maxPrix", value = max(df$Prix, na.rm = TRUE))
      updateNumericInput(session, "minEmission", value = min(df$emission, na.rm = TRUE))
      updateNumericInput(session, "maxEmission", value = max(df$emission, na.rm = TRUE))
      updateNumericInput(session, "minConductivity", value = min(df$Conductivity, na.rm = TRUE))
      updateNumericInput(session, "maxConductivity", value = max(df$Conductivity, na.rm = TRUE))
      updateNumericInput(session, "minMassevolumique", value = min(df$Massevolumique, na.rm = TRUE))
      updateNumericInput(session, "maxMassevolumique", value = max(df$Massevolumique, na.rm = TRUE))
      updateNumericInput(session, "minChaleurmassique", value = min(df$Chaleurmassique, na.rm = TRUE))
      updateNumericInput(session, "maxChaleurmassique", value = max(df$Chaleurmassique, na.rm = TRUE))
}

get_compatible_isolants <- function(classified_df, model) {
  isolants_list <- classified_df %>%
    filter(Nom_Matériau == model) %>%
    pull(Isolants) %>%
    unlist() %>%
    strsplit(split = ", ") %>%
    unlist()

  return(isolants_list)
}


filter_data <- function(df, input) {

  df %>%
        filter(Prix >= input$minPrix & Prix <= input$maxPrix,
               emission >= input$minEmission & emission <= input$maxEmission,
               Conductivity >= input$minConductivity & Conductivity <= input$maxConductivity,
               Massevolumique >= input$minMassevolumique & Massevolumique <= input$maxMassevolumique,
               Chaleurmassique >= input$minChaleurmassique & Chaleurmassique <= input$maxChaleurmassique)
}

  calculate_scores <- function(df, maxPrix, maxEmission, input, criteriaValues) {
    data_construction <- read_excel(excel_path)
    construction_model <- data_construction$`Matériaux de Construction`[1]
    compatible_isolants <- get_compatible_isolants(isolants_classified_df, construction_model)
    weightPrice <- if(is.numeric(criteriaValues$weightPrice)) criteriaValues$weightPrice else 1.5
    weightEmission <- if(is.numeric(criteriaValues$weightEmission)) criteriaValues$weightEmission else 1.5
    weightConductivity <- if(is.numeric(criteriaValues$weightConductivity)) criteriaValues$weightConductivity else 1.5
    weightDensity <- if(is.numeric(criteriaValues$weightDensity)) criteriaValues$weightDensity else 1.5
    weightSpecificHeat <- if(is.numeric(criteriaValues$weightSpecificHeat)) criteriaValues$weightSpecificHeat else 1.5
    df <- df %>%
    filter(Nom_Matériau %in% compatible_isolants)
    df %>%
        mutate(score = ((maxPrix - Prix) / maxPrix * weightPrice) + 
                 ((maxEmission - emission) / maxEmission * weightEmission) + 
                 (Conductivity / max(df$Conductivity, na.rm = TRUE) * weightConductivity) +
                 (Massevolumique / max(df$Massevolumique, na.rm = TRUE) * weightDensity) +
                 (Chaleurmassique / max(df$Chaleurmassique, na.rm = TRUE) * weightSpecificHeat))
}
    print(df)



select_top_solutions <- function(df) {
  df %>%
    arrange(desc(score)) %>%
    slice(1:3)
}
getWeightValue <- function(inputValue) {
    switch(as.character(inputValue),
           "2" = 1.5,  
           "3" = 2.5,  
           "4" = 3.5, 
           "5" = 4.5,  
           1.5)  
}
