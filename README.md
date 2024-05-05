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
