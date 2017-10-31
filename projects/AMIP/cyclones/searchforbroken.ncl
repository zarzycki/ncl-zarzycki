;========================================================
; Reads in a trajectory data file and calculates hurricane days
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;========================================================

begin

debug=False

traj_dir = "/glade/u/home/zarzycki/tcstats/"
traj_dir = "/glade/u/home/dtatch/et_ncl/"
;traj_dir = "/glade/u/home/zarzycki/scratch/camsetracking/"
;traj_dir = "/glade/scratch/zarzycki/camsetracking/1992/"
traj_filename = "traj_vr_nolatrestriction"
;traj_filename = "traj"

traj_ori_file = "ori.TMP" ; hardcoded temp file name, feel free to change
traj_death_file = "death.TMP"

print("Removing text headers from trajectories")
system("grep -A1 '^start' "+ traj_dir+traj_filename +" | grep -v '^start' | grep -v '^--' > "+traj_ori_file+"")
system("grep -B1 '^start' "+ traj_dir+traj_filename +" | grep -v '^start' | grep -v '^--' > "+traj_death_file+"")

traj_ncols = numAsciiCol(traj_ori_file)

traj_ori_data = readAsciiTable(traj_ori_file,traj_ncols,"float",0)
traj_ori_nrows = dimsizes(traj_ori_data(:,0))

traj_death_data = readAsciiTable(traj_death_file,traj_ncols,"float",0)
traj_death_nrows = dimsizes(traj_death_data(:,0))

if (debug) then
  print(traj_ori_nrows)
  print(traj_death_nrows)
end if
    ;(0)	291.75 lon
  ;(1)	34.75 lat
  ;(2)	31.85 wind
  ;(3)	986.89 pres
  ;(4)	1980 year
  ;(5)	 1 mon
  ;(6)	23 day
  ;(7)	12 hour

ori_lat = traj_ori_data(:,1)
ori_lon = traj_ori_data(:,0)
ori_wind = traj_ori_data(:,2)
ori_pres = traj_ori_data(:,3)
ori_yr = traj_ori_data(:,4)
ori_mon = traj_ori_data(:,5)
ori_day = traj_ori_data(:,6)
ori_hr = traj_ori_data(:,7)

death_lat = traj_death_data(:,1)
death_lon = traj_death_data(:,0)
death_wind = traj_death_data(:,2)
death_pres = traj_death_data(:,3)
death_yr = traj_death_data(:,4)
death_mon = traj_death_data(:,5)
death_day = traj_death_data(:,6)
death_hr = traj_death_data(:,7)

badstorms = 0

do i = 0,traj_ori_nrows-1
  ;print("Working on storm #: "+i)
  do j = 0,traj_death_nrows-1
    gcdist = gc_latlon(ori_lat(i),ori_lon(i),death_lat(j),death_lon(j),2,4)
    if (gcdist .lt. 400 .and. i .ne. j) then
      if (abs(death_day(j) - ori_day(i)) .le. 1 .and. abs(death_yr(j) - ori_yr(i)) .le. 1 .and. abs(death_mon(j) - ori_mon(i)) .le. 1) then
        if (ori_yr(i) .ge. death_yr(j) .and. abs(ori_hr(i) - death_hr(j)) .eq. 12) then
          print("------------------")
          print("Possibly a problem with storm "+i+" and storm "+j)
          print("Storm "+j+" dies at "+death_lat(j)+" "+death_lon(j)+" on "+death_yr(j)+" "+death_mon(j)+" "+death_day(j)+" "+death_hr(j))
          print("Storm "+i+" oris at "+ori_lat(i)  +" "+ori_lon(i)  +" on "+ori_yr(i)  +" "+ori_mon(i)  +" "+ori_day(i)  +" "+ori_hr(i))
          print("Suggesting...")
          newlat = (ori_lat(i) + death_lat(j)) / 2.
          newlon = (ori_lon(i) + death_lon(j)) / 2.
          newwind = (ori_wind(i) + death_wind(j)) / 2.
          newpres = (ori_pres(i) + death_pres(j)) / 2.
          print("  "+newlon+"  "+newlat+"  "+newwind+"  "+newpres+" ")
            ;167.00  -23.25   22.62  983.19  1980     1    25    18
          badstorms = badstorms +1
          if((i-j) .ne. 1) then
            print("WARNING, DIFFERENT STORM FORMS IN BETWEEN")
          end if
        end if
      end if
    end if
  end do
end do

print("=====================================")
print("Potentially "+badstorms+" bad storms.")

system("rm -rf "+traj_ori_file)
system("rm -rf "+traj_death_file)

end
