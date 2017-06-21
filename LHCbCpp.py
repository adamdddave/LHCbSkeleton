#!/usr/bin/python
import sys,os,pwd,time
from string import Template
from support import comment

class LHCbCpp:
    def __init__(self, name,configs = None, requirements = None):
        self.name = name
        self.configs = configs
        self.requirements = requirements
        self.configs.date = time.strftime("%Y-%m-%d")
        self.configs.author = (pwd.getpwuid(os.getuid())[4]).split(',')[0]
        curr_path = os.path.dirname(os.path.abspath(__file__))
        if self.configs.type =='GFA':
            the_string = open(curr_path+'/raw_skeletons/raw_GaudiFunctional.cpp','r').read()
            self.configs.operatorParenText = self.configs.GaudiFunctionalOutput + ' ret; return ret;'
            if self.configs.GaudiFunctional=='Consumer':
                self.configs.operatorParenText = 'return;'
        elif self.configs.type == 'T':
            the_string = open(curr_path+'/raw_skeletons/raw_Tool.cpp','r').read()
        elif self.configs.type == 'I':
            the_string = open(curr_path+'/raw_skeletons/raw_Interface.cpp','r').read()
        elif self.configs.type == 'DVA':
            the_string = open(curr_path+'/raw_skeletons/raw_DaVinciAlgorithm.cpp','r').read()
            if self.configs.DaVinciAlgorithmType=='Normal':
                self.configs.DaVinciAlgorithmTypeName=''
            else:
                self.configs.DaVinciAlgorithmTypeName = self.configs.DaVinciAlgorithmType
        elif self.configs.type == 'A':
            if self.configs.AlgorithmType == "Normal":
                self.configs.AlgorithmTypeName='Algorithm'
            else:
                self.configs.AlgorithmTypeName = self.configs.AlgorithmType+'Alg'
            the_string = open(curr_path+'/raw_skeletons/raw_Algorithm.cpp','r').read()
        else:
            the_string = open(curr_path+'/raw_skeletons/raw_class.cpp','r').read()
        temp = Template(the_string)
        self.genText =  temp.safe_substitute(vars(self.configs))


#     def genText(self):
#         ret = '//Include files\n\n'
#         ret+= '//local\n\n'
#         ret+= '#include "%s.h"\n'%self.name
#         ret+= comment('Implementation file for class : %s\n//\n// %s : %s'%(self.name,
#                                                                             time.strftime("%d/%m/%Y"),
#                                                                             (pwd.getpwuid(os.getuid())[4]).split(',')[0]))
        
#         if self.configs.type=='GFA':
#             ret+='using namespace Gaudi::Functional;\n\n'
#         ret+='// Declaration of the factory\nDECLARE_COMPONENT( %s )\n\n\n'%self.name

#         #constructor
#         if not self.configs.type=='GFA':
#             ret+=comment('Standard constructor, initializes variables',sep='=')
#             constr_text = ''
#             if self.configs.type=='A' or self.configs.type=='DVA':
#                 constr_text = 'const std::string& name,\n'+' '*(2*len(self.name))+'    ISvcLocator* pSvcLocator'
#             elif self.configs.type=='T':
#                 constr_text = 'const std::string& type,\n'+' '*(2*len(self.name))+'    const std::string& name,\n'+' '*(2*len(self.name))+'    const IInterface* parent '
#             ret+='%s::%s( %s )'%(self.name,self.name,constr_text)
            
            
#             if self.configs.type=='A':
#                 algtype = ('Algorithm' if self.configs.AlgorithmType=='Normal' else '%sAlg'%self.configs.AlgorithmType)
                
