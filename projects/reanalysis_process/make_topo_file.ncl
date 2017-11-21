;========================================================
;
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

whatData="JRA"
write_output=True
isglobal=False
if (whatData .eq. "MERRA" .or. whatData .eq. "MERRA2") then
  doLonShift=True
else
  doLonShift=False ; True for MERRA, False for CFSR
end if
topoFileName="/glade/p/work/zarzycki/cam_tools/hires-topo/2deg_cesm_topo_latlon.nc"
outDir="/glade/p/work/zarzycki/reanalysis-detection/topo/"
outFileName = whatData+".topo.nc"

trackerFileName="/glade/scratch/zarzycki/h1files/"+whatData+"/2000/"+whatData+".h1.20000901.nc"
;trackerFileName="~/scratch/nhemi_30_x4_slab/run/1001/nhemi_30_x4_slab.cam.h4.1001-05-01-00000.nc_regrid.nc"


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
trackerLon=trackerFile->lon

trackerTopo = linint2_Wrap(topoTopo&lon,topoTopo&lat,topoTopo,isglobal,trackerLon,trackerLat,0)

if (write_output) then
	print("Writing output file!")

	system("/bin/rm -f "+outDir+"/"+outFileName)   ; remove any pre-existing file
	ncdf     = addfile(outDir+"/"+outFileName ,"c")  ; open output netCDF file

	; make time and UNLIMITED dimension      ; recommended  for most applications
	filedimdef(ncdf,"time",-1,True) 

	ncdf->PHIS = trackerTopo         
end if

end
