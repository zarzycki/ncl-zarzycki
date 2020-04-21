import numpy as np
#import calwxt_ramer
import calpreciptype

print(calpreciptype.calwxt_ramer.__doc__)
#python -m numpy.f2py -c calwxt_ramer.f90 -m calwxt_ramer
#python -m numpy.f2py -c calpreciptype.f90 -m calpreciptype

# constants
a = 17.271
b = 237.7 # degC
 
def dewpoint_approximation(T,RH):
  Td = (b * gamma(T,RH)) / (a - gamma(T,RH))
  return Td

def gamma(T,RH):
  g = (a * T / (b + T)) + np.log(RH/100.0)
  return g

f = open('CRP_sounding.csv', 'r')
data = np.genfromtxt(f, delimiter=',')

pmid = data[:,0] * 100.
t = data[:,2] + 273.15
q = data[:,2] + 273.15
rh = data[:,4] / 100.
td = dewpoint_approximation(t-273.15,rh*100.)+273.15
pint = np.hstack((pmid, 0.))


ptype = calpreciptype.calwxt_ramer(t,q,pmid,rh,td,pint)

print(ptype)