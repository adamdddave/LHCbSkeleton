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
" - GaudiFunctional
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

" avoid loading this script twice, or in nocompatible mode
if exists("loaded_cpp_gaudi") || &cp
    finish
endif

" list of basic Gaudi entity types the script can handle
let s:GaudiTypes=["Algorithm", "DaVinciAlg", "Functional",
\               "Interface", "Tool"]
" dictionary mapping Gaudi entity types to their subtypes
let s:GaudiSubtypes={ 'Functional': ["Producer",
\           "Consumer", "Transformer", "MultiTransformer",
\           "SplittingTransformer", "MergingTransformer",
\           "FilterPredicate", "MultiTransformerFilter"],
\           'Algorithm': ['Normal', 'Histo', 'Tuple'],
\           'DaVinciAlg': ['Normal', 'Histo', 'Tuple'],
\           'Tool': ['Normal', 'Histo', 'Tuple'] }
let s:GaudiCmdLineTypeMap={ 'DaVinciAlg': 'DaVinciAlgorithm',
\           'Functional': 'GaudiFunctionalAlgorithm' }
" dictionary for the option used for subtypes (depending on differnt types)
let s:GaudiCmdLineSubtypeOptionMap={ 'DaVinciAlg': '--DaVinciAlgorithmType',
\           'Functional': '--GaudiFunctional', 'Algorithm': '--AlgorithmType',
\           'Tool': '--AlgorithmType'}
" list of possible completions
let s:prompt_compl_alternatives = []

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
    for l:path in l:scriptpathlist
        if getfperm(l:path) =~ 'r.\+x'
            let s:scriptpath=l:path
            return
        endif
    endfor
    echo "MakeLHCbCppClass.py not found!"
endfunction

" a little helper to make vim complete in our prompts
function! _GaudiPromptCompl(arglead, cmdline, cursorpos)
    " FIXME: is there a way to limit the scope of this routine, too, just as
    " it's done for the others with '<SID>functionName'? - Manuel
    if "" != a:arglead
        " check which alternatives match
        let l:matches=filter(s:prompt_compl_alternatives,
\           "-1 != match(tolower(v:val), '" . tolower(a:arglead) . "')")
        if 0 == len(l:matches) || (1 == len(l:matches)
\               && tolower(a:arglead) == tolower(l:matches[0]))
            " if no matches, there's probably a typo or similar, so provide
            " all alternatives; we do the same if we already have a full
            " match, since the user is probably trying to find something else
            let l:matches=s:prompt_compl_alternatives
        endif
        return join(l:matches, "\n")
    else
        " any one is a potential completion
        return join(s:prompt_compl_alternatives, "\n")
    endif
endfunction

" ask the user questions in the status line, allow completion
"
" this routine does all the heavy lifting when the user is required to select
" among several alternatives
" arguments:
" @param prompt                 prompt to show to the user
" @param alternatives           list of valid answers
" @param[optional] default      default to present (can be empty/absent)
" @param[optional] askAnyway    whether to ask user if there is a default
function! <SID>_GaudiPrompt(prompt, alternatives, ...)
    if "" != a:prompt
        let l:prompt=a:prompt
    else
        let l:prompt=map(copy(a:alternatives),
\           '"(" . v:val[0] . ")" . v:val[1:]')
        let l:prompt=join(l:prompt, ", ") . "? "
    endif
    " check if we have a default value to present to the user
    if a:0 > 0
        let l:default=a:1
        if a:0 > 1
            let l:askAnyway=a:2
        else
            let l:askAnyway=0
        endif
    else
        let l:default=""
        let l:askAnyway = 0
    endif
    " check if the default is already good enough, or if we need to ask anyway
    if ("" == l:default && "" == get(a:alternatives, l:default, "")) || l:askAnyway
        " set up completion - save old completion parameters
        let l:prompt_compl_alternatives_save = s:prompt_compl_alternatives
        try " set new completion, and ask user - cleanup in finally below
            let s:prompt_compl_alternatives=a:alternatives
            " set up matching
            let l:matchlist=map(copy(a:alternatives), 'tolower(v:val)')
            " set up prompt to use
            let l:useprompt=l:prompt
            " ask user until they provide a reasonable answer
            let l:prompt_reply=-1
            while -1 == l:prompt_reply
                " prompt with completion
                call inputsave()
                let l:prompt_reply=tolower(input(l:useprompt, l:default,
                            \           "custom,_GaudiPromptCompl"))
                call inputrestore()
                " check against list of alternatives (case insensitive)
                let l:prompt_reply=match(l:matchlist, "^" . l:prompt_reply)
                " assume user botched it first time around
                let l:useprompt="try again: " . l:prompt
            endwhile
            " user provided valid choice - go to pretty format
            let l:prompt_reply=get(a:alternatives, l:prompt_reply)
        finally " restore old set of completions
            let s:prompt_compl_alternatives = l:prompt_compl_alternatives_save
        endtry
    else
        let l:prompt_reply=l:default
    endif
    return l:prompt_reply
