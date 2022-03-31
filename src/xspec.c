#include <stdio.h>
#include <string.h>
#include <stdint.h>

typedef struct XRequest {
	uint8_t major_opcode;
	uint16_t length;
	uint8_t* data;
} XRequest;

// Retrieves the length of an X request in bytes by using the `length` field.
uint32_t x_request_length(const XRequest* xr) {
	return xr->length * 4;
}

// Calculates the length of an XRequest using the `data` field, then puts it in the `length` field.
void x_request_calculate_length(XRequest* xr) {
}


typedef struct XReply {
	uint32_t length;
} XReply;

