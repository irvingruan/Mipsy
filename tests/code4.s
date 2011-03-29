jal start
add $v0, $s4, $0
j end
add $t5, $t5, $t5 # should never get here
start: addi $t0, $0, 3
sll $t1, $t0, 4
addi $t3, $0, 7
sub $t4, $t1, $t3
addi $t6, $0, 5
mul $t5, $t4, $t6
slti $s0, $t5, 205
slt $s1, $0, $t5
# (NOT $s0) AND $s1
# NOT X = 0-X+1 if x = 0 or 1
sub $s2, $0, $s0
addi $s2, $s2, 1
and $s2, $s2, $s1
add $t5, $t5, $s2
add $s4, $0, $t5
lui $s0, 23405
addi $s0, $s0, 14043
lui $s1, 69
addi $s1, $s1, 5375
and $s2, $s0, $s1
andi $s3, $t5, 186
add $s4, $s2, $s3
jr $ra
add $t5, $t5, $t5 # should never get here
end:

