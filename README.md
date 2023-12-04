# XV6 Operating System Extension

This repository contains an extension of the XV6 operating system, introducing new features and improvements. The enhancements focus on providing additional system calls, incorporating new scheduling algorithms, and improving the handling of processes, jobs, signals, and I/O redirection.

## Features

### 1. New System Calls

Extended the XV6 operating system with new system calls to enable user monitoring of processes. This includes functionality to gather information about running processes, their states, and resource utilization.

### 2. Scheduling Algorithms

Implemented and tested new scheduling algorithms to enhance the performance of the operating system. The introduced scheduling algorithms include:

- **Priority-Based Scheduling:** Assigns priority levels to processes, allowing higher-priority processes to be scheduled before lower-priority ones.
  
- **Multi-level Feedback Scheduling:** Utilizes multiple queues with different priorities, allowing processes to move between queues based on their behavior.

- **First-Come-First-Serve (FCFS) Queue Scheduling:** Schedules processes in the order they arrive, ensuring fairness in execution.

### 3. Robust System

Developed a robust system capable of efficiently handling various tasks, including:

- **Job Handling:** Implemented mechanisms to manage jobs efficiently, allowing users to monitor, control, and interact with running processes.

- **Signal Handling:** Enhanced signal processing capabilities, providing better control over inter-process communication through signals.

- **Built-in Commands:** Expanded the set of built-in commands, including functionalities such as changing directories (`cd`), displaying the current working directory (`pwd`), providing process information (`pinfo`), and managing jobs.

- **I/O Redirection:** Improved I/O redirection through piping, enabling users to redirect input and output streams between processes seamlessly.

## Getting Started

Follow these steps to build and run the extended XV6 operating system:

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/xv6-extension.git
