;;; lhcb-c++.el --- Special settings for LHCb C++ editing

;; Copyright (C) 2001 by LHCb

;; Maintener        : Olivier Callot 
;; Main contributor : Sebastien Ponce
;; Updated with python config : Adam Davis

; This defines all specificities of the LHCb C++ mode

(defun lhcb-c++-mode-internal
  ()
  "defines all specificities of the LHCb C++ mode"
  ; This inserts a new LHCb specific menu in Xemacs
  ;(c++-insert-menu-in-XEmacs-menubar)
  ; This is for checking the line lengths at save time.
  ; This is placed here since emacs defines this hook as buffer specific
  ; The added function is `c++-check-line-length' since xemacs defines
  ; this hook once for every buffers
  (add-hook 'write-contents-hooks 'c++-check-line-length)
  (setq fill-column 130 )
  )
(setq c++-fill-column 130 )


; This code was provided by David Hutchcroft for making fume work in
; Xemacs, in the lhcb-c++ mode.
; Fume provides a list of functions in the current file and optionally
; the function you are currently in in the status bar.
(cond (is-xemacs
       (require 'func-menu)
       (define-key global-map 'f8 'function-menu)
       (add-hook 'find-file-hooks 'fume-add-menubar-entry)
       (define-key global-map "\C-cg" 'fume-prompt-function-goto)
       (define-key global-map '(shift button3) 'mouse-function-menu)
       (setq fume-function-name-regexp-alist 
             (cons (cons 'lhcb-c++-mode 'fume-function-name-regexp-c++) 
                   fume-function-name-regexp-alist ))
       (setq fume-find-function-name-method-alist 
             (cons (cons 'lhcb-c++-mode 'fume-match-find-next-function-name) 
                   fume-find-function-name-method-alist ))
       ))


; This makes a warning message appear while trying to save a file with 
; line too long
(defun
  check-line-length
  ()
  "This checks that every line of the current buffer are less than 
`fill-column' caracter long. If this is not the case, an error message 
is displayed"
  (interactive)
  (let ((lines-too-long 0) (list-too-long nil))
    (save-excursion
      (setq i 1)
      (setq last-line (+ 2 (count-lines (point-min) (point-max))))
      (while (< i last-line)
        (goto-line i)
        (end-of-line)
        (setq end-of-line-marker (point-marker))
        (beginning-of-line)
        (cond ((not (re-search-forward "\\$Header.*\\$[ \t]*$" 
                                       end-of-line-marker t))
               (end-of-line)
               (cond ((> (current-column) fill-column)
                      (setq lines-too-long (+ lines-too-long 1))
                      (setq list-too-long (cons i list-too-long))))))
        (setq i (1+ i))))
    (cond ((and (> lines-too-long 0)
                (string= "N" (upcase (read-string
                                      (concat
                                       "Some lines of this file are too long. "
                                       "Do you want to save anyway (y/n)?"))))
                (message "Lines to reduce are nbs %s" list-too-long)
                '0)))))

; This is a special check-line-length function that checks that the 
; C++ mode is active
(defun
  c++-check-line-length
  ()
  "This calls check-line-length if and only if the C++ mode is active"
  (if (eq major-mode 'lhcb-c++-mode) (check-line-length)))

; This places the cursor at the end of the next too long line
; This is available by hitting Ctrl x Ctrl w
(defun
  go-to-next-too-long-line
  ()
  "This places the cursor at the end of the next too long line of the file 
(if it exists). Otherwise, does nothing"
  (interactive)
  (let ((start-of-search (point-marker))
        (missing-lines 0))
    (end-of-line)
     (while (and (= missing-lines 0)
                (not (> (current-column) fill-column)))
      (setq missing-lines (forward-line 1))
      (end-of-line))
    (cond ((/= missing-lines 0)
           (message "No too long line after current position")
           (goto-char start-of-search)))))
(define-key global-map [(control x) (w)] 'go-to-next-too-long-line)

; Creates the lhcb c++ mode
(define-derived-mode 
  lhcb-c++-mode
  c++-mode
  "LHCb C++ mode"
  "Major mode for developing C++ applications in LHCb."
  (lhcb-c++-mode-internal)
)

; Avoid double indentation at statement opening
(c-set-offset 'substatement-open 0)

; Buffer specific information. Need to turn font-lock ON...
(add-hook 'c++-mode-hook '(lambda () 
                            (setq comment-line-start "//")

   (setq-default indent-tabs-mode nil)       ;; Never insert an ASCII TAB
   (setq tab-width 2)                        ;; TAB is two spaces

   ; Highlight characters after the column which is specified by 'fill-column'
   (setq c++-font-lock-comment-end-of-line 
         (list (concat "^" (make-string c++-fill-column ?.) "\\(.*\\)") 
               '(1 font-lock-overflow-face)))
   (setq c++-font-lock-keywords-3 
         (nconc (list c++-font-lock-comment-end-of-line) 
                c++-font-lock-keywords-3))
   ;;(if (not (equal 'nil global-font-lock-mode))
   (turn-on-font-lock) ;;)
))

; defines the usage of the LHCb C++ mode
(setq auto-mode-alist
      (append
       (list
        '("\\.c$"       . lhcb-c++-mode)
        '("\\.C$"       . lhcb-c++-mode)
        '("\\.cpp$"     . lhcb-c++-mode)
        '("\\.c\\+\\+$" . lhcb-c++-mode)
        '("\\.cxx$"     . lhcb-c++-mode)
        '("\\.h$"       . lhcb-c++-mode)
        '("\\.H$"       . lhcb-c++-mode)
        '("\\.hpp$"     . lhcb-c++-mode)
        '("\\.h\\+\\+$" . lhcb-c++-mode)
        '("\\.hxx$"     . lhcb-c++-mode)
        '("\\.icpp$"    . lhcb-c++-mode)
        '("\\.icc$"     . lhcb-c++-mode)
        '("\\.opts$"    . lhcb-opts-mode)
        )
       auto-mode-alist))

; Creates the lhcb c++ mode
(define-derived-mode 
  lhcb-opts-mode
  lhcb-c++-mode
  "LHCb Option File mode"
  "Major mode for editind option files."
  (lhcb-opts-mode-internal)
)

(defun lhcb-opts-mode-internal
  ()
  "defines all specificities of the LHCb opts mode"
  ; This inserts a new LHCb specific menu in Xemacs
  (c++-insert-menu-in-XEmacs-menubar)
  (c-toggle-auto-hungry-state 0)
  )
         
;;======================================================================
;;-- Auto-insert in empty buffers
;;======================================================================
(define-auto-insert "\\.\\([Hh]\\|hh\\|hpp\\|[Cc]\\|cc\\|cpp\\)\\'" (quote 
(  
 (upcase 
  (concat
   (let ((my-dir 
          (file-name-nondirectory 
           (substring (file-name-directory buffer-file-name) 0 -1 ))))
     (if (string= my-dir "src") "" (concat my-dir "_") ) )
   (file-name-nondirectory 
    (substring buffer-file-name 0 (match-beginning 0) ) ) 
   "_" 
   (substring buffer-file-name (1+ (match-beginning 0) ) )
   )
  )

(let ((ftype (upcase 
  (read-string 
   "Create Algorithm, DaVinciAlgorithm, GaudiFunctionalAlgorithm, Tool, Interface or simple class  A/D/F/T/I/[no] : "))))
  (setq file-type ftype)
  (setq is-algorithm (string= "A" ftype))
  (setq is-DValg     (string= "D" ftype))
  (setq is-tool      (string= "T" ftype))
  (setq is-interface (string= "I" ftype))
  (setq is-plain     (string= ""  ftype))
  (setq is-gaudi-functional (string="F" ftype))
  (setq class-name (file-name-nondirectory 
  		    (file-name-sans-extension (buffer-file-name)))
	)
  (if is-plain (setq file-type "S" ))
  (if is-DValg (setq file-type "DVA" ))
  (if is-gaudi-functional (setq file-type "GFA" ))
  nil
)


(if is-tool (setq interface-name 
		  (read-string 
                   "Interface name (blank = not using an interface) :") 
                  dum "")
  (setq interface-name "" ))
(if is-algorithm (let((alg-type (upcase (read-string "Normal, Histo or Tuple Algorithm [N]/H/T : "))))
		   (setq atype alg-type)
		   (if (string= "" alg-type) (setq atype "N"))
		   nil)
  
)


(if is-DValg (let ((alg-type (upcase (read-string "Normal, Histo or Tuple DaVinciAlgorithm [N]/H/T : "))))
	       (setq atype alg-type)
	       (if (string= "" alg-type) (setq atype "N"))
	       nil)
  
)
(if is-gaudi-functional (let ((alg-type (upcase (read-string "Transformer, Producer, Consumer, MultiTransformer [T]/P/C/M : "))))
			  (setq gfa-type alg-type )
			  (setq is-plain-gfa (string= "" alg-type))
			  (if (string= "" alg-type) (setq gfa-type "T"))
			  nil
			  )
  
)

(shell-command-to-string 
(concat "/afs/cern.ch/user/a/adavis/public/emacs_templates/test/MakeLHCbCppClass.py " 
	" -t " file-type " "
	(if is-algorithm (concat "-a " atype " "))
	(if is-DValg (concat "-d " atype " "))
	(if (and (not (string= "" interface-name)) is-tool) (concat "-I " interface-name " "))
	(if is-gaudi-functional (concat "-f " gfa-type " "))
				 (file-name-nondirectory buffer-file-name))
)
;;(shell-command-to-string (concat "/afs/cern.ch/user/a/adavis/public/emacs_templates/test/MakeLHCbCppClass.py" " -t A -a N " (file-name-nondirectory buffer-file-name)))
;;(call-process "/afs/cern.ch/user/a/adavis/public/emacs_templates/test/MakeLHCbCppClass.py" nil t nil (concat " -t A -a N" (file-name-nondirectory buffer-file-name) ))

) 

))


;; keywords in template:
;;    & = new line if line not whitespace only so far
;;    > = indent current line (after insertion...)
;;    p = mark to go back after completion
;;    n = new line
;;
(require 'tempo)

(defun split-if-needed () "Go to next start of line for insertion"
  (setq tempo-marks nil)
  (if (= 0 (current-column)) (insert "")
    (end-of-line)
    (insert ""))
)

; generates a member declaration and the corresponding default accessors
(defcustom c++-gen-member-and-accessors-template
  '((split-if-needed) &  n >
    (P "Give the name of the member (without m_) : " member-name 'noinsert)
    (P "Give the type of the member : " member-type 'noinsert)
    "  /**" > n
    "   * Set accessor to member m_" (s member-name) > n
    "   * @param " (s member-name) " the new value for m_" (s member-name) > n
    "   */" > n
    "  void set" (upcase-initials (tempo-lookup-named 'member-name)) " (" (s member-type) " " (s member-name) ") {" > n
    "    m_" (s member-name) " = " (s member-name) ";" > n
    "  }" > n n
    "  /**" > n
    "   * Get accessor to member m_" (s member-name) > n
    "   * @return the current value of m_" (s member-name) > n
    "   */" > n
    "  " (s member-type) " " (s member-name) " () {" > n
    "    return m_" (s member-name) ";" > n
    "  }" > n p
    "///--- Move this line to the private section... " > n
    "  " (s member-type) " m_" (s member-name) ";" > % )
   "Template to create a C++ member declaration and the corresponding accessors"
   :set '(lambda (sym val)
           (defalias 'c++-gen-member-and-accessors
             (tempo-define-template
              "c++-member-and-accessors"
              val) )))

; generates a comment structure
(defcustom c++-gen-comment-var-template
  '( (split-if-needed) & "//====================================================================" > n 
     "// " p > n         "//====================================================================" > % )
  "Template for creating an C++ comment."
  :set '(lambda (sym val)
          (defalias 'c++-gen-comment
            (tempo-define-template "c++-gen-comment" val ))))

; generates a do loop structure
(defcustom c++-gen-do-loop-var-template
  '( (split-if-needed) & "do { " p > n "} while (  );" > % )
  "Template for creating a C++ do loop. "
  :set '(lambda (sym val)
          (defalias 'c++-gen-do-loop
            (tempo-define-template "c++-gen-do-loop" val ))))

; generates a if structure
(defcustom c++-gen-if-var-template
  '( (split-if-needed) & "if ( " p " ) {" > n "} else {" > n "}" > %)
  "Template for creating an C++ if statement."
  :set '(lambda (sym val)
          (defalias 'c++-gen-if
            (tempo-define-template "c++-gen-if" val ))))

; generates a for
(defcustom c++-gen-for-var-template
  '( (split-if-needed) & > "for ( " p " ;  ;  ) {" > n "}" > % )
  "Template for creating an C++ for statement."
  :set '(lambda (sym val)
          (defalias 'c++-gen-for
            (tempo-define-template "c++-gen-for" val ))))

(defcustom c++-gen-decl-int-template
   '( (split-if-needed) & "int    " p ";" > % )
   "Template to create a C++ int declaration"
   :set '(lambda (sym val)
           (defalias 'c++-gen-int
             (tempo-define-template "c++-int" val) )))
  
(defcustom c++-gen-decl-real-template
   '( (split-if-needed) & "double " p ";" > % )
   "Template to create a C++ double declaration"
   :set '(lambda (sym val)
           (defalias 'c++-gen-double
             (tempo-define-template "c++-dble" val) )))
  
(defcustom c++-gen-decl-include-template
   '( (split-if-needed) & "#include \"" p ".h\"" > % )
   "Template to create a C++ include declaration"
   :set '(lambda (sym val)
           (defalias 'c++-gen-include
             (tempo-define-template "c++-include" val) )))
  
(defcustom c++-gen-member-template
  '((split-if-needed) &  n 
"//=========================================================================" n
"//  " n 
"//=========================================================================" n
"void " (file-name-nondirectory (file-name-sans-extension (buffer-file-name))) 
    "::" p " ( ) {" n "}" % )
   "Template to create a C++ member declaration"
   :set '(lambda (sym val)
           (defalias 'c++-gen-member
             (tempo-define-template "c++-member" val) )))
  

;; --- List of templates inserted.

(defun LHCb-c++-insert ()
  "Inserts various C++ constructs"
  (message "Which option A/C/D/F/I/J/M/N/R/? : ")
  (setq key (upcase (read-char-exclusive)))
  (message "")
  (cond ((= 65 key) (c++-gen-member-and-accessors) ) ;; A
        ((= 67 key) (c++-gen-comment) )              ;; C
        ((= 68 key) (c++-gen-do-loop) )              ;; D
        ((= 70 key) (c++-gen-for) )                  ;; F
        ((= 73 key) (c++-gen-if) )                   ;; I
        ((= 74 key) (c++-gen-int) )                  ;; J
        ((= 77 key) (c++-gen-member) )               ;; M
        ((= 78 key) (c++-gen-include) )              ;; N
        ((= 82 key) (c++-gen-double) )               ;; R
        ( t         (c++-gen-choices) )              ;; any undefined...
  )
)

(defun c++-gen-choices () "Display the InsertHere choices"
  (interactive)
  (let ((old-buf (buffer-name)))
    (switch-to-buffer "C++ InsertHere options" t)
    (if (= 0 (buffer-size) ) (insert
"
When you hit the InsertHere key in C++ , the following commands are valid:

  A : Inserts a new member and the corresponding accessors
  C : Inserts a C-style comment, /** */
  D : Inserts a 'do while' loop
  F : Inserts a 'for' loop
  I : Inserts an 'if' block
  J : Declares an int
  M : Inserts a new member function
  N : Inserts an #include statement
  R : Declares a real (double)

Type any character to exit this window " ) )
    (read-char)
    (switch-to-buffer old-buf)
  )
)    
;;; lhcb-c++.el ends here
