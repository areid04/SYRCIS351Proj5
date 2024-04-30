# Discussion and Reflection


The bulk of this project consists of a collection of five
questions. You are to answer these questions after spending some
amount of time looking over the code together to gather answers for
your questions. Try to seriously dig into the project together--it is
of course understood that you may not grasp every detail, but put
forth serious effort to spend several hours reading and discussing the
code, along with anything you have taken from it.

Questions will largely be graded on completion and maturity, but the
instructors do reserve the right to take off for technical
inaccuracies (i.e., if you say something factually wrong).

Each of these (six, five main followed by last) questions should take
roughly at least a paragraph or two. Try to aim for between 1-500
words per question. You may divide up the work, but each of you should
collectively read and agree to each other's answers.

[ Question 1 ] 

For this task, you will three new .irv programs. These are
`ir-virtual?` programs in a pseudo-assembly format. Try to compile the
program. Here, you should briefly explain the purpose of ir-virtual,
especially how it is different than x86: what are the pros and cons of
using ir-virtual as a representation? You can get the compiler to to
compile ir-virtual files like so: 


racket compiler.rkt -v test-programs/sum1.irv 
ld test-programs\sum1.o -o test-programs\sum1

(Also pass in -m for Mac)

The purpose of ir-vrtual is to utalize virtual registers (like r0, r1, r2...)
instead of registers like rax or rbi and the stack. This makes writing programs 
significantly easier; with no manipulation of the stack in ir-virtual, you could avoid
memory corruption bugs like accidently overwriting a return address on the stack. 
In ir-virtual, you can have an infinite number of registers to move around data / arithmatic,
which is physically impossible for a machine using x86 instructions. Using our particular
virtual register strategy, we extend the stack with our virtual registers content (like 8, 5, 3...)
and later refer to these adresses on the stack when we need to do some processing (like add). A downside to this is in order to 
keep things simple, we have
a lack of functions in our language: if we are to add functions to our code (things like C's gets) we would have to
keep track of our virtual registers on the stack and our functions that also use the stack. Simply using x86 directly
wouldn't neccisarily have this complexity: we can keep registers in things like rax, rbx, and keep the stack cleaner for calling
functions.

Having an ir-vrirtual step allows us to generalize our irtharith code, so that any
ISA could take our virtual pseudo-assembly and translate it to their specific
architecture. Steps like (move-lit r1 5) are genrally interpetable by all ISA's, but
mov $5, rsi could only be intepretted by those with 64 bit functionality (and those that use a src, DST grammar)

Example Codes:

((mov-lit r1 10)
(mov-lit r2 20)
(mov-lit r3 0)
(add r2 r1)
(add r2 r1)
(print r2))




[ Question 2 ] 

For this task, you will write four new .ifa programs. Your programs
must be correct, in the sense that they are valid. There are a set of
starter programs in the test-programs directory now. Your job is to
create three new `.ifa` programs and compile and run each of them. It
is very much possible that the compiler will be broken: part of your
exercise is identifying if you can find any possible bugs in the
compiler.

For each of your exercises, write here what the input and output was
from the compiler. Read through each of the phases, by passing in the
`-v` flag to the compiler. For at least one of the programs, explain
carefully the relevance of each of the intermediate representations.

For this question, please add your `.ifa` programs either (a) here or
(b) to the repo and write where they are in this file.

Program 1:
(let* ([a (+ 1 1)]
        [b (+ a 3)]
        [z (* a b)]
        [q (+ a b)])
        (if 0 (print z) (print q))
        )

Output : 7

[ Question 3 ] 

Describe each of the passes of the compiler in a slight degree of
detail, using specific examples to discuss what each pass does. The
compiler is designed in series of layers, with each higher-level IR
desugaring to a lower-level IR until ultimately arriving at x86-64
assembler. Do you think there are any redundant passes? Do you think
there could be more?

In answering this question, you must use specific examples that you
got from running the compiler and generating an output.

Why are we putting the  data the way it is?

[ Question 4 ] 

This is a larger project, compared to our previous projects. This
project uses a large combination of idioms: tail recursion, folds,
etc.. Discuss a few programming idioms that you can identify in the
project that we discussed in class this semester. There is no specific
definition of what an idiom is: think carefully about whether you see
any pattern in this code that resonates with you from earlier in the
semester.

Recursive helper in the normalize section.
overall matching expressions, and reducing within those larger expressions.

[ Question 5 ] 

In this question, you will play the role of bug finder. I would like
you to be creative, adversarial, and exploratory. Spend an hour or two
looking throughout the code and try to break it. Try to see if you can
identify a buggy program: a program that should work, but does
not. This could either be that the compiler crashes, or it could be
that it produces code which will not assemble. Last, even if the code
assembles and links, its behavior could be incorrect.

To answer this question, I want you to summarize your discussion,
experiences, and findings by adversarily breaking the compiler. If
there is something you think should work (but does not), feel free to
ask me.

Your team will receive a small bonus for being the first team to
report a unique bug (unique determined by me).


Linux distro fix.
We're matching to jnz, but we never match to jnz???
we should have the unconditional jnz to jz..

Making sure that normalize can read our #t / #f as true and false.

[`(let* ([,(? symbol? x0) ,e0]) ,e-body) `(let ([,x0 ,e0]) ,(ifarith->ifarith-tiny e-body))]
    [`(let* ([,(? symbol? x0) ,e0] ,rest-binding-pairs ...) ,e-body) `(let ([,x0 ,e0]) ,(ifarith->ifarith-tiny `(let* ,rest-binding-pairs ,e-body)))]
    

SWITCH THINGS AROUND!!!!!!!!1

[ High Level Reflection ] 

In roughly 100-500 words, write a summary of your findings in working
on this project: what did you learn, what did you find interesting,
what did you find challenging? As you progress in your career, it will
be increasingly important to have technical conversations about the
nuts and bolts of code, try to use this experience as a way to think
about how you would approach doing group code critique. What would you
do differently next time, what did you learn?

mnt/c/\Users\alexr\OneDrive\Desktop\CIS352\ifarith-compiler

cd /mnt/c/Users/alexr/OneDrive/Desktop/CIS352/ifarith-compiler/test-programs

nasm -felf64 file
ld -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o sum1 sum1.o -lc