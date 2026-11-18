/* solver_core.c - IDA* with two nibble-packed 4-cubie PDBs.
 *
 * State: x[c] = position<<2 | twist for each of the 7 cubies.
 *   one quarter turn  = 7 loads from QT (twist handled by the table: no mod 3)
 *   solved            = both PDB values are 0 (A u B covers all 7 cubies)
 * Search: explicit stack (<= 12 levels), no recursion, no heap.
 */

#include "rubik.h"
#include "pdb_spec.h"
#include "tables.h"

#define PATH_LENGTH_BOUND 11

static const uint8_t move_face[9] = {0, 0, 0, 1, 1, 1, 2, 2, 2};
static const uint8_t move_turn[9] = {0, 1, 2, 0, 1, 2, 0, 1, 2};

static inline uint32_t h_a(const uint8_t *x)
{
    uint32_t i;
    i = pdb_index_fast(x[A0], x[A1], x[A2], x[A3]);

    return pdb_get(PDB_A_TAB, i);
}

static inline uint32_t h_b(const uint8_t *x)
{
    uint32_t i;
    i = pdb_index_fast(x[B0], x[B1], x[B2], x[B3]);

    return pdb_get(PDB_B_TAB, i);
}


const uint8_t *solver_pdb(int which)
{
    return which ? PDB_B_TAB : PDB_A_TAB;
}
const uint8_t *solver_qt(void)
{
    return QT;
}

/* dst = one quarter turn of `face` applied to src (7 cubies). */
static inline void turn(uint8_t *dst, const uint8_t *src, uint32_t face)
{
    const uint8_t *q = QT + (face << 5);

    dst[0] = q[src[0]];
    dst[1] = q[src[1]];
    dst[2] = q[src[2]];
    dst[3] = q[src[3]];
    dst[4] = q[src[4]];
    dst[5] = q[src[5]];
    dst[6] = q[src[6]];
}

/* Parse into the cubie-indexed form. No division, no mod. */
static int parse(const char *state, uint8_t x[7])
{
    /* stop at early \0 */
    for (uint8_t i = 0; i < 14; i++) {
        if (state[i] == '\0')
            return -1;
    }
    if (state[14] != '\0')
        return -1;

    uint32_t seen = 0, sum = 0;
    for (uint32_t i = 0; i < 7; i++) {
        uint32_t c = (uint32_t) (uint8_t) (state[i] - '1');
        uint32_t o = (uint32_t) (uint8_t) (state[7 + i] - '1');
        if (c > 6 || o > 2)
            return -1;
        uint8_t bit = 1u << c;
        if (seen & bit)
            return -1;
        seen |= bit;
        sum += o;
        x[c] = (uint8_t) (i << 2 | o);
    }
    while (sum >= 3)
        sum -= 3;

    return sum ? -1 : 0;
}

/* move name can be 1 or 2 character long */
static inline uint8_t move_name_length(uint8_t taken)
{
    return (taken == 0 || taken == 3 || taken == 6) ? 1u : 2u;
}

/* Search state: st[d] = state at depth d; st[d+1] doubles as the "last
 * generated child" so the 3 turns of one face chain without recopying. */
static uint8_t st[13][7];
static uint8_t last_face[12], next_move[12], taken[12];

int rubik_solve(const char *state, char *out, size_t cap)
{
    int d;
    uint32_t bound, h0;
    if (parse(state, st[0]) != 0)
        return -1;

    if (cap == 0)
        return -2;

    {
        uint32_t a = h_a(st[0]), b = h_b(st[0]);
        h0 = a > b ? a : b;
    }
    /* already solved */
    if (h0 == 0) {
        out[0] = '\0';
        return 0;
    }

    for (bound = h0; bound <= PATH_LENGTH_BOUND; bound++) {
        d = 0;
        last_face[0] = 3;
        next_move[0] = 0;
        for (;;) {
            uint32_t m = next_move[d], f, g, ha, hb;
            if (m < 9 && move_face[m] == last_face[d])
                m += 3;   /* same face */
            if (m >= 9) { /* exhausted */
                if (d == 0)
                    break;
                d--;
                continue;
            }
            next_move[d] = (uint8_t) (m + 1);
            f = move_face[m];
            turn(st[d + 1], move_turn[m] ? st[d + 1] : st[d], f);
            g = (uint32_t) d + 1;

            ha = h_a(st[d + 1]);
            if (g + ha > bound)
                continue;
            hb = h_b(st[d + 1]);
            if (g + hb > bound)
                continue;
            if ((ha | hb) == 0)
                goto found;

            taken[d] = (uint8_t) m;
            last_face[d + 1] = (uint8_t) f;
            next_move[d + 1] = 0;
            d++;
            continue;
        found:
            uint8_t length = d + 1;
            uint8_t needed = 1; /* \0 */

            taken[d] = (uint8_t) m;

            for (int i = 0; i < length; i++) {
                if (i != 0)
                    ++needed;
                needed += move_name_length(taken[i]);
            }

            if (cap < needed) {
                if (cap != 0)
                    out[0] = '\0';
                return -2;
            }

            char *p = out;

            for (int i = 0; i < length; i++) {
                if (i != 0)
                    *p++ = ' ';
                uint8_t suffix;
                uint8_t taken_step = taken[i];

                if (taken_step < 3) {
                    *p++ = 'R';
                    suffix = taken_step;
                } else if (taken_step < 6) {
                    *p++ = 'B';
                    suffix = taken_step - 3;
                } else {
                    *p++ = 'D';
                    suffix = taken_step - 6;
                }

                if (suffix == 1)
                    *p++ = '2';
                else if (suffix == 2)
                    *p++ = '\'';
            }
            *p = '\0';
            return d + 1;
        }
    }
    return -3; /* should not happen */
}
