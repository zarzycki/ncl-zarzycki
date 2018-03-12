# Analysis.
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import ttest_ind, ttest_ind_from_stats

def orig_split_index(raw_df,config,lead,region,verifvar,name):
  tmp=raw_df[(raw_df.config == config) & (raw_df.lead == lead) & (raw_df.region == region) & (raw_df.verifvar == verifvar)]
  df = tmp[['GFS','CAM']]
  df.rename(columns={'CAM': name}, inplace=True)
  return(df)

def merge_on_index(df,raw_df,config,lead,region,verifvar,name):
  tmp=raw_df[(raw_df.config == config) & (raw_df.lead == lead) & (raw_df.region == region) & (raw_df.verifvar == verifvar)]
  tmp2 = tmp[['CAM']]
  tmp2.rename(columns={'CAM': name}, inplace=True)
  df = df.join(tmp2)
  return(df)

def return_indices_of_a(a, b):
  b_set = set(b)
  return [i for i, v in enumerate(a) if v in b_set]

raw_df0 = pd.read_csv('stats.LAND.txt', header=None, delim_whitespace=True)
raw_df0.columns = ['date', 'GFS', 'CAM', 'ratio', 'config', 'lead', 'region', 'verifvar']
raw_df0['DateTime'] = raw_df0['date'].apply(lambda x: pd.to_datetime(str(x), format='%Y%m%d%H'))
raw_df0.set_index('DateTime', inplace=True)

print raw_df0

testlead=240
region="conus"
azvar="T850"
df1 = orig_split_index(raw_df0,"hindcast_conus_30_x8_CAM5_L30",testlead,region,azvar,"CAM5")
df1 = merge_on_index(df1,raw_df0,"hindcast_conus_30_x8_CAM6_L32",testlead,region,azvar,"CAM6")
df1 = merge_on_index(df1,raw_df0,"hindcast_conus_30_x8_CAM4_L26_HV",testlead,region,azvar,"CAM4")


t, p = ttest_ind(df1["CAM5"], df1["GFS"], equal_var=False, nan_policy="omit")
print("ttest_ind:            t = %g  p = %g" % (t, p))

print df1

print df1.describe()

### Subset particular configurations
configsToAnalyze=['GFS', 'hindcast_conus_30_x8_CAM5_L30', 'hindcast_conus_15_x16_CAM5_L30', 'hindcast_conus_60_x4_CAM5_L30']
#configsToAnalyze=['hindcast_conus_30_x8_CAM5_L30', 'hindcast_conus_30_x8_CAM5_L30_NOFILT', 'hindcast_conus_30_x8_CAM5_L30_RTOPO']
#raw_df1=raw_df0.loc[raw_df0['config'].isin(configsToAnalyze)]

forecast_hours = raw_df0.lead.unique()
forecast_regions = raw_df0.region.unique()
forecast_configs = raw_df0.config.unique()
forecast_vars = raw_df0.verifvar.unique()

array = np.empty([len(forecast_regions), len(forecast_vars), len(forecast_configs)+1, len(forecast_hours), 3])


for ii, zz in enumerate(forecast_hours):
  for jj, yy in enumerate(forecast_regions):
    for kk, xx in enumerate(forecast_configs):
      for ll, ww in enumerate(forecast_vars):
        print str(zz)+' '+str(yy)+' '+str(xx)
        tmpdf=raw_df0[(raw_df0.config == xx) & (raw_df0.lead == zz) & (raw_df0.region == yy) & (raw_df0.verifvar == ww)]
        stats=tmpdf.describe(percentiles=[.1, .25, .5, .75, .9])
        array[jj,ll,kk,ii,0] = stats.at['mean','CAM']
        array[jj,ll,kk,ii,1] = stats.at['25%','CAM']
        array[jj,ll,kk,ii,2] = stats.at['75%','CAM']
        if kk == 0:
          array[jj,ll,len(forecast_configs),ii,0] = stats.at['mean','GFS']
          array[jj,ll,len(forecast_configs),ii,1] = stats.at['25%','GFS']
          array[jj,ll,len(forecast_configs),ii,2] = stats.at['75%','GFS']

forecast_configs=np.append(forecast_configs,'GFS')

configs_configs=[ \
#  ['hindcast_conus_30_x8_CAM5_L30', 'hindcast_conus_15_x16_CAM5_L30', 'hindcast_conus_60_x4_CAM5_L30'] , \
#  ['hindcast_conus_30_x8_CAM5_L30', 'hindcast_conus_30_x8_CAM5_L30_NOFILT', 'hindcast_conus_30_x8_CAM5_L30_RTOPO'], \
#  ['hindcast_conus_30_x8_CAM5_L30', 'hindcast_conus_60_x4_CAM5_L30', 'hindcast_conus_15_x16_CAM5_L30'], \
#  ['hindcast_conus_30_x8_CAM5_L30', 'hindcast_conus_30_x8_CAM5_L59'], \
#  ['hindcast_conus_30_x8_CAM5_L30', 'hindcast_conus_30_x8_CAM4_L26_HV', 'hindcast_conus_30_x8_CAM6_L32'], \
#  ['GFS', 'hindcast_conus_30_x8_CAM5_L30', 'hindcast_mp15a-120a-US_CAM5_L30'], \
#  ['hindcast_conus_30_x8_CAM4_L26', 'hindcast_conus_30_x8_CAM4_L26_HV'] \
  ['hindcast_conus_30_x8_CAM5_L30', 'hindcast_conus_30_x8_CAM5_L30_NOLAND'] \
  ]

for CONIX, zz in enumerate(configs_configs):

  configsToAnalyze=configs_configs[CONIX]
  indices = return_indices_of_a(forecast_configs,configsToAnalyze)
  arraysub = array[:,:,indices,:,:]
  forecast_configs_sub = forecast_configs[indices]

  for REGIX, yy in enumerate(forecast_regions):
    for VARIX, ww in enumerate(forecast_vars):
      plt.plot((0, 240), (0.6, 0.6), '--', color='#000000')
      colors = ['#008744', '#d62d20' , '#ffa700' , '#0057e7' ]
      for kk, xx in enumerate(forecast_configs_sub):
        if xx == 'GFS':
          thisColor='#000000'
        else:
          thisColor=colors[kk]
        plt.plot(forecast_hours, arraysub[REGIX,VARIX,kk,:,0], 'k', color=thisColor, linewidth=2, label=xx)
        plt.fill_between(forecast_hours, arraysub[REGIX,VARIX,kk,:,1], arraysub[REGIX,VARIX,kk,:,2],
          alpha=0.15, edgecolor=thisColor, facecolor=thisColor)

      plt.xlabel('Lead (hours)')
      plt.ylabel(forecast_vars[VARIX]+' ACC ('+forecast_regions[REGIX]+')')
      plt.xlim( 0, 240 )
      plt.ylim( 0.0, 1.0 )

      plt.xticks([12, 24, 36, 48, 60, 72, 96, 120, 144, 168, 192, 216, 240])

      plt.legend(loc=3)

      #plt.show()
      plt.savefig(str(CONIX)+'_'+forecast_vars[VARIX]+'_'+forecast_regions[REGIX]+'.png', bbox_inches='tight')
      plt.clf()

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
