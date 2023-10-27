using JuMP, Gurobi, CSV, DataFrames

#Open julia terminal: Alt J Alt O 

#------------------------------Problem set up------------------------------------
<<<<<<< HEAD
#Project name!
Project = "MeOH"
=======
#Project name
Project = "NH3"
>>>>>>> 2210b3d2bdfdc4495032e1369a32c8ef9ed84d9d
# Folder name for all csv file
all_csv_files = "All_results"
# Folder paths for data acquisition and writing
Main_folder = "C:/Users/Frede/Documents/DTU/DTU_Man/OptiPlant-DME" ;
Profiles_folder = joinpath(Main_folder,Project,"Data","Profiles") ;
Inputs_folder = joinpath(Main_folder,Project,"Data","Inputs") ; 
Inputs_file = "DME_paper_data" #DME_paper_data" #"Bornholm_All_data" DME_paper_data

# Scenario set (same name as excel sheet)
Scenarios_set =  "Scenarios_DME" ; include("ImportScenarios.jl") #"Scenarios_stoch"
# Scenario under study (all between N_scen_0 and N_scen_end)
N_scen_0 = 1 ; N_scen_end = 4 # or N_scen_end = N_scenarios for total number of scenarios
#Studied hours (max 8760). When there is maintenance hours are out
#TMend = 4000-4876 : 90% time working ; T = 4000-4761 : 8000 hours
#TMstart = 4675 ; TMend = 5036 ; Tfinish= 8736 #43848 52608 #Time maintenance starts/end ; Tbegin: Time within plants can operate at 0% load (in case of no renewable power the first 3 days)
#Time = vcat(collect(1:TMstart),collect(TMend:Tfinish)) ; T = length(Time)
#Tstart = vcat(collect(1:TMstart),collect(TMend:Tfinish)) ;

#Studied hours (max 8760). When there is maintenance hours are out

#TMend = 4000-4876 : 90% time working ; T = 4000-4761 : 8000 hours

TMstart = 4675 ; TMend = 5011 ; Tbegin = 72 ; Tfinish=8760 #Time maintenance starts/end ; Tbegin: Time within plants can operate at 0% load (in case of no renewable power the first 3 days)

Time = vcat(collect(1:TMstart),collect(TMend:Tfinish)) ; T = length(Time)

Tstart = vcat(collect(1:TMstart),collect(TMend:Tfinish)) ;

if Tbegin >= 2

  splice!(Tstart,1:Tbegin) # Time within plants can operate at 0% load (in case of no renewable power the first 3 days)

end

Currency_factor = 1 # 1.12 for dollar 2019 #All input data are in Euro 2019

# Number of step in the electrolyser piecewise linear optimisation
N = 1

#=
#Change yearly demand target into periodic demand targets (weekly, monthly, etc...)
Hours_per_period = 7884 #8424 with two weeks maintenance at the end of the year #7884 for 90% availability
Numbers_of_period = 1
T = Hours_per_period*Numbers_of_period 
Time = collect(1:T)
Time_demand_target = transpose(reshape(collect(1:T),Hours_per_period,Numbers_of_period))
T_period = [collect(row) for row in eachrow(Time_demand_target)]
Tstart = collect(1:T)

Tbegin = 72 
if Tbegin >= 2
  splice!(Tstart,1:Tbegin) # Time within plants can operate at 0% load (in case of no renewable power the first 3 days)
end
=#

#--------------------- Main code -------------------------
N_scen = N_scen_0

while N_scen < N_scen_end + 1 #Run the optimization model for all scenarios

include("ImportData.jl") # Import data
Flows_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Flows") ; mkpath(Flows_result_folder)
Sold_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Sold") ; mkpath(Sold_result_folder)
Bought_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Bought") ; mkpath(Bought_result_folder)
Main_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Main results") ; mkpath(Main_result_folder)
Main_all_results_folder = joinpath(Main_folder,Project,"Results",all_csv_files,"Main results") ; mkpath(Main_all_results_folder)
Data_used_folder = joinpath(Main_folder,Project,"Results",csv_files,"Data used") ; mkpath(Data_used_folder)
#-----------------------------------Model----------------------------------
Model_LP_PW = Model(Gurobi.Optimizer)

#Decision variables
@variable(Model_LP_PW,Costs) # In €2019
@variable(Model_LP_PW,Emissions) # In kg CO2e
@variable(Model_LP_PW,X[1:U,t in Time] >= 0) # Products and energy flow (kg/h or kW)
@variable(Model_LP_PW,Xpwl[u in PWL,t in Time,1:N]>=0) # Piece-wise flows
@variable(Model_LP_PW,Capacity[1:U] >=0) #  Production capacity of each unit (kg/h or kW)
@variable(Model_LP_PW,Sold[1:U,t in Time] >= 0) # Quantity of products sold (kg/h or kW)
@variable(Model_LP_PW,Bought[1:U,t in Time] >= 0) # Quantity of input bought (kg/h or kW)


# Set higher bound to 0 for not used units
for t in Time, u in NoPWL
  if Used_Unit[u]==0
    @constraint(Model_LP_PW,X[u,t] <= 0)
    @constraint(Model_LP_PW,Capacity[u] <= 0)
    @constraint(Model_LP_PW,Sold[u,t] <= 0)
    @constraint(Model_LP_PW,Bought[u,t] <= 0)
  end
end

for t in Time, u in PWL
  if Used_Unit[u]==0
    @constraint(Model_LP_PW,Xpwl[u,t,n]<=0)
  end
end


#Minimize the total cost and/or CO2e emissions of the system
@objective(Model_LP_PW, Min, Weight_costs*Costs + Weight_emissions*Emissions)

#Costs equation in €2019
@constraint(Model_LP_PW, Costs == sum(Fuel_Buying_fixed[u]*Bought[u,t] for u=1:U, t in Time)
+ sum(Price_Profile[Grid_buy_p[u],t]*Bought[Grid_buy[u],Time[t]]*Renewable_criterion_profile[t] for u=1:nGb,t=1:T) #Price of certified electricity
+ sum((Price_Profile[Grid_buy_p[u],t]+NonRenCostPenalty)*Bought[Grid_buy[u],Time[t]]*(1-Renewable_criterion_profile[t]) for u=1:nGb,t=1:T) #Price of non-certified electricity
+ sum(Price_Profile[Heat_buy_p[u],t]*Bought[Heat_buy[u],Time[t]] for u=1:nHb,t=1:T)
+ sum(CO2taxWTTop*CO2_Profile[Grid_CO2_counted_p[u],t]*Bought[Grid_buy[u],Time[t]] for u=1:nGCO2tax,t=1:T)
+ sum((Invest[u]*Annuity_factor[u] + FixOM[u] + CO2taxWTTup*CO2_inf[u])*Capacity[u] for u=1:U)
+ sum((VarOM[u] + CO2taxWTTop*CO2_proc_fixed[u])*X[u,t] for u=1:U,t in Time)
- sum(Fuel_Selling_fixed[u]*Sold[u,t] for u=1:U,t in Time)
- sum(Price_Profile[Grid_sell_p[u],t]*Sold[Grid_sell[u],Time[t]] for u=1:nGs,t=1:T) # Hourly sale of electricity (varying price)
- sum(Price_Profile[Heat_sell_p[u],t]*Sold[Heat_sell[u],Time[t]] for u=1:nHs,t=1:T)  # Hourly sale of heat (varying price)
)
#"Total" emissions count equation in kg CO2e per year
@constraint(Model_LP_PW, Emissions == sum(CO2_Profile[Grid_CO2_emitted_p[u],t]*Bought[Grid_buy[u],Time[t]] for u=1:nGCO2em,t=1:T)
+ sum(CO2_inf[u]*Capacity[u] for u=1:U)
+ sum(CO2_proc_fixed[u]*X[u,t] for u=1:U,t in Time))

