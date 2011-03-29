##############################################################
#   simulator.s 	
#								
#   Irving Ruan
#   irvingruan@gmail.com
#
#   A simple MIPS simulator written in MIPS, which is able to 
#	process and simulate 32 and 16-bit MIPS instructions.
##############################################################

		.data

# Initialize virtual registers and stack memory

registers:	.space 128		# 32 words for registers
static:		.space 2048		# 512 words.  This stores
					# the programs you run on your
					# virtual machine and
					# also includes stack area


str1:		.asciiz "The return value: "
str2:		.asciiz "The number of instructions executed: "
str3:		.asciiz "R-type: "
str4:		.asciiz "I-type: "
str5:		.asciiz "J-type: "
retn:		.asciiz "\n"
	
		.text
        	.globl main

main:		addi $sp, $sp, -32		
		sw $ra, 20($sp)
		sw $fp, 16($sp)
		addiu $fp, $sp, 28

		# this code reads in the input file--a list of integers
		# (one per line) representing a MIPS assembly language
		# program, hand-assembled.  It stops when it sees a 0, i.e., 
		# sll $0, $0, 0 or NOP)  The code is stored at the beginning 
		# of static segment allocated above, one integer per word 
		# (one instruction per word)
		
		la $t0, static		# $t0 = pointer to beginning of
					#    static space, where your
					#    code will be stored.
	
loop1:		li $v0, 5		# code for read_int
		syscall			# $v0 gets integer
		beq $v0, $0, EO_prog
	
		sw $v0, 0($t0)		# place instruction in code space
		addi $t0, $t0, 4	# increment to next code space
		j loop1

EO_prog:	
		sw $v0, 0($t0)		# place the NOP in the code space 
					# as well to signal the end of program

		la $a0, registers
		la $a1, static
		addi $a2, $a1, 2044	# stack pointer points to highest
					#    memory in the static memory area
		la $a3, static		# $a3 can be used as the pointer
					#    to your instructions, so it
					#    is initialized to point to the
					#    first one.
	
		jal sim_mips		# Call the MIPS simulator

		move $t0, $v0		

		la $a0, str3		# "R-type: "
		li $v0, 4
		syscall
		move $a0, $s2
		li $v0, 1
		syscall
		la $a0, retn
		li $v0, 4
		syscall

		la $a0, str4		# "I-type: "
		li $v0, 4
		syscall
		move $a0, $s3
		li $v0, 1
		syscall
		la $a0, retn
		li $v0, 4
		syscall

		la $a0, str5		# "J-type: "
		li $v0, 4
		syscall
		move $a0, $s4
		li $v0, 1
		syscall
		la $a0, retn
		li $v0, 4
		syscall


		la $a0, str1		# "The return value: "
		li $v0, 4
		syscall
		move $a0, $t0
		li $v0, 1
		syscall
		la $a0, retn
		li $v0, 4
		syscall

		la $a0, str2		# "The number of instructions executed: "
		li $v0, 4
		syscall
		move $a0, $v1
		li $v0, 1
		syscall
		la $a0, retn
		li $v0, 4
		syscall

		lw $ra, 20($sp)
		lw $fp, 16($sp)
		addi $sp, $sp, 32
		# jr $ra
		
		# Added this in so the program gracefully exits on the command line
		li $v0, 10
		syscall


sim_mips:	# Arguments passed in:
		#	$a0 = pointer to space for your registers (access
		#		0($a0) up to 124($a0)
		#	$a1 = pointer to lowest address in your static 
		#		memory area (2048 bytes available)
		#	$a2 = pointer to the top of the stack (also the
		#		highest memory in the static memory area)
		#	$a3 = pointer to the first instruction in the program 
		# 		(actually contains same value as $a1, since
		#		code is loaded into lowest memory addresses).
		#               Recall that you do not need to load the
		#               instructions in! The shell takes care of this
		#               for you.
		#
		# Register allocation:
		#	You should probably assign certain SPIM registers
		#	to act as your simulated machine's PC, etc.
		#	For clarity's sake, note the assignments here.
		#          
		#	$s0 = instruction loaded from file
		#	$s1 = opcode
		#	$t2 = R[rs]
		#	$t3 = R[rt]
		#	$t4 = R[rd]
		#	$t5 = Immediate
		#	$t6 = Function code
		#	$t7 = Shamt
		#	$t8 = Temp register used sometimes
		#	$t9 = Temp address offset of $a0
		#           $a3 = Virtual PC

		addi $v0, $0, 0 	# Initiliaze return value
		addi $v1, $0, 0		# Initiliaze total instruction counter
		addi $s2, $0, 0		# Initialize s2 = R-type counter
		addi $s3, $0, 0		# Initiliaze s3 = I-type counter
		addi $s4, $0, 0		# Initiliaze s4 = J-type counter
		sub $s5, $a2, $a1	# Get the a2/a1 offset
		sw $s5, 116($a0)
		sw $s5, 120($a0)
		

