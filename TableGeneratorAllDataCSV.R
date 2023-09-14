#------------------------------------------------------------------------------#
################################### Packages ################################### 
#------------------------------------------------------------------------------#
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

#Insert directory of the files:
Directory <- 'C:/Users/njbca/Documents/Models/OptiPlant-World/Base/Data/Inputs';
DirectoryBiblio <- 'C:/Users/njbca/Documents/Models/OptiPlant-World/Base/Data/Inputs';

#Insert excel file name:
Filename <- "DME_paper_data.xlsx";
#Insert bib file name:
Filenamebib <- "Bornholm_references.bib";

#Insert excel sheet names:
#Data sheet
Sheetname1 <-"Data_base_case";
#Reference/Source sheet
Sheetname2 <-"Ref_base_case";

#Select the year:
### 2025
### 2030
### 2040
### 2050
year<- 2030

#Select the estimation:
### 'worst'
### 'bench'
### 'best'
estimation_considered <- 'bench'

#Selection of types of units, you can select within the following ones:

# CO2 capture DAC
# CO2 capture PS
# MeOH plant CCU
# Biomass bamboo 2
# Biomass bamboo 1
# Biomass wheat 2
# Biomass wheat 1
# Sale of biochar
# Bamboo2-stage-SOEC
# Bamboo1-stage-SOEC
# Wheat2-stage-SOEC
# Wheat1-stage-SOEC
# NH3 plant + ASU - AEC
# NH3 plant + ASU - SOEC
# H2 client
# Desalination plant
# Waste water plant
# Drinking water
# Electrolysers AEC
# Electrolysers SOEC heat integrated
# Electrolysers SOEC alone
# Electrolysers 75AEC-25SOEC_HI
# Electrolysers 75AEC-25SOEC_A
# H2 pipeline to MeOH CCU plant
# H2 pipeline to Bamboo-2
# H2 pipeline to Bamboo-1
# H2 pipeline to Wheat-2
# H2 pipeline to Wheat-1
# H2 pipeline to NH3 plant
# H2 pipeline to client
# Heat from district heating
# Heat sent to district heating
# Heat sent to other process
# Sale of oxygen
# H2 tank compressor
# H2 tank valve
# H2 tank
# H2 pipes compressor
# H2 pipes valve
# H2 buried pipes
# Solar fixed
# Solar tracking
# ON_SP198-HH100
# ON_SP198-HH150
# ON_SP237-HH100
# ON_SP237-HH150
# ON_SP277-HH100
# ON_SP277-HH150
# ON_SP321-HH100
# ON_SP321-HH150
# OFF_SP379-HH100
# OFF_SP379-HH150
# OFF_SP450-HH100
# OFF_SP450-HH150
# CSP_tower
# Charge TES
# Discharge TES
# TES
# CSP + TES
# Electricity from the grid
# Curtailment
# Diesel generator
# Charge batteries
# Discharge batteries
# Batteries

