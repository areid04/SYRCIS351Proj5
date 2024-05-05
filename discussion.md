(# Discussion and Reflection


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

The purpose of ir-virtual is to utilize virtual registers (like r0, r1, r2...) instead of registers like rax or rbi and the stack. This makes writing programs significantly easier; with no manipulation of the stack in ir-virtual, you could avoid memory corruption bugs like accidentally overwriting a return address on the stack. In ir-virtual, you can have an infinite number of registers to move around data/arithmetic, which is physically impossible for a machine using x86 instructions. Using our particular virtual register strategy, we extend the stack with our virtual register content (like 8, 5, 3...) and later refer to these addresses on the stack when we need to do some processing (like add). A downside to this is in order to keep things simple, we have
a lack of functions in our language: if we are to add functions to our code (things like C's gets) we would have to keep track of our virtual registers on the stack and our functions that also use the stack. Simply using x86 directly wouldn't necessarily have this complexity: we can keep registers in things like rax, rbx, and keep the stack cleaner for calling functions.

Having an ir-virtual step allows us to generalize our irtharith code so that any ISA could take our virtual pseudo-assembly and translate it to their specific architecture. Steps like (move-lit r1 5) are generally interpretable by all ISAs, but mov $5, rsi could only be interpreted by those with 64-bit functionality (and those that use a src, DST grammar).

Example Codes:

Excode1:
((mov-lit r1 10)
(mov-lit r2 20)
(mov-lit r3 0)
(add r2 r1)
(add r2 r1)
(print r2))

Excode2:
((mov-lit r1 0)
(mov-lit r2 20)
(mov-lit r3 0)
(cmp r2 r1)
(jnz lab12)
(add r2 r1)
(add r2 r1)
(print r2)
(return 0)
((label lab12) (mov-lit r3 10))
(add r2 r3)
(print r2)
(return 0))

Infinite Loop Example:

( (mov-lit r2 10)
    ((label lab1) (print r2))
    (jmp lab1)
    (return 0))





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

The first pass into if-arith->if-tiny converts our let* variable bindings into a series of stacked lets – similar to how we would curry multi-argument lambdas into single forms. We still allow larger arithmetic expressions to exist in this stage, but variables are the first to be simplified. This changes at the a-normal translation – creating a very large stacked let statement – though some statements like “if” and “print” still remain.
This changes at the virtual stage – we are able to translate let bindings into the movement of registers, if statements into standard cmp / jmp motifs, and addition of registers as basic assembly instructions (add, sub). This is crucial for the “if” statement of our example code – we check if 0 is equal to 0, which chooses if we jump to print z or print q. We still need to translate this into the final step – the x86 form – which creates a properly formatted .asm file.

Program 2:
(cond [(* 4 (- 2 2)) (print 1)]
      [(+ 3 (* 1 3)) (print 2)]
      [(* 2 (+ 1 -1)) (print 3)]
      [else (print 4)])

Output: 2

Program 3:
(cond [0 (print 1)]
      [#f (print 2)]
      [#f (print 3)]
      [else (if 0 (print 4) (print 5))])

Output: 5

[ Question 3 ] 

Describe each of the passes of the compiler in a slight degree of
detail, using specific examples to discuss what each pass does. The
compiler is designed in series of layers, with each higher-level IR
desugaring to a lower-level IR until ultimately arriving at x86-64
assembler. Do you think there are any redundant passes? Do you think
there could be more?

Stage 1 of the project is defining the smaller language. With match cases for booleans, let*, print, and, or, if, and cond all being defined in our language, stage one is all about making sure our .ifa input is valid. No function definitions for such a small language – we should only be evaluating “one” equation.

Stage 2 is a further simplifying stage.  False and true in this language are zero and anything non zero respectively using matching with the bools.

For example, the cases we’ve added with ['true 1]  ['false 0] will make sure that even if a bool is put down, it will be interpreted as either a zero or non -zero (in this case 1). The 1 could be any non-zero integer we want though – we chose to keep this standard. 

We change the logical operation to their if forms and let* to let. Similar to stage one, we first define what constitutes the form of simplified, if-arithtiny expression, in the language spec section. The function ifarith->ifarith-tiny section is where the expression from part 1 has it’s let*, and, or, and cond operation terms changed to their simpler forms. 

[`(,(? uop? uop) ,e) `(,uop ,(ifarith->ifarith-tiny e))]

In this case, we match a uop (which is either “-” or “not”) and then apply the uop and evaluate the rest of the expression to the ifarith-tiny form.


Stage 3
This stage is where we make sure the compiler can handle each expression by converting it into a-normal form. This is where we build our long sequences of lets stacked up onto each other; assembly code is not capable of large sequences of arithmetic in the same step or cycle, meaning we need to create and bind intermediate variables as we do intermediate arithmetic. Not “all” of the if-arith tiny is necessary for such a reduction (such as print, which has remained simply as “print” for the last three translations), but it’s very easy to see an exponential boom of lets for even a small equation. In our implementation, we also generate a unique label for variables – further evidence that we expect plenty of let bindings.

Stage 4
This stage is the last pass before we create any assembly code. Here, we are using virtual registers as placeholders for the stack pushing / popping we implement later. We essentially have “infinite” amount of registers here, which acts as a form of simplifying the transition between our stacked let bindings and physical, machine registers. Expressions here are arguably easier to interpret than a-normal form, especially if you’re dealing with a hefty amount of variable bindings, but minimal arithmetic expressions.

Stage 5
When passing (print (+ 1 2)) through this, the assembly file we get is

	global _start
	extern printf
section .text


_start:	call main
	mov rax, 60
	xor rdi, rdi
	syscall


main:	push rbp
	mov rbp, rsp
	sub rsp, 48
	mov esi, 1
	mov [rbp-24], esi
	mov esi, 2
	mov [rbp-16], esi
	mov esi, [rbp-24]
	mov [rbp-8], esi
	mov edi, [rbp-16]
	mov eax, [rbp-8]
	add eax, edi
	mov [rbp-8], eax
	mov esi, [rbp-8]
	lea rdi, [rel int_format]
	mov eax, 0
	call printf
	mov rax, 0
	jmp finish_up
finish_up:	add rsp, 48
	leave 
	ret 

section .data
	int_format db "%ld",10,0


We are placing things on the stack to come back to later. Commands like mov [rbp-24] esi are pushing values onto the stack, and mov esi [rbp-24] takes these saved values and puts the value into a register. This is “the” code that will eventually be turned into a usable executable file. This isn’t typical x86 assembly code, though – we might expect much more register usage to save intermediate values for addition / subtraction. While we can see that there is obvious function potential in this code (with jumps, for example), this didn’t trickle back up to our original .ifa input. We believe that this might be a result of how we store values onto the stack – implementing return addresses with how we store values into the stack would be like trying to navigate a minefield.


[ Question 4 ] 

This is a larger project, compared to our previous projects. This
project uses a large combination of idioms: tail recursion, folds,
etc.. Discuss a few programming idioms that you can identify in the
project that we discussed in class this semester. There is no specific
definition of what an idiom is: think carefully about whether you see
any pattern in this code that resonates with you from earlier in the
semester.

In Project 5, there are many idioms that we have encountered throughout class. One of the idioms used in Project 5 is the use of pattern matching through the `match` function. In Project 4, the `match` form was a large part of the project, specifically in the churchify function, which shares many similarities with some of the functions in Project 5, such as ifarith->ifarith-tiny. Using match alongside a recursive function (best demonstrated in the a-normal translation step) was a key concept in this course, allowing the creation of effective tail-recursive code. Another idiom we noticed is the use of let and let*. In projects 3 and 4 we used let and let* to create binding cases. These functions are the “heart” of project five, allowing us to bind smaller equations into variables to do later, larger, expressions. Foldl is another example of an idiom used in Project 5. In the previous projects, the use of foldl was required. In previous projects, foldl was a very useful tool for hash manipulation with hash-ref or hash-set. While it would be possible to do a recursive implementation, such cases as when we want to check the values stored in a hash (such as labeled variables acting as registers in our ir-virtual -> x86 step), are best done in a large swoop – perfect for fold!

Overall, there were many idioms used throughout Project 5 that were also used throughout the previous projects. While not an exact “cumulative” representation of all previous projects, we had to be confident in our past work before we could tackle this project directly. 

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

One of the first things we had to solve was compiling .asm code to object files, and then using our machines’ linker functions to link to the needed libraries. Some members of our team were able to find a solution for those running a UNIX x86-64 based machine, by making the following adjustments to the code and command arguments:

Using nasm, we generate .asm code from .iva files with nasm -elf64 testprograms/FILENAME.iva 
Changing the ld arguments to the following libraries: 
ld -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o DESIREDOUTPUT OBJFILENAME.o -lc

Change compiler.rkt to produce “section .data” code blocks to be at the foot of .asm files
Change global _main to global _start , as the linker parses for _start as the entry point of files.

We also had to make changes to the assembly files generated when using if statements. We noticed that “if” statements were producing the logical inverse of the guard; if 0 1 0 would produce an output of 1, for example. This is because of a generative issue in creating virtual registers, where we use (cmp xg x) to decide which label to jump to. Originally, we do this in the form of

Cmpg xg g
Jz lbxyz
Jmp lbyxz

which is the incorrect implementation; this should be jnz, as if the comparison leads to a non-zero value, the values are not equal (interpret this as false.) We had to change this in anf->ir-virtual and ir-vritual->x86.

Additionally, we noticed that “not” was not implemented in  anf->ir-virtual which resulted in none of the file using not to function correctly. The fix might be as simple as adding not to the ops so it gets recognized in the anf->ir-virtual function and in the translation section you may have to write a special case to handle not. The way it is implemented in assembly is with a mask, then the expression, then with xor. For our implementation, you would pattern match “not” expressions to something like move mask to register, push register on stack, interpret the expression, push it on the stack, pop, then xor the both of them and have that as their match case. 

We also noticed that our compiler was passing true and false symbols (#t, #f) throughout the end of the code, appearing in our final .asm file. This is clearly false; x86 should be dealing with literals and registers, not in symbols. We decided that at some point, we needed to convert these symbols to their respective integer format, modifying ifarith-tiny->anf recursive helper functions (matching [#t (k 1)] and [#f (k 0])

    

[ High Level Reflection ] 

In roughly 100-500 words, write a summary of your findings in working
on this project: what did you learn, what did you find interesting,
what did you find challenging? As you progress in your career, it will
be increasingly important to have technical conversations about the
nuts and bolts of code, try to use this experience as a way to think
about how you would approach doing group code critique. What would you
do differently next time, what did you learn?


Working on project 5 as a group provided us with a comprehensive learning experience that helped deepen our understanding of computer architecture, as well as highlighting the importance of unit tests and debugging. One of the most interesting aspects of this project was observing a cross-connection of assembly ideas previously introduced from CIS341. This cross-connection demonstrated how high-level programming translates into lower-level machine operations, giving us an appreciation of how computers execute the code we write. Insights like these are crucial as they enable us to write more efficient and effective code in higher-level languages. 

Throughout the project, the critical role of unit testing became apparent. Without the code being broken up into neat sections, debugging would be significantly more difficult. We learned that methodical testing, especially for logical errors, is essential due to logical errors being harder to detect than syntax errors. Due to our testing, we were able to identify and correct errors in the “if” condition. 

The project was not without its challenges. Setting up the necessary tools, like NASM and linker proved to be difficult for two of our members using Linux. Additionally, we struggled with compatibility issues between Mac and Linux systems, which required us to modify our code to make sure it worked on Mac. Another challenge we faced was dealing with vague error messages such as “failed to find _start symbol” which were difficult to debug and find a solution for. Searching for solutions related to broad issues through documentation proved to be challenging, often involving some trial and error with tools like VirtualBox. Reflecting on the project, we have come to recognize the importance of flexibility and persistence in development. For the future, we plan to invest more time in setting up our development environments. By investing more time in this we can avoid issues related to troubleshooting environment-specific issues. Project 5 not only sharpened our technical skills, but also provided us with valuable lessons in debugging and collaboration.
