# -*- coding: utf-8 -*-
"""
Created on Fri Sep 22 08:21:11 2023

@author: Frede
"""

import pandas as pd
import numpy as np

lgp = "PriceElectricityHourly_MainResults_LGPNoInvest2020.csv"
hgp = "PriceElectricityHourly_MainResults_HGPNoInvest2020.csv"

df = pd.read_csv(hgp)

df_slice = df.loc[df['Y'] == 2030]
df_slice = df_slice.loc[df_slice['RRR'] == 'DE4-N']
df_slice = pd.concat([df_slice,df_slice.iloc[0:24,:]])

hours = np.arange(1,8761)
df_slice['hour'] = hours

df_slice = df_slice[['hour','Y','RRR','Val']]
df_slice.columns = ['Hour', 'Year', 'Zone', 'Price [Eur/MWh]']
df_slice.set_index('Hour', inplace=True)

df_slice.to_csv("PriceElectricityHourly_HGP_2030_Germany.csv")