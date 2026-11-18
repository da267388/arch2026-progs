# op1, op2, op3 and q_mul: hand-written RV32I.
#
# uint32_t op1_asm(uint32_t a, uint32_t b, int *n)   a0, a1, a2 -> a0
# uint32_t op2_asm(uint32_t a, uint32_t b)           a0, a1 -> a0
# uint32_t op3_asm(uint32_t a, uint32_t b)           a0, a1 -> a0
# int32_t  q_mul_asm(int32_t a, int32_t b)           a0, a1 -> a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. q_mul forms a 64-bit product in a register pair. Tests:
# tests/tfixed.c.

    .text

    .globl  op1_asm
    .type   op1_asm, @function
    .align  2
op1_asm:
    # t0 = passes; a2 = pointer
    li      t0, 0

    beqz    a1, loop_end

loop:
    # t1 = carry
    and     t1, a0, a1
    xor     a0, a0, a1
    slli    a1, t1, 1
    addi    t0, t0, 1
    bnez    a1, loop

loop_end:
    sw      t0, 0(a2)
    ret
    .size   op1_asm, .-op1_asm

    .globl  op2_asm
    .type   op2_asm, @function
    .align  2
op2_asm:
    sub     a0, a0, a1
    ret
    .size   op2_asm, .-op2_asm

    .globl  op3_asm
    .type   op3_asm, @function
    .align  2
op3_asm:
    and     t0, a0, a1
    xor     a0, a0, a1
    srli    a0, a0, 1
    add     a0, a0, t0
    ret
    .size   op3_asm, .-op3_asm

    .globl  q_mul_asm
    .type   q_mul_asm, @function
    .align  2
q_mul_asm:
    # a2 = 0xFFFF
    li      a2, 0xFFFF
    # a3 = a_low
    and     a3, a0, a2
    # a4 = a_high
    srli    a4, a0, 16
    # a5 = b_low
    and     a5, a1, a2
    # a6 = b_high
    srli    a6, a1, 16

    # a7 = p00; t4 = p10
    # multiply_pair_u16 (a3, a4, a5) (a7, t4)
    li      a7, 0
    li      t4, 0
    beqz    a5, mul_done_b_low
    add     t0, a3, zero
    add     t1, a4, zero

mul_loop_b_low_1:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_1
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_1:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_2:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_2
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_2:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_3:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_3
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_3:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_4:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_4
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_4:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_5:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_5
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_5:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_6:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_6
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_6:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_7:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_7
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_7:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_8:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_8
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_8:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_9:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_9
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_9:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_10:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_10
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_10:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_11:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_11
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_11:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_12:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_12
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_12:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_13:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_13
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_13:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_14:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_14
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_14:
    slli    t0, t0, 1
    slli    t1, t1, 1

mul_loop_b_low_15:
    andi    t2, a5, 1
    srli    a5, a5, 1
    beqz    t2, mul_skip_b_low_15
    add     a7, a7, t0
    add     t4, t4, t1
    beqz    a5, mul_done_b_low
mul_skip_b_low_15:
    slli    t0, t0, 1
    slli    t1, t1, 1

    # cause not branch to done 
    add     a7, a7, t0
    add     t4, t4, t1

mul_done_b_low:

    # t4 = middle
    srli    a5, a7, 16
    add     t4, t4, a5

    # t6 = p10; a5 = p11
    # multiply_pair_u16 (a3, a4, a6) (t6, a5)
    li      t6, 0
    li      a5, 0
    beqz    a6, mul_done_b_high

mul_loop_b_high_1:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_1
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_1:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_2:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_2
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_2:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_3:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_3
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_3:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_4:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_4
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_4:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_5:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_5
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_5:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_6:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_6
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_6:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_7:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_7
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_7:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_8:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_8
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_8:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_9:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_9
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_9:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_10:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_10
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_10:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_11:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_11
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_11:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_12:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_12
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_12:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_13:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_13
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_13:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_14:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_14
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_14:
    slli    a3, a3, 1
    slli    a4, a4, 1

mul_loop_b_high_15:
    andi    t2, a6, 1
    srli    a6, a6, 1
    beqz    t2, mul_skip_b_high_15
    add     t6, t6, a3
    add     a5, a5, a4
    beqz    a6, mul_done_b_high
mul_skip_b_high_15:
    slli    a3, a3, 1
    slli    a4, a4, 1

    # cause not branch to done 
    add     t6, t6, a3
    add     a5, a5, a4

mul_done_b_high:

    # t5 = middle_low
    and     t5, t4, a2
    add     t5, t5, t6

    # a2 = low
    slli    a3, t5, 16
    and     a2, a7, a2
    or      a2, a2, a3

    # a5 = high
    srli    a3, t4, 16
    add     a5, a5, a3
    srli    a3, t5, 16
    add     a5, a5, a3


    # Convert the unsigned product to the signed product bit pattern
    srai    t0, a0, 31
    and     t0, t0, a1
    sub     a5, a5, t0

    srai    t0, a1, 31
    and     t0, t0, a0
    sub     a5, a5, t0

    # different from c, due to the data types and Cppcheck don't accept comparison base on overflow
    # t0 = old_low
    add     t0, a2, zero
    li      t1, 0x80000
    add     a2, a2, t1
    sltu    t0, a2, t0
    add     a5, a5, t0

    # s2 = result
    srli    a2, a2, 20
    slli    a5, a5, 12
    or      a0, a2, a5

    ret
    .size   q_mul_asm, .-q_mul_asm