#Enforcement of a maximum WTT operational emissions over a year in kg CO2e, Treshold also mean that grid electricity intensity is below x value.
if CO2WTTop_treshhold >= 0
  @constraint(Model_LP_PW, sum(CO2_Profile[Grid_CO2_counted_p[u],t]*Bought[Grid_buy[u],Time[t]] for u=1:nGCO2tax,t=1:T)
  + sum(CO2_proc_fixed[u]*X[u,t] for u=1:U,t in Time) <= CO2WTTop_treshhold*Fuel_energy_content*sum(Sold[i,t] for t in Time, i in MinD))
end

#Enforcement of renewable criterion satisfied at all time
#--> Can't never take from the grid when renewable criterion is 0 (i.e. considered as non renewable)

if Criterion_application == -1
  @constraint(Model_LP_PW,[u=1:nGb, t=1:T], Bought[Grid_buy[u],Time[t]] <= Renewable_criterion_profile[t]*X[Grid_buy[u],Time[t]])
end

#Demand constraint
if Option_demand == true
  #Demand_targets = zeros(1,Numbers_of_period)
  #for i = 1:1, p =1:Numbers_of_period
  #  Demand_targets[i,p] = Demand[MinD[i]]/Numbers_of_period
  #end
  #Periodic demand 
  #@constraint(Model_LP_PW,[i=1:nMinD, p=1:Numbers_of_period], sum(Sold[MinD[i],t] for t in T_period[p] ) == Demand_targets[i,p])
  #Yearly demand: have to fullfill min yearly demand if there is one
  @constraint(Model_LP_PW,[i in MinD], sum(Sold[i,t] for t in Time) == Demand[i])

  if Option_connection_limit == true
    #Hourly electricity/heat available: can't get electricity/heat from the grid when there is no excess production
    @constraint(Model_LP_PW,[i=1:nGe,t=1:T], X[Grid_in[i],Time[t]] <= Flux_Profile[Grid_excess[i],t])
    @constraint(Model_LP_PW,[i=1:nHe,t=1:T], X[Heat_in[i],Time[t]] <= Flux_Profile[Heat_excess[i],t])
    #Can't export electricity/heat to the grid when there is no external electricity/heat demand
    @constraint(Model_LP_PW,[i=1:nGd, t=1:T],X[Grid_out[i],Time[t]] <= Flux_Profile[Grid_deficit[i],t])
    @constraint(Model_LP_PW,[i=1:nHd, t=1:T],X[Heat_out[i],Time[t]] <= Flux_Profile[Heat_deficit[i],t])
  end
end

#Capacity constraints

if Option_max_capacity == true
  @constraint(Model_LP_PW,[u=1:U], Capacity[u] <= Max_Cap[u]) #Maximal capacity that can be installed
end

#Load constraints: n differents steps, 0-25, 25-50, 50-75, 75-100

@constraint(Model_LP_PW,[u in PWL, t in Time], sum(Xpwl[u,t,n] for n=1:N) == X[u,t])
@constraint(Model_LP_PW,[u in PWL,t in Time,n=1:N], Xpwl[u,t,n] <= Capacity[u]*(1/N))

@constraint(Model_LP_PW,[u=1:U,t in Tstart], X[u,t] >= Capacity[u]*Load_min[u]) #Min flow
@constraint(Model_LP_PW,[u=1:U,t in Time], X[u,t] <= Capacity[u]) #Max flow

#Ramping constraints
if Option_ramping == true

  @constraint(Model_LP_PW,[u=1:U,t=1:T], X[u,Time[t]]-(t>Time[1] ? X[u,Time[t-1]] : 0) <= Ramp_up[u]*Capacity[u])
  @constraint(Model_LP_PW,[u=1:U,t=1:T], (t>Time[1] ? X[u,Time[t-1]] : 0)-X[u,Time[t]] <= Ramp_down[u]*Capacity[u])

end

