.globl main 
.equ STDOUT, 1
.equ STDIN, 0
.equ __NR_READ, 63
.equ __NR_WRITE, 64
.equ __NR_EXIT, 93

.text
main:

	# main() prolog
	addi sp, sp, -28
	li ra, 0xffffffff
	
	//stores canary above buffer (xxxx)
	//little endian causes the bits to flip, x in UTF-8 is 7x8
	li t0, 0x78787878
	sw t0, 20(sp)
	
	//stores ra above canary
	sw ra, 24(sp)

	# main() body
	la a0, prompt
	call puts

	mv a0, sp
	call gets

	mv a0, sp
	call puts

	# main() epilog
	lw ra, 20(sp)
	addi sp, sp, 24
	ret

.space 12288

sekret_fn:
	addi sp, sp, -4
	sw ra, 0(sp)
	la a0, sekret_data
	call puts
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

##############################################################
# Add your implementation of puts() and gets() below here
##############################################################

//stores input from stdin to memory
//argument a0 is pointer to place string into
gets:

//allocate stack memory for ra, a0; save said registers
addi sp, sp, -8
sw ra, 0(sp)
sw a0, 4(sp)

mv s0, a0 //s0 will be incrementing the address pointer

//addi sp, sp, -4
//sw ra, 0(sp)
gets_loop:
jal getchar

blt a0, x0, gets_error
li t0, 10
beq a0, t0, gets_done

sb a0, 0(s0)
addi s0, s0, 1
j gets_loop


//Epilog
gets_done:
//restore stack items and sp
lw ra, 0(sp)
lw a0, 4(sp)
addi sp, sp, 8

sub a0, s0, a0
ret

gets_error :

//restores stack items and sp
lw ra, 0(sp)
lw a0, 4(sp)
addi sp, sp, 8

//return
ret

//argument a0 is pointer to string
//returns 0 or -1
puts:

//allocates stack memory, saves ra
addi sp, sp, -4
sw ra, 0(sp)

mv s0, a0 //use s0 to increment the address ptr
puts_loop :
lb a0, 0(s0)
beq a0, x0, puts_exit

jal putchar

//increments s0
addi s0, s0, 1

j puts_loop ##

//Error branch

//restore stack items (ra), stack pointer, return
li a0, -1
lw ra, 0(sp)
addi sp, sp, 4
ret
puts_exit :

//puts a newline at the end
li a0, 10
jal putchar
li a0, 0

//restore stack items (ra), restore stack pointer, return
li a0, -1
lw ra, 0(sp)
addi sp, sp, 4
ret

getchar :
//adjust sp for 1 item
addi sp, sp, -1

li a0, STDIN
mv a1, sp
li a2, 1
li a7, __NR_READ
ecall

lbu a0, 0(sp) ##
addi sp, sp, 1
ret


//takes a0 as char to be put in stdout
//returns same value
putchar:
//prologue
//adjust sp for 1 item
addi sp, sp, -1
sb a0, 0(sp)

//System call to write the character to STDOUT
li a0, STDOUT
mv a1, sp
li a2, 1
li a7, __NR_WRITE
ecall

//Epilogue
lb a0, 0(sp)
addi sp, sp, 1
ret



.data
prompt:   .ascii  "Enter a message: "
prompt_end:

.word 0
sekret_data:
.word 0x73564753, 0x67384762, 0x79393256, 0x3D514762, 0x0000000A
