#include "bf16.h"

uint16_t bf16_from_f32(uint32_t f32bits)
{
    uint32_t upper = f32bits >> 16;

    if ((upper & 0x7F80u) == 0x7F80u)
        return (uint16_t) upper;

    uint32_t rounding = 0x7FFFu + (upper & 1u);
    return (uint16_t) ((f32bits + rounding) >> 16);
}

/* The caller has already handled zero, infinity, and NaN. */
static inline uint32_t normalize_significand(uint32_t fraction, int *exponent)
{
    if (*exponent != 0)
        return 128u + fraction;

    *exponent = 1;
    if (fraction < 16u) {
        fraction <<= 4;
        *exponent -= 4;
    }
    if (fraction < 64u) {
        fraction <<= 2;
        *exponent -= 2;
    }
    if (fraction < 128u) {
        fraction <<= 1;
        --(*exponent);
    }
    return fraction;
}

/* Both significands are in [128, 255]; bit 7 always contributes. */
static inline uint32_t multiply_significands(uint32_t a, uint32_t b)
{
    uint32_t product = a << 7;
    b &= 0x7Fu;

    // bit 0
    if (!b)
        return product;
    if (b & 1u)
        product += a;

    // bit 1
    if (!(b >>= 1))
        return product;
    a <<= 1;
    if (b & 1u)
        product += a;

    // bit 2
    if (!(b >>= 1))
        return product;
    a <<= 1;
    if (b & 1u)
        product += a;

    // bit 3
    if (!(b >>= 1))
        return product;
    a <<= 1;
    if (b & 1u)
        product += a;

    // bit 4
    if (!(b >>= 1))
        return product;
    a <<= 1;
    if (b & 1u)
        product += a;

    // bit 5
    if (!(b >>= 1))
        return product;
    a <<= 1;
    if (b & 1u)
        product += a;

    // bit 6
    if (!(b >>= 1))
        return product;
    a <<= 1;
    if (b & 1u)
        product += a;

    return product;
}

uint16_t bf16_mul(uint16_t a, uint16_t b)
{
    uint32_t abs_a = a & 0x7FFFu;
    uint32_t abs_b = b & 0x7FFFu;
    uint32_t sign = (a ^ b) & 0x8000u;

    /* The contract examines a before b. */
    if (abs_a > 0x7F80u)
        return a;
    if (abs_a == 0x7F80u)
        return (uint16_t) (abs_b == 0 ? 0x7FC0u : (sign | 0x7F80u));

    if (abs_b > 0x7F80u)
        return b;
    if (abs_b == 0x7F80u)
        return (uint16_t) (abs_a == 0 ? 0x7FC0u : (sign | 0x7F80u));

    if (abs_a == 0 || abs_b == 0)
        return (uint16_t) sign;

    int exp_a = (int) (abs_a >> 7);
    int exp_b = (int) (abs_b >> 7);
    uint32_t sig_a = normalize_significand(abs_a & 0x7Fu, &exp_a);
    uint32_t sig_b = normalize_significand(abs_b & 0x7Fu, &exp_b);

    uint32_t product = multiply_significands(sig_a, sig_b);
    int exponent = exp_a + exp_b - 127;

    if (product >= 0x8000u) {
        product >>= 1;
        ++exponent;
    }

    uint32_t fraction = (product >> 7) & 0x7Fu;

    if (exponent >= 255)
        return (uint16_t) (sign | 0x7F80u);
    if (exponent < -6)
        return (uint16_t) sign;
    if (exponent <= 0)
        return (uint16_t) (sign | (fraction >> (1 - exponent)));

    return (uint16_t) (sign | ((uint32_t) exponent << 7) | fraction);
}

/* For 128 <= m <= 510, sqrt(n) has its high bit (128) set. */
static inline uint32_t sqrt_significand(uint32_t m)
{
    uint32_t n = ((m + 1u) << 7) - 1u;
    uint32_t remainder = n - (1u << 14);
    uint32_t partial = 1u << 14;

/* Restoring integer square root, starting after the known first bit. */
#define SQRT_STEP(bit)                            \
    do {                                          \
        uint32_t trial = partial + (bit);         \
        partial >>= 1;                            \
        /* remainder < trial RV32I sltu */        \
        /* (1)，1 - 1 = 0x00000000 (no update) */ \
        /* (0)，0 - 1 = 0xFFFFFFFF (update) */    \
        uint32_t mask = (remainder < trial) - 1u; \
        remainder -= trial & mask;                \
        partial += (bit) & mask;                  \
    } while (0)

    /* unroll */
    SQRT_STEP(1u << 12);
    SQRT_STEP(1u << 10);
    SQRT_STEP(1u << 8);
    SQRT_STEP(1u << 6);
    SQRT_STEP(1u << 4);
    SQRT_STEP(1u << 2);
    SQRT_STEP(1u << 0);

#undef SQRT_STEP
    return partial;
}

uint16_t bf16_sqrt(uint16_t a)
{
    uint32_t magnitude = a & 0x7FFFu;

    if (magnitude > 0x7F80u)
        return a;
    if (magnitude == 0)
        return 0;
    if ((a & 0x8000u) != 0)
        return 0x7FC0u;
    if (magnitude == 0x7F80u)
        return a;

    uint32_t exponent = magnitude >> 7;
    if (exponent == 0)
        return 0;

    uint32_t m = 128u + (magnitude & 0x7Fu);
    if ((exponent & 1u) == 0)
        m <<= 1;

    uint32_t root = sqrt_significand(m);

    uint32_t result_exp = (exponent + 127u) >> 1;
    return (uint16_t) ((result_exp << 7) | (root - 128u));
}