import subprocess


# Run a stata do file with any parameters 
def dostata(dofile, *params): 
	cmd = ["C:/Program Files (x86)/Stata12/StataSE-64", "do", dofile]
	[cmd.append(p) for p in params]
	subprocess.call(cmd, shell = 'true')


dostata("M:/IPUMS/hhstress_code/compute_hhstress.do")
