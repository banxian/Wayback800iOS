#include "AddonFuncUnt.h"


#if defined(Q_OS_UNIX) && !defined(Q_OS_MACX)
#   include <unistd.h>
#elif defined(Q_OS_MACX)
#   include <mach/mach.h>
#   include <mach/machine.h>
#endif


int greedydiv( int n, int m )
{
    int Result = (n + m - 1) / m;
    return Result;
}


bool QRectContains(const QRect& rect, int x, int y)
{
    // TODO:
    return false;
}
