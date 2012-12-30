//
//  MainViewBridge.h
//  Sim800
//
//  Created by banxian on 12/30/12.
//  Copyright (c) 2012 banxian. All rights reserved.
//

#ifndef SIM800_MAINVIEWBRIDGE_H
#define SIM800_MAINVIEWBRIDGE_H

#include <QtGui/QApplication>
#include <QtCore/QMimeData>
#include <QtCore/QDateTime>
#include <QtGui/QTreeWidgetItem>
#include "Common.h"
#include <QtGui/QImage>
#include "KeyItem.h"


typedef struct tagLCDStripe {
    QImage bitmap;
    int left, top;
} TLCDStripe;

class TMainViewBridge : public QObject {
    Q_OBJECT
public:
    explicit TMainViewBridge(void* view);
    ~TMainViewBridge();
    
private:
    int argc;
    char** argv;
    QCoreApplication fakeApp; // MViewLite for M8, no gui
    void * fParent;
    QString fLastSavedProjectFilename;
    QTime fPrepareBufferStartTime;
    QSet<Qt::Key> fPressedKeys;
    TKeyItem* fKeyItems[8][8];
    TLCDStripe* fLCDStripes;
    QImage fLCDEmpty, fLCDPixel;

private:
    // Reader
    QImage fStageProxy; // used as frame buffer in perfect model
    QRect fKeypadRect;
    
private:
    void initKeypad();
    void repaintKeypad();
    void updateKeypadMatrix();
    void initLcdStripe();
    void DrawShadowOrPixel( QByteArray* buffer, QPainter &painter, bool semishadow );
    
protected:
    virtual bool eventFilter(QObject*, QEvent*);
    virtual void keyPressEvent(QKeyEvent *);
    virtual void keyReleaseEvent(QKeyEvent *);
private slots:
    //void onEmulationStartClicked();
    //void onEmulationRestartClicked();
    //void onEmulationTestClicked();
    void onBenchmarkClicked();
    //void onLanguageEnglishClicked();
    //void onLanguageChineseClicked();
    //void onHelpContentsClicked();
    void onKeypadSizeChanged(int, int);
    //void onMouseDown(int x, int y);
    //void onMouseUp(int x, int y);
    
public slots:
    // not slots
    void onMouseDown(int x, int y);
    void onMouseUp(int x, int y);
    void onMouseDoubleClick(int x, int y);
    void onMouseMove(int x, int y);
    void onEmulationStartClicked();
    void onEmulationRestartClicked();
    void onEmulationTestClicked();
    
public slots:
    //void writeLog(QString content, TLogType logtype = ltMessage);
    void onStepFinished(quint16 pc);
    void onLCDBufferChanged(QByteArray* buffer);
    
};

QString LogTypeToString( TLogType logtype );
QString localLanguage();

#endif
