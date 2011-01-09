/*

The swift chexor function implemented as a binary sqlite extension.

build: gcc -Wall -Werror -O3 -shared -fPIC -o chex0r.so chex0r.c

select load_extension('./chex0r.so');
select chexor('00000000000000000000000000000000', 'some values', '12345');
ea786eb6b9735db0e1b3c091c38631c7

*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <sqlite3ext.h>
#include <sqlite3.h>

/*** MD5 code ***/

typedef struct {
  unsigned int scratch[4];
  unsigned int inbuf[16];
  unsigned int total_bytes;
} md5_ctx;

static void rounds(md5_ctx *context)
{
  unsigned int a = context->scratch[0], b = context->scratch[1],
               c = context->scratch[2], d = context->scratch[3];

  #define ROLL(w, x, s) w = ((w << s) | (w & 0xFFFFFFFF) >> (32 - s)) + x;
  #define F1(w, x, y, z, data, m) w += (z ^ (x & (y ^ z))) + data + m;
  F1(a, b, c, d, context->inbuf[0], 0xd76aa478) ROLL(a, b, 7)
  F1(d, a, b, c, context->inbuf[1], 0xe8c7b756) ROLL(d, a, 12)
  F1(c, d, a, b, context->inbuf[2], 0x242070db) ROLL(c, d, 17)
  F1(b, c, d, a, context->inbuf[3], 0xc1bdceee) ROLL(b, c, 22)
  F1(a, b, c, d, context->inbuf[4], 0xf57c0faf) ROLL(a, b, 7)
  F1(d, a, b, c, context->inbuf[5], 0x4787c62a) ROLL(d, a, 12)
  F1(c, d, a, b, context->inbuf[6], 0xa8304613) ROLL(c, d, 17)
  F1(b, c, d, a, context->inbuf[7], 0xfd469501) ROLL(b, c, 22)
  F1(a, b, c, d, context->inbuf[8], 0x698098d8) ROLL(a, b, 7)
  F1(d, a, b, c, context->inbuf[9], 0x8b44f7af) ROLL(d, a, 12)
  F1(c, d, a, b, context->inbuf[10], 0xffff5bb1) ROLL(c, d, 17)
  F1(b, c, d, a, context->inbuf[11], 0x895cd7be) ROLL(b, c, 22)
  F1(a, b, c, d, context->inbuf[12], 0x6b901122) ROLL(a, b, 7)
  F1(d, a, b, c, context->inbuf[13], 0xfd987193) ROLL(d, a, 12)
  F1(c, d, a, b, context->inbuf[14], 0xa679438e) ROLL(c, d, 17)
  F1(b, c, d, a, context->inbuf[15], 0x49b40821) ROLL(b, c, 22)

  #define F2(w, x, y, z, data, m) w += (y ^ (z & (x ^ y))) + data + m;
  F2(a, b, c, d, context->inbuf[1], 0xf61e2562) ROLL(a, b, 5)
  F2(d, a, b, c, context->inbuf[6], 0xc040b340) ROLL(d, a, 9)
  F2(c, d, a, b, context->inbuf[11], 0x265e5a51) ROLL(c, d, 14)
  F2(b, c, d, a, context->inbuf[0], 0xe9b6c7aa) ROLL(b, c, 20)
  F2(a, b, c, d, context->inbuf[5], 0xd62f105d) ROLL(a, b, 5)
  F2(d, a, b, c, context->inbuf[10], 0x2441453) ROLL(d, a, 9)
  F2(c, d, a, b, context->inbuf[15], 0xd8a1e681) ROLL(c, d, 14)
  F2(b, c, d, a, context->inbuf[4], 0xe7d3fbc8) ROLL(b, c, 20)
  F2(a, b, c, d, context->inbuf[9], 0x21e1cde6) ROLL(a, b, 5)
  F2(d, a, b, c, context->inbuf[14], 0xc33707d6) ROLL(d, a, 9)
  F2(c, d, a, b, context->inbuf[3], 0xf4d50d87) ROLL(c, d, 14)
  F2(b, c, d, a, context->inbuf[8], 0x455a14ed) ROLL(b, c, 20)
  F2(a, b, c, d, context->inbuf[13], 0xa9e3e905) ROLL(a, b, 5)
  F2(d, a, b, c, context->inbuf[2], 0xfcefa3f8) ROLL(d, a, 9)
  F2(c, d, a, b, context->inbuf[7], 0x676f02d9) ROLL(c, d, 14)
  F2(b, c, d, a, context->inbuf[12], 0x8d2a4c8a) ROLL(b, c, 20)

  #define F3(w, x, y, z, data, m) w += (x ^ y ^ z) + data + m;
  F3(a, b, c, d, context->inbuf[5], 0xfffa3942) ROLL(a, b, 4)
  F3(d, a, b, c, context->inbuf[8], 0x8771f681) ROLL(d, a, 11)
  F3(c, d, a, b, context->inbuf[11], 0x6d9d6122) ROLL(c, d, 16)
  F3(b, c, d, a, context->inbuf[14], 0xfde5380c) ROLL(b, c, 23)
  F3(a, b, c, d, context->inbuf[1], 0xa4beea44) ROLL(a, b, 4)
  F3(d, a, b, c, context->inbuf[4], 0x4bdecfa9) ROLL(d, a, 11)
  F3(c, d, a, b, context->inbuf[7], 0xf6bb4b60) ROLL(c, d, 16)
  F3(b, c, d, a, context->inbuf[10], 0xbebfbc70) ROLL(b, c, 23)
  F3(a, b, c, d, context->inbuf[13], 0x289b7ec6) ROLL(a, b, 4)
  F3(d, a, b, c, context->inbuf[0], 0xeaa127fa) ROLL(d, a, 11)
  F3(c, d, a, b, context->inbuf[3], 0xd4ef3085) ROLL(c, d, 16)
  F3(b, c, d, a, context->inbuf[6], 0x4881d05) ROLL(b, c, 23)
  F3(a, b, c, d, context->inbuf[9], 0xd9d4d039) ROLL(a, b, 4)
  F3(d, a, b, c, context->inbuf[12], 0xe6db99e5) ROLL(d, a, 11)
  F3(c, d, a, b, context->inbuf[15], 0x1fa27cf8) ROLL(c, d, 16)
  F3(b, c, d, a, context->inbuf[2], 0xc4ac5665) ROLL(b, c, 23)

  #define F4(w, x, y, z, data, m) w += (y ^ (x | ~z)) + data + m;
  F4(a, b, c, d, context->inbuf[0], 0xf4292244) ROLL(a, b, 6)
  F4(d, a, b, c, context->inbuf[7], 0x432aff97) ROLL(d, a, 10)
  F4(c, d, a, b, context->inbuf[14], 0xab9423a7) ROLL(c, d, 15)
  F4(b, c, d, a, context->inbuf[5], 0xfc93a039) ROLL(b, c, 21)
  F4(a, b, c, d, context->inbuf[12], 0x655b59c3) ROLL(a, b, 6)
  F4(d, a, b, c, context->inbuf[3], 0x8f0ccc92) ROLL(d, a, 10)
  F4(c, d, a, b, context->inbuf[10], 0xffeff47d) ROLL(c, d, 15)
  F4(b, c, d, a, context->inbuf[1], 0x85845dd1) ROLL(b, c, 21)
  F4(a, b, c, d, context->inbuf[8], 0x6fa87e4f) ROLL(a, b, 6)
  F4(d, a, b, c, context->inbuf[15], 0xfe2ce6e0) ROLL(d, a, 10)
  F4(c, d, a, b, context->inbuf[6], 0xa3014314) ROLL(c, d, 15)
  F4(b, c, d, a, context->inbuf[13], 0x4e0811a1) ROLL(b, c, 21)
  F4(a, b, c, d, context->inbuf[4], 0xf7537e82) ROLL(a, b, 6)
  F4(d, a, b, c, context->inbuf[11], 0xbd3af235) ROLL(d, a, 10)
  F4(c, d, a, b, context->inbuf[2], 0x2ad7d2bb) ROLL(c, d, 15)
  F4(b, c, d, a, context->inbuf[9], 0xeb86d391) ROLL(b, c, 21)

  context->scratch[0] += a;
  context->scratch[1] += b;
  context->scratch[2] += c;
  context->scratch[3] += d;
}

