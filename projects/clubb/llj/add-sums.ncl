load "functions.ncl"

begin

  ;fname = "CAM_x202.nc"
  f = addfile(fname,"w")

  vars :=(/"vpwp_ac_97.49w_36.61n", \
           "vpwp_bp_97.49w_36.61n", \
           "vpwp_cl_97.49w_36.61n", \
           "vpwp_dp1_97.49w_36.61n", \                  
           "vpwp_ma_97.49w_36.61n", \
           "vpwp_mfl_97.49w_36.61n", \
           "vpwp_pr1_97.49w_36.61n", \
           "vpwp_pr2_97.49w_36.61n", \
           "vpwp_pr3_97.49w_36.61n", \
           "vpwp_pr4_97.49w_36.61n", \
           "vpwp_ta_97.49w_36.61n", \
           "vpwp_tp_97.49w_36.61n" /)
           
  merge = sum_budgets(vars,"dvpwp_dt_97.49w_36.61n",f)
  
  vars :=(/"vpwp_ac_97.49w_36.61n", \
           "vpwp_pr2_97.49w_36.61n" /)  

  merge = sum_budgets(vars,"vpwp_sum_ac_97.49w_36.61n",f)

  vars :=(/"vpwp_bp_97.49w_36.61n", \
           "vpwp_pr3_97.49w_36.61n" /)  

  merge = sum_budgets(vars,"vpwp_sum_bp_97.49w_36.61n",f)

  vars :=(/"vpwp_tp_97.49w_36.61n", \
           "vpwp_pr4_97.49w_36.61n" /)  

  merge = sum_budgets(vars,"vpwp_sum_tp_97.49w_36.61n",f)
  
  vars :=(/"upwp_ac_97.49w_36.61n", \
           "upwp_bp_97.49w_36.61n", \
           "upwp_cl_97.49w_36.61n", \
           "upwp_dp1_97.49w_36.61n", \                  
           "upwp_ma_97.49w_36.61n", \
           "upwp_mfl_97.49w_36.61n", \
           "upwp_pr1_97.49w_36.61n", \
           "upwp_pr2_97.49w_36.61n", \
           "upwp_pr3_97.49w_36.61n", \
           "upwp_pr4_97.49w_36.61n", \
           "upwp_ta_97.49w_36.61n", \
           "upwp_tp_97.49w_36.61n" /)
           
  merge = sum_budgets(vars,"dupwp_dt_97.49w_36.61n",f)
  
  vars :=(/"upwp_ac_97.49w_36.61n", \
           "upwp_pr2_97.49w_36.61n" /)  

  merge = sum_budgets(vars,"upwp_sum_ac_97.49w_36.61n",f)

  vars :=(/"upwp_bp_97.49w_36.61n", \
           "upwp_pr3_97.49w_36.61n" /)  

  merge = sum_budgets(vars,"upwp_sum_bp_97.49w_36.61n",f)

  vars :=(/"upwp_tp_97.49w_36.61n", \
           "upwp_pr4_97.49w_36.61n" /)  

  merge = sum_budgets(vars,"upwp_sum_tp_97.49w_36.61n",f)
                 
end
