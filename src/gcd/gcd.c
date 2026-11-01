#include "gcd.h"

static inline uint32_t ctz(uint32_t x)
{
    uint32_t n = 0;
    if ((x & 0x0000FFFF) == 0) {
        n += 16;
        x >>= 16;
    }
    if ((x & 0x000000FF) == 0) {
        n += 8;
        x >>= 8;
    }
    if ((x & 0x0000000F) == 0) {
        n += 4;
        x >>= 4;
    }
    if ((x & 0x00000003) == 0) {
        n += 2;
        x >>= 2;
    }
    if ((x & 0x00000001) == 0) {
        n += 1;
    }
    return n;
}

/* The binary GCD. */
uint32_t gcd_u32(uint32_t a, uint32_t b)
{
    if (a == 0)
        return b;
    if (b == 0)
        return a;

    uint32_t shift = ctz(a | b);

    a >>= ctz(a);

    while (b != 0) {
        b >>= ctz(b);

        uint32_t is_b_less = -(b < a);

        uint32_t diff = a ^ b;
        uint32_t swap_mask = diff & is_b_less;  // 0x00000000 or (a ^ b)
        uint32_t temp = b ^ swap_mask;
        a = a ^ swap_mask;
        b = temp - a;
    }


    return a << shift;
}