endfunction

" ask user which list of things (s)he wants
function! <SID>_GaudiAskThings(things, default, askAnyway)
    if "" != a:default && !a:askAnyway
        return a:default
    endif
    call inputsave()
    if a:askAnyway && "" != a:default
        let l:defstr = ""
    else
        let l:defstr = " [default=none]"
    endif
    let l:retVal=input("semicolon-separated list of " . a:things .
\       l:defstr . ": ". a:default)
    call inputrestore()
    return l:retVal
endfunction

" ask for type if we do not know already
function! <SID>_GaudiAskType(dict)
    let l:dict = a:dict
    let l:dict['type'] = <SID>_GaudiPrompt(
\       'type of Gaudi entity (Tab for completions): ',
\       s:GaudiTypes, get(l:dict, 'type', ''))
    return l:dict
endfunction

" ask for interface(s), if appropriate, and not known already
function! <SID>_GaudiAskInterfaces(dict)
    let l:dict = a:dict
    if l:dict['type'] =~ '^Tool'
        let l:dict['interfaces'] = <SID>_GaudiAskThings(
\           'interfaces', get(l:dict, 'interfaces', ''),
\           0)
    endif
    return l:dict
endfunction

" ask user for inputs and outputs in case of FunctionalAlgorithm
function! <SID>_GaudiAskInputsOutputs(dict)
    let l:dict = a:dict
    if l:dict['type'] =~ '^Functional'
        let l:dict['inputs'] = <SID>_GaudiAskThings("input type(s)",
\           get(l:dict, 'inputs', ''), 0)
        let l:dict['outputs'] = <SID>_GaudiAskThings("output type(s)",
\           get(l:dict, 'outputs', ''), 0)
        " strip trailing semicolons
        for l:key in [ 'inputs', 'outputs' ]
            let l:dict[l:key] = substitute(l:dict[l:key], ';\+$', '', '')
        endfor
    endif
    return l:dict
endfunction

" ask for subtype if required, and not known already
function! <SID>_GaudiAskSubtype(dict)
    let l:dict = a:dict
    if l:dict['type'] =~ '^\(Algorithm\|DaVinciAlgorithm\|Functional\|Tool\)'
        let l:dict['subtype'] = <SID>_GaudiPrompt(
\           'subtype of ' . l:dict['type'] . ' (Tab for completions): ',
\           s:GaudiSubtypes[l:dict['type']], get(l:dict, 'subtype', ''),
\           l:dict['type'] =~ '^Functional')
    endif
    return l:dict
endfunction

" guess functional algorithm type based on inputs and outputs
function! <SID>_GaudiGuessFunctionalAlg(dict)
    if a:dict['type'] !~ "^Functional" || get(a:dict, 'subtype', '') != ''
        return a:dict
    endif
    let l:dict=a:dict
    let l:nIn=len(split(l:dict['inputs'], ";"))
    let l:nOut=len(split(l:dict['outputs'], ";"))
    if 0 == l:nIn && 0 == l:nOut
        " no functional algorithm fits, so ask user...
    elseif 0 == l:nIn
        let l:dict['subtype'] = "Producer"
    elseif 0 == l:nOut
        let l:dict['subtype'] = "Consumer"
    elseif 1 == l:nOut && 0 < l:nIn
        if l:dict['outputs'] =~ '^\(bool\|Bool\|Bool_t\)$'
            let l:dict['subtype'] = "FilterPredicate"
        else
            let l:dict['subtype'] = "Transformer"
        endif
    else
        let l:dict['subtype'] = "Multitransformer"
    endif
    return l:dict
endfunction

" guess class name and if we're after the header or the implementation
function! <SID>_GaudiGuessClassNameAndFiletype(dict)
    let l:dict = a:dict
    if "" == get(l:dict, 'classname', "")
        let l:dict['classname']=expand("%:r")
    endif
    if "" == get(l:dict, 'filetype', "")
        if tolower(expand("%:e")) =~ '^\(h\|hpp\|hxx\)$'
            let l:dict['filetype']='header'
        else
            let l:dict['filetype']='implementation'
        endif
    endif
    return l:dict
endfunction


