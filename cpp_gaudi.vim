" @file cpp_gaudi.vim
"
" @brief vim integration for the new MakeLHCbCppClass python code
"
" This file contains the internals to the following user-facing commands:
"
" - GaudiAnything (fully interactive)
" - GaudiAlgorithm, GaudiHistoAlg, GaudiTupleAlg
" - GaudiTool, GaudiHistoTool, GaudiTupleTool
" - DaVinciAlgorithm, DaVinciHistoAlg, DaVinciTupleAlg
" - GaudiInterface
" - missing: functional algorithms
"
" In general, these commands will ask the user interactively if there are
" questions to be asked, and the user can use the Tab key to show possible
" completions, or the shortest unambiguous prefix to the desired answer (case
" insensitive).
"
" This script takes care to not get into the user's way: there are no
" automatically executed commands when opening C++ files that would force you
" to use the commands present in this script, nor are there any other
" conventions that the script forces on the user. It does however provide
" convenient shortcuts to use the wizard capabilities of the MakeLHCbCppClass
" script in a vim-compatible manner. Tab completion works at all prompts, so
" using the functionality in this script should be as painless as possible.
"
" Installation instructions:
" 1. In your ~/.vim directory, create a ftplugin directory:
"
"    mkdir -p ~/.vim/ftplugin
"
" 2. Move or copy this script file there.
" 3. If you haven't done so already, put 'filetype plugin on' in your
"    ~/.vimrc; you may even want to use instead the more featureful
"    'filetype plugin indent on'
"
" This script likely needs a recent version of vim, i.e. vim 7.4 or newer
" (older versions may or may not work).
"
" @author Manuel Schiller <Manuel.Schiller@cern.ch>
" @date 2017-04-03
" - initial version, neither complete nor bug-free, and also limited by bugs
"   in MakeLHCbCppClass
" @date 2017-04-04
" - code cleanups, add machinery to find the MakeLHCbCppClass.py script
"   automagically
"
" @note This script builds on ideas in earlier work by Kurt Rinnert who
" 'rolled his own' at some point in the past which has been passed around by
" vi enthusiasts by mail and USB sticks. I took the liberty to borrow some of
" the command names from Kurt's excellent work, and acknowledge his efforts
" (which have made my life a lot easier in the past).

" avoid loading this twice, or in nocompatible mode
if exists("loaded_cpp_gaudi") || &cp
    finish
endif

" little helper to search for the python part in a few reasonable places
function! <SID>_GaudiFindPythonScript(vimscriptpath)
    " check $LBSCRIPTS_HOME, the path, the directory in which the vim script
    " is located and finally the current directory
    "
    " the first match wins, and is saved to s:scriptpath, which is used
    " elsewhere in the script
    let l:scriptpathlist=[
\       $LBSCRIPTS_HOME . "/InstallArea/scripts/MakeLHCbCppClass.py",
\       substitute(
\           system("which MakeLHCbCppClass.py 2>/dev/null"), '\n\+$', '', ''),
\       expand(a:vimscriptpath . ':p:h') . "/MakeLHCbCppClass.py",
\       "./MakeLHCbCppClass.py" ]
    for p in l:scriptpathlist
        if getfperm(p) =~ 'r.\+x'
            let s:scriptpath=l:p
            return
        endif
    endfor
    echo "MakeLHCbCppClass.py not found!"
endfunction

" a little helper to make vim complete in our prompts
function! _GaudiPromptCompl(arglead, cmdline, cursorpos)
    " FIXME: is there a way to limit the scope of this routine, too, just as
    " it's done for the others with '<SID>functionName'? - Manuel
    return s:prompt_compl_alternatives
endfunction

" ask the user questions in the status line, allow completion
"
" this routine does all the heavy lifting when the user is required to select
" among several alternatives
function! <SID>_GaudiPrompt(prompt, alternatives)
    if "" != a:prompt
        let l:prompt=a:prompt
    else
        let l:prompt=map(copy(a:alternatives),
\           '"(" . v:val[0] . ")" . v:val[1:]')
        let l:prompt=join(l:prompt, ", ") . "? "
    endif
    " set up completion
    let s:prompt_compl_alternatives=join(a:alternatives, "\n")
    " set up matching
    let l:matchlist=map(copy(a:alternatives), 'tolower(v:val)')
    " set up prompt to use
    let l:useprompt=l:prompt
    " ask user until they provide a reasonable answer
    let l:prompt_reply=-1
    while -1 == l:prompt_reply
        " prompt with completion
        call inputsave()
        let l:prompt_reply=tolower(input(l:useprompt, "",
\           "custom,_GaudiPromptCompl"))
        call inputrestore()
        " check against list of alternatives (case insensitive)
        let l:prompt_reply=match(l:matchlist, "^" . l:prompt_reply)
        " assume user botched it
        let l:useprompt="try again: " . l:prompt
    endwhile
    " user provided valid choice - go to pretty format
    let l:prompt_reply=get(a:alternatives, l:prompt_reply)
    return l:prompt_reply
endfunction

" use supplied type, ask user if nothing supplied
function! <SID>_GaudiAskType(type)
    if "" == a:type
        return <SID>_GaudiPrompt("Type of Gaudi entity " .
\               "(Tab shows completions)? ",
\               ["Algorithm", "DaVinciAlgorithm", "FunctionalAlgorithm",
\               "Interface", "Tool"])
    else
        return a:type
    endif
endfunction

