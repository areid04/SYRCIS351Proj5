;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;If you are a Mac USER: 
;change the refernse of global _start on line 459 to global _main
;Changes had to be made for Linux users linking to libraries.
;;
;;
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.



;; Project 5
;; Compiler from IfArith |--> x86-64
#lang racket

(provide (all-defined-out))

(define verbose-mode (make-parameter #t))
(define i-am-a-mac (make-parameter #f))

;; 
;; Our compiler will have several layers
;; 
;; Stage 1:   IfArith <-- Surface level
;;               |        (ifarith?)
;; Stage 2:   IfArithTiny <-- Subsurface level, desugars IfArith
;;               |        (ifarith-tiny?)
;; Stage 3:     ANF       <-- Administrative Normal Form
;;               |        (functions have "simple" arguments)
;; Stage 4:  IR-Virtual <-- Assembly with virtual registers
;;               |        (linearized assembly w/ virtual registers)
;; Stage 5:     x86     <-- x86, with stack allocation
;;               |        (ir-x86?)
;; Stage 6:     NASM     <-- Assembly file
;; 
;; Once we have assembly code (in this case NASM assembly), we then
;; use a standard assembler / linker.

;; Stage 1: High-level language: IfArith
;;
;; Our high-level language will be IfArith--it has the obvious
;; semantics we have written several times before; the interpretation
;; is not the interesting part here. The only interesting thing to
;; note is that true is "anything but zero," and false is "exactly
;; zero."

;; Here are our primitive operators--notice that we don't include
;; =. Our notion of true will be "anything except for 0." Our notion
;; of false will be "exactly zero." We can get here by using
;; subtracts, etc...
(define (bop? op) (member op '(+ * - << >>)))
(define (uop? op) (member op '(- not)))

;; literals are either integer literals or true / false
(define (lit? l)
  (match l
    [(? integer? i) #:when (and (>= i (- (expt 2 63))) (< i (expt 2 63))) #t]
    ['true #t]
    ['false #t]
    [_ #f]))

;; IfArith is a tiny (sub-Turing) language we've seen several times
;; throughout the course. We will compile IfArith to x86, by way of
;; several steps. Our language is intentionally tiny: project 4 showed
;; us we can compile to the lambda calculus, now we show how to
;; compile a (much less expressive) language all the way down to
;; assembly code.
(define (ifarith? e)
  (match e
    ;; literals
    [(? integer? i) #:when (and (>= i (- (expt 2 63))) (< i (expt 2 63))) #t]
    ['#t #t]
    ['#t #f]
    ['true #t]
    ['false #t]
    ;; applications of primitives, our language has no lambdas
    [`(,(? bop? bop) ,(? ifarith? e0) ,(? ifarith? e1)) #t]
    [`(,(? uop? bop) ,(? ifarith? e0)) #t]
    ;; let* works in the usual way
    [`(let* ([,(? symbol? xs) ,(? ifarith? es)] ...) ,(? ifarith? e-body)) #t]
    ;; print an arbitrary expression (must be a number at runtime)
    [`(print ,(? ifarith? e)) #t]
    ;; and/or, with short-circuiting semantics
    [`(and ,(? ifarith? e0) ,(? ifarith? es) ...) #t]
    [`(or ,(? ifarith? e0) ,(? ifarith? es) ...) #t]
    ;; if argument is 0, false, otherwise true
    [`(if ,(? ifarith? e0) ,(? ifarith? e1) ,(? ifarith? e2)) #t]
    ;; cond where the last case is else
    [`(cond [,(? ifarith? conditions) ,(? ifarith? bodies)]
            ...
            [else ,(? ifarith? else-body)]) #t]
    [_ #f]))

;; Stage 2: IfArith-Tiny
;; 
;; Now we'll observe that many of the forms in ifarith? can be written
;; in terms of other forms. This is like the desugaring we did in p4:
;; we just eliminate some forms by using existing forms. For example,
;; let* can be written as a sequence of single-binding lets (notice we
;; change let* to let). Similarly, forms for and/or/cond can be
;; compiled to usages of `if`.

;; (Stage 2) Language spec
(define (ifarith-tiny? e)
  (match e
    ;; literals
    [(? integer? i) #:when (and (>= i (- (expt 2 63))) (< i (expt 2 63))) #t]
    ['#t #t]
    ['#f #t]
    ['true #t]
    ['false #t] ;; should be true.
    ;; variables, bound in let
    [(? symbol? x) #t]
    ;; applications of primitives, our language has no lambdas
    [`(,(? bop? bop) ,(? ifarith? e0) ,(? ifarith? e1)) #t]
    [`(,(? uop? bop) ,(? ifarith? e0)) #t]
    ;; let* works in the usual way
    [`(let ([,(? symbol? x) ,(? ifarith? e)]) ,(? ifarith? e-body)) #t]
    ;; print an arbitrary expression (must be a number at runtime)
    [`(print ,(? ifarith? e)) #t]
    ;; if argument is 0, false, otherwise true
    [`(if ,(? ifarith? e0) ,(? ifarith? e1) ,(? ifarith? e2)) #t]
    [_ #f]))

;; TODO TODO TODO 
;; 
;; This is the *only* programming part, and mostly a way to get the
;; team on the same page.
;; 
;; Translator: IfArith |--> IfArith-Tiny
;; 
;; You will implement a translator from IfArith to IfArithTiny,
;; sketched up above. Specifically, you will convert everything to
;; direct-style applications of builtins, along with let, print, and
;; if.
(define (ifarith->ifarith-tiny e)
  (match e
    ;; literals
    [(? integer? i) i]
    ['#t 1]
    ['#f 0]
    ['true e]
    ['false e]
    [(? symbol? x) x]
    [`(,(? bop? bop) ,e0 ,e1) `(,bop ,(ifarith->ifarith-tiny e0) ,(ifarith->ifarith-tiny e1))]
    [`(,(? uop? uop) ,e) `(,uop ,(ifarith->ifarith-tiny e))]
    ;; 0-binding case
    [`(let* () ,e) (ifarith->ifarith-tiny e)]
    ;; 1+-binding case
    [`(let* ([,(? symbol? x0) ,e0]) ,e-body) `(let ([,x0 ,e0]) ,(ifarith->ifarith-tiny e-body))]
    [`(let* ([,(? symbol? x0) ,e0] ,rest-binding-pairs ...) ,e-body) `(let ([,x0 ,e0]) ,(ifarith->ifarith-tiny `(let* ,rest-binding-pairs ,e-body)))]
    
    
    ;; print an arbitrary expression (must be a number at runtime)
    [`(print ,_)
     e]
    ;; and/or, with short-circuiting semantics
    [`(and ,e0) (ifarith->ifarith-tiny e0)]
    [`(and ,e0 ,es ...) (ifarith->ifarith-tiny `(if ,e0 (and ,@es) 0))]
    [`(or ,e0) (ifarith->ifarith-tiny e0)]
    [`(or ,e0 ,es ...) (ifarith->ifarith-tiny `(if ,e0 true (or ,es)))]
    ;; if argument is 0, false, otherwise true
    [`(if ,e0 ,e1 ,e2) `(if ,(ifarith->ifarith-tiny e0)
                            ,(ifarith->ifarith-tiny e1)
                            ,(ifarith->ifarith-tiny e2))]
    ;; cond where the last case is else
    [`(cond [else ,(? ifarith? else-body)])
     (ifarith->ifarith-tiny else-body)]
    [`(cond [,c0 ,e0] ,rest ...)
     (ifarith->ifarith-tiny `(if ,c0 ,e0 (cond ,@rest)))]))
     ;; in racket a zero isn't neccisarily a false.

;; Stage 3: Administrative Normal Form (ANF)
;; 
;; In administrative normal form (or A-normal form) breaks up complex
;; instructions into simple instructions by introducing extra
;; "administrative" bindings. For example, (+ 1 (* 2 3)) may be
;; decomposed as (let ([v (* 2 3)]) (+ 1 v)). We want to do this
;; because, in assembly, we must do one single operation at a time.

;; Translator: IfArith-Tiny |--> ANF
;; 
;; Conversion into A-Normal form. See here if you are interested:
;; https://matt.might.net/articles/a-normalization/
;; 
;; The algorithm is tricky but intersting.
(define (value? v)
  (match v
    [(? lit? l) #t]
    [(? symbol? x) #t]
    [_ #f]))
(define (ifarith-tiny->anf e)
  (define (normalize-term M) (normalize M (lambda (x) x)))
  (define (normalize M k)
    (pretty-print M)
    (match M
      [(? lit? l) (let ([t (gensym "x")]) `(let ([,t ,l]) ,(k t)))]
      [(? value?) (k M)]
      ['#t (k 1)] ;; for true to true num rep.
      ['#f (k 0)] ;; for flase to false
      [`(if ,e0 ,e1 ,e2)
       (normalize-name e0 (lambda (t) (k `(if ,t ,(normalize-term e1) ,(normalize-term e2)))))]
      [`(let ([,x ,e]) ,e-b)
       (normalize e (lambda (N1) `(let ([,x ,N1]) ,(normalize e-b k))))]
      [`(,f ,e0 ,e1)
       (normalize-name e0
                       (lambda (t0) (normalize-name e1
                                                    (lambda (t1) (let ([t (gensym "x")])
                                                                   `(let ([,t (,f ,t0 ,t1)]) ,(k t)))))))]
      [`(,f ,e0)
       (normalize-name e0 (lambda (t0) (k `(,f ,t0))))]
      [`(print ,e0)
       (normalize-name e0 (lambda (t) (k `(print ,t))))]))
  (define (normalize-name M k)
    (normalize M
               (lambda (N) (if (symbol? N)
                               (k N)
                                (let ([t (gensym "x")]) `(let ([,t ,N]) ,(k t)))))))
  (normalize-term e))

;; Stage 4: IR-Virtual
;; 
;; Instructions in ir-virtual? are very simple. Notice that it is a
;; very restrictive language, which requires *everything* be put in a
;; virtual register. This is a pain to write manually, but it's
;; simpler to compile fewer forms, so we take this shortcut; in
;; practice, many architectures (x86, etc.) do enable instructions
;; whose operands are a mix of registers, constants, and memory
;; addresses. A more advanced compiler would employ an instruction
;; selection phase to particularize these to a given ISA; we use a
;; naive strategy: stack allocate everything, shuffle into and out of
;; registers. It will work but it will not be as fast as if we used
;; registers more optimally.

(define label? symbol?) ;; labels will be symbols

(define (virtual-instr? instr)
  (define register? symbol?)
  (match instr
    ;; move a literal into a register
    [`(mov-lit ,(? register? dst) ,(? lit? src)) #t]
    [`(mov-reg ,(? register? dst) ,(? register? src)) #t]
    ;; instructions
    [`(add ,(? register? dst) ,(? register? src)) #t]
    [`(mul ,(? register? dst) ,(? register? src)) #t]
    [`(idiv ,(? register? dst) ,(? register? src)) #t]
    [`(sub ,(? register? dst) ,(? register? src)) #t]
    [`(shr ,(? register? dst) ,(? register? src)) #t]
    [`(shl ,(? register? dst) ,(? register? src)) #t]
    [`(cmp ,(? register? dst) ,(? register? src)) #t]
    ;; unconditional jump
    [`(jmp ,(? label? symbol?)) #t]
    ;; jump if not zero
    [`(jnz ,(? label? symbol?)) #t]
    ;; print the (64-bit integer) in the register src
    [`(print ,(? register? src)) #t]
    [_ #f]))

;; a possibly-labeled (or not) instruction. When lists of instructions
;; are put in sequence, you may jump between them using the various
;; jump instructions, jmp and jnz
(define (labeled-virtual-instr? instr)
  (match instr
    [`((label ,l) ,(? virtual-instr? i)) #t]
    [(? virtual-instr? i) #t]
    [_ #f]))

;; ir-virtual is just a list of these possibly-labeled virtual
;; instructions.
(define (ir-virtual? instrs)
  (and (list? instrs)
       (andmap labeled-virtual-instr? instrs)))

;; Translation: ANF |--> Ir-Virtual
;; 
;; In this stage we will take an expression that is, essentially, a
;; decision tree (with `let`-binding and primitive application) and
;; turn it into a linearized list of instructions.
(define (anf->ir-virtual e)
  (define (name->op op)
    (hash-ref (hash '* 'imul '+ 'add '- 'sub 'not 'not) op))
  ;; helper function which does the bulk of the work, labels
  ;; everything in the return value.
  (define (linearize e)
    (define my-lab (gensym "lab"))
    (match e
      ;; these forms terminate; we mark them with a special mark,
      ;; exit. When we ultimately emit x86 code, we will need to
      ;; ensure that these points all branch to an "exit" node.
      [`(print ,x)
       `(((label ,my-lab) (print ,x)) (return 0))]
      ;;[(? symbol? x) `((mov-rax ,x) (exit))]
      ;;[(? integer? i) `((mov-rax ,i) (exit))]
      [(? value? v) `((return ,v))]
      ;; the rest of the forms either (a) contain explicit branches,
      ;; or (b) fallthrough to the rest.
      [`(let ([,x ,(? lit? l)]) ,e-b)
       `(((label ,my-lab) (mov-lit ,x ,l)) . ,(linearize e-b))]
      ;; by this point, we'll have forced literals into variables
      [`(let ([,x (,f ,x0 ,xs ...)]) ,e-b)
       `(((label ,my-lab) (mov-reg ,x ,x0))
          (,(name->op f) ,x ,@xs)
         . ,(linearize e-b))]
      [`(let ([,x ,y]) ,e-b)
       `(((label ,my-lab) (mov-reg ,x ,y))
         . ,(linearize e-b))]
      [`(if ,xg ,et ,ef)
       (define compilation-of-et (linearize et))
       (define compilation-of-ef (linearize ef))
       (define (label sequence)
         (match sequence
           [`(((label ,l) . ,_) . ,_) l]
           [_ (error "expected a label to start the instruction sequence")]))
       (define x (gensym "zero"))
       (append `(((label ,my-lab) (mov-lit ,x 0)) 
                 (cmp ,xg ,x)
                 (jnz ,(label compilation-of-et)) ;; should probably be jnz...?
                 ;; if we jump when zero flag is up, 
                 (jmp ,(label compilation-of-ef))) 
               ;; notice that the compilation of et/ef must end in a
               ;; (exit) mark so that we don't "fall through" from the
               ;; end of et to the beginning of ef.
               compilation-of-et
               compilation-of-ef)]))
  (linearize e))

;; Ir-Virtual |--> x86 (Stage 5)
;; 
;; Now we present a dirt-simple compiler from ir-virtual? to x86. The
;; central challenge is how to deal with the unbounded number of
 ;; registers in ir-virtual. We accomplish this by "spilling:" we
;; stack-allocate all virtual registers. This approach will work,
;; provided we don't run out of stack space, and that we shuffle
;; results into and out of intermediary registers.
;; 
;; We should also note here that our approach is really only thinking
;; of a single function: variables are all global. In practice, these
;; will all just be local variables sitting on the stack in the
;; program's main function. It would be more complicated to handle a
;; language with functions, for many reasons, including a more
;; thoughtful handling of environments (closures, etc...).
;; 
;; Here, we keep it dirt simple to make it (hopefully) simpler.

;; We skip a formal definition of x86. It is the output of the
;; following function: ir-virtual->x86.

(define (what-is-printf)
  (if (i-am-a-mac)
      "_printf"
      "printf"))

(define (what-is-main)
  (if (i-am-a-mac)
      "_main"
      "main"))

;; Here is a translation into x86
(define (ir-virtual->x86 instrs)
  ;; calculate the registers used, we need this to determine how much
  ;; stack space to allocate.
  (define (registers-used i)
    (match i
      [`((label ,l) ,i) (registers-used i)]
      [`(,op ,ops ...) (set->list (filter symbol? ops))]))
  (define registers (foldl (lambda (instr acc) (set-union (list->set (registers-used instr)) acc)) (set) instrs))
  (define num-registers (set-count registers))
  (define reg->stackpos (foldl (lambda (reg-name offset acc) (hash-set acc reg-name (- (* offset 8))))
                               (hash)
                               (set->list registers)
                               (range 1 (add1 num-registers))))
  ;; calculate the labels used: we add tons of unreachable labels; we
  ;; calculate reachable labels via a foldl.
  (define (labels-used i)
    (match i
      [`((label ,l) ,i) (labels-used i)]
      [`(jmp ,l) (set l)]
      [`(jnz ,l) (set l)]
      [`(jz ,l) (set l)]
      [`(call ,l) (set l)]
      [`(,op ,ops ...) (set)]))
  (define reachable-labels (foldl (lambda (instr acc) (set-union (labels-used instr) acc)) (set) instrs))
  ;; translate into a sequence of x86 instructions
  (define (translate instr)
    (match instr
      [`((label ,l) ,instr)
       (define instrs (translate instr))
       (if (set-member? reachable-labels l)
           `(((label ,l) ,(first instrs)) . ,(rest instrs))
           instrs)]

      [`(mov-lit ,dst ,src)
       `((mov "esi" ,(format "~a" src))
         (mov ,(format "[rbp~a]" (hash-ref reg->stackpos dst)) "esi"))]
      [`(mov-reg ,dst ,src)
       `((mov "esi" ,(format "[rbp~a]" (hash-ref reg->stackpos src)))
         (mov ,(format "[rbp~a]" (hash-ref reg->stackpos dst)) "esi"))]
      [`(print ,src)
       `((mov "esi" ,(format "[rbp~a]" (hash-ref reg->stackpos src)))
         (lea "rdi" "[rel int_format]")
         (mov "eax" "0")
         (call ,(what-is-printf)))]
      [`(call ,f) `((call ,f))]
      [`(jmp ,f) `((jmp ,f))]
      [`(jnz ,f) `((jnz ,f))]
      [`(jz ,f) `((jz ,f))]
      ;; mul needs to go in rax
      #;
      [`(imul ,dst ,src)
       `((mov "rdi" ,(format "[rbp~a]" (hash-ref reg->stackpos src)))
         (mov "rax" ,(format "[rbp~a]" (hash-ref reg->stackpos dst)))
         (imul "rdi")
         (mov "rax" ,(format "[rbp~a]" (hash-ref reg->stackpos dst))))]
      [`(,op ,dst ,src)
       `((mov "edi" ,(format "[rbp~a]" (hash-ref reg->stackpos src)))
         (mov "eax" ,(format "[rbp~a]" (hash-ref reg->stackpos dst)))
         (,op "eax" "edi")
         (mov ,(format "[rbp~a]" (hash-ref reg->stackpos dst)) "eax"))]
      ;; emit code to jump to the exit
      [`(return ,v)
       `((mov "rax" ,(if (number? v) (number->string v) (format "[rbp~a]" (hash-ref reg->stackpos v))))
         (jmp "finish_up"))]))
  (define translated-instrs
    (foldl (λ (instr instrs) (append instrs (translate instr))) '() instrs))

  `((function (,(string->symbol (what-is-main)))
               (push "rbp")
               (mov "rbp" "rsp")
               ;; allocate num-registers * 16. This is more than we
               ;; need but the stack needs to be 16-byte aligned :-)
               (sub "rsp" ,(format "~a" (* 16 num-registers)))
               ,@translated-instrs
               ((label "finish_up") (add "rsp" ,(format "~a" (* 16 num-registers)))) 
               (leave)
               (ret))))

;; x86 |--> NASM Assembly (Stage 5)
;; 
;; We compile to NASM assembly, which can be compiled, e.g., on Linux:
;; nasm -fmacho64 example.asm.
(define (print-x86 x86)
  (define (op->string op)
    (cond [(symbol? op) (symbol->string op)]
          [(string? op) op]
          [else (error op)]))
  (define (render-instr instr)
    (match instr
      [`((label ,l) ,i) (string-append (format "~a:" l) (render-instr i))]
      [`(,opcode ,ops ...) (format "\t~a ~a\n"
                                   (symbol->string opcode)
                                   (string-join (map op->string ops) ", "))]
      [`(call ,name) (format "\tcall ~a\n" name)]
      ['syscall "\tsyscall"]
      ['leave "\tleave"]
      ['ret "\tret"]))
  (define (print-function f)
    (match f
      [`(function (,name) ,instrs ...)
       (string-append
        (format "~a:" name)
        (apply string-append (map render-instr instrs)))]))
  ;; include a preamble
  ;; need to upload noahs code for this <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<,,,
  (displayln (format "\tglobal _start\n\textern ~a\nsection .text\n\n" (what-is-printf)))
  ;; change above to global _start for my Linux machine.
  (displayln (print-function `(function (_start)
                                        (call ,(what-is-main))
                             (mov "rax" "60")
                             (xor "rdi" "rdi")
                             syscall))) 
  (displayln "\n")
  (displayln (print-function (first x86)))
  (displayln "section .data\n\tint_format db \"%ld\",10,0\n\n")
  ) ;; only print the first (main) for now


;;
;; Command-line parsing and actually running the compiler
;; 

;; compile from ir-virtual
(define (compile-ir-virtual [ir-virtual (get-input-tree)])
  (when (verbose-mode)
    (begin
      (displayln "ir-virtual:")
      (pretty-print ir-virtual)))
  (define x86 (ir-virtual->x86 ir-virtual))
  (when (verbose-mode)
    (begin
      (displayln "x86:")
      (print-x86 x86)))
  ;; write the output .asm file
  (with-output-to-file file-to-write (lambda ()(print-x86 x86)) #:exists 'replace)
  (when (verbose-mode)
    (displayln (format "The file has now been written to ~a. You must now assemble and link it." file-to-write))
    (if (i-am-a-mac)
        (begin
          (displayln (format "(Assemble on Mac, requires nasm:)\n\tnasm -fmacho64 ~a" file-to-write))
          (displayln (format "(Link on Mac, hopefully)\n\tld ~a -o ~a -macosx_version_min 11.0 -L /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lSystem" object-file exe-file)))
        (begin
          (displayln (format "(Assemble on Linux, requires nasm)\n\tnasm -felf64 ~a" file-to-write))
          (displayln (format "(Link on Mac, hopefully)\n\tld -dynamic-linker /lib64/ld-linux-x86-64.so.2 ~a -o ~a -lc" object-file exe-file))))))

;; compile from ifarith
(define (compile-ifa)
  (define source-tree (get-input-tree))
  (when (verbose-mode)
    (begin
      (displayln "Input source tree in IfArith:")
      (pretty-print source-tree)))
  ;; compile ifarith |--> ifarith-tiny
  (define ifarith-tiny (ifarith->ifarith-tiny source-tree))
  (when (verbose-mode)
    (begin
      (displayln "ifarith-tiny:")
      (pretty-print ifarith-tiny)))
  ;; compile ifarith-tiny |--> ir-virtual
  (define anf (ifarith-tiny->anf ifarith-tiny))
  (when (verbose-mode)
    (begin
      (displayln "anf:")
      (pretty-print anf)))
  (define ir-virtual (anf->ir-virtual anf))
  (compile-ir-virtual ir-virtual))

;; Entrypoint -- we allow loading .ifa or .irv files to facilitate
;; easy testing.
;; parse the command line
(define filename
  (command-line
   #:once-each
   [("-v" "--verbose") "Run with Verbose output."
    (verbose-mode #t)]
   [("-m" "--mac") "Generate code that is compatible with MachO."
    (i-am-a-mac #t)]
   #:args (filename) ; expect one command-line argument: <filename>
   ; return the argument as a filename to compile
   filename))

(define file-to-write (string-append (first (string-split filename ".")) ".asm")) 
(define object-file (string-append (first (string-split filename ".")) ".o")) 
(define exe-file (string-append (first (string-split filename ".")))) 

;; parsing is as easy as using Racket's `read`
(define (get-input-tree)
  (with-input-from-file filename
    (lambda () (read))))

(match (last (string-split filename "."))
  ["ifa" (compile-ifa)]
  ["irv" (compile-ir-virtual)]
  [_ (print "Error: files must end in .ifa (ifarith) or .irv (ir-virtual)")])


;; 
;; Running this compiler:
;; 
;; To compile a file, invoke as follows:
;; 
;; (MacOS)
;;     racket compiler.rkt -v -m test-programs/if2.ifa
;;     < output written to test-programs/if2.asm > 
