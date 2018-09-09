#ifndef _CHEAT_TYPES_H
#define _CHEAT_TYPES_H

struct QPoint
{
    int x;
    int y;
    QPoint(): x(0), y(0){}
    QPoint(int x0, int y0): x(x0), y(y0) {}
};

struct QRect
{
    int x;
    int y;
    int w;
    int h;
    bool contains(const QPoint pt) {
        return pt.x >= x && pt.y >= y && pt.x < x + w && pt.y < y + w;
    }
    QRect(): x(0), y(0), w(0), h(0) {}
    QRect(int x0, int y0, int width, int height): x(x0), y(y0), w(width), h(height) {}
    bool isEmpty() {return x == 0 && y == 0 && w == 0 && h == 0;}
};

struct TScreenBuffer
{
    unsigned char fPixel[160*80/8];
};

#endif
