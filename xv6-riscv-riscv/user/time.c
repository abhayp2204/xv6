#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "../user/user.h"
#include "../kernel/fcntl.h"

int main(int argc, char** argv)
{
    int pid = fork();
    if(pid < 0)
    {
        printf("Forking failed\n");
        exit(1);
    }
    else if(pid == 0)
    {
        if(argc == 1)
        {
            sleep(10);
            exit(0);
        }
        else
        {
            exec(argv[1], argv + 1);
            printf("Exec failed\n");
            exit(1);
        }
    }
    else
    {
        int runTime;
        int waitTime;
        waitx(0, &runTime, &waitTime);
        
        printf("Waiting : %d\n", waitTime);
        printf("Running : %d\n\n", runTime);
    }
    exit(0);
}