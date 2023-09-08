using JuMP, Gurobi, CSV, DataFrames

#Open julia terminal: Alt J Alt O 

#------------------------------Problem set up------------------------------------
#Project name
Project = "Base"
# Folder name for all csv file
all_csv_files = "All_results"
# Folder paths for data acquisition and writing
Main_folder = "C:/Users/njbca/Documents/Models/OptiPlant-World" ;
Profiles_folder = joinpath(Main_folder,Project,"Data","Profiles") ; #mkpath(Profiles_folder)
Inputs_folder = joinpath(Main_folder,Project,"Data","Inputs") ; #mkpath(Techno_economics_folder)
Inputs_file = "Bornholm_All_data"

# Scenario set (same name as exceel sheet)
Scenarios_set =  "Scenarios_stoch" ; include("ImportScenarios.jl")
# Scenario under study (all between N_scen_0 and N_scen_end)
N_scen_0 = 16 ; N_scen_end = 16 # or N_scen_end = N_scenarios for total number of scenarios
#Studied hours (max 8760). When there is maintenance hours are out
#TMend = 4000-4876 : 90% time working ; T = 4000-4761 : 8000 hours
TMstart = 4675 ; TMend = 5011 ; Tbegin = 72 ; Tfinish=8736 #Time maintenance starts/end ; Tbegin: Time within plants can operate at 0% load (in case of no renewable power the first 3 days)
#Time = vcat(collect(1:TMstart),collect(TMend:Tfinish)) ; T = length(Time)
#Tstart = vcat(collect(1:TMstart),collect(TMend:Tfinish)) ;
#if Tbegin >= 2
  #splice!(Tstart,1:Tbegin) # Time within plants can operate at 0% load (in case of no renewable power the first 3 days)
#end
Currency_factor = 1 # 1.12 for dollar 2019 #All input data are in Euro 2019

#Piece-wise linear function of the electrolyzer is removed for simplification

#Selected scenarios
Scenarios_stoch = [2 3 4 5 6] ; S=length(Scenarios_stoch)
#Cost of overproducing or underproducing over the year in €/kg
OverProdCost = 3 #3 #€/kg of NH3 sold at grey market price instead of green price (sold at 300€/t (2.5) instead of 1300€/tonne (5.5))
UnderProdCost = 4.5 # #5.5 #€/kg of green NH3 that has not ben sold (price of 1300€/tonne or 5.5 €/kg for H2)
Demand_deviation_over = 0 #In % more compared to demand target
Demand_deviation_under = 0 #In % less compared to demand target

#Change yearly demand target into periodic demand targets (weekly, monthly, etc...)
#Change yearly demand target into periodic demand targets (weekly, monthly, etc...)
Hours_per_period = 728
Numbers_of_period = 12
T = Hours_per_period*Numbers_of_period 
Time = collect(1:T)
Time_demand_target = transpose(reshape(collect(1:T),Hours_per_period,Numbers_of_period))
T_period = [collect(row) for row in eachrow(Time_demand_target)]

Tstart = collect(1:T)
if Tbegin >= 2
  splice!(Tstart,1:Tbegin) # Time within plants can operate at 0% load (in case of no renewable power the first 3 days)
end

#--------------------- Main code -------------------------
N_scen = N_scen_0

#while N_scen < N_scen_end + 1 #Run the optimization model for all scenarios

include("ImportData.jl") # Import data
Flows_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Flows") ; mkpath(Flows_result_folder)
Sold_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Sold") ; mkpath(Sold_result_folder)
Bought_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Bought") ; mkpath(Bought_result_folder)
Main_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Main results") ; mkpath(Main_result_folder)
Main_all_results_folder = joinpath(Main_folder,Project,"Results",all_csv_files,"Main results") ; mkpath(Main_all_results_folder)
Data_used_folder = joinpath(Main_folder,Project,"Results",csv_files,"Data used") ; mkpath(Data_used_folder)
#-----------------------------------Model----------------------------------
Model_stochastic = Model(Gurobi.Optimizer)

