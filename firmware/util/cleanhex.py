#!/usr/bin/env python3
#
# Remove section address lines from a hex file from objdump
# and reformat so that no addresses are missing and all
# lines are 16 bytes each

import sys
import os

filename = sys.argv[1]
alltokens = []
address = 0

with open(filename, 'r') as ifile:
    hexlines = ifile.readlines()
    for line in hexlines:
        if line.startswith('@'):
            oldaddress = address
            address = int(line[1:],16)
            if address > oldaddress:
                print('Warning:  Address mismatch at ' + str(address))
                numpad = address - oldaddress
                print('          Padding with ' + str(numpad) + ' zeros.')
                for i in range(0, numpad):
                    alltokens.append('00')
            elif address < oldaddress:
                print('Error:  Address mismatch at ' + str(address))
                print('        Expected address was ' + str(oldaddress))
        else:
            tokens = line.strip().split()
            address += len(tokens)
            alltokens.extend(tokens)

rootname = os.path.splitext(filename)[0]
outfilename = rootname + '_out.hex'
 
print('Total number of bytes: ' + str(len(alltokens)))
print('Total number of lines: ' + str(len(alltokens) / 16))

with open(outfilename, 'w') as ofile:
    print('@00000000', file=ofile)
    for i in range(0, len(alltokens), 16):
        print(' '.join(alltokens[i:i + 16]), file=ofile)
        
