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
    return (a >> 1) + (b >> 1) + (a & b & 1u);
}

int32_t q_mul(int32_t a, int32_t b)
{
    uint32_t ua = (uint32_t) a;
    uint32_t ub = (uint32_t) b;

    uint32_t a_low = ua & 0xFFFFu;
    uint32_t a_high = ua >> 16;
    uint32_t b_low = ub & 0xFFFFu;
    uint32_t b_high = ub >> 16;

    uint32_t low_product = a_low * b_low;
    uint32_t middle = a_high * b_low + (low_product >> 16);
    uint32_t middle_low = middle & 0xFFFFu;
    uint32_t middle_high = middle >> 16;

    middle_low += a_low * b_high;

    uint32_t low = (middle_low << 16) | (low_product & 0xFFFFu);
    uint32_t high = a_high * b_high + middle_high + (middle_low >> 16);

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
