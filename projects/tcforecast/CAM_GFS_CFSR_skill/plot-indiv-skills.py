# Analysis.
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def orig_split_index(raw_df,config,lead,region,name):
  tmp=raw_df[(raw_df.config == config) & (raw_df.lead == lead) & (raw_df.region == region)]
  df = tmp[['GFS','CAM']]
  df.rename(columns={'CAM': name}, inplace=True)
  return(df)

def merge_on_index(df,raw_df,config,lead,region,name):
  tmp=raw_df[(raw_df.config == config) & (raw_df.lead == lead) & (raw_df.region == region)]
  tmp2 = tmp[['CAM']]
  tmp2.rename(columns={'CAM': name}, inplace=True)
  df = df.join(tmp2)
  return(df)

raw_df0 = pd.read_csv('stats.txt', header=None, delim_whitespace=True)
raw_df0.columns = ['date', 'GFS', 'CAM', 'ratio', 'config', 'lead', 'region']
raw_df0['DateTime'] = raw_df0['date'].apply(lambda x: pd.to_datetime(str(x), format='%Y%m%d%H'))
raw_df0.set_index('DateTime', inplace=True)

testlead=168
region="nhemi"
df1 = orig_split_index(raw_df0,"hindcast_conus_30_x8_CAM5_L30",testlead,region,"CAM5")
df1 = merge_on_index(df1,raw_df0,"hindcast_conus_30_x8_CAM6_L32",testlead,region,"CAM6")
df1 = merge_on_index(df1,raw_df0,"hindcast_conus_30_x8_CAM4_L26_HV",testlead,region,"CAM4")

print df1

print df1.describe()

forecast_hours = raw_df0.lead.unique()
forecast_regions = raw_df0.region.unique()
forecast_configs = raw_df0.config.unique()

plot_GFS = True
if plot_GFS:
  array = np.empty([len(forecast_regions), len(forecast_configs)+1, len(forecast_hours), 3])
else:
  array = np.empty([len(forecast_regions), len(forecast_configs), len(forecast_hours), 3])

for ii, zz in enumerate(forecast_hours):
  for jj, yy in enumerate(forecast_regions):
    for kk, xx in enumerate(forecast_configs):
      print str(zz)+' '+str(yy)+' '+str(xx)
      tmpdf=raw_df0[(raw_df0.config == xx) & (raw_df0.lead == zz) & (raw_df0.region == yy)]
      stats=tmpdf.describe(percentiles=[.1, .25, .5, .75, .9])
      array[jj,kk,ii,0] = stats.at['mean','CAM']
      array[jj,kk,ii,1] = stats.at['25%','CAM']
      array[jj,kk,ii,2] = stats.at['75%','CAM']
      if plot_GFS and kk == 0:
        array[jj,len(forecast_configs),ii,0] = stats.at['mean','GFS']
        array[jj,len(forecast_configs),ii,1] = stats.at['25%','GFS']
        array[jj,len(forecast_configs),ii,2] = stats.at['75%','GFS']

print(array)
if plot_GFS:
  forecast_configs=np.append(forecast_configs,'GFS')

colors = ['#CC4F1B', '#1B2ACC', '#3F7F4C' , '#000000']
facecolors = ['#FF9848', '#089FFF', '#7EFF99', '#000000']

REGIX=1
for kk, xx in enumerate(forecast_configs):
  plt.plot(forecast_hours, array[REGIX,kk,:,0], 'k', color=colors[kk], label=xx)
  plt.fill_between(forecast_hours, array[REGIX,kk,:,1], array[REGIX,kk,:,2],
    alpha=0.2, edgecolor=colors[kk], facecolor=facecolors[kk])

plt.legend(loc=3)

plt.show()

exit()


df1.plot()

tmp=raw_df0[(raw_df0.config == "hindcast_conus_30_x8_CAM5_L30")]
plt.plot(1.0)

plt.show()

tmp=raw_df0[(raw_df0.config == "hindcast_conus_30_x8_CAM5_L30")]
plt.plot(tmp['CAM'])
plt.plot(tmp['GFS'])

tmp=raw_df0[(raw_df0.config == "hindcast_conus_30_x8_CAM4_L26_HV")]
plt.plot(tmp['CAM'])

tmp=raw_df0[(raw_df0.config == "hindcast_conus_30_x8_CAM6_L32")]
plt.plot(tmp['CAM'])

#plt.show()