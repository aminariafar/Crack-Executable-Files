    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
    
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
      

    sys_mkdir       equ 83
    sys_makenewdir  equ 0q777


    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
    
     
    sys_exit     equ     60
    
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
	PROT_NONE	  equ   0x0
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
    
    ;access mode
    O_DIRECTORY equ     0q0200000
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000


    BEG_FILE_POS    equ     0
    CURR_POS        equ     1
    END_FILE_POS    equ     2
    
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20



section .data
  A: dq 0
  filename: db 'part1.txt', 0
  string: resb 150000
  message_len equ $ - string ; Length of the message
  fd: dd 1

section .text
	global _start
;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
OneSpace:
   push   rax
   mov    rax, Space
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:	

   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout 
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10 
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax 
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax 

wAgain:
   cmp    rax, 9	
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx 
   cmp    bl, 0
   je     sEnd
   neg    rax 
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret

;-------------------------------------------
printString:
   push    rax
   push    rcx
   push    rsi
   push    rdx
   push    rdi

   mov     rdi, rsi
   call    GetStrlen
   mov     rax, sys_write  
   mov     rdi, stdout
   syscall 
   
   pop     rdi
   pop     rdx
   pop     rsi
   pop     rcx
   pop     rax
   ret
;-------------------------------------------
; rdi : zero terminated string start 
GetStrlen:
   push    rbx
   push    rcx
   push    rax  

   xor     rcx, rcx
   not     rcx
   xor     rax, rax
   cld
         repne   scasb
   not     rcx
   lea     rdx, [rcx -1]  ; length in rdx

   pop     rax
   pop     rcx
   pop     rbx
   ret
;-------------------------------------------

make_string:
   xor rcx, rcx ; index for string
   xor rbx, rbx ; counter for no. of pattern repetition

   repeat_pattern:
      cmp rbx, 500
      je repeat_out

      xor rdx, rdx ; counter for no. of "cs" repetition
      add_cs:
         cmp rdx, 8
         je cs_out

         mov byte [string + rcx], 0x63
         inc rcx
         mov byte [string + rcx], 0x73
         inc rcx

         inc rdx
         jmp add_cs
      
      cs_out:
         xor r8, r8 ; counter for rest of pattern
         add_rest:
            cmp r8, 283
            je rest_out

            mov byte [string + rcx], 0x61 ; add 'a' as filler
            inc rcx
            inc r8
            jmp add_rest
         
         rest_out:
            mov byte [string + rcx], 10
            inc rcx
            inc rbx
            jmp repeat_pattern
   
   repeat_out:
      ret

_start:
   call make_string

   ; Open the file (sys_open)
   mov eax, 5          ; syscall number for sys_open
   mov ebx, filename   ; filename
   mov ecx, 2          ; flags: O_RDWR (2)
   mov edx, 0666       ; mode: rw-rw-rw-
   int 0x80            ; call kernel
   mov [fd], eax       ; store the file descriptor

   ; Write to the file (sys_write)
   mov eax, 4          ; syscall number for sys_write
   mov ebx, [fd]       ; file descriptor
   mov ecx, string    ; message to write
   mov edx, message_len ; message length
   int 0x80            ; call kernel

   ; Close the file (sys_close)
   mov eax, 6          ; syscall number for sys_close
   mov ebx, [fd]       ; file descriptor
   int 0x80            ; call kernel