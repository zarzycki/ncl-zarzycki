
# coding: utf-8

# In[5]:

import os


# In[6]:

import glob


# In[7]:

import pandas


# In[8]:

#Below I am attempting a different method to merge all the csv files, then making them into a single csv file


# In[9]:

#files = glob.glob(r'2017-12-05\Aggregated\*.csv')
files = glob.glob('/Users/zarzycki/SOARS/data/*.csv')


# In[10]:

dataf = pandas.concat([pandas.read_csv(curfile, header = None) for curfile in files])



# In[11]:

dataf.columns = ["ID", "StatLat", "StatLon", "Date", "Precip6h", "StatPress", "PrecipitWater", "Wind10m", "SurfTemp", "TCYesNo", "TCCentLat", "TCCentLon", "TCCentSLP", "MaxTCWindSpeed10m"]


# In[12]:

dataf.to_csv("results1.csv",index = None)
#dataf.to_csv("result.csv", index = None)


# In[13]:

fullDF = pandas.DataFrame(dataf)

print(fullDF)


# In[14]:

dataf.loc[dataf['TCCentLat'] != -999.0]
                
                
                
                


# In[15]:

truetc = dataf.loc[dataf['TCCentLat'] != -999.0] 
falsetc = dataf.loc[dataf['TCCentLat'] == -999.0] 


# In[16]:

kmob = dataf[(dataf['ID'] == "KMOB")] #MOBLE
kmia = dataf[(dataf['ID'] == "KMIA")] #MIAMI
khou = dataf[(dataf['ID'] == "KHOU")] #HOUSTON
ktpa = dataf[(dataf['ID'] == "KPTA")] #TAMPA
knew = dataf[(dataf['ID'] == "KNEW")] #NEW ORLEANS
knyc = dataf[(dataf['ID'] == "KNYC")] #NEW YORK CITY
kbos = dataf[(dataf['ID'] == "KBOS")] #BOSTON
kchs = dataf[(dataf['ID'] == "KCHS")] #CHARLESTON
kjax = dataf[(dataf['ID'] == "KJAX")] #JACKSONVILLE
khse = dataf[(dataf['ID'] == "KHSE")] #HATTERAS
kdca = dataf[(dataf['ID'] == "KDCA")] #WASHINGTON D.C.
ksav = dataf[(dataf['ID'] == "KSAV")] #SAVANNAH
kcrp = dataf[(dataf['ID'] == "KCRP")] #CORPUS CHRISTI
katl = dataf[(dataf['ID'] == "KATL")] #ATLANTA
ktcl = dataf[(dataf['ID'] == "KTCL")] #TUSCALOOSA
ktlh = dataf[(dataf['ID'] == "KTLH")] #TALLAHASSEE
kclt = dataf[(dataf['ID'] == "KCLT")] #CHARLOTTE


# In[17]:

dataf.describe()


# In[18]:

truetc.describe()


# In[19]:

falsetc.describe()


# In[20]:

dataf[(dataf['Precip6h'] > 80 ) & (dataf['TCCentLat'] == -999.0) & (dataf['ID']=='KMOB')] #Note: Rainfall is in mm.


# In[21]:

