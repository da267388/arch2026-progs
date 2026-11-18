#include "fixed.h"

uint32_t op1(uint32_t a, uint32_t b, int *n)
{
    int passes = 0;

    while (b != 0) {
        uint32_t carry = (a & b) << 1;
        a ^= b;
        b = carry;
        ++passes;
    }

    *n = passes;
    return a;
}

uint32_t op2(uint32_t a, uint32_t b)
{
    return a - b;
}

uint32_t op3(uint32_t a, uint32_t b)
{
    return (a & b) + ((a ^ b) >> 1);
}

/* a0, a1, b are unsigned 16-bit values. */
static inline void multiply_pair_u16(uint32_t a0,
                                     uint32_t a1,
                                     uint32_t b,
                                     uint32_t *p0,
                                     uint32_t *p1)
{
    uint32_t r0 = 0;
    uint32_t r1 = 0;

    while (b != 0) {
        if (b & 1u) {
            r0 += a0;
            r1 += a1;
        }

        a0 <<= 1;
        a1 <<= 1;
        b >>= 1;
    }

    *p0 = r0;
    *p1 = r1;
}

int32_t q_mul(int32_t a, int32_t b)
{
    uint32_t ua = (uint32_t) a;
    uint32_t ub = (uint32_t) b;

    uint32_t a_low = ua & 0xFFFFu;
    uint32_t a_high = ua >> 16;
    uint32_t b_low = ub & 0xFFFFu;
    uint32_t b_high = ub >> 16;

    uint32_t p00, p10, p01, p11;

    multiply_pair_u16(a_low, a_high, b_low, &p00, &p10);
    multiply_pair_u16(a_low, a_high, b_high, &p01, &p11);

    uint32_t middle = p10 + (p00 >> 16);
    uint32_t middle_low = (middle & 0xFFFFu) + p01;

    uint32_t low = (middle_low << 16) | (p00 & 0xFFFFu);
    uint32_t high = p11 + (middle >> 16) + (middle_low >> 16);

    /* Convert the unsigned product to the signed product bit pattern. */
    if (a < 0)
        high -= ub;
    if (b < 0)
        high -= ua;

    uint32_t rounding = 1u << (Q - 1);
    uint32_t carry = low > UINT32_MAX - rounding;
    low += rounding;
    high += carry;

    uint32_t result = (low >> Q) | (high << (32 - Q));

    if (result <= (uint32_t) INT32_MAX)
        return (int32_t) result;

    return -1 - (int32_t) (~result);
}