" build command line from dictionary
function! <SID>_GaudiBuildCmdLine(dict)
    let l:arglist=[ s:scriptpath ]
    " deal with type first
    let l:arglist=l:arglist+['--type=' . shellescape(get(
\       s:GaudiCmdLineTypeMap, a:dict['type'], a:dict['type']))]
    if a:dict['type'] =~ '^\(Algorithm\|Tool\|DaVinciAlg\|Functional\)$'
        " subtype is easy (if needed)
        let l:arglist=l:arglist+[s:GaudiCmdLineSubtypeOptionMap[a:dict['type']]
\           . '=' . shellescape(a:dict['subtype'])]
    endif
    if a:dict['type'] =~ '^Tool$'
        " next, deal with the interface (if we need one)
        let l:arglist=l:arglist+['--Interface=' . shellescape(a:dict['interfaces'])]
    endif
    if a:dict['type'] =~ '^Functional$'
        " next, deal with the inputs and outputs (if we need them)
        let l:arglist=l:arglist+[
\           '--GaudiFunctionalInput=' . shellescape(a:dict['inputs'])]
        let l:arglist=l:arglist+[
\           '--GaudiFunctionalOutput=' . shellescape(a:dict['outputs'])]
    endif
    " are we dealing with a header or the implementation?
    if a:dict['filetype'] == 'header'
        let l:arglist=l:arglist+['--HeaderOnly']
    else
        let l:arglist=l:arglist+['--cppOnly']
    endif
    " append class name
    let l:arglist=l:arglist+[shellescape(a:dict['classname'])]
    " string together list of arguments into a single string
    return join(l:arglist)
endfunction

" the magic function that makes it all happen
function! <SID>_GaudiAnything(dict)
    " ask for type, subtype, inputs, outputs, interfaces (if we do not know already)
    let l:dict=<SID>_GaudiAskType(a:dict)
    let l:dict=<SID>_GaudiAskInterfaces(l:dict)
    let l:dict=<SID>_GaudiAskInputsOutputs(l:dict)
    let l:dict=<SID>_GaudiGuessFunctionalAlg(l:dict)
    let l:dict=<SID>_GaudiAskSubtype(l:dict)
    " guess class name and guess file type (header/c++ implementation file)
    let l:dict=<SID>_GaudiGuessClassNameAndFiletype(l:dict)
    " build command line
    let l:cmdline = <SID>_GaudiBuildCmdLine(l:dict)
    if 1 " debugging (for now)
        echo "CMDLINE: " . l:cmdline
    endif
    " call MakeLHCbCppClass to produce what should be inserted
    let l:lines=systemlist(l:cmdline)
    " remove spurious newlines on the list's elements
    let l:lines=map(l:lines, "substitute(v:val, '\n\+$', '', '')")
    " remove trailing empty lines in the list
    while "" == l:lines[len(l:lines) - 1]
        call remove(l:lines, len(l:lines) - 1)
    endwhile
    " save current position in buffer
    let l:savedline = line(".")
    " insert into current buffer
    call append(l:savedline - 1, l:lines)
    " restore position in buffer
    call setpos(".", [0, l:savedline, 0, 0])
endfunction

" first order of business: find the python script
call <SID>_GaudiFindPythonScript(expand("<sfile>"))
" if successful, define user-facing commands...
if exists("s:scriptpath")
    " define the commands the user can call
    command! -nargs=0 GaudiAnything   :call <SID>_GaudiAnything({})
    command! -nargs=0 GaudiAlgorithm  :call <SID>_GaudiAnything({'type': 'Algorithm', 'subtype': 'Normal'})
    command! -nargs=0 GaudiHistoAlg   :call <SID>_GaudiAnything({'type': 'Algorithm', 'subtype': 'Histo'})
    command! -nargs=0 GaudiTupleAlg   :call <SID>_GaudiAnything({'type': 'Algorithm', 'subtype': 'Tuple'})
    command! -nargs=0 GaudiTool       :call <SID>_GaudiAnything({'type': 'Tool', 'subtype': 'Normal'})
    command! -nargs=0 GaudiHistoTool  :call <SID>_GaudiAnything({'type': 'Tool', 'subtype': 'Histo'})
    command! -nargs=0 GaudiTupleTool  :call <SID>_GaudiAnything({'type': 'Tool', 'subtype': 'Tuple'})
    command! -nargs=0 DaVinciAlg      :call <SID>_GaudiAnything({'type': 'DaVinciAlg', 'subtype': 'Normal'})
    command! -nargs=0 DaVinciHistoAlg :call <SID>_GaudiAnything({'type': 'DaVinciAlg', 'subtype': 'Histo'})
    command! -nargs=0 DaVinciTupleAlg :call <SID>_GaudiAnything({'type': 'DaVinciAlg', 'subtype': 'Tuple'})
    command! -nargs=0 GaudiInterface  :call <SID>_GaudiAnything({'type': 'Interface'})
    command! -nargs=0 GaudiFunctional :call <SID>_GaudiAnything({'type': 'Functional'})
endif

" vim: sw=4:tw=78:ft=vim:et
