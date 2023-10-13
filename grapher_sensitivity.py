import pandas as pd
import matplotlib.pyplot as plt
#from tabulate import tabulate
import numpy as np
import os
import seaborn as sns
from nltk.corpus import words


# Set the global font size
plt.rcParams.update({'font.size': 13})

### Fuel Choice:
# "MeOH"
# "DME"
fuel = "NH3"
grid = 0
flex = 0
nflex = 0
best = 0
worst = 0
tank = 0
nStore = 0
nStoreFlex = 0

cwd = os.getcwd()

# Check the files exist
scen = ["1", "2", "3"]
grid_scen = ["4", "5", "6"]
flex_scen = ["7", "8", "9"]
nflex_scen = ["10", "11", "12"]
best_scen = ["13", "14", "15"]
worst_scen = ["16", "17", "18"]
tank_scen = ["19", "20", "21"]
nStore_scen = ["22", "23", "24"]
nStoreFlex_scen = ["49", "50", "51"]

def createPathList(scen, all_names):
    ll = []
    for i in scen:
        file = str(cwd + "/NH3/Results/Results_DME/Main results/Scenario_" + i + ".csv")
        ll.append(file)
    all_names.append(ll)
    return ll, all_names


all_names = []
base, all_names = createPathList(scen, all_names)

grids, all_names = createPathList(grid_scen, all_names)

flexs, all_names = createPathList(flex_scen, all_names)

nflexs, all_names = createPathList(nflex_scen, all_names)

#bests, all_names = createPathList(best_scen, all_names)

#worsts, all_names = createPathList(worst_scen, all_names)

tanks, all_names = createPathList(tank_scen, all_names)

nStores, all_names = createPathList(nStore_scen, all_names)

nStoreFlexs, all_names = createPathList(nStoreFlex_scen, all_names)

AEC = []
SOEC = []
MIX = []
data = []

for case in all_names:
    for i,f in enumerate(case):
        df = pd.read_csv(f)
        data.append(df)
        if i == 0:
            AEC.append(df)
        elif i == 1:
            SOEC.append(df)
        else:
            MIX.append(df)


fuel_costs = {}
for scen in data:
    fuel_costs[str(scen['Scenario'].iloc[0] + ": " + scen['Electrolyser'].iloc[0])] =\
        scen['Production cost fuel (Euros/kgfuel)'].iloc[0]

fuel_costs_AEC = {}
for scen in AEC:
    fuel_costs_AEC[str(scen['Scenario'].iloc[0])] =\
        scen['Production cost fuel (Euros/kgfuel)'].iloc[0]

fuel_costs_SOEC = {}
for scen in SOEC:
    fuel_costs_SOEC[str(scen['Scenario'].iloc[0])] =\
        scen['Production cost fuel (Euros/kgfuel)'].iloc[0]

fuel_costs_MIX = {}
for scen in MIX:
    fuel_costs_MIX[str(scen['Scenario'].iloc[0])] =\
        scen['Production cost fuel (Euros/kgfuel)'].iloc[0]

cases = list(fuel_costs.keys())
df = pd.DataFrame(columns=['Production cost (€/kg)', 'Electrolyser','Case'],index=cases)

for scen in data:
    name = str(scen['Scenario'].iloc[0] + ": " + scen['Electrolyser'].iloc[0])
    df.loc[df.index==name,'Production cost (€/kg)'] =\
        scen['Production cost fuel (Euros/kgfuel)'].iloc[0]
    df.loc[df.index==name,'Electrolyser'] =\
        scen['Electrolyser'].iloc[0]
    df.loc[df.index==name,'Case'] =\
        scen['Scenario'].iloc[0]

AEC_only = 1
if AEC_only:
    cases = list(fuel_costs_SOEC.keys())
    df = pd.DataFrame(columns=['Production cost (€/kg)', 'Electrolyser','Case'],index=cases)
    for scen in SOEC:
        name = str(scen['Scenario'].iloc[0])
        df.loc[df.index==name,'Production cost (€/kg)'] =\
            scen['Production cost fuel (Euros/kgfuel)'].iloc[0]
        df.loc[df.index==name,'Electrolyser'] =\
            scen['Electrolyser'].iloc[0]
        df.loc[df.index==name,'Case'] =\
            scen['Scenario'].iloc[0]
    dd = df['Case'].values
    dd[1] = 'Semi-islanded (Grid)'
    dd[2] = 'Flex (0% min. load)'
    dd[3] = 'Non-flex (40% min. load)'
    df['Descriptions'] = dd

