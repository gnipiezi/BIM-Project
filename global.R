# global.R

library(shiny)
library(readxl)
library(DT)
library(ggplot2)
library(plotly)
library(dplyr)
library(websocket)
library(parallel)
library(shinyjs)
library(openxlsx)
# Variables globales
excel_path <- './output/materiaux_et_isolants.xlsx'
folder_input <- "inputs"