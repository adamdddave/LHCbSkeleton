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
" @date 2017-04-07
" - after much hacking, we now have a relatively clean script, that seems to
"   behave okay in my tests
" - Interfaces for Tools and inputs/outputs for Functional algorithms are
"   remembered, and offered as completion alternatives on subsequent runs
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
if version < 704
    echoerr 'Gaudi template support needs at least vim 7.4'
    finish
endif

" list of basic Gaudi entity types the script can handle
let s:GaudiTypes=["Algorithm", "DaVinciAlg", "Functional",
\               "Interface", "Tool"]
" dictionary mapping Gaudi entity types to their subtypes
let s:GaudiSubtypes={ 'Functional': [ "Producer",
\           "Consumer", "Transformer", "MultiTransformer" ],
\           'Algorithm': ['Normal', 'Histo', 'Tuple'],
\           'DaVinciAlg': ['Normal', 'Histo', 'Tuple'],
\           'Tool': ['Normal', 'Histo', 'Tuple'] }
" FIXME: add these back to Functional subtypes when Adam's script starts
"        to support these again
"\           "SplittingTransformer", "MergingTransformer",
"\           "FilterPredicate", "MultiTransformerFilter"],
let s:GaudiCmdLineTypeMap={ 'Algorithm': 'A', 'DaVinciAlg': 'DVA',
\           'Functional': 'GFA', 'Tool': 'T', 'Interface': 'I' }
" dictionary for the option used for subtypes (depending on differnt types)
let s:GaudiCmdLineSubtypeOptionMap={ 'DaVinciAlg': '--DaVinciAlgorithmType',
\           'Functional': '--GaudiFunctional', 'Algorithm': '--AlgorithmType',
\           'Tool': '--AlgorithmType'}
" dictionary to remap completion dictionary types:
" [for GaudiFunctional, inputs and outputs are completed from the same pool of
" suggestions]
let s:compldictRemap={'output type(s)': 'input type(s)'}
" completion dictionary for inputs, outputs, interfaces
" [vim learns what the user uses in a session]
let s:compldict={ 'input type(s)': {}, 'interfaces': {} }

" little helper to search for the python part in a few reasonable places
function! s:GaudiFindPythonScript(vimscriptpath)
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
    echoerr "MakeLHCbCppClass.py not found - refusing to work!"
endfunction

" little helper to get the script ID
function! <SID>GetSID()
    return matchstr(matchstr(string(function("<SID>GetSID")),
\       '<SNR>\([0-9]\+\)_'), '[0-9]\+')
endfunction
" construct our own script-specific function and variable names
let s:complfunc=printf("<SNR>%d_GaudiPromptCompl", <SID>GetSID())
" script-specific per-buffer variable for the completion
let s:complvar=printf("b:__SID%s_gaudiPromptComplAlternatives", <SID>GetSID())

