#!/usr/bin/python
#helpers
import sys,os,pwd,time
def doxyComment(text='',first = False):
    retstr = "/**\n"
    if first==True:
        retstr+='* @class %s %s.h %s\n'%(text, text, text)
    else: retstr+= "* %s\n"%text
    retstr+= "*\n"*3
    if first==True:
        retstr+= "* @author %s\n"%(pwd.getpwuid(os.getuid())[4])
        retstr+= "* @date   %s\n"%(time.strftime("%d/%m/%Y"))
    retstr+="*/"
    return retstr
def comment(text='',sep = '-',isFinal=False):
    com = "//"+sep*75
    return ("%s\n// %s\n%s\n"%(com,text,com) if isFinal==False else com)

def exists(file):
    return os.path.isfile(file) 
