# app.R 

# Importer les bibliothèques
library(shiny)

# Inclure les fichiers UI et server
source("ui.R")
source("server.R")

# Run the application 
shinyApp(ui = ui, server = server, options = list(port = 3000))