#Type_considered_all <- c('CO2 capture DAC','CO2 capture PS','MeOH plant CCU','Biomass bamboo 2','Biomass bamboo 1',,'Biomass wheat 2','Biomass wheat 1','Bio-eMeOH plant - AEC','Sale of biochar','Bamboo2-stage-SOEC', 'Bamboo1-stage-SOEC','Wheat2-stage-SOEC','Wheat1-stage-SOEC','NH3 plant + ASU - AEC', 'NH3 plant + ASU - SOEC', 'H2 client', 'Desalination plant', 'Waste water plant', 'Drinking water', 'Electrolysers AEC', 'Electrolysers SOEC heat integrated', 'Electrolysers SOEC alone', 'Electrolysers 75AEC-25SOEC_HI', 'Electrolysers 75AEC-25SOEC_A', 'H2 pipeline to MeOH CCU plant', 'H2 pipeline to BioMeOH plant', 'H2 pipeline to NH3 plant', 'H2 pipeline to client', 'Heat from district heating', 'Heat sent to district heating', 'Sale of oxygen', 'H2 tank compressor', 'H2 tank valve', 'H2 tank', 'H2 pipes compressor', 'H2 pipes valve', 'H2 buried pipes', 'Solar fixed', 'Solar tracking', 'ON_SP198-HH100', 'ON_SP198-HH150', 'ON_SP237-HH100', 'ON_SP237-HH150', 'ON_SP277-HH100', 'ON_SP277-HH150', 'ON_SP321-HH100', 'ON_SP321-HH150', 'OFF_SP379-HH100', 'OFF_SP379-HH150', 'OFF_SP450-HH100', 'OFF_SP450-HH150', 'CSP_tower', 'Charge TES', 'Discharge TES', 'TES', 'CSP + TES', 'Electricity from the grid', 'Curtailment', 'Diesel generator', 'Charge batteries', 'Discharge batteries', 'Batteries')
Type_considered_econ <- c('Bamboo2-stage-SOEC', 'Bamboo1-stage-SOEC','Wheat2-stage-SOEC','Wheat1-stage-SOEC', 'Desalination plant', 'Electrolysers SOEC heat integrated','H2 buried pipes','ON_SP198-HH100', 'ON_SP198-HH150', 'Solar tracking', 'Batteries')
Type_considered_tech <- c('Bamboo2-stage-SOEC', 'Bamboo1-stage-SOEC','Wheat2-stage-SOEC','Wheat1-stage-SOEC', 'Desalination plant', 'Electrolysers SOEC heat integrated','H2 buried pipes')
Type_considered <- Type_considered_econ
#Selection of parameters, you can select within the following ones:
### 'Yearly demand'
### 'Produced from'
### 'El balance'
### 'Heat balance'
### 'H2 balance'
### 'CSP balance'
### 'Max Capacity'
### 'Fuel production rate'
### 'Heat generated'	
### 'Load min' 
### 'Ramp up'
### 'Ramp down'
### 'Electrical consumption'
### 'Investment'
### 'Fixed cost'
### 'Variable cost'
### 'Fuel selling price'
### 'Fuel buying price'
### 'CO2e infrastructure'
### 'CO2e process'
### 'Land use'
### 'Annuity factor'

#Note that "Type" and "Capacity" must always be there
parameters_considered_all <- c('Type','Capacity','Yearly demand','Producedfrom','El balance','Heat balance','H2 balance','CSP balance','Max Capacity','Fuel production rate','Heat generated','Load min','Ramp up','Ramp down','Electrical consumption','Investment','Fixed cost','Variable cost','Fuel selling price','Fuel buying price','CO2e infrastructure','CO2e process','Land use', 'Annuity factor');
parameters_considered_econ <- c('Type', 'Capacity',  'Investment','Fixed cost', 'Variable cost');
parameters_considered_tech <- c('Type', 'Capacity', 'Input/Output', 'Fuel production rate', 'Heat generated', 'Process heat generated','Load min','Electrical consumption');
parameters_considered <- parameters_considered_econ

#Insert 0 if you want economical assumptions and 1 for technology assumptions
inout <- 0;

#Insert the name of the text file to store the latex code for the table
nametextfile <- "table_tech_2030.text";
#Insert the name of the csv file to store the table values
namecsvfile <- "csvtableeco.csv";

#------------------------------------------------------------------------------#
################################## Main Code ################################### 
#------------------------------------------------------------------------------#

#Load Data - Select your path
setwd(Directory);

#Select the file you want to read the data and sources from
basedata <- read_excel(Filename, sheet = Sheetname1, range = "D7:FS73");
refdata <- read_excel(Filename, sheet = Sheetname2, range = "D7:FS73");

#Select the file you want to read the capacity and Input/Output from
capacitybasedata <- read_excel("CapacityCSV.xlsx", range = "B1:B66");
inoutbasedata <- read_excel("CapacityCSV.xlsx", range = "C1:C66");

capacityrefdata <- data.frame(matrix(0, nrow = length(capacitybasedata), ncol = 1))
inoutrefdata <- data.frame(matrix(0, nrow = length(inoutbasedata), ncol = 1))

