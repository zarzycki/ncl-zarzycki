function find_landfalls(lat,lon,hrstride,conshours,critland,npossLF,debug)


;hrstride = hours between data
;conshours = max consecutive hours over land before new landfall can occur
;critland = landfrac threshold needed to trigger overland
;npossLF = max possible landfalls before code exits

; create array
landfallIXreturn=new(npossLF,integer)

; load landfrac dataset
maskfilename="/glade/p/cesmdata/inputdata/atm/cam/topo/USGS_gtopo30_0.23x0.31_remap_c061107.nc"
maskfile=addfile(maskfilename,"r")
LANDFRAC=maskfile->LANDFRAC

; strip trailing missing if necessary
latClean=strip_missing(lat)
lonClean=strip_missing(lon)

ntimesClean=dimsizes(latClean)
landorsea = new(ntimesClean,typeof(LANDFRAC))
do jj = 0,ntimesClean-1
  landorsea(jj)=LANDFRAC({latClean(jj)},{lonClean(jj)})
end do


landTF=where(landorsea.ge.critland,True,False)
landIX=ind(landorsea.ge.critland)
if (debug) then
  print("       ")
  print(latClean+" "+lonClean+" "+landTF)
  print("       ")
  print(landIX+"")
end if

landfallIX=0   ; set to first landfall
if (.not.all(ismissing(landIX))) 
  do kk = 0,dimsizes(landIX)-1
    if (kk .eq. 0) then
      if (landIX(kk) .eq. 0) then
        print("landfall cannot occur at first index")
      else
        landfallIXreturn=kk
        landfallIX=landfallIX+1
      end if
    else
      if ( (landIX(kk)-landIX(kk-1)) .le. 2) then
        print("Consecutive points, no sep landfall")
      else
        landfallIXreturn=kk
        landfallIX=landfallIX+1
      end if
    end if
    if(landfallIX .eq. npossLF)
      print("max landfalls reached")
      break
    end if
  end do
end if

return(landfallIXreturn)

end

