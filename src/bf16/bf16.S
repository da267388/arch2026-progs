# BFloat16 routines: hand-written RV32I.
#
# uint16_t bf16_from_f32_asm(uint32_t f32bits)   a0 -> a0
# uint16_t bf16_mul_asm(uint16_t a, uint16_t b)  a0, a1 -> a0
# uint16_t bf16_sqrt_asm(uint16_t a)             a0 -> a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. Tests: tests/tbf16.c.

    .text

    .globl  bf16_from_f32_asm
    .type   bf16_from_f32_asm, @function
    .align  2
bf16_from_f32_asm:
    srli     a1, a0, 16 # a1 = upper
    li    t0, 0x7F80 # t0 = 0x7F80
    and     t1, a1, t0
    bne     t1, t0, with_round
    add    a0, a1, zero
    ret
with_round:
    andi    a1, a1, 1
    add     a1, a1, t0
    addi     a1, a1, 0x7F # a1 = rounding
    
    add     a0, a0, a1
    srli    a0, a0, 16
    ret
    .size   bf16_from_f32_asm, .-bf16_from_f32_asm

    .globl  bf16_mul_asm
    .type   bf16_mul_asm, @function
    .align  2
bf16_mul_asm:
    xor     a2, a0, a1
    li      t0, 0x7FFF # t0 = 0x7FFF
    and     t1, a0, t0 # t1 = abs_a
    and     t2, a1, t0 # t2 = abs_b
    addi    t0, t0, 1  # t0 = 0x8000
    and     a2, a2, t0 # a2 = sign
    li      a3, 0x7F80 # a3 = 0x7F80
    
    bgeu    t1, a3, return_a_nan_or_inf
    
    bgeu    t2, a3, return_b_nan_or_inf

    beqz    t1, return_sign
    beqz    t2, return_sign

    srli    t3, t1, 7 # t3 = exp_a
    srli    t4, t2, 7 # t4 = exp_b
    
    andi    t1, t1, 0x7F
    # t1 = sig_a = normalize_significand

    bnez    t3, normal_a

    # subnormal
    li      t3, 1 # exp_a = 1
    li      a4, 16 # a4 = 16
    bgeu    t1, a4, check_64_a
    slli    t1, t1, 4
    addi    t3, t3, -4
check_64_a:
    slli    a4, a4, 2
    bgeu    t1, a4, check_128_a
    slli    t1, t1, 2
    addi    t3, t3, -2
check_128_a:
    slli    a4, a4, 1
    bgeu    t1, a4, done_a
    slli    t1, t1, 1
    addi    t3, t3, -1
    j       done_a

normal_a:
    ori     t1, t1, 0x80 # t1 = frac + 128

done_a:

    andi    t2, t2, 0x7F
    # t2 = sig_b = normalize_significand

    bnez    t4, normal_b

    # subnormal
    li      t4, 1 # exp_b = 1
    li      a4, 16 # a4 = 16
    bgeu    t2, a4, check_64_b
    slli    t2, t2, 4
    addi    t4, t4, -4
check_64_b:
    slli    a4, a4, 2
    bgeu    t2, a4, check_128_b
    slli    t2, t2, 2
    addi    t4, t4, -2
check_128_b:
    slli    a4, a4, 1
    bgeu    t2, a4, done_b
    slli    t2, t2, 1
    addi    t4, t4, -1
    j       done_b

normal_b:
    ori     t2, t2, 0x80 # t2 = frac + 128

done_b:

    # product = multiply_significands(sig_a, sig_b)
    slli    t5, t1, 7 # t5 = product
    andi    t2, t2, 0x7F
    # bit 0
    beqz    t2, mult_exit
    andi    a4, t2, 1
    beqz    a4, mult_bit1
    add     t5, t5, t1
mult_bit1:
    srli    t2, t2, 1
    beqz    t2, mult_exit
    slli    t1, t1, 1
    andi    a4, t2, 1
    beqz    a4, mult_bit2
    add     t5, t5, t1
    
mult_bit2:
    srli    t2, t2, 1
    beqz    t2, mult_exit
    slli    t1, t1, 1
    andi    a4, t2, 1
    beqz    a4, mult_bit3
    add     t5, t5, t1

mult_bit3:
    srli    t2, t2, 1
    beqz    t2, mult_exit
    slli    t1, t1, 1
    andi    a4, t2, 1
    beqz    a4, mult_bit4
    add     t5, t5, t1

mult_bit4:
    srli    t2, t2, 1
    beqz    t2, mult_exit
    slli    t1, t1, 1
    andi    a4, t2, 1
    beqz    a4, mult_bit5
    add     t5, t5, t1
    
mult_bit5:
    srli    t2, t2, 1
    beqz    t2, mult_exit
    slli    t1, t1, 1
    andi    a4, t2, 1
    beqz    a4, mult_bit6
    add     t5, t5, t1

mult_bit6:
    slli    t1, t1, 1
    andi    a4, t2, 0x02
    beqz    a4, mult_exit
    add     t5, t5, t1

