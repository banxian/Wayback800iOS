#ifndef _NEKO_DRIVER_UNIT_H
#define _NEKO_DRIVER_UNIT_H


#include <vector>
#include <string>
#ifndef _WIN32
#include <pthread.h>
#endif
#include "CheatTypes.h"

#define qDebug(...)

class EmulatorThread;

typedef void(*LCDBufferChangeCallback)();

class TNekoDriver
{
public:
    TNekoDriver();
    ~TNekoDriver();
private:
    EmulatorThread* fEmulatorThread;
    LCDBufferChangeCallback fLCDBufferChangeCallback; // TODO: to StartEmulation
    char* fNorBuffer; // for performance
    char* fBROMBuffer;
    std::string fNorFilename, fSRAMFilename;
    bool fFlashUpdated;
private:
    bool LoadBROM(const std::string& filename);
    bool LoadFullNorFlash(const std::string& filename);
    bool LoadDemoNor(const std::string& filename);
    bool SaveFullNorFlash();
    bool LoadSRAM(const std::string& filename);
    bool SaveFullSRAM();

public:
    void SwitchNorBank(int bank);
    void Switch4000toBFFF(unsigned char bank); // used 0A/0D value
    void InitInternalAddrs();
    bool StartEmulation();
    bool RunDemoBin(const std::string& filename);
    bool StopEmulation();
    bool PauseEmulation();
    bool ResumeEmulation();
    void CheckFlashProgramming(unsigned short addr, unsigned char data);
    void SetLCDBufferChangedCallback(LCDBufferChangeCallback callback);

//public slots:
//    void onLCDBufferChanged(QByteArray* buffer);
//signals:
//    void lcdBufferChanged(QByteArray* buffer);
};

class EmulatorThread
{
public:
    explicit EmulatorThread(char* brom, char* nor);
    ~EmulatorThread();
protected:
    char* fBROMBuffer;
    char* fNorBuffer;
    bool fKeeping;
    void* fLCDBuffer;
    LCDBufferChangeCallback fLCDBufferChangeCallback;
#ifndef _WIN32
    pthread_t fThreadID;
#endif
private:
    unsigned int lastTicket;
    unsigned long long totalcycle;
    //const unsigned spdc1016freq = 3686400;
    bool measured;
    unsigned remeasure;
    unsigned batchlimiter;
    long batchcount;
    double sleepgap;
    long sleepcount;

protected:
    void run();
private:
    static void* OnTheadExecute(void* data);

#ifdef AUTOTEST
private:
    bool enablelogging;
    void TryTest(unsigned line);
#endif
public:
    void start(); // qt

public:
    void StopKeeping();
    void SetLCDBufferChangedCallback(LCDBufferChangeCallback callback);
//signals:
//    void lcdBufferChanged(QByteArray* buffer);
};

typedef TNekoDriver* PNekoDriver;
extern PNekoDriver theNekoDriver;

extern unsigned short lcdbuffaddr; // unused
extern unsigned short lcdbuffaddrmask;

extern unsigned keypadmatrix[8][8]; // char -> uint32

extern TScreenBuffer renderLCDBuffer;

#define TF_STACKOVERFLOW 0x1
#define TF_TIMER1_STOPED 0x2
#define TF_NMIFLAG 0x8
#define TF_IRQFLAG 0x10
#define TF_WATCHDOG 0x80

#endif