" use supplied subtype, ask user if nothing supplied
function! <SID>_GaudiAskSubtype(type, subtype)
    if "" == a:subtype
        if a:type =~ '^\(Algorithm\|DaVinciAlgorithm\|Tool\)'
            return <SID>_GaudiPrompt("type of " . a:type . " " .
\                  "(Tab shows completions): ",
\                  ["Normal", "Histo", "Tuple" ])
        elseif a:type =~ "^FunctionalAlgorithm"
            return <SID>_GaudiPrompt("type of FunctionalAlgorithm " .
\                  "(Tab shows completions): ",
\                  ["Producer", "Consumer", "Transformer",
\                  "MultiTransformer", "SplittingTransformer",
\                  "MergingTransformer", "FilterPredicate",
\                  "MultiTransformerFilter"])
        endif
    else
        return a:subtype
    endif
endfunction

" transform a type into a command line argument
function! <SID>_GaudiType2CmdLine(type)
    return "--type=" . a:type
endfunction

" transform a subtype to a command line argument
function! <SID>_GaudiSubtype2CmdLine(type, subtype)
    return "--AlgorithmType=" . a:subtype
endfunction

" return the command line argument for headers or implementation files
function! <SID>_GaudiHeaderOrCpp2CmdLine(isheader)
    if a:isheader
        return "--HeaderOnly"
    else
        return "--cppOnly"
    endif
endfunction

" ask which interfaces a Tool/Algorithm/DaVinciAlgorithm should conform to
function! <SID>_GaudiAskInterfaces(type, cmdline, interfaces)
    if a:type =~ '^Tool'
        " no sensible default here, so we can use straight input
        if "" != a:interfaces
            let l:interfaces=a:interfaces
        else
            call inputsave()
            let l:interfaces=input("semicolon-separated list of interfaces " .
\               "[default=none]: ")
            call inputrestore()
        endif
        if "" == l:interfaces
            return a:cmdline + ["--Interface=" . shellescape(l:interfaces)]
        endif
    endif
    return a:cmdline
endfunction

" the magic function that makes it all happen
function! <SID>_GaudiTemplateBuildCmdLine(type, subtype, classname, interfaces)
    " at most one concurrent invocation - there may be race conditions, but
    " some protection is better than none... the point here is not to be
    " thread-safe, but to avoid that the routine gets stuck if the user calls
    " it on one buffer, goes to a different buffer, and calls it again
    if !exists("s:avoidracecond") || 0 == s:avoidracecond
        let s:avoidracecond = 1
    else
        echo "<sfile>: finish the :Gaudi* in the other buffer first!"
        return
    endif
    " ask or find out what we do not already know
    let l:type=<SID>_GaudiAskType(a:type)
    let l:subtype=<SID>_GaudiAskSubtype(l:type, a:subtype)
    " get class name from buffer name, if not supplied by caller
    let l:classname=a:classname
    if "" == l:classname
        let l:classname=expand("%:r")
    endif
    " need to guess header or implementation file here
    let l:is_header=((tolower(expand("%:e")) =~ '^\(h\|hpp\|hxx\)$'))
    " build the command line
    let l:cmdline= [ s:scriptpath,
\       <SID>_GaudiType2CmdLine(l:type),
\       <SID>_GaudiSubtype2CmdLine(l:type, l:subtype),
\       <SID>_GaudiHeaderOrCpp2CmdLine(l:is_header) ]
    " add interfaces, if appropriate
    let l:cmdline=<SID>_GaudiAskInterfaces(l:type, l:cmdline, a:interfaces)
    " append class name, and transform everything into a string
    let l:cmdline=join(l:cmdline + [shellescape(l:classname)])
    " okay, call the command line, and insert its output into the current
    " buffer, saving and restoring the place in the file as we go
    let l:savedline = line(".")
    call append(l:savedline - 1, systemlist(l:cmdline))
    call setpos(".", [0, l:savedline, 0, 0])
    " say we're done
    let s:avoidracecond = 0
endfunction

" first order of business: find the python script
call <SID>_GaudiFindPythonScript(expand("<sfile>"))
" if successful, define user-facing commands...
if exists("s:scriptpath")
    " define the commands the user can call
    command! -nargs=0 GaudiAnything :call <SID>_GaudiTemplateBuildCmdLine("", "", "", "")
    command! -nargs=0 GaudiAlgorithm :call <SID>_GaudiTemplateBuildCmdLine("Algorithm", "Normal", "", "")
    command! -nargs=0 GaudiHistoAlg :call <SID>_GaudiTemplateBuildCmdLine("Algorithm", "Histo", "", "")
    command! -nargs=0 GaudiTupleAlg :call <SID>_GaudiTemplateBuildCmdLine("Algorithm", "Tuple", "", "")
    command! -nargs=0 GaudiTool :call <SID>_GaudiTemplateBuildCmdLine("Tool", "Normal", "", "")
    command! -nargs=0 GaudiHistoTool :call <SID>_GaudiTemplateBuildCmdLine("Tool", "Histo", "", "")
    command! -nargs=0 GaudiTupleTool :call <SID>_GaudiTemplateBuildCmdLine("Tool", "Tuple", "", "")
    command! -nargs=0 DaVinciAlg :call <SID>_GaudiTemplateBuildCmdLine("DaVinciAlgorithm", "Normal", "", "")
    command! -nargs=0 DaVinciHistoAlg :call <SID>_GaudiTemplateBuildCmdLine("DaVinciAlgorithm", "Histo", "", "")
    command! -nargs=0 DaVinciTupleAlg :call <SID>_GaudiTemplateBuildCmdLine("DaVinciAlgorithm", "Tuple", "", "")
    command! -nargs=0 GaudiInterface :call <SID>_GaudiTemplateBuildCmdLine("Interface", "", "", "")
endif

" vim: sw=4:tw=78:ft=vim:et
