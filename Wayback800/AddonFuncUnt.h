#ifndef _ADDON_FUNC_UNIT
#define _ADDON_FUNC_UNIT

#include <string>
#include "wintypes.h"
#include "CheatTypes.h"

//bool QRectContains(const QRect& rect, int x, int y);

int greedydiv(int n, int m);
int getCpuCount();
#ifndef _WIN32
unsigned int GetTickCount();
#endif
#endif
