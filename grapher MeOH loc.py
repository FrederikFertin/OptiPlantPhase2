import pandas as pd
import matplotlib.pyplot as plt
#from tabulate import tabulate
import numpy as np
import seaborn as sns
import os
#from colour import Color
# Set the global font size
plt.rcParams.update({'font.size': 13})
# Define the colors for each bar
colors = ["green", "cyan", "lime", "pink", "darkblue", "purple","darkblue","red", "gray", "purple",  "orange"]

#%% Functions
def plotSpecCosts(data,scenarios,colors=sns.color_palette()):
    p_cost = []
    for d in data:
        p_cost.append(
            sum(d['Production cost fuel (Euros/kgfuel)']))
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
    for k,i in enumerate(scenarios):
        ll = []
        f = df.loc[i]
        for j in cols2:
            ll.append(f.loc[f['Units'] == j]['Cost Components'].values[0]
                      if sum(f.loc[i]['Units'] == j)
                      else 0)
        
        ll = list(np.array(ll)
                /data[k].loc[
                data[k]['Production cost fuel (Euros/kgfuel)']>0]
                ['Production(kton or GWh)'].values[0])
        
        d = {k:[v] for k,v in zip(cols2,ll)}
        d = pd.DataFrame(d)
        df2 = pd.concat([df2,d],axis=0, ignore_index = True)
    df2.index = scenarios
    #sns.objects.Plot(df, x="Locations", color="Units").add(sns.objects.Bar(), sns.objects.Count(), sns.objects.Stack())
    cols = cols2#[word[0:18] for word in cols2]
    df2.columns = cols
    df2.plot(kind='bar',stacked=True,
             color=colors,
             rot=45,figsize=(12, 7)
             )
    for i, txt in enumerate(p_cost):
        plt.text(i, max(np.sum(df2,axis=1))*1,
                 str(str(round(txt,3)) + " €/kg\n"),
                 ha='center', va='bottom',fontsize=12)
    plt.grid(axis='y')
    plt.ylabel('Annualized costs [€/kg]')
    plt.xlabel('Locations')
    plt.xticks(rotation=90)
    plt.title('MeOH production costs in each location')
    plt.legend(loc='upper left',bbox_to_anchor=(1,1))
    plt.ylim(min(np.min(df2,axis=1))*2,max(np.sum(df2,axis=1))*1.2)
    plt.show()


def plotProdCost(data,scenarios,colors=sns.color_palette()):
    p_cost = []
    for i,d in enumerate(data):
        p_cost.append(
            sum(d['Production cost fuel (Euros/kgfuel)']))
    
    df_p = pd.DataFrame()
    df_p['Production Cost [€/kg]'] = p_cost
    df_p['Locations'] = scenarios
    plt.figure(figsize=(12, 7))
    sns.barplot(y=df_p.columns[0],x='Locations',data=df_p,palette=colors)
    plt.xticks(rotation=45)
    plt.grid(axis='y')
    #plt.axhline(y=p_cost[-1],color='gray',label='Base case cost')
    plt.show()

#%%
# Check if the files exist
scenarios = ["Morocco - DAC",
             "Chile - DAC",
             "Aus. - DAC",
             "Esbjerg - Biogas",
             "Bornholm - biogas",
             "Esbjerg\nw/ oxygen sale",
             "Bornholm\n w/ oxygen sale",
             "Esbjerg HT mehod",
             "Esbjerg HT mehod\n w/ oxygen sale",
             "Esbjerg - DAC",
             "Bornholm - DAC",
             "Esbjerg - DAC\n w/ oxygen & heat sale",
             "Bornholm - DAC\n w/ oxygen & heat sale"]
scen = np.arange(2,15)

cwd = os.getcwd()

files = []
for i in scen:
    files.append(str(cwd + "/MeOH - locations/Results/Results_DME/Main results/Scenario_" + str(i) + ".csv"))

data = []
for f in files:
    data.append(pd.read_csv(f))



#plotProdCost(data,scenarios,colors=['darkblue','lightgreen','darkblue','lightgreen','darkblue','lightgreen','darkblue','darkblue'])
#plotProdCost(best_data,best_scen)

#%% Plot all scenarios loaded (not representable)
#Define color list to properly represent units
colors=['purple', 'lawngreen', 'lime', 'orange', 'cyan', 'brown','pink','grey','green', 'forestgreen', 'darkgreen', 'darkblue', 'mediumblue', 'red', 'yellow', 'cyan' ]
plotSpecCosts(data,scenarios,colors=colors)
#%% Choice of scenarios
choice = [0,1,2,3,4,5,6]
chosen_data = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]

#Define color list to properly represent units
colors=['purple', 'lime', 'orange', 'cyan', 'brown','pink','green', 'darkgreen', 'darkblue', 'mediumblue', 'red', 'yellow', 'cyan' ]
plotSpecCosts(chosen_data,chosen_scen,colors=colors)

#%% Choice of scenarios
choice = [0,1,2,3,4]
chosen_data = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]

#Define color list to properly represent units
colors=['purple', 'lime', 'orange', 'cyan', 'brown','pink','green', 'darkgreen', 'darkblue', 'mediumblue',  'yellow', 'cyan' ]
plotSpecCosts(chosen_data,chosen_scen,colors=colors)

#%% Choice of scenarios
choice = [0,1,2,5,6,7,8]
chosen_data = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]

#Define color list to properly represent units
colors=['purple', 'lawngreen', 'lime', 'orange', 'cyan', 'brown','pink','grey','green', 'forestgreen', 'darkgreen', 'darkblue', 'mediumblue', 'red', 'yellow', 'cyan' ]
plotSpecCosts(chosen_data,chosen_scen,colors=colors)

#%% Choice of scenarios
choice = [0,1,2,9,10]
chosen_data = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]

#Define color list to properly represent units
colors=['purple', 'orange', 'cyan', 'brown','pink','green', 'darkblue','midnightblue', 'mediumblue', 'yellow' ]
plotSpecCosts(chosen_data,chosen_scen,colors=colors)

#%% Choice of scenarios
choice = [9,10,11,12]
chosen_data = [data[i] for i in choice]
chosen_scen = [scenarios[i] for i in choice]

#Define color list to properly represent units
colors=['purple', 'orange', 'cyan', 'brown','pink','grey','green', 'darkblue','midnightblue', 'red', 'yellow', 'cyan' ]
plotSpecCosts(chosen_data,chosen_scen,colors=colors)
