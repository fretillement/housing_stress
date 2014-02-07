import csv 
import pandas as pd
import xlwt

yearlist = range(2007, 2012)

# Initialize workbook for writing msa weights by year
wb = pd.ExcelWriter('M:/IPUMS/hhstress_data/msawt_by_year.xls')

for y in yearlist: 
	# Initialize an empty list of dicts for the year 
	ydict = []
	print "Working with " + str(y)

	# Read yearly CLEANED csv file into dataframe. Keep only hhwt, msa 
	fname = "M:/IPUMS/hhdata/hhsharing/" + str(y) + "full.csv"
	f = csv.DictReader(open(fname, 'rb'))
	header = f.fieldnames
	keep = ['hhwt', 'metaread']
	indices = [header.index(v) for v in keep]
	df = pd.read_csv(fname, usecols = indices)
	print "		Read file into dataframe"

	# Group the dataframe by msa
	df = df.groupby('metaread')
	print "		Grouped by msa"

	# Compute sum of hhwt by in each msa group 
	for group in df: 
		(msa, n) = group 
		msawt = n['hhwt'].sum()
	# Attach this sum to msa entry in yearly dict
		ydict.append({'msa': msa, 'msawt': msawt})
	print "		Compiled msa weight to dict"	

	# Write yearly dict to a excel workbook where each sheet represents a different year 
	yearlydf = pd.DataFrame(ydict)
	yearlydf.to_excel(wb, str(y))
	wb.save()
	print "		Writing to excel workbook"
