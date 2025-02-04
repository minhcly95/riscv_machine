#include "circ_buf.h"

void circ_buf_init(struct circ_buf* cb) {
    cb->wr = cb->buf;
    cb->rd = cb->buf;
}

size_t circ_buf_push(struct circ_buf* cb, uint8_t* data, size_t len) {
    // Capture the values first
    uint8_t* wr = cb->wr;
    uint8_t* rd = cb->rd;

    uint8_t* wr_end  = wr + len;
    uint8_t* buf_end = circ_buf_end(cb);
    size_t   pushed  = 0;

    // The wrapped case: wr behind rd
    if (wr < rd) {
        // We need to cap wr_end by rd - 1
        if (wr_end >= rd)
            wr_end = rd - 1;
    }
    // The normal case: wr ahead rd
    // If we write past the end, we need to wrap
    // Otherwise, we don't do anything
    else if (wr_end >= buf_end) {
        // Write until buf_end
        pushed += buf_end - wr;
        while (wr != buf_end)
            *(wr++) = *(data++);

        if (rd != circ_buf_start(cb)) {
            // Wrap
            wr = circ_buf_start(cb);
            wr_end -= circ_buf_size(cb);
            // Since we wrapped, wr is now behind rd
            // and we need to cap wr_end by rd - 1
            if (wr_end >= rd)
                wr_end = rd - 1;
        }
        else {
            // If we will wrap right back to rd,
            // we need to step backward instead
            pushed -= 1;
            wr -= 1;
            wr_end = wr;
        }
    }

    // Write until wr_end
    pushed += wr_end - wr;
    while (wr != wr_end)
        *(wr++) = *(data++);

    // Commit the write atomically
    cb->wr = wr;

    return pushed;
}

size_t circ_buf_pop(struct circ_buf* cb, uint8_t* data, size_t len) {
    // Capture the values first
    uint8_t* wr = cb->wr;
    uint8_t* rd = cb->rd;

    uint8_t* rd_end  = rd + len;
    uint8_t* buf_end = circ_buf_end(cb);
    size_t   popped  = 0;

    // The normal case: rd behind wr
    if (rd <= wr) {
        // We need to cap rd_end by wr
        if (rd_end > wr)
            rd_end = wr;
    }
    // The wrapped case: rd ahead wr
    // If we read past the end, we need to wrap
    // Otherwise, we don't do anything
    else if (rd_end >= buf_end) {
        // Read until buf_end
        popped += buf_end - rd;
        while (rd != buf_end)
            *(data++) = *(rd++);
        // Wrap
        rd = circ_buf_start(cb);
        rd_end -= circ_buf_size(cb);
        // Since we wrapped, wr is now behind rd
        // and we need to cap rd_end by wr
        if (rd_end > wr)
            rd_end = wr;
    }

    // Read until rd_end
    popped += rd_end - rd;
    while (rd != rd_end)
        *(data++) = *(rd++);

    // Commit the read atomically
    cb->rd = rd;

    return popped;
}

