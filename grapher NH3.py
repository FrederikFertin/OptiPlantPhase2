import pandas as pd
import matplotlib.pyplot as plt
#from tabulate import tabulate
import numpy as np

# Set the global font size
plt.rcParams.update({'font.size': 13})
# Define the colors for each bar
colors = ["green", "cyan", "lime", "pink", "darkblue", "purple","darkblue","red", "gray", "purple",  "orange"]

### Fuel Choice:
# "MeOH"
# "DME"
fuel = "NH3"

""" Technical sensitivity """
flex = 1
nflex = 0
best = 0
worst = 0
tank = 0
nStore = 0
nStoreFlex = 0

""" Power grid """
grid = 0

""" Locations """
dakhla_off = 0
dakhla_all = 0
arica_off = 0
arica_all = 0
ceduna_off = 0
ceduna_all = 0
esbjerg_off = 0

# Check if the files exist
scenarios = ["NH3 (AEC)", "NH3 (SOEC)", "NH3 (Mix)"]
scen = ["1", "2", "3"]; plot_title = "Islanded NH3 production";
if grid: scen = ["4", "5", "6"]; plot_title = "Grid-connected NH3 production";
if flex: scen = ["7", "8", "9"]; plot_title = "Islanded NH3 production - flexible NH3 plant";
if nflex: scen = ["10", "11", "12"]; plot_title = "Islanded NH3 production - inflexible NH3 plant";
if best: scen = ["13", "14", "15"]; plot_title = "Islanded NH3 production - optimistic";
if worst: scen = ["16", "17", "18"]; plot_title = "Islanded NH3 production - pessimistic";
if tank: scen = ["19", "20", "21"]; plot_title = "Islanded NH3 production - H2 tank storage";
if nStore: scen = ["22", "23", "24"]; plot_title = "Islanded NH3 production - no H2 storage";
if nStoreFlex: scen = ["49", "50", "51"]; plot_title = "Islanded NH3 production - flexible NH3 plant without H2 storage";
if dakhla_off: scen = ["28", "29", "30"]; plot_title = "Islanded offshore NH3 production in Dakhla, Morocco";
if dakhla_all: scen = ["31", "32", "33"]; plot_title = "Islanded onshore NH3 production in Dakhla, Morocco";
if arica_off: scen = ["34", "35", "36"]; plot_title = "Islanded offshore NH3 production in Arica, Chile";
if arica_all: scen = ["37", "38", "39"]; plot_title = "Islanded onshore NH3 production in Arica, Chile";
if ceduna_off: scen = ["40", "41", "42"]; plot_title = "Islanded offshore NH3 production in Ceduna, Australia";
if ceduna_all: scen = ["43", "44", "45"]; plot_title = "Islanded onshore NH3 production in Ceduna, Australia";
if esbjerg_off: scen = ["46", "47", "48"]; plot_title = "Islanded offshore NH3 production in Esbjerg, Denmark";


files = []
for i in scen:
    files.append(str("C:/Users/Frede/Documents/DTU/DTU_Man/OptiPlant-DME/NH3/Results/Results_DME/Main results/Scenario_" + i + ".csv"))
#C:\Users\Frede\Documents\DTU\DTU_Man\OptiPlant-DME\MeOH\Results\Results_DME\Main results
#%% Data handling
unit_mask = 'Type of unit'

if grid:
    units = ["NH3 plant + ASU - SOEC",
             "NH3 plant + ASU - AEC",
             "Waste water plant",
             "Electrolysers SOEC heat integrated",
             "Electrolysers AEC",
             "Electrolysers 75AEC-25SOEC_HI",
             "H2 buried pipes",
             "H2 tank",
             "OFF_SP379-HH150",
             "Batteries",
             "Electricity from the grid"]
    ### For MeOH
    unitlist = ["NH3 prod. plant (+ASU)",
             "Waste water plant",
             "Electrolysis plant",
             "H2 buried pipes",
             "Offshore WF",
             "Grid connection",
             "Batteries"]
    mainIx = 0
    unitIx = 1