#Decision variables
@variable(Model_stochastic,Costs) # In €2019
@variable(Model_stochastic,Emissions) # In kg CO2e
@variable(Model_stochastic,X[1:U,t in Time,s in Scenarios_stoch] >= 0) # Products and energy flow (kg/h or kW)
@variable(Model_stochastic,Capacity[1:U] >=0) #  Production capacity of each unit (kg/h or kW)
@variable(Model_stochastic,Sold[1:U,t in Time,s in Scenarios_stoch] >= 0) # Quantity of products sold (kg/h or kW)
@variable(Model_stochastic,Bought[1:U,t in Time,s in Scenarios_stoch] >= 0) # Quantity of input bought (kg/h or kW)
@variable(Model_stochastic, OverProd[1:Numbers_of_period, s in Scenarios_stoch] >= 0) #Slack variable for demand over Production
@variable(Model_stochastic, UnderProd[1:Numbers_of_period, s in Scenarios_stoch] >= 0) #Slack variable for demand under production


# Set higher bound to 0 for not used units
for t in Time, u = 1:U, s in Scenarios_stoch
  if Used_Unit[u]==0
    @constraint(Model_stochastic,X[u,t,s] <= 0)
    @constraint(Model_stochastic,Capacity[u] <= 0)
    @constraint(Model_stochastic,Sold[u,t,s] <= 0)
    @constraint(Model_stochastic,Bought[u,t,s] <= 0)
  end
end

#Minimize the total cost and/or CO2e emissions of the system
  #@objective(Model_stochastic, Min, Weight_costs*Costs + Weight_emissions*Emissions)
  #@objective(Model_stochastic, Min, Costs)

#Costs equation in €2019
@objective(Model_stochastic, Min,  
sum((Invest[u]*Annuity_factor[u] + FixOM[u] + CO2taxWTTup*CO2_inf[u])*Capacity[u] for u=1:U)
+ (1/S)*sum((OverProd[p,s]*OverProdCost + UnderProd[p,s]*UnderProdCost for p=1:Numbers_of_period, s in Scenarios_stoch)) #Remove cost from obj function (or put 0)
#+ (1/S)*sum(Fuel_Buying_fixed[u]*Bought[u,t,s] for u=1:U, t in Time, s in Scenarios_stoch)
#+ (1/S)*sum(Price_Profile[Grid_buy_p[u],t]*Bought[Grid_buy[u],Time[t],s] for u=1:nGb,t=1:T, s in Scenarios_stoch)
#+ (1/S)*sum(Price_Profile[Heat_buy_p[u],t]*Bought[Heat_buy[u],Time[t],s] for u=1:nHb,t=1:T, s in Scenarios_stoch)
#+ (1/S)*sum(CO2taxWTTop*CO2_Profile[Grid_CO2_counted_p[u],t]*Bought[Grid_buy[u],Time[t],s] for u=1:nGCO2tax,t=1:T, s in Scenarios_stoch) 
+ (1/S)*sum((VarOM[u] + CO2taxWTTop*CO2_proc_fixed[u])*X[u,t,s] for u=1:U,t in Time, s in Scenarios_stoch)
#- sum(Fuel_Selling_fixed[u]*Sold[u,t,s] for u=1:U,t in Time, s in Scenarios_stoch)
#- sum(Price_Profile[Grid_sell_p[u],t]*Sold[Grid_sell[u],Time[t],Scenarios_stoch[s]] for u=1:nGs,t=1:T,s=1:S)
#- sum(Price_Profile[Heat_sell_p[u],t]*Sold[Heat_sell[u],Time[t],Scenarios_stoch[s]] for u=1:nHs,t=1:T,s=1:S)
)
#"Absolute" emissions equation in kg CO2e per year
#@constraint(Model_stochastic, Emissions == 
#+ sum(CO2_inf[u]*Capacity[u] for u=1:U)
#+ (1/S)*sum(CO2_Profile[Grid_CO2_emitted_p[u],t]*Bought[Grid_buy[u],Time[t],s] for u=1:nGCO2em,t=1:T,s in Scenarios_stoch)
#+ (1/S)*sum(CO2_proc_fixed[u]*X[u,t,s] for u=1:U,t in Time, s in Scenarios_stoch))

#Maximum WTT operational emissions over a year in kg CO2e
if CO2WTTop_treshhold >= 0
  @constraint(Model_stochastic,[s in Scenarios_stoch], sum(CO2_Profile[Grid_CO2_counted_p[u],t]*Bought[Grid_buy[u],Time[t],s] for u=1:nGCO2tax,t=1:T)
  + sum(CO2_proc_fixed[u]*X[u,t,s] for u=1:U,t in Time) <= CO2WTTop_treshhold*Fuel_energy_content*sum(Sold[i,t,s] for t in Time, i in MinD))
