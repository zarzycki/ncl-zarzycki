#!/bin/bash

arr=""
for YYYY in {2017..2019}
do
	  arr=$arr"ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV3/prsSI/hgt.${YYYY}.nc \
		      ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV3/prsSI/uwnd.${YYYY}.nc \
		          ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV3/prsSI/vwnd.${YYYY}.nc \
			      ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV3/prsSI/air.${YYYY}.nc \
			          ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV3/miscSI/prmsl.${YYYY}.nc \
				      ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV3/10mSI/uwnd.10m.${YYYY}.nc \
				          ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV3/10mSI/vwnd.10m.${YYYY}.nc "
  done

  echo $arr | xargs -n 1 -P 4 wget -q
