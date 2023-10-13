#------------------------------------------------------------------------------#
################################### Packages ################################### 
#------------------------------------------------------------------------------#
library("data.table")
library("readxl")
library(gt)
library(dplyr)
library(kableExtra)
library("data.table")
library("readxl")
library(gt)
library(dplyr)
library(knitr)
library(kableExtra)
library(bibtex)
library(readxl)
library(xtable)
library(writexl)
library(openxlsx)

#------------------------------------------------------------------------------# 
################################ Inputs needed  ################################ 
######################## Change this for the data needed #######################
#------------------------------------------------------------------------------# 
#Insert directory and name of the scenario file - CHANGE!
project <- 'MeOH'
setwd('C:/Users/Frede/Documents/DTU/DTU_Man/OptiPlant-DME/MeOH/Results/Results_DME/Main results')
tablescenario = fread("Scenario_100.csv", sep=",", header = T)


#Filter by type of units
typeofunits <- tablescenario$`Type of unit`
typeofunits <- as.array(typeofunits)
#Insert key words for the technologies wanted (you can print the array 'typeofunits' to see all the types of units) - CHANGE!
keywords_typeofunits <- c('MeOH','batteries','H2')
keywords_typeofunits <- c("MeOH - Biogas - SOEC","Biogas w H2","Waste water plant","Electrolysers SOEC alone","H2 buried pipes","Solar tracking","OFF_SP450-HH150","Curtailment","Electricity from the grid")


#Filter by parameters
parameters <- colnames(tablescenario)
#Insert key words for the parameters wanted (you can print the array 'parameters' to see all the parameters) - CHANGE!
#keywords_parameters <- c('Type of unit','cost','production','location', 'capacity')
#keywords_parameters <- c('Type of unit','Fuel cost(MEuros)','Cost per unit(MEuros)','Production(kton or GWh)','Production cost per unit (Euros/kg or kWh output)')
#keywords_parameters <- c('Type of unit', 'capacity', 'Fuel cost', 'Cost per unit', 'Production (kton', 'Production cost per unit')
keywords_parameters <- c('Type of unit','kton', 'capacity','investment','electricity')

#------------------------------------------------------------------------------# 
############################ Latex Table Generation ############################
#------------------------------------------------------------------------------#

#Title
titlescenario <- paste0("Scenario ",as.character(tablescenario[2,1]))

#Name of the file
namefile <- paste0(as.character(tablescenario[2,1]),".text")

#Filtering Data
filtered_typeofunits <- typeofunits[grepl(paste(keywords_typeofunits, collapse = "|"), typeofunits,ignore.case = TRUE)]
filtered_parameters <- parameters[grepl(paste(keywords_parameters, collapse = "|"), parameters,ignore.case = TRUE)]
filtertablescenario <- tablescenario %>% select(filtered_parameters)
filtertablescenario <- subset(filtertablescenario, tablescenario$`Type of unit` %in% filtered_typeofunits)

#Generation of table
tablescenario <- filtertablescenario%>% 
  kbl(caption= titlescenario,format="latex",align="l",booktabs = T,escape = F) %>%
  kable_styling(latex_options = c( "scale_down"),position = "center")%>%
  kable_minimal(full_width = F,  html_font = "Source Sans Pro")%>%
  
  #Replace cite with \cite in LaTeX mode
  gsub(pattern = "cite", replacement = "\\cite", ., fixed = TRUE)%>%
  
  #Replace symbols in LaTeX mode
  gsub(pattern = "%", replacement = "\\%", ., fixed = TRUE)%>%
  gsub(pattern = "_", replacement = "\\_", ., fixed = TRUE)%>%
  gsub(pattern = "..", replacement = ".", ., fixed = TRUE)%>%
  gsub(pattern = " .", replacement = ".", ., fixed = TRUE)%>%
  
  #Replace capacity units in LaTeX mode
  gsub(pattern = "kg\\_{", replacement = "kg\\textsubscript{", ., fixed = TRUE)%>%
  gsub(pattern = "CO2", replacement = "CO\\textsubscript{2}", ., fixed = TRUE)%>%
  gsub(pattern = "H20", replacement = "H\\textsubscript{2}O", ., fixed = TRUE)%>%
  gsub(pattern = "NH3", replacement = "NH\\textsubscript{3}", ., fixed = TRUE)%>%
  gsub(pattern = "NH3 ", replacement = "NH\\textsubscript{3} ", ., fixed = TRUE)%>%
  gsub(pattern = "H2", replacement = "H\\textsubscript{2}", ., fixed = TRUE)%>%
  gsub(pattern = "H\\textsubscript{2}in", replacement = "H\\textsubscript{2in}", ., fixed = TRUE)%>%
  gsub(pattern = "H\\textsubscript{2}out", replacement = "H\\textsubscript{2out}", ., fixed = TRUE)%>%
  gsub(pattern = "kWhin", replacement = "kWh\\textsubscript{in}", ., fixed = TRUE)%>%
  gsub(pattern = "kWhout", replacement = "kWh\\textsubscript{out}", ., fixed = TRUE)%>%
  
  #Replace specific parameters in Latex mode
  gsub(pattern = "/H\\textsubscript{2}O", replacement = "-/H\\textsubscript{2}O", ., fixed = TRUE)%>%
  gsub(pattern = "75AEC-25SOEC\\_HI", replacement = "75AEC-25SOEC\\textsubscript{HI}", ., fixed = TRUE)%>%
  gsub(pattern = "75AEC-25SOEC\\_A", replacement = "75AEC-25SOEC\\textsubscript{A}", ., fixed = TRUE)%>%
  gsub(pattern = "H\\textsubscript{2} tank", replacement = "H\\textsubscript{2} storage tank", ., fixed = TRUE)%>%
  gsub(pattern = "H\\textsubscript{2} buried pipes", replacement = "H\\textsubscript{2} storage buried pipes", ., fixed = TRUE)%>%
  #gsub(pattern = "Electrolysers", replacement = "Electrolyser Park ", ., fixed = TRUE)%>%
  gsub(pattern = "EUR", replacement = " \\officialeuro ", ., fixed = TRUE)
  #gsub(pattern = "Batteries", replacement = "Battery Park ", ., fixed = TRUE)

#Print the table in a text file
setwd('C:/Users/Frede/Documents/DTU/DTU_Man/OptiPlant-DME/MeOH')
sink(namefile)
print(tablescenario)
sink()


#------------------------------------------------------------------------------# 
############################ CSV Table Generation ############################
#------------------------------------------------------------------------------#
# Create a new Excel workbook
wb <- createWorkbook()
titlescenario <- substr(titlescenario, 0, 31)
# Add the first data frame to a new sheet
addWorksheet(wb, sheetName = titlescenario)
writeData(wb, sheet = titlescenario, x = filtertablescenario, startRow = 1, startCol = 1)

# Save the workbook to a file
filescenario = paste0("C:/Users/Frede/Documents/DTU/DTU_Man/OptiPlant-DME/MeOH/",titlescenario,".xlsx")
saveWorkbook(wb, file = filescenario, overwrite = TRUE)