end

#Demand constraint
if Option_demand == true

  #Yearly demand: have to fullfill min yearly demand if there is one
  #@constraint(Model_stochastic, Demand[i in MinD,s in Scenarios_stoch], sum(Sold[i,t,s] for t in Time) == Demand[i] + OverProd[s] - UnderProd[s]) #Relax that constraint while using a cost penalty
  
  Demand_targets = zeros(1,Numbers_of_period)
  for i=1:1, p =1:Numbers_of_period
    Demand_targets[i,p] = Demand[i]/Numbers_of_period
  end
  #Periodic demand
  @constraint(Model_stochastic,yolo[i in MinD, p=1:Numbers_of_period, s in Scenarios_stoch], sum(Sold[i,t,s] for t in T_period[p] ) == Demand_targets[i,p] + OverProd[p,s] - UnderProd[p,s])
  
  #if Demand_deviation_over != 0
   # @constraint(Model_stochastic, Demand_dev_over[i in MinD,s in Scenarios_stoch], OverProd[p,s] <= Demand_deviation_over*Demand[i]) #Same for underproduction, dual will be price of not overproducing
  #end
  #if Demand_deviation_under != 0
   # @constraint(Model_stochastic, Demand_dev_under[i in MinD,s in Scenarios_stoch], UnderProd[p,s] <= Demand_deviation_under*Demand[i]) #Same for underproduction, dual will be price of not overproducing
  #end
    #if Option_connection_limit == true
    #Hourly electricity/heat available: can't get electricity/heat from the grid when there is no excess production
    #@constraint(Model_stochastic,[i=1:nGe,t in Time], X[Grid_in[i],t] <= Flux_Profile[Grid_excess[i],t])
    #@constraint(Model_stochastic,[i=1:nHe,t in Time], X[Heat_in[i],t] <= Flux_Profile[Heat_excess[i],t])
    #Can't export electricity/heat to the grid when there is no external electricity/heat demand
    #@constraint(Model_stochastic,[i=1:nGd, t in Time],X[Grid_out[i],t] <= Flux_Profile[Grid_deficit[i],t])
    #@constraint(Model_stochastic,[i=1:nHd, t in Time],X[Heat_out[i],t] <= Flux_Profile[Heat_deficit[i],t])
  #end
end

#Capacity constraints

#if Option_max_capacity == true
  #@constraint(Model_stochastic,[u=1:U], Capacity[u] <= Max_Cap[u]) #Maximal capacity that can be installed
#end

#Load constraints: 

@constraint(Model_stochastic,[u=1:U,t in Tstart,s in Scenarios_stoch], X[u,t,s] >= Capacity[u]*Load_min[u]) #Min flow
@constraint(Model_stochastic,[u=1:U,t in Time,s in Scenarios_stoch], X[u,t,s] <= Capacity[u]) #Max flow

#Ramping constraints
#if Option_ramping == true

  # @constraint(Model_stochastic,[u=1:U,t=1:T], X[u,Time[t]]-(t>Time[1] ? X[u,Time[t-1]] : 0) <= Ramp_up[u]*Capacity[u])
  #@constraint(Model_stochastic,[u=1:U,t=1:T], (t>Time[1] ? X[u,Time[t-1]] : 0)-X[u,Time[t]] <= Ramp_down[u]*Capacity[u])

#end

# Productions rates
@constraint(Model_stochastic,[i=1:nProd,t in Time,s in Scenarios_stoch], X[Products[i],t,s] == X[Reactants[i],t,s]*Prod_rate[Products[i]])
# Hydrogen balance
@constraint(Model_stochastic,[t in Time,s in Scenarios_stoch],sum(H2_balance[u]*X[u,t,s] for u=1:U)==0)
# Heat balance
#@constraint(Model_stochastic,[t in Time],sum(Heat_balance[u]*Heat_generated[u]*X[u,t] for u=1:U)==0)
# Storages balance
@constraint(Model_stochastic,[i=1:nST,t=1:T,s in Scenarios_stoch], X[Tanks[i],Time[t],s] == (t>Time[1] ? X[Tanks[i],Time[t-1],s] : 0) + X[Stor_in[i],Time[t],s] - X[Stor_out[i],Time[t],s])

