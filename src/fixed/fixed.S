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
    andi    t0, t0, 1
    srli    a0, a0, 1
    srli    a1, a1, 1
    add     a0, a0, a1
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

    # a7 = low_product
    # multi_p00 (a7) (a3, a5)
    add     t0, a3, zero
    add     t1, a5, zero
    li      a7, 0
    beqz    t1, .Lmul_done_p00

.Lmul_loop_p00:
    andi    t2, t1, 1
    beqz    t2, .Lmul_skip_p00
    add     a7, a7, t0

.Lmul_skip_p00:
    slli    t0, t0, 1
    srli    t1, t1, 1
    bnez    t1, .Lmul_loop_p00

.Lmul_done_p00:

    # t4 = middle
    # multi_p10 (t4) (a4, a5)
    add     t0, a4, zero
    add     t1, a5, zero
    li      t4, 0
    beqz    t1, .Lmul_done_p10

.Lmul_loop_p10:
    andi    t2, t1, 1
    beqz    t2, .Lmul_skip_p10
    add     t4, t4, t0

.Lmul_skip_p10:
    slli    t0, t0, 1
    srli    t1, t1, 1
    bnez    t1, .Lmul_loop_p10

.Lmul_done_p10:
    srli    t6, a7, 16
    add     t4, t4, t6

    # t5 = middle_low
    and     t5, t4, a2
    # multi_p01 (t6) (a3, a6)
    add     t0, a3, zero
    add     t1, a6, zero
    li      t6, 0
    beqz    t1, .Lmul_done_p01

.Lmul_loop_p01:
    andi    t2, t1, 1
    beqz    t2, .Lmul_skip_p01
    add     t6, t6, t0

.Lmul_skip_p01:
    slli    t0, t0, 1
    srli    t1, t1, 1
    bnez    t1, .Lmul_loop_p01

.Lmul_done_p01:
    add     t5, t5, t6

    # a2 = low
    and     a2, a7, a2
    slli    t6, t5, 16
    or      a2, a2, t6

    # t4 = middle_high
    srli    t4, t4, 16
    
    srli    t5, t5, 16

    # a3 = high
    # multi_p11 (a3) (a4, a6)
    add     t0, a4, zero
    add     t1, a6, zero
    li      a3, 0
    beqz    t1, .Lmul_done_p11

.Lmul_loop_p11:
    andi    t2, t1, 1
    beqz    t2, .Lmul_skip_p11
    add     a3, a3, t0

.Lmul_skip_p11:
    slli    t0, t0, 1
    srli    t1, t1, 1
    bnez    t1, .Lmul_loop_p11

.Lmul_done_p11:
    add     t4, t4, t5
    add     a3, a3, t4

    # Convert the unsigned product to the signed product bit pattern
    slt     t0, a0, zero
    sub     t0, zero, t0
    and     t0, t0, a1
    sub     a3, a3, t0

    slt     t0, a1, zero
    sub     t0, zero, t0
    and     t0, t0, a0
    sub     a3, a3, t0

    # s2 = old_low
    add     t0, a2, zero
    li      t1, 0x80000
    add     a2, a2, t1
    sltu    t0, a2, t0
    add     a3, a3, t0

    # s2 = result
    srli    a2, a2, 20
    slli    a3, a3, 12
    or      a0, a2, a3

    ret
    .size   q_mul_asm, .-q_mul_asm