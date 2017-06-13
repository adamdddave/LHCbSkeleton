#!/usr/bin/python
# What:  python tool to replace emacs template for LHCb Algorithms
# Author: Adam Davis
# Date: 29/03/2017
# Updated: 11/06/2017

import sys,os,pwd,time
from optparse import OptionParser
from LHCbHeader import LHCbHeader
from LHCbCpp import LHCbCpp
from support import * #doxyComment,comment,exists
#possibilities
headerConfigs= { 'algorithm': ['A (Algorithm)','GFA (GaudiFunctionalAlgorithm)','DVA (DaVinciAlgorithm)','T (Tool)','I (Interface)','simple'],
                 'DVtype' : ['Normal','Histo','Tuple'],
                 'GFtype' : ['Producer','Consumer','Transformer','MultiTransformer'],#,'SplittingTransformer','MergingTransformer','FilterPredicate','MultiTransformerFilter'
                 'NAtype' : ['Normal','Histo','Tuple'],
                 }

def make_files(options,name):
    ###parse the name.
    #print 'name = ',name
    options.cpp = False
    options.Header=False
    if '.cpp' in name:
        options.cpp = True
        name = name.split('.cpp')[0]
    if '.h' in name:
        options.Header = True
        name = name.split('.h')[0]
    #case of no .cpp or h given
        #print 'parsing .cpp'
    ####Type parsing. 
    ##NOTE: This is really only supported for command line, e.g. tty
    if options.type==None:
        atype = raw_input("Create Algorithm, DaVinciAlgorithm, GaudiFunctionalAlgorithm, Tool, Interface or simple class  A/D/F/T/I/[no] : ").upper()#upper to break possible problems
        if atype=='':
            options.type='S'
        elif atype=='A':
            options.type = 'A'
        elif atype=='D':
            options.type = 'DVA'
        elif atype=='F':
            options.type = 'GFA'
        elif atype=='T':
            options.type = 'T'
            if options.Interface==None and options.isTTY==True:
                itype = raw_input("Interface name (blank = not using an interface) : ")
                if itype=='': itype = None
                options.Interface=itype
            else:
                options.Interface=None
        elif atype=='I':
            options.type = 'I'
        else:
            options.type = 'S'
    #type parsing
    elif options.type=='T' and options.Interface==None and options.isTTY==True:
#TODO add interface="" exception
        itype = raw_input("Interface name (blank = not using an interface) : ")
        options.Interface=itype
    else: pass
    ###parse functional settings    
    
    if options.type=='GFA' and options.GaudiFunctional==None:
        gtype = raw_input("Transformer, Producer, Consumer, MultiTransformer [T]/P/C/M : ")#add later , MultiTransformerFilter or FilterPredicate
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
    #add parsing of input/output
    #input
    if options.type=='GFA' and options.GaudiFunctionalInput==None and not options.GaudiFunctional=='Producer':
        
#         #should be a single string
#         #print 'parsing input'
#         ip = raw_input("Do you want to declare the input type(s)? [y]/n : ")
#         if 'y'==ip or ''==ip:
#             inputtxt = raw_input("please give the input (concatenate with ;) : ")
#             if '' == inputtxt:
#                 print "you didn't give an input text! appending 'INPUT'"
#                 options.GaudiFunctionalInput = 'INPUT'
#             else:
#                 thething = ''
#                 for thing in inputtxt.split(';'):
#                     thething+=thing.rstrip()
#                     if not thing == inputtxt.split(';')[-1]:
#                         thething +=', '
#                 options.GaudiFunctionalInput = thething
#         else:
        options.GaudiFunctionalInput = 'INPUT'        
    else:
        options.GaudiFunctionalInput=''
    #output
    if options.type=='GFA' and options.GaudiFunctionalOutput==None and not options.GaudiFunctional=='Consumer':
        # print 'parsing output'