mult_exit:
    # t3 = exponent
    add     t3, t3, t4
    addi    t3, t3, -127

    sltu    a4, t5, t0
    xori    a4, a4, 1
    srl     t5, t5, a4
    add     t3, t3, a4

    li      a4, 255
    bge     t3, a4, mult_return_inf

    li      a4, -6
    blt     t3, a4, return_sign

    # a1 = fraction
    srli    a1, t5, 7
    andi    a1, a1, 0x7F

    bge     zero, t3, return_subnormal

    slli    t3, t3, 7
    or      a0, a2, t3
    or      a0, a0, a1
    ret

return_subnormal:
    xori    t3, t3, -1
    addi    a0, t3, 2
    srl     a0, a1, a0
    or      a0, a0, a2
    ret

return_a_nan_or_inf:
    beq     t1, a3, is_inf_a
    # return a
    ret
is_inf_a:
    beqz    t2, mult_return_nan
    or      a0, a2, a3
    ret

return_b_nan_or_inf:
    beq     t2, a3, is_inf_b
    # return b
    add     a0, a1, zero
    ret
is_inf_b:
    beqz    t1, mult_return_nan
    or      a0, a2, a3
    ret
mult_return_nan:
    li      a0, 0x7FC0
    ret
mult_return_inf:
    or      a0, a2, a3
    ret
return_sign:
    add     a0, a2, zero
    ret
    .size   bf16_mul_asm, .-bf16_mul_asm

    .globl  bf16_sqrt_asm
    .type   bf16_sqrt_asm, @function
    .align  2
bf16_sqrt_asm:
    li      t0, 0x7FFF # t0 = 0x7FFF
    li      t1, 0x7F80 # t1 = 0x7F80
    and     a1, a0, t0 # a1 = magnitude

    bltu    t1, a1, return_a
    beqz    a1, return_0
    addi    t0, t0, 1 # t0 = 0x8000
    and     a4, a0, t0
    bnez    a4, sqrt_return_nan
    beq     a1, t1, return_a # return_inf

    srli    a2, a1, 7 # a2 = exponent
    beqz    a2, return_0

    # a3 = m
    andi    a3, a1, 0x7F
    addi    a3, a3, 128

    andi    a4, a2, 1
    xori     a4, a4, 1
    sll     a3, a3, a4

    # t2 = root
    # t0 = n
    addi    t0, a3, 1
    slli    t0, t0, 7
    addi    t0, t0, -1
    # t2 = partial
    li      t2, 0x4000
    # t1 = remainder
    sub     t1, t0, t2

    # SQRT_STEP(1u << 12)
    # t0 = bit
    # t4 = trial
    li      t0, 0x1000
    add     t4, t2, t0
    srli    t2, t2, 1
    # t3 = mask
    sltu    t3, t1, t4
    addi    t3, t3, -1
    and     t5, t4, t3
    sub     t1, t1, t5
    and     t5, t0, t3
    add     t2, t2, t5

    # SQRT_STEP(1u << 10)
    # t4 = trial
    addi     t4, t2, 0x400
    srli    t2, t2, 1
    # t3 = mask
    sltu    t3, t1, t4
    addi    t3, t3, -1
    and     t5, t4, t3
    sub     t1, t1, t5
    andi     t5, t3, 0x400
    add     t2, t2, t5

    # SQRT_STEP(1u << 8)
    # t4 = trial
    addi     t4, t2, 0x100
    srli    t2, t2, 1
    # t3 = mask
    sltu    t3, t1, t4
    addi    t3, t3, -1
    and     t5, t4, t3
    sub     t1, t1, t5
    andi     t5, t3, 0x100
    add     t2, t2, t5

    # SQRT_STEP(1u << 6)
    # t4 = trial
    addi     t4, t2, 0x40
    srli    t2, t2, 1
    # t3 = mask
    sltu    t3, t1, t4
    addi    t3, t3, -1
    and     t5, t4, t3
    sub     t1, t1, t5
    andi     t5, t3, 0x40
    add     t2, t2, t5

    # SQRT_STEP(1u << 4)
    # t4 = trial
    addi     t4, t2, 0x10
    srli    t2, t2, 1
    # t3 = mask
    sltu    t3, t1, t4
    addi    t3, t3, -1
    and     t5, t4, t3
    sub     t1, t1, t5
    andi     t5, t3, 0x10
    add     t2, t2, t5

    # SQRT_STEP(1u << 2)
    # t4 = trial
    addi     t4, t2, 0x4
    srli    t2, t2, 1
    # t3 = mask
    sltu    t3, t1, t4
    addi    t3, t3, -1
    and     t5, t4, t3
    sub     t1, t1, t5
    andi     t5, t3, 0x4
    add     t2, t2, t5

    # SQRT_STEP(1u << 0)
    # t4 = trial
    addi     t4, t2, 0x1
    srli    t2, t2, 1
    # t3 = mask
    sltu    t3, t1, t4
    addi    t3, t3, -1
    and     t5, t4, t3
    sub     t1, t1, t5
    andi     t5, t3, 0x1
    add     t2, t2, t5

    # a5 = result_exp
    addi    a5, a2, 127
    srli    a5, a5, 1

    slli    a0, a5, 7
    addi    t2, t2, -128
    or      a0, a0, t2
    ret

return_0:
    add     a0, zero, zero
    ret
sqrt_return_nan:
    li      a0, 0x7FC0
    ret
return_a:
    ret
    .size   bf16_sqrt_asm, .-bf16_sqrt_asm