#
# Main simulation loop to process each instruction
#
SimLoop:
		
		lw $s0, 0($a3)		# Load first instruction to $s0
		beq $s0, $0, EndSim    # If it's a zero, then we reached end of instructions file		

		# Go to DECODE to perform operation
		
##########################################################
# 									           #
#       	                                              DECODE                                                       #
#				$s0 = Instruction			           #
#				$s1 = Opcode				           #
##########################################################
Decode:

		srl $s1, $s0, 26	# Shift right to get opcode from instruction
		addi $t1, $0, 3
		
		beq $s1, $0, RtypeDecode 	# If opcode = Rtype, go to Rtype decode
		beq $s1, $t1, JtypeDecode	# If opcode = Jtype, go to Jtype decode
		bne $s1, $0, ItypeDecode	# If opcode != 3, go to Itype decode 
##########################################################
#           			 R-TYPE Decode                                                 #
#                                                   					           #
# 				 $s1 = Opcode				           #
#				 $t2 = R[rs]				           #
#				 $t3 = R[rt] 				           #
#				 $t4 = R[rd] 				           #
#				 $t5 = Immediate			           #
#				 $t6 = Function code			           #
#				 $t7 = Shamt			           	           #
#				 $t9 = Temp address of registers	           #
##########################################################
RtypeDecode:

		# Check what R-type Instruction it is by function code
		sll $t6, $s0, 26		
		srl $t6, $t6, 26		# t6 = Function code
		
		addi $t1, $0, 0		# t1 = 0 (sll Function code)			
		beq $t6, $t1, SLL	# Go to sll Decode

		addi $t1, $0, 32	# t1 = 32 (add Function code)
		beq $t6, $t1, Add	# Go to add Decode

		addi $t1, $0, 42	# t1 = 42 (slt Function code)
		beq $t6, $t1, SLT	# Go to slt Decode

		addi $t1, $0, 8		# t1 = 8 (jr Function code)
		beq $t6, $t1, JR	# Go to jr Decode

		addi $t1, $0, 34	# t1 = 34 (sub Function code)
		beq $t6, $t1, Sub	# Go to sub Decode

		addi $t1, $0, 36	# t1 = 36 (and Function code)
		beq $t6, $t1, And	# Go to and Decode

		addi $t1, $0, 24	# t1 = 24 (mul Function code)
		beq $t6, $t1, Mul	# Go to mul Decode

		addi $t1, $0, 23	#t1 = 23 (mac Function code)
		beq $t6, $t1, Mac	# Go to mac Decode

		j DecodeDone

###################        Mac DECODE        #####################
Mac:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = n($a0)
		lw $t3, 0($t9)		# t3 = R[rt]

		# Get R[rd] register value
		sll $t4, $s0, 16
		srl $t4, $t4, 27
		sll $t4, $t4, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t4	# t9 = R[rd]($a0)
		lw $t4, 0($t9)	
	
		mult $t2, $t3		# t2 = R[rs] * R[rt]
		mflo $t8
		add $t4, $t4, $t8	# R[rd] = R[rd] + R[rs] * R[rt]

		sw $t4, 0($t9)		

		j RtypeDone

###################        Mul DECODE        #####################
Mul:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = n($a0)
		lw $t3, 0($t9)		# t3 = R[rt]

		# Get R[rd] register value
		sll $t4, $s0, 16
		srl $t4, $t4, 27
		sll $t4, $t4, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t4	# t9 = R[rd]($a0)

		mult $t2, $t3		# t2 = R[rs] * R[rt]
		mflo $t4
		sw $t4, 0($t9)		

		j RtypeDone


###################        And DECODE        #####################
And:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = n($a0)
		lw $t3, 0($t9)		# t3 = R[rt]

		# Get R[rd] register value
		sll $t4, $s0, 16
		srl $t4, $t4, 27
		sll $t4, $t4, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t4	# t9 = R[rd]($a0)

		and $t4, $t2, $t3	# R[rd] = R[rs] & R[rt]
		sw $t4, 0($t9)		

		j RtypeDone

###################        Sub DECODE        #####################
Sub:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = n($a0)
		lw $t3, 0($t9)		# t3 = R[rt]

		# Get R[rd] register value
		sll $t4, $s0, 16
		srl $t4, $t4, 27
		sll $t4, $t4, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t4	# t9 = R[rd]($a0)

		sub $t4, $t2, $t3	# R[rd] = R[rs] - R[rt]
		sw $t4, 0($t9)		

		j RtypeDone

###################        JR DECODE        #####################
JR:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = virtual $ra

		#add $a3, $t2, $a1
		addi $a3, $t2, 0
		
		j JrDone

