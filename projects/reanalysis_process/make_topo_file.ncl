;========================================================
;
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

whatData="ERA5"
write_output=True
isglobal=False
isStoN=False
keepStoN=False

;if (whatData .eq. "MERRA" .or. whatData .eq. "JRA") then
;  doLonShift=True
;else
  doLonShift=False ; True for MERRA, False for JRA
;end if
topoFileName="/glade/work/zarzycki/cam_tools/hires-topo/2deg_cesm_topo_latlon.nc"
outDir="/glade/work/zarzycki/reanalysis-detection/topo/"
outFileName = whatData+".topo.nc"

;trackerFileName="/glade/scratch/zarzycki/h1files/"+whatData+"/2000/"+whatData+".h1.20000901.nc"
;trackerFileName="~/scratch/nhemi_30_x4_slab/run/1001/nhemi_30_x4_slab.cam.h4.1001-05-01-00000.nc_regrid.nc"
;trackerFileName="/glade/u/home/zarzycki/scratch/ERAI-ETC/2017/ERAI.h1.2017111700.nc"
trackerFileName="/glade/u/home/zarzycki/scratch/h1files/ERA5/1980/ERA5.h1.19800101.nc"
;trackerFileName="/glade/u/home/zarzycki/scratch/ERA5/CAT.ERA5.U850.201701.nc"

topoFile=addfile(topoFileName,"r")
topoLat=topoFile->lat
topoLon=topoFile->lon
topoTopo=topoFile->PHIS
;topoTopo=topoTopo/9.81
printVarSummary(topoTopo)

if(doLonShift) then
  topoTopoShift=lonFlip(topoTopo)
  delete(topoTopo)
  topoTopo = topoTopoShift
  delete(topoTopoShift)
end if

trackerFile=addfile(trackerFileName,"r")
trackerLat=trackerFile->lat
if (isStoN) then
  trackerLat = trackerLat(::-1)
end if
trackerLon=trackerFile->lon

trackerTopo = linint2_Wrap(topoTopo&lon,topoTopo&lat,topoTopo,isglobal,trackerLon,trackerLat,0)

if (isStoN .and. keepStoN) then
  trackerTopo = trackerTopo(::-1,:)
end if

if (write_output) then
	print("Writing output file!")
  system("mkdir -p "+outDir)
	system("/bin/rm -f "+outDir+"/"+outFileName)   ; remove any pre-existing file
	ncdf     = addfile(outDir+"/"+outFileName ,"c")  ; open output netCDF file

	; make time and UNLIMITED dimension      ; recommended  for most applications
	filedimdef(ncdf,"time",-1,True) 

	ncdf->PHIS = trackerTopo         
end if

end