#                 ret+='\n  : Gaudi%s ( name , pSvcLocator )\n{\n\n\n}\n'%algtype
#             elif self.configs.type=='DVA':
#                 algtype = ('' if self.configs.DaVinciAlgorithmType=='Normal' else '%s'%self.configs.DaVinciAlgorithmType)
#                 ret+='\n : DaVinci%sAlgorithm( name , pSvcLocator )\n{\n\n\n}\n'%(algtype)
#             elif self.configs.type=='T':
#                 ret+='\n : GaudiTool ( type, name , parent )\n{\n'
#                 if self.configs.Interface==None:
#                     ret+='\tdeclareInterface<%s>(this);\n'%self.name
#                 else:
#                     ret+='\tdeclareInterface<%s>(this);\n'%self.configs.Interface
#                 ret+='\n}\n\n'
#             else: ret+="{\n\n\n}"
#             ret+='\n\n'
#             #destructor
#             ret+=comment('Destructor',sep='=')
#             ret+='%s::~%s() {} \n\n'%(self.name,self.name)
#             #all other methods are only for algorithms
#             if self.configs.type=='A' or self.configs.type=='DVA':
#                 #initialize
#                 ret+=comment('Initialization',sep='=')
#                 ret+='StatusCode %s::initialize() {\n'%self.name
#                 text_type = ''
#                 if self.configs.type=='A':
#                     if self.configs.AlgorithmType == 'Normal':
#                         text_type = 'GaudiAlgorithm'
#                     else:
#                         text_type= 'Gaudi%sAlg'%self.configs.AlgorithmType
#                 if self.configs.type=='DVA':
#                     if self.configs.DaVinciAlgorithmType == 'Normal':
#                         text_type = 'DaVinciAlgorithm'
#                     else:
#                         text_type='DaVinci%sAlgorithm'%self.configs.DaVinciAlgorithmType
#                 ret+='\tStatusCode sc = %s::initialize(); // must be executed first\n'%(text_type)
#                 ret+='\tif ( sc.isFailure() ) return sc;  // error printed already by GaudiAlgorithm\n\n'
#                 ret+='\tif ( msgLevel(MSG::DEBUG) ) debug() << "==> Initialize" << endmsg;\n\n'
#                 ret+='\treturn StatusCode::SUCCESS; \n}\n\n'
#                 #execute
#                 ret+=comment('Main execution',sep='=')
#                 ret+='StatusCode %s::execute() {\n\n'%self.name
#                 ret+='\tif ( msgLevel(MSG::DEBUG) ) debug() << "==> Execute" << endmsg;\n'
#                 if self.configs.type=='DVA':
#                     ret+='\tsetFilterPassed(true);  // Mandatory. Set to true if event is accepted.\n'
#                 ret+='\treturn StatusCode::SUCCESS;\n}\n'
#                 #finalize
#                 ret+=comment('Finalize',sep='=')
#                 ret+='StatusCode %s::finalize() {\n\n'%self.name
#                 ret+='\tif ( msgLevel(MSG::DEBUG) ) debug() << "==> Finalize" << endmsg;\n\n'
#                 algtype = 'Algorithm'
#                 if self.configs.type=='A':
#                     algtype = ('GaudiAlgorithm' if self.configs.AlgorithmType=='Normal' else 'Gaudi%sAlg'%self.configs.AlgorithmType)
#                 else:
#                     algtype = 'DaVinci%s'%(self.configs.DaVinciAlgorithmType if not self.configs.DaVinciAlgorithmType=='Normal' else '')+algtype
#                 ret+='\treturn %s::finalize();\n'%algtype
#                 ret+='}\n\n'
        
#         #gaudi functional
#         else:
#             ret+='\n'
#             ret+=comment('operator () implementation',sep='=')
#             inputstr = ''
#             counter = 1;
#             if not self.configs.GaudiFunctional=='Producer':
#                 ret+='%s %s::operator() (const %s &) const {\n\n'%(self.configs.GaudiFunctionalOutput, self.name, self.configs.GaudiFunctionalInput)
#             else:
#                 ret+='%s %s::operator() () const {\n\n'%(self.configs.GaudiFunctionalOutput, self.name)
#             retstr = ''
#             if not self.configs.GaudiFunctional=='Consumer':
#                 ret+='\t %s ret;\n'%self.configs.GaudiFunctionalOutput
#                 retstr = 'ret'
#             ret+='\t return %s;\n}'%retstr
#         ret+=comment(isFinal=True,sep='=')
#         return ret
