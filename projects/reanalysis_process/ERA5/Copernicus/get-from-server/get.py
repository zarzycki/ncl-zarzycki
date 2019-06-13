import cdsapi
import sys

# python get.py 1995 '10m_u_component_of_wind'
print ("This is the name of the script: ", sys.argv[0])
print ("Number of arguments: ", len(sys.argv))
print ("The arguments are: " , str(sys.argv))

c = cdsapi.Client()

OUTYEAR=sys.argv[1]
VARIABLE=sys.argv[2]

OUTVAR='out.' + OUTYEAR + '.'+ VARIABLE + '.grib'

c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type':'reanalysis',
        'format':'grib',
        'variable':VARIABLE,
        'year':OUTYEAR,
        'month':[
            '01','02','03',
            '04','05','06',
            '07','08','09',
            '10','11','12'
        ],
        'day':[
            '01','02','03',
            '04','05','06',
            '07','08','09',
            '10','11','12',
            '13','14','15',
            '16','17','18',
            '19','20','21',
            '22','23','24',
            '25','26','27',
            '28','29','30',
            '31'
        ],
        'time':[
            '00:00','06:00','12:00',
            '18:00'
        ]
    },
    OUTVAR)