import numpy as np
import math

f = open('JRA-55.model_level_coef_L60.csv', 'r')
data = np.genfromtxt(f, delimiter=',')
hyai = data[:,0]
hybi = data[:,1]
nlevi=len(hyai)
nlev=nlevi-1

PS = 100000.

pint = hyai + hybi * PS

pmid = np.empty([nlev])
for ii in range(nlev-1):
  pmid[ii] = math.exp(  (pint[ii]*math.log(pint[ii]) - pint[ii+1]*math.log(pint[ii+1])) / (pint[ii] - pint[ii+1]) - 1)

# after loop
pmid[ii+1] = pint[ii+1]/2.

print(pmid)