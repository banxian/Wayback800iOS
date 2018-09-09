#include "KeyItem.h"
//#include "AddonFuncUnt.h"
#include <TargetConditionals.h>


TKeyItem::TKeyItem( int ID, const char* graphic, const char* subscript )
    : fRow(ID / 10)
    , fColumn(ID % 10)
    , fGraphic(graphic)
    , fSubscript(subscript)
    , fSuperLabel(0)
{
}

TKeyItem::TKeyItem( int ID, const char* graphic, const char* subscript, const char* label )
    : fRow(ID / 10)
    , fColumn(ID % 10)
    , fGraphic(graphic)
    , fSubscript(subscript)
    , fSuperLabel(label)
{
}


