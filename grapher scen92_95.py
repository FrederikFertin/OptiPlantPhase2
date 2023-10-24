import pandas as pd
import matplotlib.pyplot as plt
#from tabulate import tabulate
import numpy as np
import os

# Set the global font size
plt.rcParams.update({'font.size': 13})

### Fuel Choice:
# "MeOH"
# "DME"
fuel = "DME"
grid = 0
ren_crit = 0

# Check if the files exist
scen = ((["99", "100", "101", "102"] if grid else ["95", "110", "97", "98"]) if fuel == "MeOH" else ["4", "5", "6"])
if grid and ren_crit: scen = ["103", "104", "105", "106"]

files = []
for i in scen:
    files.append(str("C:/Users/Frede/Documents/DTU/DTU_Man/OptiPlant-DME/MeOH/Results/Results_DME/Main results/Scenario_" + i + ".csv"))
#C:\Users\Frede\Documents\DTU\DTU_Man\OptiPlant-DME\MeOH\Results\Results_DME\Main results
#%% Data handling
unit_mask = 'Type of unit'

if fuel == "MeOH":
    if grid:
        units = ["MeOH - Biogas - SOEC",
                 "Biogas w H2",
                 "Biogas wo H2",
                 "Waste water plant",
                 "Electrolysers SOEC alone",
                 "Electrolysers AEC",
                 "H2 buried pipes",
                 "Solar tracking",
                 "OFF_SP450-HH150",
                 "Electricity from the grid",
                 "Batteries"]
        scenarios = ["BGtMeOH (SOEC)", "BGtMeOH (AEC)", "BGtMeOH (worst)",
                     "BGtMeOH (best)"]
        plot_title = "Grid-connected biogas based MeOH production"
        if ren_crit:
            scenarios = ["BGtMeOH - hgp", "BGtMeOH - lgp", "BGtMeOH - hgp_renewable",
                         "BGtMeOH - lgp_renewable"]
            plot_title = "Grid-connected biogas based MeOH production (2030)"
        ### For MeOH
        unitlist = ["Methanol plant",
                 "Biogas",
                 "Waste-water plant",
                 "Electrolysis plant",
                 "H2 buried pipes",
                 "Solar Farm",
                 "Offshore WF",
                 "Grid connection",
                 "Batteries",
                 "Electricity"]
        mainIx = 0
        unitIx = 1
    else:
        units = ["MeOH - Biogas - SOEC",
                 "Biogas w H2",
                 "Biogas wo H2",
                 "Waste water plant",
                 "Electrolysers SOEC alone",
                 "Electrolysers AEC",
                 "H2 buried pipes",
                 "Solar tracking",
                 "OFF_SP450-HH150"]
        scenarios = ["BG (357 €/t) - SOEC", "BG (357 €/t) - AEC", "BG (507 €/t) - SOEC",
                     "BG (277 €/t) - SOEC"]
        ### For MeOH
        unitlist = ["Methanol plant",
                 "Biogas",
                 "Wastewater treat. plant",
                 "Electrolysis plant",
                 "H2 buried pipes",
                 "Solar Farm",
                 "Wind Farm"]
        mainIx = 0
        unitIx = 1
        plot_title = "Islanded biogas based MeOH production"
elif fuel == "DME":
    units = ["Bamboo2-stage-SOEC",
             "Bamboo1-stage-SOEC",
             "Wheat2-stage-SOEC",
             "Wheat1-stage-SOEC",
             "Biomass bamboo 2",
             "Biomass bamboo 1",
             "Biomass wheat 2",
             "Biomass wheat 1",
             "Sale of biochar",
             "Desalination plant",
             "Electrolysers SOEC heat integrated",
             "H2 buried pipes",
             "Solar tracking",
             "OFF_SP450-HH150"]
    scenarios = ["Wheat (92.8 €/t)", "Wheat (72.5 €/t)", "Wheat (132.0 €/t)"]
    ### For DME
    unitlist = ["Straw",
             "DME plant",
             "Waste water plant",
             "Electrolysis plant",
             "H2 buried pipes",
             "Solar Farm",
             "Wind Farm"]
    mainIx = 1
    unitIx = 0
    plot_title = "Islanded biomass based DME production"



# units = ["Methanol plant",
#          "Wastewater treat. plant",
#          "Electrolysis plant",
#          "H2 buried pipes",
#          "Solar Farm",
#          "Wind Farm"]





cols = ['Type of unit',
        'Annualised investment(MEuros)',
        'Fixed O&M(MEuros)',
        'Production cost per unit (Euros/kg or kWh output)',
        'Production cost fuel (Euros/kgfuel)',
        'Production cost fuel (Euros/MWhfuel)',
        'Production(kton or GWh)',
        'Total investment(MEuros)',
        'Installed capacity(MW or t/h)']

