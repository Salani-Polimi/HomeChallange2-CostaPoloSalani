
#ifndef SEND_ACK_H
#define SEND_ACK_H

//payload of the msg

typedef nx_struct my_msg {
	nx_uint8_t type;
    nx_uint8_t counter;
	nx_uint8_t data;
} my_msg_t;

#define REQ 1
#define RESP 2 

enum{
AM_MY_MSG = 6,
};

#endif