static void md5_init(md5_ctx *context)
{
  static md5_ctx blank = {{0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476}};
  *context = blank;
}

static void md5_update(md5_ctx *context, const unsigned char *inbuf, unsigned int length)
{
  while (length--)
  {
    context->inbuf[(context->total_bytes & 63) >> 2] |=
          (*inbuf++) << (((context->total_bytes & 63) % 4) << 3);
    if (++context->total_bytes % 64)
      continue;
    rounds(context);
    memset(context->inbuf, 0, sizeof(context->inbuf));
  }
}

static void md5_hex(md5_ctx *context, char *dig)
{
  static unsigned char *hex = (unsigned char *)"0123456789abcdef", padding[64] = {0x80};
  md5_ctx ctx = *context;
  int i;

  ctx.inbuf[14] = ctx.total_bytes << 3;
  ctx.inbuf[15] = ctx.total_bytes >> 29;
  md5_update(&ctx, padding, ((ctx.total_bytes % 64) < 56) ?
          (56 - (ctx.total_bytes % 64)) : (120 - (ctx.total_bytes % 64)));
  rounds(&ctx);
  for (i = 0; i < 32; i++)
    dig[i + (i % 2 ? -1 : 1)] = hex[ctx.scratch[i / 8] >> ((i & 7) << 2) & 15];
  dig[32] = '\0';
}

/*** sqlite function implementation ***/

SQLITE_EXTENSION_INIT1

static void chexor(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  if (argc != 3)
    return;

  unsigned char dash = '-', i;
  char digest[33], new_digest[33];

  const unsigned char *old = sqlite3_value_text(argv[0]);
  int len_old = sqlite3_value_bytes(argv[0]);

  const unsigned char *name = sqlite3_value_blob(argv[1]);
  int len_name = sqlite3_value_bytes(argv[1]);

  const unsigned char *timestamp = sqlite3_value_text(argv[2]);
  int len_timestamp = sqlite3_value_bytes(argv[2]);

  if (len_old != 32)
    return;

  md5_ctx ctx;
  md5_init(&ctx);
  md5_update(&ctx, name, len_name);
  md5_update(&ctx, &dash, 1);
  md5_update(&ctx, timestamp, len_timestamp);
  md5_hex(&ctx, digest);

  for (i = 0; i < 4; i++)
  {
    unsigned int scratch1 = 0, scratch2 = 0;
    sscanf((char *)&old[i * 8], "%08x", &scratch1);
    sscanf(&digest[i * 8], "%08x", &scratch2);
    sprintf(&new_digest[i * 8], "%08x", scratch1 ^ scratch2);
  }
  digest[32] = 0;
  sqlite3_result_text(context, strdup(digest), 32, free);
}

/*** sqlite extension entry point ***/

int sqlite3_extension_init(sqlite3 *db, char **pzErrMsg,
        const sqlite3_api_routines *pApi)
{
  SQLITE_EXTENSION_INIT2(pApi);
  sqlite3_create_function(db, "chexor", 3, SQLITE_ANY, 0, chexor, 0, 0);
  return 0;
}