# Renewable energy production constraint (profile dependent)
#@constraint(Model_stochastic, [i = 1:nRPU,t=1:T], X[RPU[i],Time[t]] == Flux_Profile[RPU_p[i],t]*Capacity[RPU[i]])

# Renewable energy production constraint (profile dependent) only for offshore wind selected turbine
@constraint(Model_stochastic, [i = 1:nRPU,t=1:T,s=1:S], X[RPU[i],Time[t],Scenarios_stoch[s]] == Scenario_profile[RPU_s[i],t,s]*Capacity[RPU[i]])
# Electricity produced and consumed have to be at equilibrium
@constraint(Model_stochastic, [t in Time,s in Scenarios_stoch], sum((El_balance[u]-Sc_nom[u])*X[u,t,s] for u=1:U) == 0)

# Sold and bought ouputs/inputs
@constraint(Model_stochastic,[u=1:U,t in Time,s in Scenarios_stoch],Sold[u,t,s] <= X[u,t,s]) # Have to sell less than what is produced
@constraint(Model_stochastic,[u=1:U,t in Time,s in Scenarios_stoch],Bought[u,t,s] == X[u,t,s]) # Have to buy exactly what you use

# solve
optimize!(Model_stochastic)

#--------------------------Results output------------------------------------------
if termination_status(Model_stochastic) == MOI.OPTIMAL
  Optimum = objective_value(Model_stochastic)

  #-----------------------Techno_economical data and sources used------------------------

  df_techno_eco = DataFrame(Data_units[Parameters_index[1]:end,Subsets_index[2]:end], :auto)
  techno_eco = "Data_$N_scen.csv"
  CSV.write(joinpath(Data_used_folder,techno_eco),df_techno_eco ; writeheader = false)

  df_sources = DataFrame(Data_sources[Parameters_index[1]:end,Subsets_index[2]:end], :auto)
  techno_eco_sources = "Sources_$N_scen.csv"
  CSV.write(joinpath(Data_used_folder,techno_eco_sources),df_sources ; writeheader = false)

  #----------------------------Main results---------------------------

  R_capacity = zeros(U) ; R_prodcost_fuel = zeros(U) ; R_prodcost_fuel_GJ = zeros(U) ; R_prodcost_fuel_MWh = zeros(U) ;
  R_prodcost_perunit = zeros(U); R_year = Array{String,1}(undef,U) ; R_location = Array{String,1}(undef,U) ;
  R_fuel = Array{String,1}(undef,U) ; R_electrolyser = Array{String,1}(undef,U) ; R_production = zeros(U,S)
  R_CO2_capture = Array{String,1}(undef,U) ; R_profile = Array{String,1}(undef,U) ; R_overprod = zeros(U,S) ; R_underprod = zeros(U,S);
  R_scenario_name = Array{String,1}(undef,U); R_cost_overprod = zeros(U,S) ; R_cost_underprod = zeros(U,S)

  for u=1:U
    R_scenario_name[u] = Scenario_name
    R_year[u] = Year
    R_location[u] = Location
    R_profile[u] = Profile_name
    R_fuel[u] = Fuel
    R_electrolyser[u] = Electrolyser
    R_CO2_capture[u] = CO2_capture
    R_capacity[u] = JuMP.value.(Capacity[u])*10^-3 #In MW for unit producing electricity, in t/h for other units, in t for hydrogen storage, in MWh for batteries
    for s=1:S
      R_production[u,s] = sum(JuMP.value.(X[u,t,Scenarios_stoch[s]]) for t in Time)*10^-6 #In ktons ou GWh
      R_overprod[u,s] = sum(JuMP.value.(OverProd[p,Scenarios_stoch[s]]) for p=1:Numbers_of_period)*10^-6 #Sum of overproduction over the year
      R_underprod[u,s] = sum(JuMP.value.(UnderProd[p,Scenarios_stoch[s]]) for p=1:Numbers_of_period)*10^-6 #Sum of underproduction over the year
    end
  end

  for u in MainFuel
    R_prodcost_fuel[u] = (Optimum*Currency_factor)/((1/S)*sum(R_production[u,s] for s=1:S)*10^6)
    R_prodcost_fuel_GJ[u] = R_prodcost_fuel[u]*1000/Fuel_energy_content
    R_prodcost_fuel_MWh[u] = R_prodcost_fuel_GJ[u]*3.6
    for s=1:S
      if Demand_deviation_over != 0
        R_cost_overprod[u,s] = JuMP.dual.(Demand_dev_over[u,Scenarios_stoch[s]])
      end
      if Demand_deviation_under != 0
        R_cost_underprod[u,s] = JuMP.dual.(Demand_dev_under[u,Scenarios_stoch[s]])
      end
    end
  end

  df_results = DataFrame([R_scenario_name Name_selected_units R_year R_location R_profile R_fuel R_electrolyser R_CO2_capture R_capacity R_prodcost_fuel R_prodcost_fuel_GJ R_prodcost_fuel_MWh R_cost_overprod R_cost_underprod R_production R_overprod R_underprod], :auto)

  results = "Scenario_$N_scen.csv"

  Prod_s_num = Array{String}(undef,S)
  OverProd_s_num = Array{String}(undef,S)
  UnderProd_s_num = Array{String}(undef,S)
  Cost_overProd_s_num = Array{String}(undef,S)
  Cost_underProd_s_num = Array{String}(undef,S)
  for s=1:S
    Prod_s_num[s]= "Prod_S$s"
    OverProd_s_num[s]= "OverProd_S$s"
    UnderProd_s_num[s]= "UnderProd_S$s"
    Cost_overProd_s_num[s] = "CostOverProd_S$s"
    Cost_underProd_s_num[s] = "CostUnderProd_S$s"
  end

  Result_name = ["Scenario";"Type of unit";"Year data";"Location";"Profile";"Fuel";"Electrolyser";
  "CO2 capture";"Installed capacity(MW or t/h)";"Production cost fuel (Euros/kgfuel)";
  "Production cost fuel (Euros/GJfuel)"; "Production cost fuel (Euros/Mwhfuel)"; Cost_overProd_s_num ; Cost_underProd_s_num ; Prod_s_num ; OverProd_s_num ; UnderProd_s_num]

  rename!(df_results, Result_name)
  CSV.write(joinpath(Main_result_folder,results),df_results)
  CSV.write(joinpath(Main_all_results_folder,results),df_results)

  #---------------- Under and Overproduction -------------
  Infos = Array{String,1}(undef,T)
  Infos[1] = "Scenario: "*Scenario_name
  Infos[2] = "Year data: "*"$Year"
  Infos[2] = "Profile: "*Profile_name
  Infos[3] = "Location: "*Location
  Infos[4] = "Fuel: "*Fuel
  Infos[5] = "Electrolyser: "*Electrolyser
  Infos[6] = "CO2 capture: "*CO2_capture
  Infos[7] = "CO2taxWTTup: "*"$CO2taxWTTup"
  Infos[8] = "CO2taxWTTop: "*"$CO2taxWTTop"
  Infos[9] = "CO2WTTop_treshhold "*"$CO2WTTop_treshhold"
  Infos[10] = "Renewable criterion: "*Current_rencrit
  Infos[11] = "Renewable application: "*"$Criterion_application"

  for i=12:Numbers_of_period
    Infos[i] = " "
  end

  # Over and under prod
  Sol_overprod = zeros(Numbers_of_period,S)
  Sol_underprod = zeros(Numbers_of_period,S)
  for p=1:Numbers_of_period, s=1:S
    Sol_overprod[p,s] = JuMP.value.(OverProd[p,Scenarios_stoch[s]])*10^-6
    Sol_underprod[p,s] = JuMP.value.(UnderProd[p,Scenarios_stoch[s]])*10^-6
  end

  df_und_ov = DataFrame([Sol_overprod Sol_underprod], :auto)
  #Headlines
  Ovprod_Name = Array{String}(undef,S)
  Unprod_Name = Array{String}(undef,S)
  for s=1:S
      Ovprod_Name[s]= "OverProd_S$s"
      Unprod_Name[s]= "UnderProd_S$s"
  end
  rename!(df_und_ov,[Ovprod_Name;Unprod_Name])
  #File name
  UnderOverprod = "UO_$N_scen.csv"
  #Write the Csv file
  CSV.write(joinpath(Flows_result_folder,UnderOverprod),df_und_ov)


  #Results about under and over production


else
  println("No optimal solution available")
end

#global N_scen += 1 #Increment and run the script for another scenario

#end