data = []
for f in files:
    data.append(pd.read_csv(f))

a_cost = []
f_cost = []
e_cost = []
for i,d in enumerate(data):
    data[i] = d[pd.DataFrame(d[unit_mask].tolist()).isin(units).any(1).values][cols]
    a_cost.append(data[i][cols[1]]+data[i][cols[2]])
    # Unit of biogas cost is in M€:
    if fuel == 'MeOH':
        f_cost.append(
            data[i].loc[data[i]['Type of unit']=='Biogas w H2','Production cost per unit (Euros/kg or kWh output)'].values[0]\
                * data[i].loc[data[i]['Type of unit']=='Biogas w H2','Production(kton or GWh)'].values[0])
    elif fuel == 'DME':
        f_cost.append(
            data[i]['Production cost per unit (Euros/kg or kWh output)'].iloc[0]\
                * data[i]['Production(kton or GWh)'].iloc[0])
    if grid: # Unit of electricity cost is in M€:
        e_cost.append(
            data[i].loc[data[i]['Type of unit']=='Electricity from the grid','Production cost per unit (Euros/kg or kWh output)'].values[0]\
                * data[i].loc[data[i]['Type of unit']=='Electricity from the grid','Production(kton or GWh)'].values[0])





costs = pd.DataFrame(columns=unitlist,index=scenarios)
for i in range(len(scen)):
    for j in range(len(unitlist)):
        if grid and j == len(unitlist)-1:
            costs[unitlist[j]].iloc[i] = e_cost[i]
        elif j == unitIx:
            costs[unitlist[j]].iloc[i] = f_cost[i]
        else:
            costs[unitlist[j]].iloc[i] = a_cost[i].iloc[j]

prod = data[0]['Production(kton or GWh)'].iloc[1]

#%% Plotting
# Define the colors for each bar
colors = ["green", "lime", "cyan", "brown", "pink", "yellow","darkblue","red", "gray", "purple",  "orange"]

# ... [the rest of your code is unchanged]

# Create a stacked bar plot
plt.figure(figsize=(12, 7))

# To stack values in one bar, we use bottom argument in plt.bar() to specify from where to start
bottom = [0]*len(scen)
ax1 = plt.gca() # Store reference to the original y-axis
for i, unit in enumerate(unitlist):
    plt.bar(scenarios, costs.iloc[:, i].values, bottom=bottom, color=colors[i])
    bottom = [sum(x) for x in zip(bottom, list(costs.iloc[:, i]))]

####################################################################################################################

# Add a second y-axis
#ax2 = ax1.twinx()

# Define the y-values for the dots
fuel_production_costs = []
fuel_production_costs_mwh = []
for i in range(len(scen)):
    fuel_production_costs.append(data[i]['Production cost fuel (Euros/kgfuel)'].iloc[mainIx]*1000)
    fuel_production_costs_mwh.append(data[i]['Production cost fuel (Euros/MWhfuel)'].iloc[mainIx])

# Scatter plot on the second y-axis
#ax2.scatter(scenarios, fuel_production_costs, color='black', s=5000, marker = '_')

# Set labels for y-axes
ax1.set_ylabel('Total annualized cost [M€/yr]')
#ax2.set_ylabel('LCOF [€/t]')

# Set the range and step size for y-axes
ax1.set_ylim([0,max(bottom)*1.05])
#ax1.yaxis.set_ticks(np.arange(0, 401, 50))
#ax2.set_ylim([0, max(fuel_production_costs)*1.05])
#ax2.yaxis.set_ticks(np.arange(0, 401, 500))

# Add numbers (or text in this case) on top of each dot
for i, txt in enumerate(fuel_production_costs):
    ax1.text(i, max(bottom)/4,
             str(str(round(txt,1)) + "€/t\n(" +
                 str(round(fuel_production_costs_mwh[i],2)) + "€/MWh)"),
             ha='center', va='bottom')

ax1.set_xlabel('Scenarios', labelpad=20)  # Setting the x-label using the axes object
plt.title(plot_title)
ax1.grid(axis='y')
ax1.legend(unitlist, loc='upper left',bbox_to_anchor=(1,1)) # Moved the legend to the right side
ax1.set_xticks(np.arange(len(scenarios)))  # Explicitly setting the x-ticks positions
ax1.set_xticklabels(scenarios, rotation=45)  # Rotating the x-tick labels by 45 degrees
plt.subplots_adjust(bottom=0.15, right=0.75)
plt.show()


