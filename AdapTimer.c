#include <stdio.h>
#include <unistd.h>
#include "platform.h"
#include "xil_io.h"
#include "xparameters.h"





int main()
{
	u32 adaptimer;

    init_platform();

	Xil_Out32(0x43c00000,2);
	Xil_Out32(0x43c00000,2);
	Xil_Out32(0x43c00000,2);
	Xil_Out32(0x43c00000,2);
	Xil_Out32(0x43c00000,2);
	Xil_Out32(0x43c00000,2);
	Xil_Out32(0x43c00000,1);
	Xil_Out32(0x43c00000,1);
	Xil_Out32(0x43c00000,3);
	Xil_Out32(0x43c00000,4);
	Xil_Out32(0x43c00000,4);
	Xil_Out32(0x43c00000,4);
	adaptimer=Xil_In32(0x43c00000);
	printf("%08lx\n",adaptimer);
	adaptimer=Xil_In32(0x43c00000);
	printf("%08lx\n",adaptimer);



    cleanup_platform();
    return 0;
}