elif dakhla_all or ceduna_all or arica_all:
    units = ["NH3 plant + ASU - SOEC",
             "NH3 plant + ASU - AEC",
             "Waste water plant",
             "Electrolysers SOEC heat integrated",
             "Electrolysers AEC",
             "Electrolysers 75AEC-25SOEC_HI",
             "H2 buried pipes",
             "H2 tank",
             "Solar tracking",
             "ON_SP198-HH100",
             "ON_SP237-HH100",
             "Batteries"]
    
    ### For MeOH
    unitlist = ["NH3 prod. plant (+ASU)",
             "Waste water plant",
             "Electrolysis plant",
             "H2 buried pipes",
             "Solar tracking",
             "ON_SP198-HH100",
             "ON_SP237-HH100",
             "Batteries"]
    mainIx = 0
    unitIx = 1
    
    # Define the colors for each bar
    colors = ["green", "cyan", "lime", "pink", "yellow","darkblue","mediumblue", "purple","red", "gray", "purple",  "orange"]
elif dakhla_off or esbjerg_off or arica_off or ceduna_off:
    units = ["NH3 plant + ASU - SOEC",
             "NH3 plant + ASU - AEC",
             "Waste water plant",
             "Electrolysers SOEC heat integrated",
             "Electrolysers AEC",
             "Electrolysers 75AEC-25SOEC_HI",
             "H2 buried pipes",
             "H2 tank",
             "OFF_SP450-HH150",
             "Batteries"]
    ### For MeOH
    unitlist = ["NH3 prod. plant (+ASU)",
             "Waste water plant",
             "Electrolysis plant",
             "H2 buried pipes",
             "Offshore WF",
             "Batteries"]
    
    mainIx = 0
    unitIx = 1
else:
    units = ["NH3 plant + ASU - SOEC",
             "NH3 plant + ASU - AEC",
             "Waste water plant",
             "Electrolysers SOEC heat integrated",
             "Electrolysers AEC",
             "Electrolysers 75AEC-25SOEC_HI",
             "H2 buried pipes",
             "H2 tank",
             "OFF_SP379-HH150",
             "Batteries"]
    ### For MeOH
    unitlist = ["NH3 prod. plant (+ASU)",
             "Waste water plant",
             "Electrolysis plant",
             "H2 buried pipes",
             "Offshore WF",
             "Batteries"]
    if tank:
        unitlist = ["NH3 prod. plant (+ASU)",
                 "Waste water plant",
                 "Electrolysis plant",
                 "H2 tank",
                 "Offshore WF",
                 "Batteries"]
        
    if nStore:
        unitlist = ["NH3 prod. plant (+ASU)",
                 "Waste water plant",
                 "Electrolysis plant",
                 "Offshore WF",
                 "Batteries"]
        colors = ["green", "cyan", "lime", "darkblue", "purple", "pink", "yellow","mediumblue", "purple","red", "gray",   "orange"]
    mainIx = 0
    unitIx = 1



# units = ["Methanol plant",
#          "Wastewater treat. plant",
#          "Electrolysis plant",
#          "H2 buried pipes",
#          "Solar Farm",
#          "Wind Farm"]





cols = ['Type of unit',
        'Annualised investment(MEuros)',
        'Fixed O&M(MEuros)',
        'Cost per unit(MEuros)',
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
e_cost = []
for i,d in enumerate(data):
    data[i] = d[pd.DataFrame(d[unit_mask].tolist()).isin(units).any(1).values][cols]
    a_cost.append(data[i][cols[3]])
    # Unit of biogas cost is in M€:
    if grid and 0: # Unit of electricity cost is in M€:
        e_cost.append(
            data[i].loc[data[i]['Type of unit']=='Electricity from the grid','Production cost per unit (Euros/kg or kWh output)'].values[0]\
                * data[i].loc[data[i]['Type of unit']=='Electricity from the grid','Production(kton or GWh)'].values[0])





costs = pd.DataFrame(columns=unitlist,index=scenarios)
for i in range(len(scen)):
    for j in range(len(unitlist)):
        if grid and j == len(unitlist)-1 and 0:
            costs[unitlist[j]].iloc[i] = e_cost[i]
        else:
            costs[unitlist[j]].iloc[i] = a_cost[i].iloc[j]

prod = data[0]['Production(kton or GWh)'].iloc[1]

#%% Plotting

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
    ax1.text(i, max(bottom)/5,
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