# Productions rates
@constraint(Model_LP_PW,[i=1:nProd,t in Time], X[Products[i],t] == X[Reactants[i],t]*Prod_rate[Products[i]])
# Hydrogen balance
@constraint(Model_LP_PW,[t in Time],sum(H2_balance[u]*X[u,t] for u=1:U)==0)
# District heat balance
@constraint(Model_LP_PW,[t in Time],sum(Heat_balance[u]*Heat_generated[u]*X[u,t] for u=1:U)==0)
# Process heat balance
@constraint(Model_LP_PW,[t in Time],sum(Process_heat_balance[u]*Process_heat_generated[u]*X[u,t] for u=1:U)==0)
# CSP balance
@constraint(Model_LP_PW,[t in Time], sum(CSP_balance[u]*X[u,t] for u=1:U)==0)
# Storages balance
@constraint(Model_LP_PW,[i=1:nST,t=1:T], X[Tanks[i],Time[t]] == (t>Time[1] ? X[Tanks[i],Time[t-1]] : 0) + X[Stor_in[i],Time[t]] - X[Stor_out[i],Time[t]])

# Renewable energy production constraint (profile dependent)
@constraint(Model_LP_PW, [i = 1:nRPU,t=1:T], X[RPU[i],Time[t]] == Flux_Profile[RPU_p[i],t]*Capacity[RPU[i]])

# Electricity produced and consumed have to be at equilibrium (Production = Consumption)
@constraint(Model_LP_PW, [t in Time], sum(El_balance[u]*X[u,t] for u=1:U) ==
sum(Sc[u,n]*Xpwl[u,t,n] for u in PWL, n=1:N) + sum(Sc_nom[u]*X[u,t] for u in NoPWL))


# Sold and bought ouputs/inputs
@constraint(Model_LP_PW,[u=1:U,t in Time],Sold[u,t] <= X[u,t]) # Have to sell less than what is produced
@constraint(Model_LP_PW,[u=1:U,t in Time],Bought[u,t] == X[u,t]) # Have to buy exactly what you use

# solve
optimize!(Model_LP_PW)

