import os
import glob
import pandas

# Here we tell the script what station we want this script to focus on.
STATION="KNEW"
PRECIPUNITS="mm"

# if we are looking at a particular station, we can make this less memory-intensive by only passing in that station's CSV files
# This will be much faster since it doesn't have to load ALL stations into memory and then just pick one.

# We can also specify what are called "relative" paths to the datafiles, if we like (for example, I have a folder called SOARS
# where I store my python and my data folder lives inside of that. But what you do (specify an absolute path) works as well.
files = glob.glob('./data/*'+STATION+'*.csv')

dataf = pandas.concat([pandas.read_csv(curfile, header = None) for curfile in files])

dataf.columns = ["ID", "StatLat", "StatLon", "Date", "Precip6h", "StatPress", "PrecipitWater", "Wind10m", "SurfTemp", "TCYesNo", "TCCentLat", "TCCentLon", "TCCentSLP", "MaxTCWindSpeed10m"]

dataf.to_csv("./data/results1.csv",index = None)

fullDF = pandas.DataFrame(dataf)

dataf.loc[dataf['TCCentLat'] != -999.0]

truetc = dataf.loc[dataf['TCCentLat'] != -999.0] 
falsetc = dataf.loc[dataf['TCCentLat'] == -999.0] 

dataf.describe()
truetc.describe()
falsetc.describe()

# Sometimes it is nice to print empty lines or horizontal lines just to break up what your code spits out at you!
print "-----------------"

# Instead of "hardcoding" KHOU (etc.) here, we can call the variable we defined above.
df1present = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']==STATION) & (dataf['Date'] < 2050010100)]
df1totpres = dataf[(dataf['ID']==STATION) & (dataf['Date'] < 2050010100)]

STATIONFiltPrecipPres = df1present['Precip6h'].sum()
STATIONTotPrecipPres = df1totpres['Precip6h'].sum()
print STATION,"present-day TC precipitation:",STATIONFiltPrecipPres,PRECIPUNITS
print STATION,"present-day total precipitation:",STATIONTotPrecipPres,PRECIPUNITS

STATIONFractionPres = STATIONFiltPrecipPres/STATIONTotPrecipPres
print STATION,"present-day percentage of precip. from TCs:",STATIONFractionPres*100.,"%"

print "-----------------"

df1future = dataf[(dataf['TCCentLat'] != -999.0) & (dataf['ID']==STATION) & (dataf['Date'] >= 2050010100)]
df1totfut = dataf[(dataf['ID']==STATION) & (dataf['Date'] >= 2050010100)]

STATIONFiltPrecipFut = df1future['Precip6h'].sum()
STATIONTotPrecipFut = df1totfut['Precip6h'].sum()
print STATION,"future TC precipitation:",STATIONFiltPrecipFut,PRECIPUNITS
print STATION,"future total precipitation:",STATIONTotPrecipFut,PRECIPUNITS

STATIONFractionFut = STATIONFiltPrecipFut/STATIONTotPrecipFut
print STATION,"future percentage of precip. from TCs:",STATIONFractionFut*100.,"%"