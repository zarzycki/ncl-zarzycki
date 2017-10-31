;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
;========================================================
begin

;---------------User settings----------------------------

plot_850=True

wind_factor = "log"
traj_a_dir = "/glade/scratch/zarzycki/clubb-tracking/CAM5/"
traj_a_filename = "trajectories.txt.CAM5"
traj_a_name="CAM5"
traj_b_dir = "/glade/scratch/zarzycki/clubb-tracking/CLUBB/"
traj_b_filename = "trajectories.txt.CLUBB"
traj_b_name="CAM5.5"


factor = surfaceWindCorrFactor(-1,-1,"log")
print("Read in TC locations from CAM")

ncols = 13
maxLines = -1

traj_a_data = getTrajectories(traj_a_dir+"/"+traj_a_filename,ncols,maxLines)
traj_a_lon = traj_a_data(:,1,:)
traj_a_lat = traj_a_data(:,2,:)
traj_a_pres = traj_a_data(:,3,:)/100.
if (plot_850) then
  traj_a_wind = traj_a_data(:,4,:)
else
  traj_a_wind = traj_a_data(:,5,:)*factor
end if
traj_a_yyyy=traj_a_data(:,9,:)
traj_a_mm=traj_a_data(:,10,:)
traj_a_dd=traj_a_data(:,11,:)
traj_a_hh=traj_a_data(:,12,:)
dims=dimsizes(traj_a_lon)
n_a_storms=dims(0)
n_a_times=dims(1)
delete(dims)

ncols=13
maxLines = -1
traj_b_data = getTrajectories(traj_b_dir+"/"+traj_b_filename,ncols,maxLines)
traj_b_lon = traj_b_data(:,1,:)
traj_b_lat = traj_b_data(:,2,:)
traj_b_pres = traj_b_data(:,3,:)/100.
if (plot_850) then
  traj_b_wind = traj_b_data(:,4,:)
else
  traj_b_wind = traj_b_data(:,5,:)*factor
end if
traj_b_yyyy=traj_b_data(:,9,:)
traj_b_mm=traj_b_data(:,10,:)
traj_b_dd=traj_b_data(:,11,:)
traj_b_hh=traj_b_data(:,12,:)
dims=dimsizes(traj_b_lon)
n_b_storms=dims(0)
n_b_times=dims(1)
delete(dims)




print("Finding max for "+traj_a_name)
currentMax=0.
do i = 0,n_a_storms-1
  do j = 0,n_a_times-1
    if (.not.ismissing(traj_a_lon(i,j)))
      if (traj_a_wind(i,j) .gt. currentMax) then
        currentMax=traj_a_wind(i,j)
        print(""+traj_a_wind(i,j)+" "+traj_a_yyyy(i,j)+" "+traj_a_mm(i,j)+" "+traj_a_dd(i,j)+" "+traj_a_hh(i,j)+"    "+traj_a_lat(i,j)+" "+traj_a_lon(i,j))
      end if
    end if
  end do
end do

print("Finding max for "+traj_b_name)
currentMax=0.
do i = 0,n_b_storms-1
  do j = 0,n_b_times-1
    if (.not.ismissing(traj_b_lon(i,j)))
      if (traj_b_wind(i,j) .gt. currentMax) then
        currentMax=traj_b_wind(i,j)
        print(""+traj_b_wind(i,j)+" "+traj_b_yyyy(i,j)+" "+traj_b_mm(i,j)+" "+traj_b_dd(i,j)+" "+traj_b_hh(i,j)+"    "+traj_b_lat(i,j)+" "+traj_b_lon(i,j))
      end if
    end if
  end do
end do


end