#--------------------------Results output------------------------------------------
if termination_status(Model_LP_PW) == MOI.OPTIMAL
  #Optimum = objective_value(Model_LP_PW)
  #println("Fuel production cost = $(Optimum/Demand[1])")
  #println(JuMP.value.(Capacity))

  #----------------Variable flows and total specific consumption -------------
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

  for i=12:T
    Infos[i] = " "
  end

  if Write_flows == true
    #Total electricity consumption
    Sc_tot = zeros(T)
    for t=1:T
        Sc_tot[t] = sum(Sc[u,n]*JuMP.value.(Xpwl[u,Time[t],n]) for u in PWL, n=1:N) + 
        sum(Sc_nom[u]*JuMP.value.(X[u,Time[t]]) for u in NoPWL)
    end
    # Flows
    Solution_X = zeros(T,U)
    Solution_Xpwl_ely = zeros(T,N)
    for u=1:U, t=1:T
        Solution_X[t,u] = JuMP.value.(X[u,Time[t]])
    end
    for t=1:T, n=1:N
        Solution_Xpwl_ely[t,n] = JuMP.value.(Xpwl[PWL[1],Time[t],n])
    end
    df_flow = DataFrame([Infos Time Solution_X Solution_Xpwl_ely Sc_tot Renewable_criterion_profile], :auto)
    #Headlines
    Piece_Name = Array{String}(undef,N)
    for n=1:N
        Piece_Name[n]= "Xpwl$n"
    end
    rename!(df_flow,["Informations";"Time";Unit_tag;Piece_Name;"Electricity consumption";"Certified grid electricity"])
    #File name
    flows = "F_$N_scen.csv"
    #Write the Csv file
    CSV.write(joinpath(Flows_result_folder,flows),df_flow)
  end
  #----------------Variable sold ---------------------------------
  if Write_sold_products == true
      Solution_Sold = zeros(T,U)
      for u=1:U, t=1:T
          Solution_Sold[t,u] = JuMP.value.(Sold[u,Time[t]])
      end
      #Data frame definition
      df_sold = DataFrame([Infos Time Solution_Sold], :auto)
      #Headlines
      rename!(df_sold, ["Informations";"Time";Unit_tag])
      #File name
      sold = "S_$N_scen.csv"
      #Write the Csv file
      CSV.write(joinpath(Sold_result_folder,sold),df_sold)
  end

  #----------------Variable fuel cost (~ bought)---------------------------------
  if Write_fuel_cost == true
      #Data frame definition
      Fuel_cost= zeros(U,T)
      Fuel_cost_t_ren = zeros(U,T)
      Fuel_cost_t_noren = zeros(U,T)
      Solution_Bought = zeros(T,U)
      for u=1:U, t=1:T
        Solution_Bought[t,u] = JuMP.value.(Bought[u,Time[t]])
      end
  
      for u=1:nGb, t=1:T
          Fuel_cost_t_ren[Grid_buy[u],t] = Price_Profile[Grid_buy_p[u],t]*JuMP.value.(Bought[Grid_buy[u],Time[t]])*Renewable_criterion_profile[t]*Currency_factor #Price of certified electricity
          Fuel_cost_t_noren[Grid_buy[u],t] = (Price_Profile[Grid_buy_p[u],t]+NonRenCostPenalty)*JuMP.value.(Bought[Grid_buy[u],Time[t]])*(1-Renewable_criterion_profile[t])*Currency_factor #Price of non-certified electricity
      end
      for u=1:nHb, t=1:T
          Fuel_cost_t_ren[Heat_buy[u],t] = Price_Profile[Heat_buy_p[u],t]*JuMP.value.(Bought[Heat_buy[u],Time[t]])*Currency_factor
      end
      for u=1:U, t=1:T
          Fuel_cost[u,t] = Fuel_cost_t_ren[u,t] + Fuel_cost_t_noren[u,t] + Fuel_Buying_fixed[u]*JuMP.value.(Bought[u,Time[t]])*Currency_factor
      end
      df_fuel_cost = DataFrame([Infos Time transpose(Fuel_cost_t_ren) transpose(Fuel_cost_t_noren) transpose(Fuel_cost) Solution_Bought], :auto)
      #Headlines
      rename!(df_fuel_cost, ["Informations";"Time";Unit_tag.*"Ren";Unit_tag.*"NoRen";Unit_tag.*"tot";Unit_tag.*"Bought"])
      #File name
      fuel_cost = "FC_$N_scen.csv"
      #Write the Csv file
      CSV.write(joinpath(Bought_result_folder,fuel_cost),df_fuel_cost)
  end
  #-----------------------Techno_economical data and sources used------------------------

  df_techno_eco = DataFrame(Data_units[Parameters_index[1]:end,Subsets_index[2]:end], :auto)
  techno_eco = "Data_$N_scen.csv"
  CSV.write(joinpath(Data_used_folder,techno_eco),df_techno_eco ; writeheader = false)

  df_sources = DataFrame(Data_sources[Parameters_index[1]:end,Subsets_index[2]:end], :auto)
  techno_eco_sources = "Sources_$N_scen.csv"
  CSV.write(joinpath(Data_used_folder,techno_eco_sources),df_sources ; writeheader = false)

  #----------------------------Main results---------------------------

  R_fuelprice = zeros(U) ; R_fuelprice_t = zeros(U) ; R_fixOM = zeros(U) ; R_varOM = zeros(U) ;
  R_invest = zeros(U) ; R_invest_year = zeros(U) ; R_production = zeros(U) ;
  R_TotCO2tax_up = zeros(U) ; R_TotCO2tax_op = zeros(U); R_CO2WTTop_treshhold = zeros(U) ; R_sold = zeros(U);
  R_fuelsold_t = zeros(U) ; R_prodcost = zeros(U) ; R_capacity = zeros(U) ;
  R_El_cons = zeros(U) ; R_costs = zeros(U) ; R_cost_unit = zeros(U) ;
  R_load_av = zeros(U) ; R_FLH = zeros(U) ; R_prodcost_fuel = zeros(U) ;
  R_prodcost_fuel_GJ = zeros(U) ; R_prodcost_fuel_MWh = zeros(U) ;
  R_prodcost_perunit = zeros(U); R_year = Array{String,1}(undef,U) ; R_location = Array{String,1}(undef,U) ;
  R_fuel = Array{String,1}(undef,U) ; R_electrolyser = Array{String,1}(undef,U) ;
  R_CO2_capture = Array{String,1}(undef,U) ; R_profile = Array{String,1}(undef,U) ;
  R_CO2taxWTTop = zeros(U) ; R_CO2taxWTTup = zeros(U) ; R_rencrit = Array{String,1}(undef,U) ; 
  R_crit_app = zeros(U) ; R_CO2_proc_t = zeros(U) ; R_CO2_proc_count_t = zeros(U) ; 
  R_CO2_tot = zeros(U) ; R_CO2_counted = zeros(U) ; R_CO2_perunitfuel = zeros(U) ; R_CO2_perunitfuel_count = zeros(U)
  R_CO2_totalperGJ = zeros(U) ; R_CO2_totalperGJ_count = zeros(U) ; 
  R_elec_cost = zeros(U) ; R_scenario = Array{String,1}(undef,U);
  R_Weight = Array{String,1}(undef,U); R_land_use = zeros(U) ;
  R_land_use_perunitfuel = zeros(U) ; R_land_use_totperGJ = zeros(U)

  for u=1:nGb
    R_fuelprice_t[Grid_buy[u]] = sum(Price_Profile[Grid_buy_p[u],t]*JuMP.value.(Bought[Grid_buy[u],Time[t]])*Renewable_criterion_profile[t] for t=1:T)*10^-6*Currency_factor + 
    sum(Price_Profile[Grid_buy_p[u],t]*JuMP.value.(Bought[Grid_buy[u],Time[t]])*(1-Renewable_criterion_profile[t]) for t=1:T)*10^-6*Currency_factor
  end
  for u=1:nHb
    R_fuelprice_t[Heat_buy[u]] = sum(Price_Profile[Heat_buy_p[u],t]*JuMP.value.(Bought[Heat_buy[u],Time[t]]) for t=1:T)*10^-6*Currency_factor
  end
  if Option_hourly_elec_sale == true
    for u=1:nGs
      R_fuelsold_t[Grid_sell[u]] = sum(Price_Profile[Grid_sell_p[u],t]*JuMP.value.(Sold[Grid_sell[u],Time[t]]) for t=1:T)*10^-6*Currency_factor
    end
  end
  if Option_hourly_heat_sale == true
    for u=1:nHs
      R_fuelsold_t[Heat_sell[u]] = sum(Price_Profile[Heat_sell_p[u],t]*JuMP.value.(Sold[Heat_sell[u],Time[t]]) for t=1:T)*10^-6*Currency_factor
    end
  end
  for u=1:nGCO2em
    R_CO2_proc_t[Grid_in[u]] = sum(CO2_Profile[Grid_CO2_emitted_p[u],t]*JuMP.value.(Bought[Grid_buy[u],Time[t]]) for t=1:T)*10^-3 #Total of grid emitted CO2 emissions in ton
    R_CO2_proc_count_t[Grid_in[u]] = sum(CO2_Profile[Grid_CO2_counted_p[u],t]*JuMP.value.(Bought[Grid_buy[u],Time[t]]) for t=1:T)*10^-3 #Total of grid accounted CO2 emissons in ton
  end
  for u=1:U
      R_scenario[u] = Scenario_name
      R_year[u] = Year
      R_location[u] = Location
      R_profile[u] = Profile_name
      R_fuel[u] = Fuel
      R_electrolyser[u] = Electrolyser
      R_CO2_capture[u] = CO2_capture
      R_CO2taxWTTup[u] = CO2taxWTTup
      R_CO2taxWTTop[u] = CO2taxWTTop
      R_CO2WTTop_treshhold[u] = CO2WTTop_treshhold
      R_rencrit[u] = Current_rencrit
      R_crit_app[u] = Criterion_application
      R_Weight[u] = "C$Weight_costs"*"_"*"E$Weight_emissions"
      R_capacity[u] = JuMP.value.(Capacity[u])*10^-3 #In MW for unit producing electricity, in t/h for other units, in t for hydrogen storage, in MWh for batteries
      R_invest[u] = Invest[u]*JuMP.value.(Capacity[u])*10^-6*Currency_factor #In M€
      R_invest_year[u] = R_invest[u]*Annuity_factor[u] #Annulized investment in M€
      R_fixOM[u] = FixOM[u]*JuMP.value.(Capacity[u])*10^-6*Currency_factor #In M€
      R_varOM[u] = sum(VarOM[u]* JuMP.value.(X[u,t]) for t in Time)*10^-6*Currency_factor #In M€
      R_TotCO2tax_up[u] = CO2taxWTTup*CO2_inf[u]*JuMP.value.(Capacity[u])*10^-6*Currency_factor #Expenses due to CO2 tax on infrastructure in M€
      R_TotCO2tax_op[u] = sum(CO2taxWTTop*CO2_proc_fixed[u]*JuMP.value.(X[u,t]) for t in Time)*10^-6*Currency_factor + CO2taxWTTop*R_CO2_proc_t[u]*10^-3*Currency_factor #Expenses due to CO2 tax on operational emissions in M€
      R_fuelprice[u] = sum(Fuel_Buying_fixed[u]*JuMP.value.(Bought[u,t]) for t in Time)*10^-6*Currency_factor + R_fuelprice_t[u] # In M€
      R_production[u] = sum(JuMP.value.(X[u,t]) for t in Time)*10^-6 #In ktons ou GWh
      R_sold[u] = - sum(Fuel_Selling_fixed[u]*JuMP.value.(Sold[u,t]) for t in Time)*10^-6*Currency_factor + R_fuelsold_t[u]
      R_cost_unit[u] = R_invest_year[u] + R_fixOM[u] + R_varOM[u] + R_fuelprice[u] + R_sold[u] + R_TotCO2tax_up[u] + R_TotCO2tax_op[u]
      R_load_av[u] = sum(JuMP.value.(X[u,t])/JuMP.value.(Capacity[u]) for t in Time)*1/T
      R_FLH[u] = R_load_av[u]*T
      R_land_use[u] = Land_use[u]*JuMP.value.(Capacity[u])*10^-6 # Surface occupied in km2
      if R_production[u] == 0
        R_prodcost_perunit[u] = 0
      else
        R_prodcost_perunit[u] = R_cost_unit[u]/R_production[u]
      end
      R_CO2_tot[u] = R_capacity[u]*CO2_inf[u] + R_production[u]*CO2_proc_fixed[u]*10^3 + R_CO2_proc_t[u]
      R_CO2_counted[u] = R_production[u]*CO2_proc_fixed[u]*10^3 + R_CO2_proc_count_t[u]
  end
  for u=1:U
    R_CO2_perunitfuel[u] = R_CO2_tot[u]/(sum(R_production[i] for i in MainFuel)*Fuel_energy_content) #kgCO2e/GJ
    R_CO2_perunitfuel_count[u] = R_CO2_counted[u]/(sum(R_production[i] for i in MainFuel)*Fuel_energy_content) #kgCO2e/GJ
    R_land_use_perunitfuel[u] = R_land_use[u]/(sum(R_production[i] for i in MainFuel)*Fuel_energy_content) #km2/GJ
  end
  Sum_km2 = sum(R_land_use[u] for u=1:U)
  Sum_CO2 = sum(R_CO2_tot[u] for u=1:U)
  Sum_CO2_count = sum(R_CO2_counted[u] for u=1:U)
  for u in MainFuel
    R_prodcost_fuel[u] = (JuMP.value.(Costs)*10^-6*Currency_factor)/R_production[u]
    R_prodcost_fuel_GJ[u] = R_prodcost_fuel[u]*1000/Fuel_energy_content
    R_prodcost_fuel_MWh[u] = R_prodcost_fuel_GJ[u]*3.6

    R_CO2_totalperGJ[u] = Sum_CO2/(R_production[u]*Fuel_energy_content) #kgCO2e/GJ
    R_CO2_totalperGJ_count[u] = Sum_CO2_count/(R_production[u]*Fuel_energy_content) #kgCO2e/GJ
    R_land_use_totperGJ[u] = Sum_km2/(R_production[u]*Fuel_energy_content) #km2/GJ
  end
  for u in NoPWL
      R_El_cons[u] = sum(Sc_nom[u]*JuMP.value.(X[u,t]) for t in Time)*10^-6
  end
  for u in PWL
      R_El_cons[u] = sum(Sc[u,n]*JuMP.value.(Xpwl[u,t,n]) for t in Time,n=1:N)*10^-6
  end
  R_elec_cost_1 = 10^3*sum(R_prodcost_perunit[u]*R_production[u] for u in PU)/sum(R_production[u] for u in PU)
  for u=1:U
    R_elec_cost[u] = R_elec_cost_1
  end

  df_results = DataFrame([R_scenario, Name_selected_units, R_year,R_location, R_profile, 
  R_fuel,R_electrolyser,R_CO2_capture, R_CO2taxWTTup, R_CO2taxWTTop, R_Weight, R_CO2WTTop_treshhold, R_rencrit, R_crit_app,
  R_capacity, R_invest, R_invest_year, R_fixOM, R_varOM, R_TotCO2tax_up,
  R_TotCO2tax_op, R_fuelprice, R_cost_unit, R_production,R_sold, R_El_cons,
  R_prodcost_fuel, R_prodcost_fuel_GJ, R_prodcost_fuel_MWh,R_prodcost_perunit,
  R_load_av, R_FLH,R_CO2_perunitfuel, R_CO2_perunitfuel_count, R_CO2_totalperGJ, R_CO2_totalperGJ_count,
  R_land_use,R_land_use_perunitfuel,R_land_use_totperGJ,R_elec_cost], :auto)
  results = "Scenario_$N_scen.csv"
  Result_name = ["Scenario","Type of unit","Year data","Location","Profile","Fuel","Electrolyser",
  "CO2 capture","CO2 tax level upstream (Eur/kgCO2)","CO2 tax level operational(Eur/kgCO2)", "Weight costs vs emissions", 
  "Max yearly emission treshhold", "Renewable criterion", "Criterion application",
  "Installed capacity(MW or t/h)","Total investment(MEuros)",
  "Annualised investment(MEuros)", "Fixed O&M(MEuros)", "Variable O&M(MEuros)",
  "CO2 tax infrastructure (MEuros)", "CO2 tax process (MEuros)",
  "Fuel cost(MEuros)","Cost per unit(MEuros)","Production(kton or GWh)","Sale (MEuros)",
  "Electricity consumption(GWh)", "Production cost fuel (Euros/kgfuel)",
  "Production cost fuel (Euros/GJfuel)","Production cost fuel (Euros/MWhfuel)",
  "Production cost per unit (Euros/kg or kWh output)", "Load average","Full load hours",
  "CO2e per unit total (kgCO2e/GJfuel)","CO2e per unit counted (kgCO2e/GJfuel)",
  "CO2e total all system (kg CO2e/GJfuel)", "CO2e counted all system (kg CO2e/GJfuel)", 
  "Land use per unit (km2)","Land use per unit (km2/GJfuel)","Land use total system (km2/GJfuel)","Av electricity cost(Euros/MWh)"]
  rename!(df_results, Result_name)
  CSV.write(joinpath(Main_result_folder,results),df_results)
  CSV.write(joinpath(Main_all_results_folder,results),df_results)
else
  println("No optimal solution available")
end

global N_scen += 1 #Increment and run the script for another scenario

end
