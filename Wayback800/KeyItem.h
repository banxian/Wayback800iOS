#ifndef KEYITEM_H
#define KEYITEM_H




struct TKeyItem {
    TKeyItem(int ID, const char* graphic, const char* subscript);
    TKeyItem(int ID, const char* graphic, const char* subscript, const char* label);

    int fRow;
    int fColumn;
    const char* fGraphic; // TODO:
    const char* fSubscript;
    const char* fSuperLabel; // label on top
};

#endif // KEYPADUNT_H
