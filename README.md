# XV6 Operating System Extension

Enhanced the existing XV6 Operating System, showcasing expertise in prominent operating system domains including scheduling algorithms and system calls.

## Features

### 1. strace
* ``strace mask command [args]``
* The mask identifies which system calls to trace. For instance, the mask `1 << 3, or 1000` traces the third system call.
* Keeps track of a process's system calls invoked during the process's execution.


### 2. Scheduling Algorithms

Implemented and tested new scheduling algorithms to enhance the performance of the operating system. The introduced scheduling algorithms include:

- **Priority-Based Scheduling:** Assigns priority levels to processes, allowing higher-priority processes to be scheduled before lower-priority ones.
- **Multi-level Feedback Scheduling:** Utilizes multiple queues with different priorities, allowing processes to move between queues based on their behavior.
- **First-Come-First-Serve (FCFS) Queue Scheduling:** Schedules processes in the order they arrive, ensuring fairness in execution.