#         ip = raw_input("Do you want to declare the output type(s)? [y]/n : ")
#         if 'y'==ip or ''==ip:
#             inputtxt = raw_input("please give the output (concatenate with ;) : ")
#             if ''==inputtxt:
#                 print "you didn't give an input text! appending 'OUTPUT'"
#                 options.GaudiFunctionalOutput = 'OUTPUT'
#             else:
#                 thething = ''
#                 for thing in inputtxt.split(';'):
#                     thething+=thing.rstrip()
#                     if not thing == inputtxt.split(';')[-1]:
#                         thething+=', '
#                 options.GaudiFunctionalOutput = thething
#         else:
        options.GaudiFunctionalOutput = 'OUTPUT'
    else:
        options.GaudiFunctionalOutput = 'void'
    #print'input', options.GaudiFunctionalInput
    #print 'output',options.GaudiFunctionalOutput
    
    ###parse normal/davinci settings
    
    ##algorithm settings
    if options.type=='A':
        if options.AlgorithmType==None and options.isTTY == True:
            btype = raw_input("Normal, Histo or Tuple [N]/H/T :")
            if btype =='' or btype == 'N': options.AlgorithmType='Normal'
            elif btype=='H': options.AlgorithmType='Histo'
            elif btype=='T': options.AlgorithmType='Tuple'
            else: 
                print 'input unknown option! cannot parse!'
                sys.exit()
        elif options.AlgorithmType==None and isTTY==False: options.AlgorithmType='Normal'
        elif options.AlgorithmType=='H': options.AlgorithmType='Histo'
        elif options.AlgorithmType=='T': options.AlgorithmType='Tuple'
        elif options.AlgorithmType=='N': options.AlgorithmType='Normal'
    if options.type=='DVA':
        if options.DaVinciAlgorithmType==None and options.isTTY==True:
            btype = raw_input("Normal, Histo or Tuple [N]/H/T :")
            if btype =='' or btype == 'N': options.DaVinciAlgorithmType='Normal'
            elif btype=='H': options.DaVinciAlgorithmType='Histo'
            elif btype=='T': options.DaVinciAlgorithmType='Tuple'
            else: 
                print 'input unknown option! cannot parse!'
                sys.exit()
        elif options.DaVinciAlgorithmType==None and options.isTTY==False:
            options.DaVinciAlgorithmType='Normal'
        elif options.DaVinciAlgorithmType=="H": options.DaVinciAlgorithmType='Histo'
        elif options.DaVinciAlgorithmType=="T": options.DaVinciAlgorithmType='Tuple'
        elif options.DaVinciAlgorithmType=="N": options.DaVinciAlgorithmType='Normal'
    #good to go, make some useful things:
    print 'dumping info'
    print 'options = ', options
    #print 'btype = ', btype
    # print 
#    print 'now using options',options
    thing = LHCbHeader(name,options)
    # print '-'*50
    # print 'Generating header'
    # print '-'*50
    if options.Header==True and not exists(name+'.h'):
        ret = thing.genHeader()
        ret+= doxyComment(first=True, text = name)
        ret+= thing.makebody()
        # if options.write==True:
#             f_dot_h = open(name+'.h','w')
#             f_dot_h.write(ret)
#             f_dot_h.close()
        print ret
    else: pass#print name+'.h exists!'
    # print '-'*50
    # print 'Generating cpp'
    # print '-'*50
    thing2 = LHCbCpp(name,options)
    if options.cpp==True and not exists(name+'.cpp'):
        # if options.write==True:
#             f_dot_cpp = open(name+'.cpp','w')
#             f_dot_cpp.write(thing2.genText())
#             f_dot_cpp.close()
        print thing2.genText()
    else: pass#print name+'.cpp exists!'

#parse options    
#classes for header and .cpp file.

if __name__ == "__main__":
    # if (os.isatty(0)) : print "stdin is a tty"
    # if (os.isatty(1)) : print "stdout is a tty"
    # if (os.isatty(2)) : print "stderr is a tty"

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
    #parser.add_option('-H','--Header',action='store_true',help=' generate the header')
    #parser.add_option('-C','--cpp',action='store_true',help=' generate the .cpp implementation')
    #parser.add_option('-W','--write', action='store_true',help='Use the python script to write the output')
    (options, args) = parser.parse_args()
    print '*'*50
    print options
    print args
    print '*'*50
    options.isTTY = (os.isatty(0)) and (os.isatty(1)) and (os.isatty(2))
    if len(args)==0: 
        print 'need a class name!'
        sys.exit()
    make_files(options,args[0])

