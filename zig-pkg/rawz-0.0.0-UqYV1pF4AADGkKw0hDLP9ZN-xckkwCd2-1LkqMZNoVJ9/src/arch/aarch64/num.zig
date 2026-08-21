pub const read = 63;
pub const write = 64;
pub const close = 57;
pub const fcntl = 25;
pub const socket = 198;
pub const connect = 203;
pub const accept = 202;
pub const accept4 = 242;
pub const bind = 200;
pub const listen = 201;
pub const shutdown = 210;

// No standalone send/recv on aarch64 because the generic syscall table only
// has sendto/recvfrom. Callers implement send/recv
// as sendto/recvfrom with dest_addr=NULL, addrlen=0.
pub const sendto = 206;
pub const recvfrom = 207;

pub const sendmsg = 211;
pub const recvmsg = 212;
pub const getsockname = 204;
pub const getpeername = 205;
pub const setsockopt = 208;
pub const getsockopt = 209;

// No standalone select/poll on aarch64 because only the extended variants
// exist. pselect6 takes a timespec + sigmask, ppoll takes a timespec +
// sigmask. Callers implement select/poll on top of these with the
// sigmask arg fixed at NULL/0.
pub const pselect6 = 72;
pub const ppoll = 73;

pub const epoll_create1 = 20;
pub const epoll_ctl = 21;

// No standalone epoll_wait either because only epoll_pwait exists. Callers
// implement epoll_wait as epoll_pwait with sigmask=NULL.
pub const epoll_pwait = 22;
