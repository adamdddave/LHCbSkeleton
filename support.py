#!/usr/bin/python
#helpers
import sys,os,pwd,time
def doxyComment(text='',first = False):
    retstr = "/*"
    if first==True:
        cwd = os.getcwd().split('/')[-1]
        retstr+='* @class %s %s.h %s.h\n'%(text, text, cwd+'/'+text)
    else: retstr+= "* %s\n"%text
    retstr+= "*\n"*2
    if first==True:
        retstr+= "* @author %s\n"%((pwd.getpwuid(os.getuid())[4]).split(',')[0])
        retstr+= "* @date   %s\n"%(time.strftime("%Y-%m-%d"))
    retstr+="*/\n"
    return retstr
def comment(text='',sep = '-',isFinal=False):
    com = "//"+sep*75
    return ("%s\n// %s\n%s\n"%(com,text,com) if isFinal==False else com)

def exists(file):
    return os.path.isfile(file) 
