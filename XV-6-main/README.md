This is my Xv6 Operating System project for the Operating Systems course.

# Scheduling Algorithms in Our Operating System

## Specification 2: Scheduling Algorithms

### FCFS (First-Come, First-Served)

- **Changes Made:**
  - Added an `int mask` in the `struct proc` in `proc.h`.
  - Edited `allocproc()` in `proc.c` to include `p->mask = 0;`.
  - Added a macro in the Makefile to choose which scheduler to run.
  - Added an FCFS infinite loop to `proc.c` and `if defined` statements for Round Robin and FCFS in `scheduler()` function in `proc.c`.
  - Edited `kerneltrap()` in `trap.c` to disable the preemption of the process after the clock interrupts.

### PBS (Priority-Based Scheduling)

- **Changes Made:**
  - Added `int rtime`, `etime`, `ctime`, `stime` in `struct proc` in `proc.h`.
  - Added a new syscall `set_priority` and followed the same steps as for the `strace` syscall.
  - Updated `allocproc` in `proc.c` to include `rtime`, `ctime`, `stime`.
  - Added an infinite for loop for PBS in the `scheduler()` function in `proc.c`.
  - Added the `set_priority` function in `proc.c`.
  - Updated `defs.h`.
  - Added a program `setpriority.c` to the user programs.
  - Updated `user.h` and `usys.pl`.

### Performance Comparison

Unfortunately, we were unable to benchmark the performance of the scheduling algorithms using the provided benchmark program due to the lack of access to it.

## Specification 3: MLFQ (Multi-Level Feedback Queue)

### MLFQ (Multi-Level Feedback Queue)

- **Not Implemented:**
  - We were unable to implement the MLFQ scheduling algorithm within the given timeframe.

However, we made enhancements to the existing system by updating `procdump()` to show extra statistics for PBS.

## General Notes on MLFQ

If a process voluntarily relinquishes control of the CPU (e.g., for performing I/O), it leaves the queuing network. When the process becomes ready again after the I/O, it is inserted at the tail of the same queue from which it relinquished earlier. This mechanism helps prevent processes from starving and optimizes processor time usage.

---

