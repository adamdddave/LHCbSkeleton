#!/usr/bin/python
import sys,os,pwd,time
from support import comment

class LHCbCpp:
    def __init__(self, name,configs = None, requirements = None):
        self.name = name
        self.configs = configs
        self.requirements = requirements
    


    def genText(self):
        ret = '//Include files\n\n'
        if self.configs.type=='Algorithm' or self.configs.type=='DaVinciAlgorithm':
            ret+='#include "GaudiKernel/AlgFactory.h"\n\n'
        elif self.configs.type=='Tool':
            ret+='#include "GaudiKernel/ToolFactory.h"\n\n'
        ret+='//local\n\n'
        ret+= '#include "%s.h"\n'%self.name
        ret+= comment('Implementation file for class : %s\n//\n// %s : %s'%(self.name,
                                                                            time.strftime("%d/%m/%Y"),
                                                                            pwd.getpwuid(os.getuid())[4]))
        if self.configs.type=='Algorithm' or self.configs.type=='DaVinciAlgorithm' or self.configs.type=='GaudiFunctionalAlgorithm':
            ret+='// Declaration of the Algorithm Factory\nDECLARE_ALGORITHM_FACTORY( %s )\n\n\n'%self.name

        elif self.configs.type=='Tool':
            ret+='// Declaration of the Tool Factory\nDECLARE_TOOL_FACTORY( %s )\n\n\n'%self.name
        #constructor
        if not self.configs.type=='GaudiFunctionalAlgorithm':
            ret+=comment('Standard constructor, initializes variables',sep='=')
            constr_text = ''
            if self.configs.type=='Algorithm' or self.configs.type=='DaVinciAlgorithm':
                constr_text = 'const std::string& name,\n'+' '*(2*len(self.name))+'    ISvcLocator* pSvcLocator'
            elif self.configs.type=='Tool':
                constr_text = 'const std::string& type,\n'+' '*(2*len(self.name))+'    const std::string& name,\n'+' '*(2*len(self.name))+'    const IInterface* parent '
            ret+='%s::%s( %s )'%(self.name,self.name,constr_text)
            
            
            if self.configs.type=='Algorithm':
                algtype = ('Algorithm' if self.configs.AlgorithmType=='Normal' else '%sAlg'%self.configs.AlgorithmType)
                
                ret+='\n  : Gaudi%s ( name , pSvcLocator )\n{\n\n\n}\n'%algtype
            elif self.configs.type=='DaVinciAlgorithm':
                algtype = ('' if self.configs.DaVinciAlgorithmType=='Normal' else '%s'%self.configs.DaVinciAlgorithmType)
                ret+='\n : DaVinci%sAlgorithm( name , pSvcLocator )\n{\n\n\n}\n'%(algtype)
            elif self.configs.type=='Tool':
                ret+='\n : GaudiTool ( type, name , parent )\n{\n'
                if self.configs.Interface==None:
                    ret+='\tdeclareInterface<%s>(this);\n'%self.name
                else:
                    ret+='\tdeclareInterface<%s>(this);\n'%self.configs.Interface
                ret+='\n}\n\n'
            else: pass
            #destructor
            ret+=comment('Destructor',sep='=')
            ret+='%s::~%s() {} \n\n'%(self.name,self.name)
            #all other methods are only for algorithms
            if self.configs.type=='Algorithm' or self.configs.type=='DaVinciAlgorithm':
                #initialize
                ret+=comment('Initialization',sep='=')
                ret+='StatusCode %s::initialize() {\n'%self.name
                ret+='\tStatusCode sc = GaudiHistoAlg::initialize(); // must be executed first\n'
                ret+='\tif ( sc.isFailure() ) return sc;  // error printed already by GaudiAlgorithm\n\n'
                ret+='\tif ( msgLevel(MSG::DEBUG) ) debug() << "==> Initialize" << endmsg;\n\n'
                ret+='\treturn StatusCode::SUCCESS; \n}\n\n'
                #execute
                ret+=comment('Main execution',sep='=')
                ret+='StatusCode %s::execute() {\n\n'%self.name
                ret+='\tif ( msgLevel(MSG::DEBUG) ) debug() << "==> Execute" << endmsg;\n'
                if self.configs.type=='DaVinciAlgorithm':
                    ret+='\tsetFilterPassed(true);  // Mandatory. Set to true if event is accepted.\n'
                ret+='\treturn StatusCode::SUCCESS;\n}\n'
                #finalize
                ret+=comment('Finalize',sep='=')
                ret+='StatusCode %s::finalize() {\n\n'%self.name
                ret+='\tif ( msgLevel(MSG::DEBUG) ) debug() << "==> Finalize" << endmsg;\n\n'
                algtype = 'Algorithm'
                if self.configs.type=='Algorithm':
                    algtype = ('GaudiAlgorithm' if self.configs.AlgorithmType=='Normal' else 'Gaudi%sAlg'%self.configs.AlgorithmType)
                else:
                    algtype = 'DaVinci%s'%(self.configs.DaVinciAlgorithmType if not self.configs.DaVinciAlgorithmType=='Normal' else '')+algtype
                ret+='\treturn %s::finalize();\n'%algtype
                ret+='}\n\n'

        #gaudi functional
        else:
            ret+='\n'
            ret+=comment('operator () implementation',sep='=')
            inputstr = ''
            counter = 1;
            inputstr=''
            for thing in self.configs.GaudiFunctionalInput.split(','):
                inputstr = thing+' input%s'%counter
                if not thing ==self.configs.GaudiFunctionalInput.split(',')[-1]:
                    inputstr+=', '
                counter+=1
            ret+='%s %s::operator() (%s) const {\n\n'%(self.configs.GaudiFunctionalOutput, self.name, inputstr)
            retstr = ''
            if not self.configs.GaudiFunctional=='Consumer':
                ret+='\t %s ret;\n'%self.configs.GaudiFunctionalOutput
                retstr = 'ret'
            ret+='\t return %s;\n}'%retstr
        ret+=comment(isFinal=True,sep='=')
        return ret
