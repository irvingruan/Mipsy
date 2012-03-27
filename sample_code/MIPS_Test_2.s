# code2: does some funny adds and substracts to two numbers.  
#        returns result in $v0
#        we expect $v0 = -16 (0xfffffff0)
#                  $v1 = 16

main:
	addi 	$a0, $0, 4
	addi	$a1, $0, -8
	jal	label
	addi	$v0, $a3, 0
	jal	exit
label:	addi	$sp, $sp, -12
	sw	$ra, 4($sp)
	sw	$fp, 8($sp)
	addi	$fp, $sp, 8
	add	$a3, $a0, $a1
	addi	$a3, $a3, -20
	sub	$a3, $a3, $a1
	lw	$ra, -4($fp)
	lw	$fp, 0($fp)
	addi	$sp, $sp, 12 
	jr	$ra
exit:	nop
	nop
	jr	$ra


