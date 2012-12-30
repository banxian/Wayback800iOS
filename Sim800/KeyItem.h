#ifndef KEYITEM_H
#define KEYITEM_H

#include <QtGui/QImage>
#include <QtCore/QSet>


class TKeyItem {
public:
    explicit TKeyItem(int ID, const QString& graphic, int matchedkeycode);
private:
    int fRow;
    int fColumn;
    bool fPressed;
    bool fHold;
    QString fGraphic;
    QString fSubscript;
    QSet<int> fMatchedKeycodes;
    QRect fRect;
public:
    void addKeycode(int matchedkeycode);
    void setRect(const QRect& rect);
    void setSubscript(const QString& subscript);
    bool inRect(const QPoint& point);
    void paintSelf(QImage& image);
    bool press(int keycode);
    bool release(int keycode);
    void hold();
    void press();
    void release();
    bool pressed();
    int row();
    int column();
};

#endif // KEYPADUNT_H
