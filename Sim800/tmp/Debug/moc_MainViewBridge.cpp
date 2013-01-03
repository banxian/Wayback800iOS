/****************************************************************************
** Meta object code from reading C++ file 'MainViewBridge.h'
**
** Created: Thu Jan 3 23:47:34 2013
**      by: The Qt Meta Object Compiler version 63 (Qt 4.8.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../MainViewBridge.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'MainViewBridge.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 63
#error "This file was generated using the moc from 4.8.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_TMainViewBridge[] = {

 // content:
       6,       // revision
       0,       // classname
       0,    0, // classinfo
      10,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // slots: signature, parameters, type, tag, flags
      17,   16,   16,   16, 0x08,
      40,   38,   16,   16, 0x08,
      73,   69,   16,   16, 0x0a,
      94,   69,   16,   16, 0x0a,
     113,   69,   16,   16, 0x0a,
     141,   69,   16,   16, 0x0a,
     162,   16,   16,   16, 0x0a,
     188,   16,   16,   16, 0x0a,
     216,   16,   16,   16, 0x0a,
     248,  241,   16,   16, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_TMainViewBridge[] = {
    "TMainViewBridge\0\0onBenchmarkClicked()\0"
    ",\0onKeypadSizeChanged(int,int)\0x,y\0"
    "onMouseDown(int,int)\0onMouseUp(int,int)\0"
    "onMouseDoubleClick(int,int)\0"
    "onMouseMove(int,int)\0onEmulationStartClicked()\0"
    "onEmulationRestartClicked()\0"
    "onEmulationTestClicked()\0buffer\0"
    "onLCDBufferChanged(QByteArray*)\0"
};

void TMainViewBridge::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        Q_ASSERT(staticMetaObject.cast(_o));
        TMainViewBridge *_t = static_cast<TMainViewBridge *>(_o);
        switch (_id) {
        case 0: _t->onBenchmarkClicked(); break;
        case 1: _t->onKeypadSizeChanged((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2]))); break;
        case 2: _t->onMouseDown((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2]))); break;
        case 3: _t->onMouseUp((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2]))); break;
        case 4: _t->onMouseDoubleClick((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2]))); break;
        case 5: _t->onMouseMove((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2]))); break;
        case 6: _t->onEmulationStartClicked(); break;
        case 7: _t->onEmulationRestartClicked(); break;
        case 8: _t->onEmulationTestClicked(); break;
        case 9: _t->onLCDBufferChanged((*reinterpret_cast< QByteArray*(*)>(_a[1]))); break;
        default: ;
        }
    }
}

const QMetaObjectExtraData TMainViewBridge::staticMetaObjectExtraData = {
    0,  qt_static_metacall 
};

const QMetaObject TMainViewBridge::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_TMainViewBridge,
      qt_meta_data_TMainViewBridge, &staticMetaObjectExtraData }
};

#ifdef Q_NO_DATA_RELOCATION
const QMetaObject &TMainViewBridge::getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

const QMetaObject *TMainViewBridge::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->metaObject : &staticMetaObject;
}

void *TMainViewBridge::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_TMainViewBridge))
        return static_cast<void*>(const_cast< TMainViewBridge*>(this));
    return QObject::qt_metacast(_clname);
}

int TMainViewBridge::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 10)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 10;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
