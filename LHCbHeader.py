#!/usr/bin/python
import sys,os

class LHCbHeader:
    def __init__(self, name, configs = None, requirements = None):
        self.name = name
        self.configs = configs
        self.requirements = requirements

    
    def genHeader(self):        
        retstr = "#pragma once\n// from Gaudi\n"
        incl = '#include "%s.h"\n'
        if self.configs.type == 'GaudiFunctionalAlgorithm': 
            incl = incl%('GaudiAlg/'+self.configs.GaudiFunctional)            
        elif self.configs.type=='Tool' :
            incl = incl%('GaudiAlg/GaudiTool')
            if not self.configs.Interface==None: 
                incl += '#include "%s.h"\n'%self.configs.Interface
        elif self.configs.type=='Interface':
            retstr+='\n// from STL\n#include <string>\n\n'
            incl = incl%('GaudiAlg/IAlgTool')
            incl+='static const InterfaceID IID_%s" ( "%s", 1, 0 );\n'%(self.name,self.name)
        elif self.configs.type=='DaVinciAlgorithm':
            incl = incl%('Kernel/DaVinci%sAlgorithm'%(self.configs.DaVinciAlgorithmType if not self.configs.DaVinciAlgorithmType=='Normal' else ''))
        elif self.configs.type=='Algorithm':
            if self.configs.AlgorithmType=='Normal':
                incl = incl%('GaudiAlg/GaudiAlgorithm')
            else:
                incl = incl%('GaudiAlg/Gaudi%sAlg'%(self.configs.AlgorithmType))
        else: incl = '\n'
        retstr+=incl
        if self.configs.type=='GaudiFunctionalAlgorithm':
            retstr+='using namespace Gaudi::Functional;\n\n'
        return retstr
    
    def makebody(self):
        retstr = 'class %s : '%self.name
        if self.configs.type=='DaVinciAlgortihm':
            sub_str = 'public DaVinci%sAlgorithm {\n'%(self.configs.DaVinciAlgorithmType if not self.configs.DaVinciAlgorithmType=='Normal' else '')
            retstr+=substr
        elif self.configs.type=='Algorithm': 
            sub_str = 'public Gaudi%s {\n'%('%sAlg'%(self.configs.AlgorithmType) if not self.configs.AlgorithmType == 'Normal' else 'Algorithm ')
            retstr+=sub_str
        elif self.configs.type=='Interface':
            sub_str = 'virtual public IAlgTool {\n'
            retstr+=sub_str
        elif self.configs.type=='Tool':
            sub_str = 'public GaudiTool'
            if not self.configs.Interface ==None:
                sub_str+=', virtual public %s'%self.configs.Interface
            sub_str+=' {\n'
            retstr+=sub_str
        elif self.configs.type=='GaudiFunctionalAlgorithm':
            substr = 'public Gaudi::Functional::%s<%s(%s)>{\n'%(self.configs.GaudiFunctional,self.configs.GaudiFunctionalOutput, self.configs.GaudiFunctionalInput)
            retstr+=substr
        else: retstr+='\n'
        
        #constructors
        retstr+='public:\n'
        if self.configs.type=='GaudiFunctionalAlgorithm':
            retstr+='\t/// Standard constructor\n\t%s( const std::string& name, ISvcLocator* pSvcLocator ) \n\t\t: %s(name, pSvcLocator,KeyValue("PYTHONAME",{LOCALNAME}))\n\t{}\n\n'%(self.name, self.configs.GaudiFunctional)
            

        elif self.configs.type=='Interface':
            retstr+='\t// Return the interface ID\n\tstatic const InterfaceID& interfaceID() { return IID_%s; }\n'%self.name

        elif self.configs.type=='Tool':
            if not self.configs.Interface==None:
                retstr+='\t// Return the interface ID \n\tstatic const InterfaceID& interfaceID() { return IID_%s; }\n\n'%self.name
            retstr+='\t/// Standard constructor\n\t%s( const std::string& type,\n\t%sconst std::string& name,\n\t%sconst IInterface* parent);'%(self.name,' '*(len(self.name)+2),' '*(len(self.name)+2))            

        else:
            retstr+='\t/// Standard constructor\n\t%s( const std::string& name, ISvcLocator* pSvcLocator );\n'%(self.name)
        
        #destructor and class members
        if self.configs.type=='GaudiFunctionalAlgorithm':
            #retstr+='\n\tvirtual StatusCode initialize();    ///< Algorithm initialization\n'
            # add the new operator () method
            #make a string for the inputs
            retstr+='\n\n\t%s operator() (%s) const override;'%(self.configs.GaudiFunctionalOutput,self.configs.GaudiFunctionalInput)
        elif self.configs.type=='Interface': 
            pass
        else:
            retstr+='\n\tvirtual ~%s( ); ///< Destructor \n'%(self.name)
        if self.configs.type=='Algorithm' or self.configs.type=='DaVinciAlgorithm':
            retstr+='\n\tvirtual StatusCode initialize();    ///< Algorithm initialization\n'
            retstr+='\tvirtual StatusCode execute   ();    ///< Algorithm execution\n'
            retstr+='\tvirtual StatusCode finalize  ();    ///< Algorithm finalization\n'
        retstr+='\n\nprotected:\n\nprivate:\n\n};\n'
        return retstr
