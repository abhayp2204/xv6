#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "../user/trace.h"

uint64
sys_exit(void)
{
  int n;
  if (argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if (argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_waitx(void)
{
  uint64 address, address1, address2;
  uint runTime, waitTime;

  if(argaddr(0, &address) < 0)
    return -1;
  if(argaddr(1, &address1) < 0)
    return -1;
  if(argaddr(2, &address2) < 0)
    return -1;

  int ret = waitx(address, &runTime, &waitTime);
  struct proc* p = myproc();

  if(copyout(p->pagetable, address1, (char*)&waitTime, sizeof(int)) < 0)
    return -1;
  if(copyout(p->pagetable, address2, (char*)&runTime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if (argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if (argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_strace(void)
{
  int mask = 0;
  if(argint(0, &mask) < 0) return -1;
  
  struct proc* p = myproc();
  p->mask = mask;
  return 0;
}