using XLSX, DataFrames

Datafile_inputs = joinpath(Inputs_folder,Inputs_file*".xlsx")

function read_xlsx(filename,sheetname)
    sheet = XLSX.readxlsx(filename)[sheetname]
    data = sheet[:]
    data = coalesce.(data,0)  #Replace missing by zero
    return data
end

Data_scenarios = read_xlsx(Datafile_inputs,Scenarios_set)

#Get inputs from the scenario sheet
L1_scenario = findfirst(x -> x == "Scenario number", Data_scenarios)[1] + 1

C_Scenario_name = findfirst(x -> x == "Scenario name", Data_scenarios)[2]
C_Scenario = findfirst(x -> x == "Scenario", Data_scenarios)[2]
C_location = findfirst(x -> x == "Location", Data_scenarios)[2]
C_fuel = findfirst(x -> x == "Fuel", Data_scenarios)[2]
C_year_data = findfirst(x -> x == "Year data", Data_scenarios)[2]
C_name_profile = findfirst(x -> x == "Profile name", Data_scenarios)[2]
C_electrolyser = findfirst(x -> x == "Electrolyser", Data_scenarios)[2]
C_CO2_capture = findfirst(x -> x == "CO2 capture", Data_scenarios)[2]
C_input_ref = findfirst(x -> x == "Input references sheet", Data_scenarios)[2]
C_CO2taxWTTop = findfirst(x -> x == "CO2taxWTTop", Data_scenarios)[2]
C_CO2taxWTTup = findfirst(x -> x == "CO2taxWTTup", Data_scenarios)[2]
C_CO2WTTop_treshhold = findfirst(x -> x == "CO2treshWTTop", Data_scenarios)[2]
C_rencrit = findfirst(x -> x == "Renewable criterion", Data_scenarios)[2]
C_criterion_application = findfirst(x -> x == "Criterion application", Data_scenarios)[2]
C_Weight_costs = findfirst(x -> x == "Weight costs", Data_scenarios)[2]
C_Weight_emissions = findfirst(x -> x == "Weight CO2e", Data_scenarios)[2]
C_input_data = findfirst(x -> x == "Input data sheet", Data_scenarios)[2]
C_profile_folder_name = findfirst(x -> x == "Profile folder name", Data_scenarios)[2]
C_results_folder = findfirst(x -> x == "Result folder name", Data_scenarios)[2]
C_max_profit = findfirst(x -> x == "Max profit", Data_scenarios)[2]
C_demand = findfirst(x -> x == "Demand", Data_scenarios)[2]
C_max_capacity = findfirst(x -> x == "Max capacity", Data_scenarios)[2]
C_ramping = findfirst(x -> x == "Ramping", Data_scenarios)[2]
C_no_negative_elec_price = findfirst(x -> x == "No negative elec price", Data_scenarios)[2]
C_hourly_elec_sale = findfirst(x -> x == "Hourly electricity sale", Data_scenarios)[2]
C_fixed_oxygen_sale = findfirst(x -> x == "Fixed oxygen sale", Data_scenarios)[2]
C_fixed_heat_sale = findfirst(x -> x == "Fixed heat sale", Data_scenarios)[2]
C_fixed_process_heat_sale = findfirst(x -> x == "Fixed process heat sale", Data_scenarios)[2]
C_fixed_biochar_sale = findfirst(x -> x == "Fixed biochar sale", Data_scenarios)[2]
C_hourly_heat_sale = findfirst(x -> x == "Hourly heat sale", Data_scenarios)[2]
C_connection_limit = findfirst(x -> x == "Connection limit", Data_scenarios)[2]
C_sold_products = findfirst(x -> x == "Sold products", Data_scenarios)[2]
C_fuel_cost = findfirst(x -> x == "Fuel cost", Data_scenarios)[2]
C_flows = findfirst(x -> x == "Flows", Data_scenarios)[2]

All_Scenario_name = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_Scenario_name]]
All_Scenario = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_Scenario]] ; N_scenarios = length(All_Scenario)
All_location = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_location]]
All_fuel = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_fuel]]
All_year_data = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_year_data]]
All_profile_name = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_name_profile]]
All_profile_folder_name = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_profile_folder_name]]
All_electrolyser = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_electrolyser]]
All_CO2_capture = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_CO2_capture]]
All_ref_sheet = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_input_ref]]
All_CO2taxWTTop = Data_scenarios[L1_scenario:end , C_CO2taxWTTop]
All_CO2taxWTTup = Data_scenarios[L1_scenario:end , C_CO2taxWTTup]
All_CO2WTTop_treshhold = Data_scenarios[L1_scenario:end , C_CO2WTTop_treshhold]
All_rencrit = Data_scenarios[L1_scenario:end , C_rencrit]
All_criterion_application = Data_scenarios[L1_scenario:end , C_criterion_application]
All_Weight_costs = Data_scenarios[L1_scenario:end , C_Weight_costs]
All_Weight_emissions = Data_scenarios[L1_scenario:end , C_Weight_emissions]
All_results_folder = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_results_folder]]
All_Input_data = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_input_data]]
#Maximum profit optimization if true, minimum production cost if false
All_Option_maximal_profit = Data_scenarios[L1_scenario:end , C_max_profit]
# Add a minimal demand constraint (has to be true for min cost)
All_Option_demand = Data_scenarios[L1_scenario:end , C_demand]
# Add a maximum capacity constraint (has to be true for maximal profit or when selling electricity )
All_Option_max_capacity = Data_scenarios[L1_scenario:end , C_max_capacity]
# Add ramping constraints (higher computational time)
All_Option_ramping = Data_scenarios[L1_scenario:end , C_ramping]
# Replace negative electricity prices with 0
All_Option_no_negative_prices = Data_scenarios[L1_scenario:end , C_no_negative_elec_price]
# Possibility to sell output on hourly market price (heat and electricity)
All_Option_hourly_elec_sale = Data_scenarios[L1_scenario:end , C_hourly_elec_sale]
# Grid and heat availability restriction: surplus or deficit from the main grid/network
All_Option_connection_limit = Data_scenarios[L1_scenario:end , C_connection_limit]
#Oxygen and heat sale
All_Option_fixed_oxygen_sale = Data_scenarios[L1_scenario:end , C_fixed_oxygen_sale]
All_Option_fixed_heat_sale = Data_scenarios[L1_scenario:end , C_fixed_heat_sale]
All_Option_fixed_process_heat_sale = Data_scenarios[L1_scenario:end , C_fixed_process_heat_sale]
All_Option_fixed_biochar_sale = Data_scenarios[L1_scenario:end , C_fixed_biochar_sale]
All_Option_hourly_heat_sale = Data_scenarios[L1_scenario:end , C_hourly_heat_sale]

# Results that you want to write
All_Write_sold_products =  Data_scenarios[L1_scenario:end , C_sold_products]
All_Write_fuel_cost = Data_scenarios[L1_scenario:end , C_fuel_cost]
All_Write_flows = Data_scenarios[L1_scenario:end , C_flows]