" a little helper to make vim complete in our prompts
function! <SID>GaudiPromptCompl(arglead, cmdline, cursorpos)
    if "" != a:arglead
        " check which alternatives match
        let l:matches=filter(eval(s:complvar),
\           "-1 != match(tolower(v:val), '" . tolower(a:arglead) . "')")
        if 0 == len(l:matches) || (1 == len(l:matches)
\               && tolower(a:arglead) == tolower(l:matches[0]))
            " if no matches, there's probably a typo or similar, so provide
            " all alternatives; we do the same if we already have a full
            " match, since the user is probably trying to find something else
            let l:matches=eval(s:complvar)
        endif
        return join(l:matches, "\n")
    else
        " any one is a potential completion
        return join(eval(s:complvar), "\n")
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
" @param[optional] doNotEnforce enforce that choice is among alternatives (no)
function! s:GaudiPrompt(prompt, alternatives, ...)
    if "" != a:prompt
        let l:prompt=a:prompt
    else
        let l:prompt=map(copy(a:alternatives),
\           '"(" . v:val[0] . ")" . v:val[1:]')
        let l:prompt=join(l:prompt, ", ") . "? "
    endif
    " check if we have a default value to present to the user
    let l:default=""
    let l:askAnyway = 0
    let l:doNotEnforce = 0
    if a:0 > 0
        let l:default=a:1
        if a:0 > 1
            let l:askAnyway=a:2
            if a:0 > 2
                let l:doNotEnforce=a:3
            endif
        endif
    endif
    " check if the default is already good enough, or if we need to ask anyway
    if "" == l:default || "" == get(a:alternatives, l:default, "") || l:askAnyway
        " set up completion - save old completion parameters
        if exists(s:complvar)
            " previous value needs saving
            let l:prompt_compl_alternatives_save = eval(s:complvar)
        else
            " no previous value...
            let l:prompt_compl_alternatives_save=[]
        endif
        try " set new completion, and ask user - cleanup in finally below
            execute 'let ' . s:complvar . '=a:alternatives'
            " set up matching
            let l:matchlist=map(copy(a:alternatives), 'tolower(v:val)')
            " set up prompt to use
            let l:useprompt=l:prompt
            " ask user until they provide a reasonable answer
            let l:prompt_reply=-1
            while -1 == l:prompt_reply
                " prompt with completion
                call inputsave()
                let l:prompt_reply=input(l:useprompt, l:default,
\                   "custom," . s:complfunc)
                call inputrestore()
                if !l:doNotEnforce
                    let l:prompt_reply=tolower(l:prompt_reply)
                    " check against list of alternatives (case insensitive)
                    let l:prompt_reply=match(l:matchlist, "^" . l:prompt_reply)
                    " assume user botched it first time around
                    let l:useprompt="try again: " . l:prompt
                endif
            endwhile
            if !l:doNotEnforce
                " user provided valid choice - go to pretty format
                let l:prompt_reply=get(a:alternatives, l:prompt_reply)
            endif
        finally " restore old set of completions
            if type(l:prompt_compl_alternatives_save) == type("")
                " restore previous value
                execute 'let ' . s:complvar . '=l:prompt_compl_alternatives_save'
            else
                " undefine the variable
                execute 'unlet ' . s:complvar
            endif
        endtry
    else
        let l:prompt_reply=l:default
    endif
    return l:prompt_reply
endfunction

" ask user which list of things (s)he wants
function! s:GaudiAskThings(things, default, askAnyway)
    if "" != a:default && !a:askAnyway
        return a:default
    endif
    " remap things if needed...
    let l:things=get(s:compldictRemap, a:things, a:things)
    " ... and get the completion dictionary; build up list of previously used
    " things
    let l:alternatives=sort(keys(s:compldict[l:things]))
    " make a builtin default
    if a:askAnyway && "" != a:default
        let l:defstr = ""
    else
        let l:defstr = " [default=none]"
    endif
    " pop the question
    let l:retVal=s:GaudiPrompt("semicolon-separated list of " . a:things .
\       l:defstr . ": ", l:alternatives, a:default, a:askAnyway, 1)
    " register the user's reply for next time
    for l:val in split(l:retVal, ';')
        let s:compldict[l:things][l:val] = 1
    endfor
    return l:retVal
endfunction

" ask for type if we do not know already
function! s:GaudiAskType(dict)
    let l:dict = a:dict
    let l:dict['type'] = s:GaudiPrompt(
\       'type of Gaudi entity (Tab for completions): ',
\       s:GaudiTypes, get(l:dict, 'type', ''))
    return l:dict
endfunction

" ask for interface(s), if appropriate, and not known already
function! s:GaudiAskInterfaces(dict)
    let l:dict = a:dict
    if l:dict['type'] =~ '^Tool'
        let l:dict['interfaces'] = s:GaudiAskThings(
\           'interfaces', get(l:dict, 'interfaces', ''),
\           0)
    endif
    return l:dict
endfunction

" ask user for inputs and outputs in case of GaudiFunctional
function! s:GaudiAskInputsOutputs(dict)
    let l:dict = a:dict
    if l:dict['type'] =~ '^Functional'
        let l:dict['inputs'] = s:GaudiAskThings("input type(s)",
\           get(l:dict, 'inputs', ''), 0)
        let l:dict['outputs'] = s:GaudiAskThings("output type(s)",
\           get(l:dict, 'outputs', ''), 0)
        " strip trailing semicolons
        for l:key in [ 'inputs', 'outputs' ]
            let l:dict[l:key] = substitute(l:dict[l:key], ';\+$', '', '')
        endfor
    endif
    return l:dict
endfunction

