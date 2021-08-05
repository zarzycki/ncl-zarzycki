begin

;filename = "/glade/scratch/zarzycki/erain_1993_pvar_one_side.nc"
f=addfile(filename,"w")

;cp /glade/p/cisl/risc/bukovsky/pvar/erain/erain_1993_pvar_one_side.nc ~/scratch/
;ncrename -v time,date /glade/u/home/zarzycki/scratch/erain_1993_pvar_one_side.nc

date=f->date

yyyy  = date/1000000 
mmddhh  = date-yyyy*1000000
mm    = mmddhh/10000
ddhh    = mmddhh-mm*10000
dd    = ddhh/100
hh    = ddhh - dd*100

mn    = dd
sc    = dd
mn    = 0
sc    = 0
  
;print(yyyy+" "+mmddhh+" "+mm+" "+dd+ " "+hh)

units  = "days since 1900-01-01 00:00:00"

time   = cd_inv_calendar(yyyy,mm,dd,hh,mn,sc,units, 0)
time!0 = "time"
time&time = time

;filedimdef(f,"time",-1,True) 
f->time = time

end
