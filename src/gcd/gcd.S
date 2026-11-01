# gcd_u32_asm: binary GCD, hand-written RV32I.
#
# uint32_t gcd_u32_asm(uint32_t a, uint32_t b)   a in a0, b in a1, result in a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. Tests: tests/tgcd.c.

    .text

    .globl  gcd_u32_asm
    .type   gcd_u32_asm, @function
    .align  2
gcd_u32_asm:

    beqz    a0, return_b
    beqz    a1, return_a

    # t0 = shift
    li      t0, 0

    # mask
    lui     t1, 0x10
    addi    t1, t1, -1 # t1 = 0xFFFF

    or      t2, a0, a1 # t2 = a | b
    and     t3, t2, t1
    bnez    t3, ctz_a_or_b_1
    addi    t0, t0, 16
    srli    t2, t2, 16
ctz_a_or_b_1:
    andi    t3, t2, 0xFF
    bnez    t3, ctz_a_or_b_2
    addi    t0, t0, 8
    srli    t2, t2, 8
ctz_a_or_b_2:
    andi    t3, t2, 0xF
    bnez    t3, ctz_a_or_b_3
    addi    t0, t0, 4
    srli    t2, t2, 4
ctz_a_or_b_3:
    andi    t3, t2, 0x3
    bnez    t3, ctz_a_or_b_4
    addi    t0, t0, 2
    srli    t2, t2, 2
ctz_a_or_b_4:
    andi    t3, t2, 0x1
    bnez    t3, ctz_a_or_b_end
    addi    t0, t0, 1

ctz_a_or_b_end:

    and     t3, a0, t1
    bnez    t3, ctz_a_1
    srli    a0, a0, 16
ctz_a_1:
    andi    t3, a0, 0xFF
    bnez    t3, ctz_a_2
    srli    a0, a0, 8
ctz_a_2:
    andi    t3, a0, 0xF
    bnez    t3, ctz_a_3
    srli    a0, a0, 4
ctz_a_3:
    andi    t3, a0, 0x3
    bnez    t3, ctz_a_4
    srli    a0, a0, 2
ctz_a_4:
    andi    t3, a0, 0x1
    bnez    t3, loop
    srli    a0, a0, 1

loop:
    and     t3, a1, t1
    bnez    t3, ctz_b_1
    srli    a1, a1, 16
ctz_b_1:
    andi    t3, a1, 0xFF
    bnez    t3, ctz_b_2
    srli    a1, a1, 8
ctz_b_2:
    andi    t3, a1, 0xF
    bnez    t3, ctz_b_3
    srli    a1, a1, 4
ctz_b_3:
    andi    t3, a1, 0x3
    bnez    t3, ctz_b_4
    srli    a1, a1, 2
ctz_b_4:
    andi    t3, a1, 0x1
    bnez    t3, ctz_b_end
    srli    a1, a1, 1

ctz_b_end:
    xor     t2, a0, a1
    sltu    t3, a1, a0
    sub     t3, zero, t3
    and     t2, t2, t3 # t2 = mask
    xor     t3, a1, t2 # t3 = temp
    xor     a0, a0, t2
    sub     a1, t3, a0

    bnez    a1, loop

    sll     a0, a0, t0

    ret

return_a:
    ret
return_b:
    add     a0, a1, zero
    ret
    .size   gcd_u32_asm, .-gcd_u32_asm
