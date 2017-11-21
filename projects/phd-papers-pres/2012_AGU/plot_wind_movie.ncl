load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"


begin
;	out_type = "pdf"
;	out_type = "x11"
	out_type = "png"
	
stitch = 1

;a = addfile("/glade/proj3/mich1098/zarzycki/detect_files/1980/test2.nc","r")
a = addfile("/glade/scratch/zarzycki/tohpss/cat.nc","r")

if (stitch .eq. 0) then
    zz  = ispan(0,100,1)
    zzs = sprinti("%0.3i",zz)   ; "000", "001", ... "100"
end if

if (stitch .eq. 1) then
    wks = gsn_open_wks("pdf","850AMIPmovie")
end if

do time = 0,getfilevardimsizes(a, "time" )-1

if (stitch .eq. 0) then   
    wks = gsn_open_wks(out_type,"850AMIPmovie"+zzs(time))
end if

; For AGU 2012 plot
minlat = 5
maxlat = 45
minlon = 265
maxlon = 355

minlat = 0
maxlat = 50
minlon = 255
maxlon = 355


U = a->U850(time,{minlat:maxlat},{minlon:maxlon})
V = a->V850(time,{minlat:maxlat},{minlon:maxlon})

wind = U
wind = sqrt(U^2+V^2)

print(max(wind))

;************************************************
; Plot underlying field
;************************************************

	res = True
	res@tiMainString = ""

	res@gsnDraw = False
	res@gsnFrame = False
  
	res@mpOutlineOn = True
	
	res@mpGreatCircleLinesOn = True

	res@mpGridAndLimbOn = True
	res@mpGridLineDashPattern = 2

	res@gsnMajorLonSpacing = 20
	res@mpGridLonSpacingF = 20
	res@gsnMajorLatSpacing = 15
	res@mpGridLatSpacingF = 15

    res@cnFillOn		  = True
    
    res@gsnAddCyclic = False

   res@mpMaxLatF                   = maxlat
   res@mpMinLatF                   = minlat
   res@mpMaxLonF                   = maxlon
   res@mpMinLonF                   = minlon
    
; WIND
 gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
 res@cnLineLabelsOn       = False             ; turn off line labels
 res@gsnSpreadColors      = True              ; use full colormap
 res@lbLabelStride        = 2
 res@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
 res@cnLevelSpacingF      =  4.0                ;
 res@cnMinLevelValF       =  0.0           ;
 res@cnMaxLevelValF       =  80.0 ; Use 80.0 -> 60 for this
  
  res@cnLinesOn   = False		   				; turn off the contour lines

  

	plot2 = gsn_csm_contour_map(wks,wind(:,:),res) 
	draw(plot2)
	
	
	frame(wks)
	
;************************************************

end do

end



