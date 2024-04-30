# IfArith Compiler Project

For this project, you must fork / clone the GitHub repo and make your
own with your solutions and discussion. There are three deliverables:
compiler.rkt, several new programs in test-programs, and
discussion.md.

This is a group code review project--you should plan for roughly 5
hours outside of class meeting with your group (in person or zoom is
fine, as long as everyone is there together). There will be a small
amount of programming, comprising the warmup.

In this project, we will implement a tiny fragment of a compiler, from
a small language of IfArith down to NASM (an x86-like
Assembler). There will be only a small amount of implementation during
this project. Instead, this project will have you practice peer code
review.

Your team is to arrange (potentially several) times to meet and go
through the compiler together, running examples and trying to get it
to work on someone's machine. If you are stuck and having trouble,
reach out to the professor (Kris) and I will try to get you unstuck.

We wil discuss on Slack precisely how to run the compiler on various
architectures. It should be possible on either a Mac or a Linux
machine. I have not tested on Windows: if you have a Windows machine
only, please pair up with someone that has a Linux or Mac machine you
can use.

Remember to keep things focused on code review: the purpose is to
meet, try to run the compiler, document your success or failure (reach
out to me if things are breaking, I will work to get you unstuck), and
make some reflections. Try to use this as a time to read a larger
codebase and discuss it seriously with some peers.

I recommend starting by implementing--as a group--the function
ifarith->ifarith-tiny in compiler.rkt. Once you have this function
(correctly) implemented and tested, move on to the other parts.

# Tasks

[ 20% ] -- The implementation of `ifarith->ifarith-tiny`. This should
be completed in `compiler.rkt` and must be done first. It should
largely consist of your team discussing (perhaps rewriting) the
implementation I detail in class. Please at least discuss the forms
and make sure everyone is on the same page.

[ 65% ] -- Answering questions in discussion.md

[ 15% ] -- Peer assessment form, fill our peer.md and send to the TA
Jialin Ye and the instructor.

Link on Mac, hopefully -- should be link on linux.
Running with a windows machine leads to problems.

Paragraph or two.


.ifa are INPUTS. the output should be x86-64 code. Takes in an if arif exam


vvv need to have NASM installed.
NASM - netwide assembler.

sudo apt-get NASM...

Will be in .asm format.

First step : Desugaring . WE have ifArith.

Unary and binary steps. 

cond , and , or can all be desugared into if.

Second step: ifArith-tiny. This is what we will implement.

Integers translates to self
True : 1
False : 0

translate e0 and e1
let* translates e0 into x and moves into the body

let* compiles into a sequence of lets.

print needs to put it into input lang

and with a single thing is e0 ; and e0 is e0

(and e0 and es ... ) => DONT TRANSLATE TO (if e1 e0 e1)
side effects of e0 might be evaulated multiple times.

capture in a let!
(let ([v e0]) (if v v e1))
only evals e0 once.

or is the same way.


cond can be turned into usages of if :
(or e) => e
(or e0 e1) -> (let ([v e0]) (if v v e1))
(and e) => e
(cond ([e0 b0] next...)) -> (if e0 b0 (cond rest...))
(cond ([else e])) -> e


USE FOR p4!!!!!!!!!!!! <<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>
(let* ([,x ,e] ,rest...) eb) -> (let ([x e]) (let* (@rest) eb))


first desugaring path goes to ifArithTiny.
In ifArithTiny we have (+ (* 2 3) (* 4 5))
Instructions in assembly can only have an atomic arguement. would have to translate to:
mov rax, 2
mov rbx, 3
imul rbx, rax
mov

A normal form: we build up admiinistrative bindings.

(let ([x 2] [y 3]) (let ([x2 (* x y)] (let ([a 4] [b 5] (let [(x23 (* a b))] (+ x2 x23)))))))

Task 1: Compile a bunch of the test programs.
desugaring translates it to ifarith tiny

a normalization translates it down to ANF

Step four : Linearization. in a normal, we have all let instructions
linearization is the next phase . IrVirtual is a virtual assembly language.
It has virtual registers (as many as we want!)

Step five: take ir Virtual and go to pseudo x86 (s expression form of 86)
Output: x86-64 NASM is the final file.

task1 : write three new .irv programs in pseudo assembly format.

look at a few of them.
sum1 . irv is an example of a virtual file.
This is the guts of the compiler. Not source syntax, but it's intermediate format.
should turn into code that prints into 13. Look at definition of ir virtual.
has add, mul, div, shifts left and right
and has jmp and jnz. We only need jnz. Compile a guard if its zero, jump to zero.

Run this and see what happens. We are starting at IR-Virtual, it will SKIP! the three stages

Difficultu 2/5


Task 2:

Three new IfA programs. They are supposed to be valid. They must be correct. 
Set of starter programs. Write what the input as and what the output was.


Question 3: Describe each pass of the compiler. What is the pass of the designer supposed to be?
Are there any redundency? Should you use more phases?

Use specific examples from running compiler and generating output.
3/5

Question 4:
look for idioms : using fold l to calcaluate number of virtuals

Ir Virtual -> x86
Ir virtual uses an unbounded number of registers. Can't fit this all to registers!
We calculate all the registers being used. Say it uses 50.
It requires fifty times 8 bytes. (each register is 8 bytes long)
50 * 8 allocated bytes on the stack.
50 * 16 (stack has to be 16 byte aligned.)

We calclulate the lables we use. 
Each individual ir virtual instructions translates down to a set of instructions
Loads into a register.

Can't do memroy to memory transalte into move, we have to go to a register and go to another.
Move reg : storing on the stack.


>>> Read through the compiler and notice specificm idoims. Tail recursion, foldl, accumulating over an AST.
no specific definition. what is being used in code? what do we see that can be used better?

Function calls and returns?

Question 5:

Play bug finder. Explore code. Some little bugs in the compiler.
MOST compile correctly. If you can fidn a bug and report it, we can get bonus credit. First team to report a "unique" bug.

Inputs and outputs should do the wrong thing.

Summarize our discussion and experiences and findings by breaking the compiler.




END : High level refection


We have until MAY FIFTH! To do the project.
To acutally turn in the project, there's a sign up.

We need to fork the review.

compiler.rkt should be friendly.
List inputs and outputs.

Social activity. Reading and crituqing your code. Find bugs.
See something a compiler would be better.


WRiting code proffessionall has plenty of reviews.

PC architecutre / Compiler course.

godbolt.org

Online compiler. Webapp. Lets us write code.
use x86-64 compiler (clang)

How the compiler and assembly works.

-O3 optimizer.

Next week in class is review session. Practice exam out tomorrow. Same format as first midterm.
Four questions
1. STLC. Proof system type rules. Write a simpler version of the excerises
Three other questions. TBD....

Most recent : Challenging..........


/mnt/c/Users/alexr

(Assemble on Linux, requires nasm)
        nasm C:\Users\alexr\OneDrive\Desktop\CIS352\ifarith-compiler\test-programs\sum1.asm
(Link on Mac, hopefully)
        ld C:\Users\alexr\OneDrive\Desktop\CIS352\ifarith-compiler\test-programs\sum1.o -o C:\Users\alexr\OneDrive\Desktop\CIS352\ifarith-compiler\test-programs\sum1