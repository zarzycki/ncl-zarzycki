import sys
import os
import math
import numpy as np

T = 273.15 + 20
rharr = 0.5

TW = (T-273.15)*math.atan(0.151977*((rharr*100.)+8.313659)**(0.5))+math.atan((T-273.15) + (rharr*100.)) - math.atan((rharr*100.) - 1.676331) + 0.00391838*(rharr*100.)**(3/2)*math.atan(0.023101*(rharr*100.)) - 4.686035

TW = (T-273.15)*np.arctan(0.151977*((rharr*100.)+8.313659)**(0.5))+np.arctan((T-273.15) + (rharr*100.)) - np.arctan((rharr*100.) - 1.676331) + 0.00391838*(rharr*100.)**(3/2)*np.arctan(0.023101*(rharr*100.)) - 4.686035

print(TW)