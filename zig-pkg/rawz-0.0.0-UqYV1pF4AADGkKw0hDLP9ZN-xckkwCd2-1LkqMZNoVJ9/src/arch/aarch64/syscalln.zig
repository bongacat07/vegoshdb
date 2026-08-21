pub inline fn syscall1(number: usize, arg1: usize) isize {
    return asm volatile ("svc #0"
        : [ret] "={x0}" (-> isize),
        : [arg1] "{x0}" (arg1),
          [number] "{x8}" (number),
    );
}

pub inline fn syscall2(number: usize, arg1: usize, arg2: usize) isize {
    return asm volatile ("svc #0"
        : [ret] "={x0}" (-> isize),
        : [arg1] "{x0}" (arg1),
          [arg2] "{x1}" (arg2),
          [number] "{x8}" (number),
    );
}

pub inline fn syscall3(
    number: usize,
    arg1: usize,
    arg2: usize,
    arg3: usize,
) isize {
    return asm volatile ("svc #0"
        : [ret] "={x0}" (-> isize),
        : [arg1] "{x0}" (arg1),
          [arg2] "{x1}" (arg2),
          [arg3] "{x2}" (arg3),
          [number] "{x8}" (number),
    );
}

pub inline fn syscall4(
    number: usize,
    arg1: usize,
    arg2: usize,
    arg3: usize,
    arg4: usize,
) isize {
    return asm volatile ("svc #0"
        : [ret] "={x0}" (-> isize),
        : [arg1] "{x0}" (arg1),
          [arg2] "{x1}" (arg2),
          [arg3] "{x2}" (arg3),
          [arg4] "{x3}" (arg4),
          [number] "{x8}" (number),
    );
}

pub inline fn syscall5(
    number: usize,
    arg1: usize,
    arg2: usize,
    arg3: usize,
    arg4: usize,
    arg5: usize,
) isize {
    return asm volatile ("svc #0"
        : [ret] "={x0}" (-> isize),
        : [arg1] "{x0}" (arg1),
          [arg2] "{x1}" (arg2),
          [arg3] "{x2}" (arg3),
          [arg4] "{x3}" (arg4),
          [arg5] "{x4}" (arg5),
          [number] "{x8}" (number),
    );
}

pub inline fn syscall6(
    number: usize,
    arg1: usize,
    arg2: usize,
    arg3: usize,
    arg4: usize,
    arg5: usize,
    arg6: usize,
) isize {
    return asm volatile ("svc #0"
        : [ret] "={x0}" (-> isize),
        : [arg1] "{x0}" (arg1),
          [arg2] "{x1}" (arg2),
          [arg3] "{x2}" (arg3),
          [arg4] "{x3}" (arg4),
          [arg5] "{x4}" (arg5),
          [arg6] "{x5}" (arg6),
          [number] "{x8}" (number),
    );
}