#All electrolyzer technologies
plt.figure(figsize=(12, 7))
plt.grid(axis='y')
sns.barplot(y='Production cost (€/kg)',x='Electrolyser',hue='Case',data=df)
plt.title('Production costs given different assumptions')
plt.legend(loc='upper left',bbox_to_anchor=(1,1)) # Moved the legend to the right side
plt.show()


plt.figure(figsize=(12, 7))
plt.grid(axis='y')
sns.barplot(x='Production cost (€/kg)',y='Case',data=df)
plt.title('Production costs given different assumptions')
plt.legend(loc='upper left',bbox_to_anchor=(1,1)) # Moved the legend to the right side
plt.show()

dfs = df.copy()
if AEC_only:
    dfs['Cost difference (%)'] = (dfs['Production cost (€/kg)']-dfs['Production cost (€/kg)'].iloc[0])/dfs['Production cost (€/kg)'].iloc[0]*100
    dfs = dfs.iloc[1:,:]
else:
    dfs['Cost difference (%)'] = (dfs['Production cost (€/kg)']-np.mean(dfs['Production cost (€/kg)'].iloc[0:3]))/np.mean(dfs['Production cost (€/kg)'].iloc[0:3])*100
    dfs = dfs.iloc[3:,:]

plt.figure(figsize=(12, 7))
plt.grid(axis='y')
sns.barplot(x='Cost difference (%)',y='Case',estimator=np.mean,errwidth=1,data=dfs,orient="h",palette=sns.color_palette()[1:])
plt.axvline(x=0,color=sns.color_palette()[0],label='Base case cost')
plt.title('Production cost sensitivity to plant specifications')
plt.legend(loc='upper right') # Moved the legend to the right side
plt.grid(axis='x')
plt.show()


f_cases = [v for v in cases if 'lex' in v]
flexibility = pd.DataFrame(columns=['Production cost (Euros/kg)', 'Electrolyser'],index=f_cases)

plt.barh(df['Case'],df['Production cost (€/kg)'],alpha=0.2)

#SOEC absolute values
intervals = {}
c = fuel_costs_SOEC['Base case']

flex = [fuel_costs_SOEC['Non-flex']-c,fuel_costs_SOEC['Flex']-c]
tot = [fuel_costs_SOEC['Worst case']-c,fuel_costs_SOEC['Best case']-c]
grid = [fuel_costs_SOEC['Semi-islanded']-c]
storage = [fuel_costs_SOEC['H2 tank']-c,fuel_costs_SOEC['No H2 storage']-c]

intervals['NH3 plant flexibility'] = flex
intervals['Plant benchmarking'] = tot
intervals['Power source (grid)'] = grid
intervals['Storage type'] = storage

fig, ax = plt.subplots(figsize=(12, 7))
for i in intervals.keys():
    plt.barh(i,intervals[i],alpha=0.7)
plt.axvline(x=0,color='black')
plt.xlabel('Change in production cost (€/kg)')
plt.ylabel('Model component')
plt.title('SOEC sensitivity to model assumptions')
plt.show()

#SOEC relative values
intervals = {}
c = fuel_costs_SOEC['Base case']

flex = [(fuel_costs_SOEC['Non-flex']-c)/c,(fuel_costs_SOEC['Flex']-c)/c]
tot = [(fuel_costs_SOEC['Worst case']-c)/c,(fuel_costs_SOEC['Best case']-c)/c]
grid = [(fuel_costs_SOEC['Semi-islanded']-c)/c]
storage = [(fuel_costs_SOEC['H2 tank']-c)/c,(fuel_costs_SOEC['No H2 storage']-c)/c]

intervals['NH3 plant flexibility'] = flex
intervals['Plant benchmarking'] = tot
intervals['Power source (grid)'] = grid
intervals['Storage type'] = storage

fig, ax = plt.subplots(figsize=(12, 7))
for i in intervals.keys():
    plt.barh(i,np.array(intervals[i])*100,alpha=0.7)
plt.axvline(x=0,color='black',label='Base case cost')
plt.xlabel('Change in production cost (%)')
plt.ylabel('Model component')
plt.title('SOEC sensitivity to model assumptions')
plt.legend()
plt.show()



