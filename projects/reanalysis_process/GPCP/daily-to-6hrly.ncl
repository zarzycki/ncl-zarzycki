begin

f1=addfile("/glade/u/home/zarzycki/scratch/j1files/GPCP/2005/precip.2005.nc","r")
doFlip=False

time=f1->time
ntim=dimsizes(time)

sttime=time(0)
;entime=time(ntim-1)+18.
entime=time(ntim-1)+0.75

time_new=fspan(sttime,entime,ntim*4)
time_new!0="time"
time_new&time=time_new
copy_VarAtts(time,time_new)

print(time_new)

if (doFlip) then
  PRECT = f1->precip(:,::-1,:)
else
  PRECT = f1->precip(:,:,:)
end if

PRECT_new = linint1_n_Wrap(time, PRECT, False, time_new, 0, 0) 

PRECT_new!1="lat"
PRECT_new!2="lon"

;PRECT_new = where(ismissing(PRECT_new),0.0,PRECT_new)

;=====================================================================
 
outfile="/glade/u/home/zarzycki/scratch/j1files/GPCP/2005/precip.2005_interp.nc"
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
ncdf = addfile(outfile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

ncdf->PRECT=PRECT_new

end
