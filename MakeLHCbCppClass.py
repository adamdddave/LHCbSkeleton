#!/usr/bin/python
# What:  python tool to replace emacs template for LHCb Algorithms
# Author: Adam Davis
# Date: 29/03/2017

import sys,os,pwd,time
from optparse import OptionParser
from LHCbHeader import LHCbHeader
from LHCbCpp import LHCbCpp
from support import * #doxyComment,comment,exists
#possibilities
headerConfigs= { 'algorithm': ['Algorithm','GaudiFunctionalAlgorithm','DaVinciAlgorithm','Tool','Interface','simple'],
                 'DVtype' : ['Normal','Histo','Tuple'],
                 'GFtype' : ['Producer','Consumer','Transformer','MultiTransformer','SplittingTransformer','MergingTransformer','FilterPredicate','MultiTransformerFilter'],
                 'NAtype' : ['Normal','Histo','Tuple'],
                 }

def make_files(options,name):
    ####Type parsing. 
    ###check for no options given
    if options.type==None:
        atype = raw_input('Create Algorithm, DaVinciAlgorithm, GaudiFunctionalAlgorithm, Tool, Interface or simple class  A/D/F/T/I/[no] : ')
        if atype=='A':
            options.type = 'Algorithm'
        elif atype=='F':
            options.type = 'GaudiFunctionalAlgorithm'
        elif atype=='D':
            options.type = 'DaVinciAlgorithm'
        elif atype=='T':
            options.type = 'Tool'
            if options.Interface==None:
                itype = raw_input('Interface name (blank = not using an interface) : ')
                if itype=='': itype = None
                options.Interface=itype
        elif atype=='I':
            options.type = 'Interface'
        else:
            options.type = 'simple'
    #type parsing
    elif options.type=='Tool' and options.Interface==None:
        itype = raw_input('Interface name (blank = not using an interface) : ')
        options.Interface=itype
    else: pass
    ###parse functional settings    
    
    if options.type=='GaudiFunctionalAlgorithm' and options.GaudiFunctional==None:
        gtype = raw_input('Transformer, Producer, Consumer, MultiTransformer [T]/P/C/M : ')#add later , MultiTransformerFilter or FilterPredicate
        if gtype=="T" or gtype=='':
            options.GaudiFunctional= "Transformer"
        elif gtype=="P":
            options.GaudiFunctional="Producer"
        elif gtype=="C":
            options.GaudiFunctional="Consumer"
        elif gtype=="M":
            options.GaudiFunctional="MultiTransformer"
        else: 
            print 'input unknown option! cannot parse!'
            sys.exit()
