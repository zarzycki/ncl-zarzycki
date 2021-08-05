;======================================================================
; mpas_2.ncl
;
; Concepts illustrated:
;   - Drawing a subset of an MPAS-O (ocean) grid
;   - Drawing polylines on a map plot
;   - Drawing cylindrical equidistant or polar stereographic maps
;======================================================================
; For a faster version of this code, see "mpas_faster_2.ncl", which
; uses the new resource "gsSegments" to significantly speed up the 
; drawing of polylines.  You need NCL V6.2.0 in order to use this 
; resource.
;======================================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
  RAD2DEG   = get_r2d("double")  ; Radian to Degree

  plot_name = "mpas"

;--Open MPAS-O (ocean) file
  filename = "/Users/cmz5202/Desktop/x1.10242/x1.10242.grid.nc"
  f        = addfile(filename,"r")

;---Read edge and lat/lon information
  verticesOnEdge = f->verticesOnEdge
  lonCell        = f->lonCell * RAD2DEG
  latCell        = f->latCell * RAD2DEG
  lonVertex      = f->lonVertex * RAD2DEG
  latVertex      = f->latVertex * RAD2DEG

;---Start the graphics
  wks = gsn_open_wks("pdf",plot_name)        ; send graphics to PNG file

  res                       = True
  res@gsnFrame              = False

res@mpProjection      = "Orthographic"
res@mpCenterLatF      =  39.
res@mpCenterLonF      =  262.

res@vpXF      = 0.05
res@vpYF      = 0.9
res@vpWidthF  = 0.9
res@vpHeightF = 0.8

res@mpOutlineOn            = True
res@mpPerimOn              = False
res@mpLandFillColor        = "tan"
res@mpOceanFillColor       = "LightBlue"
res@mpInlandWaterFillColor = "Blue"
res@mpGreatCircleLinesOn = True


    map = gsn_csm_map(wks,res)  ; Create the map, don't draw it.



;---Code to draw MPAS edge lines on the existing map
  res_p                     = True
  res_p@gsLineThicknessF    = 1.0            ; default is 1
  res_p@gsLineColor         = "black"       ; default is black.

;---This is the code for the MPAS grid edges
  esizes = getfilevardimsizes(f,"latEdge")
  nedges = esizes(0)
  print("Number of edges = " + nedges)

  ecx = new((/nedges,2/),double)
  ecy = new((/nedges,2/),double)

  ecx(:,0) = lonVertex(verticesOnEdge(:,0)-1)
  ecx(:,1) = lonVertex(verticesOnEdge(:,1)-1)
  ecy(:,0) = latVertex(verticesOnEdge(:,0)-1)
  ecy(:,1) = latVertex(verticesOnEdge(:,1)-1)

  ii0 = ind((abs(ecx(:,0)-ecx(:,1)).gt.180.and.(ecx(:,0).gt.ecx(:,1))))
  ii1 = ind((abs(ecx(:,0)-ecx(:,1)).gt.180.and.(ecx(:,0).lt.ecx(:,1))))
  ecx(ii0,0) = ecx(ii0,0) - 360.0
  ecx(ii1,1) = ecx(ii1,1) - 360.0
;
; Use gsn_polyline here. gsn_add_polyline is extremely slow!
;
; NCL Version 6.2.0 has a faster algorithmfor drawing polylines
; and polygons. See mpas_faster_2.ncl
;
  start_cpu_time = get_cpu_time()
  print("Drawing the polylines...")

;---The "if" test below makes plotting go much faster

    do j=0,nedges-1
        gsn_polyline(wks,map,ecx(j,:),ecy(j,:),res_p)
    end do

  end_cpu_time = get_cpu_time()
  print("CPU elapsed time = " + (end_cpu_time-start_cpu_time))

  frame(wks)
end



