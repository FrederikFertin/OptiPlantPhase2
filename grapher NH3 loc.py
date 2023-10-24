import pandas as pd
import matplotlib.pyplot as plt
#from tabulate import tabulate
import numpy as np
import seaborn as sns
from colour import Color
# Set the global font size
plt.rcParams.update({'font.size': 13})
# Define the colors for each bar
colors = ["green", "cyan", "lime", "pink", "darkblue", "purple","darkblue","red", "gray", "purple",  "orange"]

# Check if the files exist
scenarios = ["MA OFF", "Morocco", "CL OFF", "Chile", "AU OFF", "Australia", "Esbjerg", "Bornholm","Esbjerg - bp sale","Bornholm - bp sale", "Esbjerg -\n oxygen sale", "Bornholm -\n oxygen sale"]
scen = np.arange(2,14)

files = []
for i in scen:
    files.append(str("C:/Users/Frede/Documents/DTU/DTU_Man/OptiPlant-DME/NH3 - locations/Results/Results_DME/Main results/Scenario_" + str(i) + ".csv"))

data = []
for f in files:
    data.append(pd.read_csv(f))

def plotProdCost(data,scenarios,colors=sns.color_palette()):
    p_cost = []
    for i,d in enumerate(data):
        p_cost.append(
            d['Production cost fuel (Euros/kgfuel)'].iloc[0])
    
    df_p = pd.DataFrame()
    df_p['Production Cost [€/kg]'] = p_cost
    df_p['Locations'] = scenarios
    plt.figure(figsize=(12, 7))
    sns.barplot(y=df_p.columns[0],x='Locations',data=df_p,palette=colors)
    plt.xticks(rotation=45)
    plt.grid(axis='y')
    #plt.axhline(y=p_cost[-1],color='gray',label='Base case cost')
    plt.show()

"""
best = [1,3,5,6,7]
best_data = [data[i] for i in best]
best_scen = [scenarios[i] for i in best]

plotProdCost(data,scenarios,colors=['darkblue','lightgreen','darkblue','lightgreen','darkblue','lightgreen','darkblue','darkblue'])
plotProdCost(best_data,best_scen)"""
#%%
def plotSpecCosts(data,scenarios,colors=sns.color_palette()):
    p_cost = []
    for d in data:
        p_cost.append(
            d['Production cost fuel (Euros/kgfuel)'].iloc[0])
    a_cost = []
    labels = []
    scens = []
    for i,d in enumerate(data):
        units = d['Type of unit']
        aa = d['Cost per unit(MEuros)']
        used = abs(aa) > 0.001
        units = units[used]
        aa = aa[used]
        a_cost.append(list(aa.values))
        labels.append(list(units.values))
        scens.append([scenarios[i]]*sum(used))
    
    df = pd.DataFrame()
    df['Cost Components'] = [item for sublist in a_cost for item in sublist]
    df['Units'] = [item for sublist in labels for item in sublist]
    df['Locations'] = [item for sublist in scens for item in sublist]
    df.set_index(df['Locations'],inplace=True)
    
    cols2 = np.unique(df['Units'])
    df2 = pd.DataFrame(columns=cols2)
    for i in scenarios:
        ll = []
        f = df.loc[i]
        for j in cols2:
            ll.append(f.loc[f['Units'] == j]['Cost Components'].values[0]
                      if sum(f.loc[i]['Units'] == j)
                      else 0)
        #ll = pd.Series(ll)
        d = {k:[v] for k,v in zip(cols2,ll)}
        d = pd.DataFrame(d)
        df2 = pd.concat([df2,d],axis=0, ignore_index = True)
    df2.index = scenarios
    #sns.objects.Plot(df, x="Locations", color="Units").add(sns.objects.Bar(), sns.objects.Count(), sns.objects.Stack())
    #cols = [word[0:18] for word in cols2]
    cols = cols2
    df2.columns = cols
    df2.plot(kind='bar',stacked=True,
             color=colors,
             rot=45,figsize=(12, 7)
             )
    for i, txt in enumerate(p_cost):
        plt.text(i, max(np.sum(df2,axis=1))*1.1,
                 str(str(round(txt,3)) + " €/kg\n"),
                 ha='center', va='bottom',fontsize=12)
    plt.grid(axis='y')
    plt.ylabel('Annualized costs [M€]')
    plt.xlabel('Locations')
    plt.xticks(rotation=90)
    plt.title('NH3 production costs in each location')
    plt.ylim(min(np.min(df2,axis=1))*2,max(np.sum(df2,axis=1))*1.25)
    plt.legend(loc='upper left',bbox_to_anchor=(1,1))
    plt.show()

#Define color list to properly represent units
choice = [1,3,5,6,7]
chosen = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]
colors=['purple', 'lime', 'pink', 'green', 'midnightblue','darkblue','mediumblue', 'yellow', 'cyan' ]
plotSpecCosts(chosen,chosen_scen,colors=colors)

choice = np.arange(0,8)
chosen = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]
colors=['purple', 'lime', 'pink', 'green','midnightblue', 'midnightblue','darkblue','mediumblue', 'yellow', 'cyan' ]
plotSpecCosts(chosen,chosen_scen,colors=colors)

choice = np.arange(6,10)
chosen = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]
colors=['purple', 'lime', 'lightgreen', 'pink', 'gray', 'olivedrab','green', 'midnightblue','darkblue','red', 'cyan' ]
plotSpecCosts(chosen,chosen_scen,colors=colors)

choice = [1,3,5,6,7,10,11]
chosen = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]
colors=['purple', 'lime', 'pink', 'green', 'midnightblue','darkblue','mediumblue', 'red','yellow', 'cyan' ]
plotSpecCosts(chosen,chosen_scen,colors=colors)