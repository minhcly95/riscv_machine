#ifndef __CIRC_BUF_H__
#define __CIRC_BUF_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define CIRC_BUF_LEN  32

// Circular buffer
struct circ_buf {
    uint8_t            buf[CIRC_BUF_LEN];
    uint8_t *volatile  wr;
    uint8_t *volatile  rd;
};

// Initialize the struct
void circ_buf_init(struct circ_buf* cb);

// Simple properties
inline uint8_t* circ_buf_start(struct circ_buf* cb) { return cb->buf; }
inline size_t circ_buf_size(struct circ_buf* cb) { return sizeof(cb->buf); }
inline uint8_t* circ_buf_end(struct circ_buf* cb) { return circ_buf_start(cb) + circ_buf_size(cb); }

// Push to the tail, return number of bytes pushed
size_t circ_buf_push(struct circ_buf* cb, uint8_t* data, size_t len);

// Pop from the head, return number of bytes popped
size_t circ_buf_pop(struct circ_buf* cb, uint8_t* data, size_t len);

#endif
