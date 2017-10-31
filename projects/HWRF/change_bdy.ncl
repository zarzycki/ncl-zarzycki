load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

in_wrf_bdy_nm = "wrfbdy_d01"
in_wrf_bdy = addfile(in_wrf_bdy_nm,"w")

thestring=in_wrf_bdy->md___nextbdytimee_x_t_d_o_m_a_i_n_m_e_t_a_data_

print(thestring)

thestring(0,8) =tocharacter("2")

print(thestring)

in_wrf_bdy->md___nextbdytimee_x_t_d_o_m_a_i_n_m_e_t_a_data_=thestring

end
