import sys

start_year=1980
end_year=2016

# single vars
vars = ["mean_sea_level_pressure", "10m_u_component_of_wind", "10m_v_component_of_wind"]
for y in range(start_year,end_year):
  for x in vars:
    print(x+' '+str(y))
    sys.argv = ['get.py',str(y), x]
    execfile('get.py')

# vars = ["u_component_of_wind", "v_component_of_wind"]
# for y in range(start_year,end_year):
#   for x in vars:
#     for z in times:
#       print(x+' '+str(y)+' '+z)
# 
# vars = ["geopotential"]
# for y in range(start_year,end_year):
#   for x in vars:
#     for z in times:
#       print(x+' '+str(y)+' '+z)
# 
# vars = ["temperature"]
# for y in range(start_year,end_year):
#   for x in vars:
#     for z in times:
#       print(x+' '+str(y)+' '+z)