" ask for subtype if required, and not known already
function! s:GaudiAskSubtype(dict)
    let l:dict = a:dict
    if l:dict['type'] =~ '^\(Algorithm\|DaVinciAlgorithm\|Functional\|Tool\)'
        let l:dict['subtype'] = s:GaudiPrompt(
\           'subtype of ' . l:dict['type'] . ' (Tab for completions): ',
\           s:GaudiSubtypes[l:dict['type']], get(l:dict, 'subtype', ''),
\           l:dict['type'] =~ '^Functional')
    endif
    return l:dict
endfunction

" guess functional algorithm type based on inputs and outputs
function! s:GaudiGuessFunctionalAlg(dict)
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
            " FIXME: Adam's script seems to have scrapped support for
            " FilterPredicate, so we disable the mapping that the script
            " cannot seem to handle, and go with the logic that something with
            " inputs and exactly one output is a Transformer, too...
            "let l:dict['subtype'] = 'FilterPredicate'
            let l:dict['subtype'] = 'Transformer'
        else
            let l:dict['subtype'] = 'Transformer'
        endif
    else
        let l:dict['subtype'] = 'MultiTransformer'
    endif
    return l:dict
endfunction

" guess class name and if we're after the header or the implementation
function! s:GaudiGuessClassNameAndFiletype(dict)
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
function! s:GaudiBuildCmdLine(dict)
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
        let l:classname=a:dict['classname'] . '.h'
    else
        let l:classname=a:dict['classname'] . '.cpp'
    endif
    " append class name
    let l:arglist=l:arglist+[shellescape(l:classname)]
    " string together list of arguments into a single string
    return join(l:arglist)
endfunction

" the magic function that makes it all happen
function! <SID>GaudiAnything(dict)
    " ask for type, subtype, inputs, outputs, interfaces (if we do not know already)
    let l:dict=s:GaudiAskType(a:dict)
    let l:dict=s:GaudiAskInterfaces(l:dict)
    let l:dict=s:GaudiAskInputsOutputs(l:dict)
    let l:dict=s:GaudiGuessFunctionalAlg(l:dict)
    let l:dict=s:GaudiAskSubtype(l:dict)
    " guess class name and guess file type (header/c++ implementation file)
    let l:dict=s:GaudiGuessClassNameAndFiletype(l:dict)
    " build command line
    let l:cmdline = s:GaudiBuildCmdLine(l:dict)
    if 1 " debugging (for now)
        echo "CMDLINE: " . l:cmdline
    endif
    " call MakeLHCbCppClass to produce what should be inserted
    let l:lines=systemlist(l:cmdline)
    " remove spurious newlines on the list's elements
    for l:line in l:lines
        let l:line=substitute(l:line, '\n\+$', '', '')
    endfor
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
call s:GaudiFindPythonScript(expand("<sfile>"))
" if successful, define user-facing commands...
if exists("s:scriptpath")
    " define the commands the user can call
    command! -nargs=0 GaudiAnything   :call <SID>GaudiAnything({})
    command! -nargs=0 GaudiAlgorithm  :call <SID>GaudiAnything({'type': 'Algorithm', 'subtype': 'Normal'})
    command! -nargs=0 GaudiHistoAlg   :call <SID>GaudiAnything({'type': 'Algorithm', 'subtype': 'Histo'})
    command! -nargs=0 GaudiTupleAlg   :call <SID>GaudiAnything({'type': 'Algorithm', 'subtype': 'Tuple'})
    command! -nargs=0 GaudiTool       :call <SID>GaudiAnything({'type': 'Tool', 'subtype': 'Normal'})
    command! -nargs=0 GaudiHistoTool  :call <SID>GaudiAnything({'type': 'Tool', 'subtype': 'Histo'})
    command! -nargs=0 GaudiTupleTool  :call <SID>GaudiAnything({'type': 'Tool', 'subtype': 'Tuple'})
    command! -nargs=0 DaVinciAlg      :call <SID>GaudiAnything({'type': 'DaVinciAlg', 'subtype': 'Normal'})
    command! -nargs=0 DaVinciHistoAlg :call <SID>GaudiAnything({'type': 'DaVinciAlg', 'subtype': 'Histo'})
    command! -nargs=0 DaVinciTupleAlg :call <SID>GaudiAnything({'type': 'DaVinciAlg', 'subtype': 'Tuple'})
    command! -nargs=0 GaudiInterface  :call <SID>GaudiAnything({'type': 'Interface'})
    command! -nargs=0 GaudiFunctional :call <SID>GaudiAnything({'type': 'Functional'})
endif

" vim: sw=4:tw=78:ft=vim:et