colnames(capacityrefdata) <- colnames(capacitybasedata)
colnames(inoutrefdata) <- colnames(inoutbasedata)

#Select the file you want to read the bibliography from
setwd(DirectoryBiblio);
bib <-  read.bib(Filenamebib);

#Changing names of the first 2 columns
names(basedata)[names(basedata) == '...1'] <- 'Type of units';
names(basedata)[names(basedata) == '...2'] <- 'Line/Column index';
names(refdata)[names(refdata) == '...1'] <- 'Type of units';
names(refdata)[names(refdata) == '...2'] <- 'Line/Column index';

#Removing the fist row
basedata <- basedata[-c(1),];
refdata <- refdata[-c(1),];

#Adding the capacity column into the data frame
basedata <- cbind(basedata[, 1], capacitybasedata, basedata[, 2:ncol(basedata)])
refdata <- cbind(refdata[, 1], capacityrefdata, refdata[, 2:ncol(refdata)])

if (inout==1){
  basedata <- cbind(basedata[, 1], inoutbasedata, basedata[, 2:ncol(basedata)])
  refdata <- cbind(refdata[, 1], inoutrefdata, refdata[, 2:ncol(refdata)])
}
names(basedata)[1] <- 'Type of units'
names(refdata)[1] <- 'Type of units'

#Fixing percentage columns
parameters_percentage <- c('Load min','Ramp up','Ramp down')
basedata <- basedata %>%
  mutate_at(vars(matches(parameters_percentage)), funs(. * 100))

#Filtering based on selection of rows (Types of units)
basedata <- subset(basedata,`Type of units` %in% Type_considered);
refdata <- subset(refdata,`Type of units` %in% Type_considered);

#Filtering based on selection of columns (Parameters)
years_considered <- as.character(year)
parameters_noyear <- c('Type','Capacity','Input/Output','Yearly demand','Producedfrom','El balance','Heat balance','Max CapacityAll');
num_matches <- length(intersect(parameters_considered, parameters_noyear))
parameters_considered <- sprintf("^%s", parameters_considered)
original_columns <- colnames(basedata)

basedata <- select(basedata, c(1:num_matches), matches(years_considered))
basedata <- select(basedata, matches(parameters_considered))
basedata <- select(basedata, c(1:num_matches), matches(estimation_considered))
basedata <- basedata[,order(match(names(basedata[num_matches,]), original_columns))]
basedatacsv <- basedata

refdata <- select(refdata, c(1:num_matches), matches(years_considered))
refdata <- select(refdata, matches(parameters_considered))
refdata <- select(refdata, c(1:num_matches), matches(estimation_considered))
refdata <- refdata[,order(match(names(refdata[num_matches,]), original_columns))]
refdatacsv <- refdata


#Obtaining all the sources without repeating in a vector 
#Removing the first column (Types of units)
references <- refdata[,-c(1)]
#Flatten the matrix into a 1-dimensional array
references <- as.vector(t(references))
#Remove all occurrences of the number 0 from the array
references <- references[references != 0]
#Identify which elements are strings
indexstrings <- is.character(references)
#Subset the array to keep only the string elements
references <- references[indexstrings]
#Remove all duplicate values from the array
references <- unique(references)

counternameauthor <- 0;
nameauthor<- character(0);
for (refer in references){
  words <- unlist(strsplit(refer, " "))
  # Replace the dot with a space and concatenate the vector into a single string
  words <- paste(gsub("\\.", " .", paste(words, collapse = " ")));
  # Split the new string at each space
  words <- strsplit(words, " ")[[1]];
  counternameauthor = counternameauthor + 1;
  for (w in words){
    if(!is.na(w) && w %in% names(bib)) {
    nameauthor[counternameauthor]<-w;
  }
  }
}

