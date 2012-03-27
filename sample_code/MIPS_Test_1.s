# code1: counter from (2^16 + 64) to (2^16 + 128).  
#        returns the counter in $v0
#        we expect $v0 = 65664 (0x00010080)
#                  $v1 = 268
#

main:	addi	$t0, $0, 1
	sll	$t0, $t0, 16
	addi	$t1, $0, 64
	add	$t2, $t1, $t0
	sw	$t2, 0($t1)
	addi	$t2, $0, 128
	add	$t2, $t0, $t2
	sw	$t2, 4($t1)
	lw	$t3, 0($t1)
loop:	slt	$t4, $t3, $t2
	beq	$t4, $0, end
	addi	$t3, $t3, 1
	beq	$0, $0, loop
end:	addi	$v0, $t3, 0
	nop
	nop
	jr	$ra