JrDone:
		addi $s2, $s2, 1
		addi $v1, $v1, 1
		j SimLoop


###################        SLT DECODE        ######################
SLT:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = n($a0)
		lw $t3, 0($t9)		# t3 = R[rt]

		# Get R[rd] register value
		sll $t4, $s0, 16
		srl $t4, $t4, 27
		sll $t4, $t4, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t4	# t9 = R[rd]($a0)

		# Perform slt operation
		slt $t4, $t2, $t3	# R[rd] = (R[rs] < R[rd]) ? 1 : 0
		sw $t4, 0($t9)

		j RtypeDone
		

###################        Add DECODE        #####################
Add:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = n($a0)
		lw $t3, 0($t9)		# t3 = R[rt]


		# Get R[rd] register value
		sll $t4, $s0, 16
		srl $t4, $t4, 27
		sll $t4, $t4, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t4	# t9 = R[rd]($a0)

		add $t4, $t2, $t3	# R[rd] = R[rs] + R[rt]
		sw $t4, 0($t9)		

		j RtypeDone


###################        SLL DECODE        ######################
SLL:
		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = R[rt]($a0)
		lw $t3, 0($t9)		# t3 = R[rt]

		# Get shamt register value
		sll $t7, $s0, 21
		srl $t7, $t7, 27		# t7 = Shamt

		# Get R[rd] register value
		sll $t4, $s0, 16
		srl $t4, $t4, 27
		sll $t4, $t4, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t4	# t9 = R[rd]($a0)

		# Perform sll operation
		sllv $t4, $t3, $t7	# R[rd] = R[rt] << shamt
		sw $t4, 0($t9)		# t4($a0) = R[rd] 					
				
		j RtypeDone


RtypeDone:
		addi $s2, $s2, 1	# Increment R-type counter		
		j DecodeDone		# Go to done after parsing
				

##########################################################
#           			 J-TYPE Decode                                                  #
#                                                   					           #
# 				 $s1 = Opcode				           #
#				 $t5 = Immediate			           #
#				 $t9 = Temp address of registers	           #
##########################################################
JtypeDecode:
		
		# Check what J-type Instruction it is by opcode
		addi $t1, $0, 3		# t1 = 3 (Jal opcode)
		beq $s1, $t1, Jal	# Go to jal Decode
		
		addi $t1, $0, 2
		beq $s1, $t1, Jump
		
		j DecodeDone

###################        Jal DECODE        #####################
Jal:
		add $t8, $a3, 4	# Obtain PC + 4
		#sub $t8, $a3, $a1
		sw $t8, 124($a0)	# R[31] = PC + 4

		# Get immediate value (jump address)
		sll $t5, $s0, 6
		srl $t5, $t5, 4		# t5= Immediate value		
		
		add $a3, $a1, $t5

		j JtypeDone

Jump:
		# Get immediate value (jump address)
		sll $t5, $s0, 6
		srl $t5, $t5, 4		# t5= Immediate value		
		
		add $a3, $a1, $t5

		j JtypeDone


JtypeDone:
		addi $s4, $s4, 1	# Increment J-type counter
		addi $v1, $v1, 1
		j SimLoop	# Go to done after parsing


##########################################################
#           			 I-TYPE Decode                                                  #
#                                                   					           #
# 				 $s1 = Opcode				           #
#				 $t2 = R[rs]				           #
#				 $t3 = R[rt] 				           #
#				 $t5 = Immediate			           #
#				 $t9 = Temp address of registers	           #
##########################################################
ItypeDecode:
		
		# Check what I-type Instruction it is by opcode
		addi $t1, $0, 8		# t1 = 8 (Addi Opcode)			
		beq $s1, $t1, Addi	# Go to addi Decode

		addi $t1, $0, 43	# t1 = 43 (Sw Opcode)
		beq $s1, $t1, Sw	# Go to sw Decode

		addi $t1, $0, 35	# t1 = 35 (Lw Opcode)
		beq $s1, $t1, Lw	# Go to lw Decode

		addi $t1, $0, 4		# t1 = 4 (Beq Opcode)
		beq $s1, $t1, Beq	# Go to beq Decode

		addi $t1, $0, 5		# t1 = 5 (Bne Opcode)
		beq $s1, $t1, Bne	# Go to bne Decode

		addi $t1, $0, 10	# t1 = 10 (Slti Opcode)
		beq $s1, $t1, SLTi	# Go to slti Decode

		addi $t1, $0, 12	# t1 = 12 (Andi Opcode)
		beq $s1, $t1, Andi	# Go to andi Decode

		addi $t1, $0, 15	# t1 = 15 (Lui Opcode)
		beq $s1, $t1, Lui	# Go to lui Decode

		j DecodeDone

###################        Lui DECODE        #####################
Lui:
		
		# Get immediate value
		sll $t5, $s0, 16

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = n($a0)

		sw $t5, 0($t9)		# Load upper 16-bits into n($a0) [virtual reg.]

		j ItypeDone	

###################        Andi DECODE        #####################
Andi:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get immediate value
		sll $t5, $s0, 16
		sra $t5, $t5, 16	# t5= Immediate value

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = n($a0)

		and $t3, $t2, $t5	# R[rd] = R[rs] & ZeroExtImm.
		sw $t3, 0($t9)		

		j ItypeDone

###################        SLTi DECODE        ######################
SLTi:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]
		
		# Get immediate value
		sll $t5, $s0, 16
		sra $t5, $t5, 16	# t5= Immediate value

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = R[rt]($a0

		# Perform slt operation
		slt $t3, $t2, $t5	# R[rd] = (R[rs] < SignExtImm) ? 1 : 0
		sw $t3, 0($t9)

		j ItypeDone

###################        Bne DECODE        #####################
Bne:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = R[rt]($a0)
		lw $t3, 0($t9)		# t3 = R[rt]
	
		# Get immediate value
		sll $t5, $s0, 16
		sra $t5, $t5, 16	# t5= Immediate value
		sll $t5, $t5, 2		# Word align Imm. for virtual PC ($a3)

		bne $t2, $t3, BneCmp # If R[rs] != R[rt], goto BneCmp
		j ItypeDone
		
BneCmp:
		add $a3, $a3, $t5
		j ItypeDone


###################        Beq DECODE        #####################
Beq:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = R[rt]($a0)
		lw $t3, 0($t9)		# t3 = R[rt]
	
		# Get immediate value
		sll $t5, $s0, 16
		sra $t5, $t5, 16	# t5= Immediate value
		sll $t5, $t5, 2		# Word align Imm. for virtual PC ($a3)

		beq $t2, $t3, BeqCmp # If R[rs] == R[rt], goto BeqCmp
		j ItypeDone
		
BeqCmp:
		add $a3, $a3, $t5
		j ItypeDone
		

###################        Lw DECODE        #####################
Lw:
		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t8, $a0, $t3	# t8 = R[rt]($a0)
		#### lw $t3, 0($t9)		# t3 = R[rt]

		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)

		# Get immediate value
		sll $t5, $s0, 16
		sra $t5, $t5, 16	# t5= Immediate value

		# Get the memory offset in heap
		add $t9, $a1, $t2	# Static = Static + R[rs]
		add $t9, $t9, $t5	# Static = Static + R[rs] + Immd.

		# Load the word
		lw $t9, 0($t9)		# t9 = R[rs] + SignExtImm.
		sw $t9, 0($t8)		# i.e. lw $t8, 0($t9)

		j ItypeDone


###################        Sw DECODE        #####################
Sw:
		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = R[rt]($a0)
		lw $t3, 0($t9)		# t3 = R[rt]

		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)

		# Get immediate value
		sll $t5, $s0, 16
		sra $t5, $t5, 16	# t5= Immediate value

		# Get the memory offset in heap
		add $t9, $a1, $t2	# Static = Static + $t9
		add $t9, $t9, $t5	# Static = Static + $t9 + SignImmd.

		# Store it to heap
		sw $t3, 0($t9)		# M[R[rs] + SignExtImm] = R[rt]

		j ItypeDone
		

###################        Addi DECODE        #####################
Addi:
		# Get R[rs] register value
		sll $t2, $s0, 6
		srl $t2, $t2, 27
		sll $t2, $t2, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t2	# t9 = n($a0)
		lw $t2, 0($t9)		# t2 = R[rs]

		# Get immediate value
		sll $t5, $s0, 16
		sra $t5, $t5, 16		# t5= Immediate value
		
		# Get R[rt] register value
		sll $t3, $s0, 11
		srl $t3, $t3, 27
		sll $t3, $t3, 2		# Multiply by 4 for byte offset
		add $t9, $a0, $t3	# t9 = R[rt]($a0)
		
		# Perform addi operation
		add $t3, $t2, $t5	# R[rt] = R[rs] + Imm.
		sw $t3, 0($t9)		# t3($a0) = R[rt] 

		j ItypeDone
	
ItypeDone:
		
		addi $s3, $s3, 1	# Increment I-type count
		j DecodeDone		# Go to done after parsing

##########################################################
#           		                 DECODE DONE                                               #
##########################################################
DecodeDone:
		
		addi $v1, $v1, 1	# Increment total instruction counter
		addi $a3, $a3, 4	# Increment virtual program counter
		j SimLoop		# Go to next instruction for decoding

EndSim:
		lw $v0, 8($a0)		# Load real $v0 from virtual $v0
		jr $ra

		

		

