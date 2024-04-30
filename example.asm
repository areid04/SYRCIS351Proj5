;;  Set up to work on mac, change _main to main and _printf to printf for Linux
section .data
    int_format db "%ld",10,0 ; Format string for printing a long integer, followed by newline and null terminator
    global _main    
    extern _printf

section .text

_main:
    push rbp
    mov rbp, rsp
    sub rsp, 16 ; Reserve space for two 64-bit integers on the stack

    ; Store integers 5 and 8 into reserved space
    mov qword [rbp-8], 5
    mov qword [rbp-16], 8

    ; Load the first integer, add the second integer to it
    mov rax, [rbp-8]
    add rax, [rbp-16]

    ; Set up for calling printf
    mov rsi, rax ; Move the sum into rsi, printf's second argument for the integer value
    lea rdi, [rel int_format] ; Load address of format string into rdi
    mov rax, 0 ; Zero rax to indicate no floating-point arguments are passed
    call _printf ; Call printf

    ; Clean up and return
    leave
    ret