dataf[(dataf['Precip6h'] > 100 ) & (dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KMOB')]


# In[ ]:

#Below I am taking the 3 stations (Houston, Mobile, and NYC) with a TCYesNo = TRUE and creating separate data frames for them

#https://pandas.pydata.org/pandas-docs/stable/merging.html


# In[31]:

df1 = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KHOU')]
print(df1)


# In[32]:

df2 = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KMOB')]
print(df2)


# In[34]:

df3 = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KNYC')]
print(df3)


# In[ ]:

#Below I am taking the 3 data frames and concatenating them to where all three cities with a TCYesNo = True are all in one dataframe


# In[35]:

sampleframe = [df1, df2, df3]


# In[38]:

sampresult = pandas.concat(sampleframe)


# In[39]:

print (sampresult)


# In[40]:

sampresult.describe() #This is giving the statistics of the three cities with TCYesNo = TRUE


# In[ ]:

#Now I am creating a data frame including both TCYesNo = True and False and concatenating them


# In[43]:

df3tot = dataf[(dataf['ID']=='KNYC')]


# In[44]:

print (df3tot)


# In[45]:

df1tot = dataf[(dataf['ID']=='KHOU')]
print (df1tot)


# In[46]:

df2tot = dataf[(dataf['ID']=='KMOB')]
print (df2tot)


# In[47]:

totframe = [df1tot, df2tot, df3tot]


# In[48]:

totresult = pandas.concat(totframe)


# In[49]:

print(totresult)


# In[50]:

totresult.describe()


# In[51]:

sampresult.describe()


# In[ ]:

#For all 3 cities combined, I am finding the sum of total precip and sum of filtered precip with
#this document https://stackoverflow.com/questions/41286569/get-total-of-pandas-column


# In[52]:

TotalPrecip = totresult['Precip6h'].sum()
print(TotalPrecip)


# In[54]:

FilteredPrecip = sampresult['Precip6h'].sum()
print(FilteredPrecip)


# In[55]:

threecityfraction = FilteredPrecip/TotalPrecip #This is the fraction for all 3 cities combined!
print (threecityfraction)


# In[ ]:




# In[56]:

#Below I am going to do the same operation as above, with the cities separated.


# In[ ]:

#Houston 


# In[59]:

HOUfilteredprecip = df1['Precip6h'].sum()
print (HOUfilteredprecip)


# In[60]:

HOUtotalprecip = df1tot['Precip6h'].sum()
print(HOUtotalprecip)


# In[62]:

HOUfraction = HOUfilteredprecip/HOUtotalprecip
print (HOUfraction)


# In[63]:

#Mobile


# In[64]:

MOBfilteredprecip = df2['Precip6h'].sum()
print(MOBfilteredprecip)


# In[65]:

MOBtotalprecip = df2tot['Precip6h'].sum()
print (MOBtotalprecip)


# In[66]:

MOBfraction = MOBfilteredprecip/MOBtotalprecip
print (MOBfraction)


# In[67]:

#New York City


# In[68]:

NYCfilteredprecip = df3['Precip6h'].sum()
print(NYCfilteredprecip)


# In[69]:

NYCtotalprecip = df3tot['Precip6h'].sum()
print (NYCtotalprecip)


# In[71]:

NYCfraction = NYCfilteredprecip/NYCtotalprecip
print (NYCfraction)


# In[ ]:




# In[72]:

#Now I will do the above tasks, but I am going to filter by date because I forgot. Twice.


# In[ ]:

#This is for the PRESENT time period (any time before the year 2050)


# In[73]:

#Houston


# In[102]:

df1present = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KHOU') & (dataf['Date'] < 2050010100)]
df1totpres = dataf[(dataf['ID']=='KHOU') & (dataf['Date'] < 2050010100)]


# In[92]:

#Mobile


# In[103]:

df2present = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KMOB') & (dataf['Date'] < 2050010100)]
df2totpres = dataf[(dataf['ID']=='KMOB') & (dataf['Date'] < 2050010100)]


# In[94]:

#NYC


# In[104]:

df3present = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KNYC') & (dataf['Date'] < 2050010100)]
df3totpres = dataf[(dataf['ID']=='KNYC') & (dataf['Date'] < 2050010100)]


# In[ ]:

#Below is the fraction of precip in PRESENT (before 2050) 


# In[101]:

#Houston


# In[105]:

HOUFiltPrecipPres = df1present['Precip6h'].sum()
HOUTotPrecipPres = df1totpres['Precip6h'].sum()
print(HOUFiltPrecipPres)
print(HOUTotPrecipPres)


# In[106]:

HOUFractionPres = HOUFiltPrecipPres/HOUTotPrecipPres
print (HOUFractionPres)


# In[107]:

#Mobile


# In[108]:

MOBFiltPrecipPres = df2present['Precip6h'].sum()
MOBTotPrecipPres = df2totpres['Precip6h'].sum()
print(MOBFiltPrecipPres)
print(MOBTotPrecipPres)


# In[109]:

MOBFractionPres = MOBFiltPrecipPres/MOBTotPrecipPres
print (MOBFractionPres)


# In[ ]:

#NYC


# In[110]:

NYCFiltPrecipPres = df3present['Precip6h'].sum()
NYCTotPrecipPres = df3totpres['Precip6h'].sum()
print(NYCFiltPrecipPres)
print(NYCTotPrecipPres)


# In[111]:

NYCFractionPres = NYCFiltPrecipPres/NYCTotPrecipPres
print (NYCFractionPres)


# In[ ]:




# In[ ]:

#Here I am filtering for days in the FUTURE (after the year 2050)


# In[ ]:

#Houston


# In[96]:

df1future = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KHOU') & (dataf['Date'] >= 2050010100)]
df1totfut = dataf[(dataf['ID']=='KHOU') & (dataf['Date'] >= 2050010100)]


# In[97]:

#Mobile


# In[98]:

df2future = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KMOB') & (dataf['Date'] >= 2050010100)]
df2totfut = dataf[(dataf['ID']=='KMOB') & (dataf['Date'] >= 2050010100)]


# In[99]:

#NYC


# In[100]:

df3future = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']=='KNYC') & (dataf['Date'] >= 2050010100)]
df3totfut = dataf[(dataf['ID']=='KNYC') & (dataf['Date'] >= 2050010100)]


# In[ ]:

#Below is the fraction of precip in FUTURE 


# In[113]:

HOUFiltPrecipFut = df1future['Precip6h'].sum()
HOUTotPrecipFut = df1totfut['Precip6h'].sum()
print(HOUFiltPrecipFut)
print(HOUTotPrecipFut)


# In[114]:

HOUFractionFut = HOUFiltPrecipFut/HOUTotPrecipFut
print (HOUFractionFut)


# In[ ]:

#Mobile


# In[116]:

MOBFiltPrecipFut = df2future['Precip6h'].sum()
MOBTotPrecipFut = df2totfut['Precip6h'].sum()
print(MOBFiltPrecipFut)
print(MOBTotPrecipFut)


# In[117]:

MOBFractionFut = MOBFiltPrecipFut/MOBTotPrecipFut
print (MOBFractionFut)


# In[ ]:

#NYC


# In[118]:

NYCFiltPrecipFut = df3future['Precip6h'].sum()
NYCTotPrecipFut = df3totfut['Precip6h'].sum()
print(NYCFiltPrecipFut)
print(NYCTotPrecipFut)


# In[119]:

NYCFractionFut = NYCFiltPrecipFut/NYCTotPrecipFut
#print (NYCFractionFut)
print "KNYC future fraction: ",NYCFractionFut


# In[ ]:



