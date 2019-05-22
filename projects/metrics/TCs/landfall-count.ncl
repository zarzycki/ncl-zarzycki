;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "read_csv.ncl"
load "../../../functions/trackDensity.ncl"

begin

files=(/"./landfall_txt/LF.ibtracs-2003-2015-GLOB.txt", \
"./landfall_txt/LF.trajectories.txt.CFSR", \
"./landfall_txt/LF.trajectories.txt.JRA", \
"./landfall_txt/LF.trajectories.txt.MERRA", \
"./landfall_txt/LF.trajectories.txt.MERRA2", \
"./landfall_txt/LF.trajectories.txt.ERA5", \
"./landfall_txt/LF.trajectories.txt.ERAI", \
"./landfall_txt/LF.trajectories.txt.MP15A-120A-US-EXP213", \
"./landfall_txt/LF.trajectories.txt.NE0CONUS30X8-EXP211", \
"./landfall_txt/LF.trajectories.txt.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.ALL", \
"./landfall_txt/LF.trajectories.txt.VR28.NATL.REF.CAM5.4CLM5.0.dtime900.ALL", \
"./landfall_txt/LF.trajectories.txt.VR28.NATL.EXT.CAM5.4CLM5.0.dtime900.ALL", \
"./landfall_txt/LF.trajectories.txt.VR28.NATL.ALL.CAM5.4CLM5.0.dtime900.ALL", \
"./landfall_txt/LF.trajectories.txt.CHEY.111.GLOB.CAM5.4CLM5.0.dtime1800.ALL"/)

strs=(/"IBTrACS","CFSR","JRA","MERRA","MERRA2","ERA5","ERAI","MPAS","SE","CAMWAT","CAMREF","CAMEXT","CAMALL","CAMLR"/)

ensmembers=(/1,1,1,1,1,1,1,1,1,3,3,3,9,3/)
yearspermember=(/13,13,13,13,13,13,13,34,34,30,30,30,30,30/)

do ii = 0,dimsizes(files)-1

nyears=ensmembers(ii)*yearspermember(ii)
file1=read_CSV_f(files(ii))

lf_reg=file1(:,5)

num_ceus=num(lf_reg .eq. 1)
num_seus=num(lf_reg .eq. 2)
num_neus=num(lf_reg .eq. 3)
num_nono=num(lf_reg .eq. -999)

freq_ceus = tofloat(num_ceus)/nyears*10
freq_seus = tofloat(num_seus)/nyears*10
freq_neus = tofloat(num_neus)/nyears*10
freq_nono = tofloat(num_nono)/nyears*10

print(""+files(ii))
print(nyears+" years")
print("CEUS: "+freq_ceus+"   SEUS: "+freq_seus+"    NEUS: "+freq_neus)

delete(file1)
delete(lf_reg)

end do

end