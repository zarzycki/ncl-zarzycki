function find_landfalls(latClean,lonClean,hrstride,conshours,critland,npossLF,debug)


;hrstride = hours between data
;conshours = max consecutive hours over land before new landfall can occur
;critland = landfrac threshold needed to trigger overland
;npossLF = max possible landfalls before code exits

local  latClean,lonClean,landorsea,landIX,landTF,jj,kk

begin

; create array
landfallIXreturn=new(npossLF,"integer")

; load landfrac dataset
maskfilename="/glade/p/cesmdata/inputdata/atm/cam/topo/USGS_gtopo30_0.23x0.31_remap_c061107.nc"
maskfile=addfile(maskfilename,"r")
LANDFRAC=maskfile->LANDFRAC

; find number of times
ntimesClean=dimsizes(latClean)

; find landmask values at lat/lon 1-D pts
landorsea = new(ntimesClean,typeof(LANDFRAC))
do jj = 0,ntimesClean-1
  landorsea(jj)=LANDFRAC({latClean(jj)},{lonClean(jj)})
end do


; what indices of lat/lon do we exceed our threshold?
landIX=ind(landorsea.ge.critland)

if (debug) then
  ; where does landmask exceed our threshold?
  landTF=where(landorsea.ge.critland,True,False)
  print("       ")
  print(latClean+" "+lonClean+" "+landTF)
  print("       ")
  print(landIX+"")
end if

landfallIX=0   ; set to first landfall
if (.not.all(ismissing(landIX)))   ; if NO landfalls, ignore this traj
  do kk = 0,dimsizes(landIX)-1     ; loop over available indices where storm was over land
    if (kk .eq. 0) then            ; if we are on the FIRST index found...
      if (landIX(kk) .eq. 0) then
        print("landfall cannot occur at first index")
      else
        print("landfall spotted!")
        landfallIXreturn(landfallIX)=landIX(kk)   ; add this landIX as a landfall in our return array
        landfallIX=landfallIX+1                   ; increment index to next landfall counter
      end if
    else                           ; now we have established at least ONE landfall (maybe)
      if ( (landIX(kk)-landIX(kk-1)) .le. toint(conshours/hrstride) ) then
        print("Consecutive points, no sep landfall")
      else
        print("landfall spotted!")
        landfallIXreturn(landfallIX)=landIX(kk)   ; add this landIX as a landfall in our return array
        landfallIX=landfallIX+1                   ; increment index to next landfall counter
      end if
    end if
    if(landfallIX .eq. npossLF)    ; if we are at our max, break out of the loop
      print("max landfalls reached")
      break
    end if
  end do
end if

; return the list of indexes corresponding to lat, lon where we have made landfall
return(landfallIXreturn)

end

