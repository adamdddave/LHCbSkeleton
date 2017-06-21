#!/usr/bin/python
import sys,os
from string import Template
from support import * #doxyComment,comment,exists
class LHCbHeader:
    def __init__(self, name, configs = None, requirements = None):
        self.name = name
        self.configs = configs
        self.configs.name = name
        self.requirements = requirements
        self.configs.comment = doxyComment(first=True, text = name)
        the_string = ''
        curr_path = os.path.dirname(os.path.abspath(__file__))

        if self.configs.type =='GFA':
            the_string = open(curr_path+'/raw_skeletons/raw_GaudiFunctional.h','r').read()
            funcIO = ''
            if self.configs.GaudiFunctional=='Producer':
                #no input, only output
                funcIO = 'KeyValue("OutputLocation",{"OUTPUTLOCATION"})'
            elif self.configs.GaudiFunctional=='Transformer':
                funcIO = 'KeyValue("InputLocation",{"INPUTLOCATION"}),\nKeyValue("OutputLocation",{"OUTPUTLOCATION"})'
            elif self.configs.GaudiFunctional=='Consumer':
                funcIO = 'KeyValue("OutputLocation",{"OUTPUTLOCATION"})'
            elif self.configs.GaudiFunctional=='MultiTransformer':
                funcIO = '{KeyValue("Input1",{"INPUT1LOC"}),\n KeyValue("Input2",{"INPUT2LOC"})},\n{KeyValue("Output1",{"OUTPUTLOC1"}),\n KeyValue("Output2",{"OUTPUTLOC2"})}'
            self.configs.funcIO = funcIO

        elif self.configs.type == 'T':
            the_string = open(curr_path+'/raw_skeletons/raw_Tool.h','r').read()

        elif self.configs.type == 'I':
            the_string = open(curr_path+'/raw_skeletons/raw_Interface.h','r').read()

        elif self.configs.type == 'DVA':
            if self.configs.DaVinciAlgorithmType=='Normal':
                self.configs.DaVinciAlgorithmTypeName=''
            else:
                self.configs.DaVinciAlgorithmTypeName = self.configs.DaVinciAlgorithmType
            the_string = open(curr_path+'/raw_skeletons/raw_DaVinciAlgorithm.h','r').read()

        elif self.configs.type == 'A':
            if self.configs.AlgorithmType == "Normal":
                self.configs.AlgorithmTypeName='Algorithm'
            else:
                self.configs.AlgorithmTypeName = self.configs.AlgorithmType+'Alg'
            the_string = open(curr_path+'/raw_skeletons/raw_Algorithm.h','r').read()

        else:
            the_string = open(curr_path+'/raw_skeletons/raw_class.h','r').read()
        temp = Template(the_string)
        self.genText =  temp.safe_substitute(vars(self.configs))