# Function to check if a string contains a specific word
check_word_in_string <- function(word, string) {
  pattern <- paste0("\\b", word, "\\b")  # Adding word boundaries for exact match
  if (grepl(pattern, string)) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

#Assigning the corresponding reference for each data element (if any) 
#Initialization of a new zero data frame
basedatanew <- data.frame(matrix(0, nrow(basedata), ncol(basedata)));
#For every element in the data set adding the corresponding reference source if any
for (i in 1:nrow(basedata)){
  for (j in 1:ncol(basedata)){
    #If there is a reference
    if(refdata[i,j] != 0){
      for (r in references)
        if(refdata[i,j]==r){
          #Add data element with its corresponding reference
          if (is.numeric(basedata[i,j])){
            numbernote <- match(r, references);
            #for (author in nameauthor){
            #  if (check_word_in_string(author, r)) {
            #    refnote <- paste0(" ", author)
            refnote <- paste0("EXP", numbernote)
            basedatanew[i,j] <- paste0(round(basedata[i,j],1), refnote)
             # }
           # }
          }
          else{
            numbernote <- match(r, references);
            #for (author in nameauthor){
            #  if (check_word_in_string(author, r)) {
            #    refnote <- paste0(" ", author)
            refnote <- paste0("EXP", numbernote)
            basedatanew[i,j] <- paste0(basedata[i,j], refnote)
              }
            }
          }
    #    }
   # }
    #If there is not a reference
    else{
      #Add data element
      if (is.numeric(basedata[i,j])){
        basedatanew[i,j] <- round(basedata[i,j],1)
      }
      else{
        basedatanew[i,j]<- basedata[i,j]
      }
    }
  }  
}
for (i in 1:nrow(basedata)){
  for (j in 1:ncol(basedata)){
    print(refdata[i,j])
  }}


#Keeping the first column as before
basedatanew[,1] = basedata[,1];

#Removing year from all column title names
colnames(basedatanew) <- gsub(year, "", colnames(basedata))
colnames(basedatanew) <- gsub(estimation_considered, "", colnames(basedatanew))

#Separating name of the parameter and its unit in two different arrays
colnames <- colnames(basedatanew)

#Extract variable names and units
names <- gsub("(\\s*\\(.*?\\))", "", colnames)
units <- gsub(".*?\\((.*?)\\)", "\\1", colnames)

#If there is not unit, return NA
units[units == ""] <- NA

#Remove leading/trailing whitespace from names and units
names <- trimws(names)
units <- trimws(units)

#Renaming first element in units vector
units[1] <- "Units"
units[units==names]<- "-"
for (pattern in estimation_considered) {
  units <- gsub(pattern, "", units)
}

#Update the title of the columns 
colnames(basedatanew) <- names
#Append the units vector into the data frame
basedatanew <- rbind(units, basedatanew)



#------------------------------------------------------------------------------# 
############################ Latex Table Generation ############################
#------------------------------------------------------------------------------#

#Setting all the references compatible with Latex format
referencesnew <- character(0);
counter = 0;
for (refe in references){
  counter = counter+1;
  words <- unlist(strsplit(refe, " "))
  # Replace the dot with a space and concatenate the vector into a single string
  words <- paste(gsub("\\.", " .", paste(words, collapse = " ")))
  # Split the new string at each space
  words <- strsplit(words, " ")[[1]]
  temp <- character(0) 
  for (word in words){
    if(!is.na(word) && word %in% names(bib)) {
      citeref <- paste0(word)
      temp <- c(temp, citeref)
    }
    else if(!is.na(word)){
      temp <- c(temp, word)
    }
  }
  temp[length(temp)] <- paste0(temp[length(temp)], ".")
  referencesnew[counter] <- paste0("EXP", counter, " ", paste0(temp, collapse = " "))
}

# #Generate a Latex code for the table
# table <- basedatanew %>%
#   #Table style generation
#   kbl(caption= paste("Techno-economical inputs", year, sep = " "),format="latex",align="l",booktabs = T,escape = F) %>%
#   kable_styling(latex_options = c( "scale_down"),position = "center")%>%
#   kable_minimal(full_width = F,  html_font = "Source Sans Pro")%>%
#   #Adding footnote with notes and references
#   footnote(number = referencesnew,footnote_as_chunk = FALSE, title_format="italic",general_title="References",escape = F)%>%
#   
#   #Replace cite with \cite in LaTeX mode
#   gsub(pattern = "cite", replacement = "\\cite", ., fixed = TRUE)%>%
#   
#   #Replace symbols in LaTeX mode
#   gsub(pattern = "%", replacement = "\\%", ., fixed = TRUE)%>%
#   gsub(pattern = "_", replacement = "\\_", ., fixed = TRUE)%>%
#   gsub(pattern = "..", replacement = ".", ., fixed = TRUE)%>%
#   gsub(pattern = " .", replacement = ".", ., fixed = TRUE)%>%
#   
#   #Replace capacity units in LaTeX mode
#   gsub(pattern = "kg\\_{", replacement = "kg\\textsubscript{", ., fixed = TRUE)%>%
#   gsub(pattern = "CO2", replacement = "CO\\textsubscript{2}", ., fixed = TRUE)%>%
#   gsub(pattern = "H20", replacement = "H\\textsubscript{2}O", ., fixed = TRUE)%>%
#   gsub(pattern = "NH3", replacement = "NH\\textsubscript{3}", ., fixed = TRUE)%>%
#   gsub(pattern = "NH3 ", replacement = "NH\\textsubscript{3} ", ., fixed = TRUE)%>%
#   gsub(pattern = "H2", replacement = "H\\textsubscript{2}", ., fixed = TRUE)%>%
#   gsub(pattern = "H\\textsubscript{2}in", replacement = "H\\textsubscript{2in}", ., fixed = TRUE)%>%
#   gsub(pattern = "H\\textsubscript{2}out", replacement = "H\\textsubscript{2out}", ., fixed = TRUE)%>%
#   gsub(pattern = "kWhin", replacement = "kWh\\textsubscript{in}", ., fixed = TRUE)%>%
#   gsub(pattern = "kWhout", replacement = "kWh\\textsubscript{out}", ., fixed = TRUE)%>%
#   
#   #Replace specific parameters in Latex mode
#   gsub(pattern = "/H\\textsubscript{2}O", replacement = "-/H\\textsubscript{2}O", ., fixed = TRUE)%>%
#   gsub(pattern = "75AEC-25SOEC\\_HI", replacement = "75AEC-25SOEC\\textsubscript{HI}", ., fixed = TRUE)%>%
#   gsub(pattern = "75AEC-25SOEC\\_A", replacement = "75AEC-25SOEC\\textsubscript{A}", ., fixed = TRUE)%>%
#   gsub(pattern = "H\\textsubscript{2} tank", replacement = "H\\textsubscript{2} storage tank", ., fixed = TRUE)%>%
#   gsub(pattern = "H\\textsubscript{2} buried pipes", replacement = "H\\textsubscript{2} storage buried pipes", ., fixed = TRUE)%>%
#   gsub(pattern = "Electrolysers", replacement = "Electrolyser Park ", ., fixed = TRUE)%>%
#   gsub(pattern = "EUR", replacement = " \\officialeuro ", ., fixed = TRUE)%>%
#   gsub(pattern = "Batteries", replacement = "Battery Park ", ., fixed = TRUE)

#Print the table in a text file
sink(nametextfile)
print(table)
sink()


# Create a new Excel workbook
wb <- createWorkbook()

# Add the first data frame to a new sheet
addWorksheet(wb, sheetName = "Data")
writeData(wb, sheet = "Data", x = basedatanew, startRow = 1, startCol = 1)

# Add the second data frame to a new sheet
addWorksheet(wb, sheetName = "Sources")
writeData(wb, sheet = "Sources", x = referencesnew, startCol = 1)

# Save the workbook to a file
saveWorkbook(wb, file = "C:/Users/njbca/Documents/Models/OptiPlant-World/Base/Data/Inputs/DMETableeco.xlsx", overwrite = TRUE)