#         elif gtype=="MTF":
#             options.GaudiFunctional="MultiTransformerFilter"
#         else:
#             options.GaudiFunctional="FilterPredicate"
    #add parsing of input/output
    #input
    if options.type=='GaudiFunctionalAlgorithm' and options.GaudiFunctionalInput==None and not options.GaudiFunctional=='Producer':
        #should be a single string
        print 'parsing input'
        ip = raw_input('Do you want to declare the input type(s)? [y]/n : ')
        if 'y'==ip or ''==ip:
            inputtxt = raw_input('please give the input (concatenate with ;) : ')            
            if '' == inputtxt:
                print "you didn't give an input text! appending 'INPUT'"
                options.GaudiFunctionalInput = 'INPUT'
            else:
                thething = ''
                for thing in inputtxt.split(';'):
                    thething+=thing.rstrip()
                    if not thing == inputtxt.split(';')[-1]:
                        thething +=', '
                options.GaudiFunctionalInput = thething
        else: options.GaudiFunctionalInput = 'INPUT'        
    else:
        options.GaudiFunctionalInput=''
    #output
    if options.type=='GaudiFunctionalAlgorithm' and options.GaudiFunctionalOutput==None and not options.GaudiFunctional=='Consumer':
        print 'parsing output'
        ip = raw_input('Do you want to declare the output type(s)? [y]/n : ')
        if 'y'==ip or ''==ip:
            inputtxt = raw_input('please give the output (concatenate with ;) : ')
            if ''==inputtxt:
                print "you didn't give an input text! appending 'OUTPUT'"
                options.GaudiFunctionalOutput = 'OUTPUT'
            else:
                thething = ''
                for thing in inputtxt.split(';'):
                    thething+=thing.rstrip()
                    if not thing == inputtxt.split(';')[-1]:
                        thething+=', '
                options.GaudiFunctionalOutput = thething
        else:
            options.GaudiFunctionalOutput = 'OUTPUT'
    else:
        options.GaudiFunctionalOutput = 'void'
    #print'input', options.GaudiFunctionalInput
    #print 'output',options.GaudiFunctionalOutput
    
    ###parse normal/davinci settings
    
    ##algorithm settings
    if options.type=='Algorithm' and options.AlgorithmType==None:
        btype = raw_input('Normal, Histo or Tuple [N]/H/T :')
        if btype =='' or btype == 'N': options.AlgorithmType='Normal'
        elif btype=='H': options.AlgorithmType='Histo'
        elif btype=='T': options.AlgorithmType='Tuple'
        else: 
            print 'input unknown option! cannot parse!'
            sys.exit()
    if options.type=='DaVinciAlgorithm' and options.DaVinciAlgorithmType==None:
        btype = raw_input('Normal, Histo or Tuple [N]/H/T :')
        if btype =='' or btype == 'N': options.DaVinciAlgorithmType='Normal'
        elif btype=='H': options.DaVinciAlgorithmType='Histo'
        elif btype=='T': options.DaVinciAlgorithmType='Tuple'
        else: 
            print 'input unknown option! cannot parse!'
            sys.exit()
    #good to go, make some useful things:
    
#    print 'now using options',options
    thing = LHCbHeader(name,options)
    # print '-'*50
    # print 'Generating header'
    # print '-'*50
    if options.HeaderOnly==True and not exists(name+'.h'):
        ret = thing.genHeader()
        ret+= doxyComment(first=True, text = name)
        ret+= thing.makebody()
        if options.write==True:
            f_dot_h = open(name+'.h','w')
            f_dot_h.write(ret)
            f_dot_h.close()
        print ret
    else: pass#print name+'.h exists!'
    # print '-'*50
    # print 'Generating cpp'
    # print '-'*50
    thing2 = LHCbCpp(name,options)
    if options.cppOnly==True and not exists(name+'.cpp'):
        if options.write==True:
            f_dot_cpp = open(name+'.cpp','w')
            f_dot_cpp.write(thing2.genText())
            f_dot_cpp.close()
        print thing2.genText()
    else: pass#print name+'.cpp exists!'

#parse options    
#classes for header and .cpp file.

if __name__ == "__main__":
    usage = "usage: %prog [options] name"
    parser = OptionParser( usage = usage )
    parser.add_option('-t','--type',action='store',dest='type',help="Create Algorithm type %s"%headerConfigs['algorithm'])
    parser.add_option('-f','--GaudiFunctional',action='store',help='Gaudi Functional Algorithm type %s'%headerConfigs['GFtype'])
    parser.add_option('-d','--DaVinciAlgorithmType',action='store',help='DaVinci Algorithm type %s'%headerConfigs['DVtype'])
    parser.add_option('-a','--AlgorithmType',action='store',help = 'Normal Algorithm type %s'%headerConfigs['NAtype'])
    parser.add_option('-I','--Interface', action='store', help = 'Interface (name interpreted for use here)')
    parser.add_option('-T','--Tool', action='store',help = 'Tool (can also provide -i flag too)')
    parser.add_option('-i','--GaudiFunctionalInput',action='append',help='Input for Gaudi Functional Algorithm')
    parser.add_option('-o','--GaudiFunctionalOutput',action='append',help='Output for Gaudi Functional Algorithm')
    parser.add_option('-H','--HeaderOnly',action='store_true',help='Only generate the header')
    parser.add_option('-C','--cppOnly',action='store_true',help='Only generate the .cpp implementation')
    parser.add_option('-W','--write', action='store_true',help='Use the python script to write the output')
    (options, args) = parser.parse_args()
    if len(args)==0: 
        print 'need a class name!'
        sys.exit()
    #todo: parse length of input and output to determine type
    #pass
    make_files(options,args[0])

