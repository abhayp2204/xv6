# xv6
The xv6 OS was modified to support strace syscall, FCFS type scheduling in addition to the default Round Robin scheduling and
time to display the waiting and run time of a process

## Makefile
Changes were made to support conditional compilation and `$U/_time\`, `$U/_strace\` were added

## proc.h
The following variables were added to the process structure in proc.h
- uint rtime;                  // How long the process ran for
- uint wtime;                  // How long did the process wait
- uint ctime;                  // When was the process created
- uint etime;                  // When did the process exit

## proc.c
- `waitx()` function was added to support time function
- `updateTime()` function was added to increment runtime
- `scheduler()` function was modifified to support FCFS scheduling

## strace.c
- this is used to trace the system calls used by a command
- Syntax: strace mask command [args]

## syscall.c
- The `syscall()` function was modified to print the results of strace
- The `syscallnum[]` array was created to store the number of parameters for each syscall
- The necessary elements were added to the `system_call_name[]`, `syscalls[]` arrays

## sysproc.c
- Changes were made to support the newly added syscalls

## syscall.h
- `SYS_waitx` and `SYS_strace` syscalls were added

## usys.pl
- THe necessary entries were added