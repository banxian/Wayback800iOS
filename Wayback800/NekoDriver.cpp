#include "NekoDriver.h"
#include "DBCentre.h"
extern "C" {
#ifdef HANDYPSP
#include "ANSI/w65c02.h"
#else
#include "ANSI/65C02.h"
#endif
}
#include "CC800IOName.h"
#include "NekoDriverIO.h"
#include "AddonFuncUnt.h" // GetTickCount
#include <unistd.h> // usleep
#include <stdio.h>
#include <TargetConditionals.h>
#include "AddonFuncUntObjc.h"
#include <assert.h>


TScreenBuffer renderLCDBuffer;

// Storage
PNekoDriver theNekoDriver;

TNekoDriver::TNekoDriver()
    : fEmulatorThread(NULL)
    , fNorBuffer(NULL)
    , fBROMBuffer(NULL)
    , fFlashUpdated(false)
    , fLCDBufferChangeCallback(NULL)
{
    // Do initialization that must be repeated for a restart
    restart = 0;

#ifdef USE_BUSROM
    fBROMBuffer = (char*)malloc(384 * 0x8000); // 32K * 128 * 3
    for (int i = 0; i < 128; i++) {
        // 0~128 
        volume0array[i] = (unsigned char*)fBROMBuffer + i * 0x8000;
        volume1array[i] = volume0array[i];
        volume2array[i] = volume0array[i];
        volume3array[i] = volume0array[i];

        volume0array[i + 128] = (unsigned char*)fBROMBuffer + (i + 128) * 0x8000;
        volume1array[i + 128] = volume0array[i + 128] + 128 * 0x8000;
    }
#else
    fBROMBuffer = (char*)malloc(512 * 0x8000); // 32K * 256 * 2
    for (int i = 0; i < 256; i++) {
        volume0array[i] = (unsigned char*)fBROMBuffer + i * 0x8000;
        volume1array[i] = volume0array[i] + 256 * 0x8000;
    }
#endif

    fNorBuffer = (char*)malloc(16 * 0x8000); // 32K * 16
    for (int i = 0; i < 16; i++) {
        norbankheader[i] = (unsigned char*)fNorBuffer + i * 0x8000;
    }

    //         DebugInitialize();
    MemInitialize();
    //         TermInitialize();
    //         FrameCreateWindow();

    // enter the main message loop
    //         EnterMessageLoop();

//     fEmulatorThread->start();
}


TNekoDriver::~TNekoDriver()
{
    if (fNorBuffer) {
        free(fNorBuffer);
        fNorBuffer = NULL;
    }
    if (fBROMBuffer) {
        free(fBROMBuffer);
        fBROMBuffer = NULL;
    }
}


//void TNekoDriver::onLCDBufferChanged( QByteArray* buffer )
//{
//    emit lcdBufferChanged(buffer);
//}

void TNekoDriver::SetLCDBufferChangedCallback(LCDBufferChangeCallback callback)
{
    fLCDBufferChangeCallback = callback;
    if (fEmulatorThread) {
        fEmulatorThread->SetLCDBufferChangedCallback(callback);
    }
}

bool TNekoDriver::StartEmulation()
{
    fEmulatorThread = new EmulatorThread(NULL, NULL);
    //connect(fEmulatorThread, SIGNAL(lcdBufferChanged(QByteArray*)),
    //    this, SLOT(onLCDBufferChanged(QByteArray*)));
    //fEmulatorThread->start(QThread::InheritPriority);
    fEmulatorThread->SetLCDBufferChangedCallback(fLCDBufferChangeCallback);
    fEmulatorThread->start();
    return true;
}

bool TNekoDriver::StopEmulation()
{
    if (fEmulatorThread) {
        fEmulatorThread->StopKeeping();
        //fEmulatorThread->wait(4000);
        //fEmulatorThread->deleteLater();
        fEmulatorThread = NULL;
        if (fFlashUpdated) {
            SaveFullNorFlash();
        }
        SaveFullSRAM();
    }
    return true;
}

bool TNekoDriver::RunDemoBin( const std::string& filename )
{
    if (filename.empty()) {
#ifdef USE_BUSROM
        // BROM dumped from real PC1000
        LoadBROM(GetResourcePath() + "/brom.bin");
#else
        // grab from ggv's emulator
        LoadBROM(GetResourcePath() + "/obj.bin");
#endif
        LoadFullNorFlash(GetDocumentsPath() + "/cc800.fls");
        LoadSRAM(GetDocumentsPath() + "/cc800.sram");
    } else {
        LoadDemoNor(filename);
        zpioregs[io00_bank_switch] = 1;
        SwitchNorBank(1);
        *(unsigned short*)&(pmemmap[mapE000][0x1FFC]) = 0x4018; // mario.bin
    }
    //fEmulatorThread->start(QThread::InheritPriority);
    StopEmulation();
    StartEmulation();
    return true;
}

bool TNekoDriver::PauseEmulation()
{
    return false;
}

bool TNekoDriver::ResumeEmulation()
{
    return false;
}



EmulatorThread::EmulatorThread( char* brom, char* nor )
    : fBROMBuffer(brom)
    , fNorBuffer(nor)
    , fKeeping(true)
    , fLCDBuffer(malloc(160*80/8))
    , fLCDBufferChangeCallback(NULL)
    , lastTicket(0)
    , totalcycle(0)
    , measured(false)
#ifdef AUTOTEST
    , remeasure(0)
#else
    , remeasure(2)
#endif
    , batchlimiter(0)
    , batchcount(UINT_MAX)
    , sleepgap(10)
    , sleepcount(0)
{

}

EmulatorThread::~EmulatorThread()
{
    free(fLCDBuffer);
}


extern WORD LogDisassembly (WORD offset, char* text);
extern void AppendLog(const char* text);

extern bool timer0run;
extern bool timer1run_tmie;
extern unsigned short gThreadFlags;


#if !TARGET_IPHONE_SIMULATOR
#define spdc1016freq 3686400
#endif


// WQXSIM
extern bool timer0waveoutstart;
extern int prevtimer0value;
int gDeadlockCounter = 0;
extern bool lcdoffshift0flag;
bool matrixupdated = false;
long nmicount = 0;
long twohznmicycle;

void CheckTimebaseSetTimer0IntStatusAddIRQFlag();
void CheckTimebaseAndSetIRQTBI();
void EnableWatchDogFlag();
void CheckSleepFlagAndForceWakeup();
bool KeepTimer01( unsigned int cpuTick );
bool KeepTimer01Fake( unsigned int cpuTick );


void EmulatorThread::run()
{
    // Load PC from Reset Vector
    CpuInitialize();
    CreateHotlinkMapping();
    lcdoffshift0flag = false;
    //g_stp = 1; // test
#ifndef FAKENMI
    unsigned int nmistart = GetTickCount();
#endif
    gThreadFlags &= 0xFFFEu; // Remove 0x01 from gThreadFlags (stack related)
#ifdef AUTOTEST
    unsigned totalline = 0; // TODO: long long
    enablelogging = false;
#endif
    while(fKeeping) {
#if TARGET_IPHONE_SIMULATOR
        const unsigned spdc1016freq = GlobalSetting.SPDC1016Frequency;
#endif
#ifdef FAMENMI
        twohznmicycle = spdc1016freq / 2;
#endif
        while (batchcount >= 0 && fKeeping) {
#ifdef AUTOTEST
            totalline++;
            TryTest(totalline);
#endif // AUTOTEST
#ifdef LOGASM
#ifdef AUTOTEST
            if (enablelogging) {
#endif
#ifdef HANDYPSP
                LogDisassembly(mPC, NULL);
#else
                LogDisassembly(regs.pc, NULL);
#endif // HANDYPSP
#ifdef AUTOTEST
            }
#endif // AUTOTEST
#endif // LOGASM
            if (matrixupdated) {
                matrixupdated = false;
                AppendLog("keypadmatrix updated.");
            }

            nmicount++; // MERGEASM
            // 2Hz NMI
            // TODO: use batchcount as NMI source
#ifdef FAKENMI
            if (nmicount % 400000 == 0) {
                nmicount = 0; // MERGEASM
            //if (twohznmicycle < 0) {
            //    twohznmicycle = spdc1016freq / 2; // reset
#else
            // in CC800 hardware, NMI is generated by 32.768k crystal, but spdc1016 use RC oscillator so cycle/NMI can be mismatched.
            unsigned int dummynow = GetTickCount();
            if (dummynow - nmistart >= 500) {
                nmistart += 500;
#endif
                //g_nmi = 0; // next CpuExecute will execute two instructions
                gThreadFlags |= 0x08; // Add NMIFlag
            }

            // NMI > IRQ
            if ((gThreadFlags & 0x08) != 0) {
                gThreadFlags &= 0xFFF7u; // remove 0x08 NMI Flag
                // FIXME: NO MORE REVERSE
                g_nmi = TRUE; // next CpuExecute will execute two instructions
                qDebug("ggv wanna NMI.");
                //fprintf(stderr, "ggv wanna NMI.\n");
                gDeadlockCounter--; // wrong behavior of wqxsim
#ifdef HANDYPSP
            } else if (((PS() & AF_INTERRUPT) == 0) && ((gThreadFlags & TF_IRQFLAG) != 0)) {
#else
            } else if (((regs.ps & 0x4) == 0) && ((gThreadFlags & 0x10) != 0)) {
#endif
                gThreadFlags &= 0xFFEFu; // remove 0x10 IRQ Flag
                g_irq = TRUE; // B flag (AF_BREAK) will remove in CpuExecute
                qDebug("ggv wanna IRQ.");
                gDeadlockCounter--; // wrong behavior of wqxsim
            }

            DWORD CpuTicks = CpuExecute();
            totalcycle += CpuTicks;
            twohznmicycle -= CpuTicks;
            // add checks for reset, IRQ, NMI, and other pin signals
            if (lastTicket == 0) {
                lastTicket = GetTickCount();
            }

            gDeadlockCounter++;
            bool needirq = false;
            if (gDeadlockCounter == 6000) {
                // overflowed
                gDeadlockCounter = 0;
                if ((gThreadFlags & 0x80u) == 0) {
                    // CheckTimerbaseAndEnableIRQnEXIE1
                    CheckTimebaseAndSetIRQTBI();
                    needirq = KeepTimer01(CpuTicks);
                } else {
                    // RESET
                    zpioregs[io01_int_enable] |= 0x1; // TIMER A INTERRUPT ENABLE
                    zpioregs[io02_timer0_val] |= 0x1; // [io01+1] Timer0 bit1 = 1
                    gThreadFlags &= 0xFF7F;      // remove 0x80 | 0x10
#ifdef HANDYPSP
                    mPC = *(unsigned short*)&pmemmap[mapE000][0x1FFC];
#else
                    regs.pc = *(unsigned short*)&pmemmap[mapE000][0x1FFC];
#endif
                }
            } else {
                needirq = KeepTimer01(CpuTicks);
                }
            
            if (needirq) {
                CheckTimebaseSetTimer0IntStatusAddIRQFlag();
            }
            
            // TODO: dynamic re-measure
            if (measured == false && totalcycle % spdc1016freq < 10 && totalcycle > spdc1016freq) {
                measured = true;
#if !TARGET_IPHONE_SIMULATOR
                // fixed rate on device
                // realworld time = 106
#ifdef HANDYPSP
                batchlimiter = spdc1016freq / 88; // 12*10=120ms
#else
                batchlimiter = spdc1016freq / 4;
#endif
                batchcount = batchlimiter;
#else
                if (totalcycle < spdc1016freq * 2) {
                    // first loop check!
                    // spdc1016 executed one second in fullspeed virtual timeline
                    unsigned long long realworldtime = GetTickCount() - lastTicket; // should less than 1000ms
                    lastTicket = GetTickCount();
                    //double virtual100ms = realworldtime / 100.0;
                    qDebug("realworldtime:%llu", realworldtime);
                    fprintf(stderr, "realworldtime:%llu\n", realworldtime);
                    if (realworldtime > 1000) {
                        // TODO: device may slower than simulator
                        // in my test iPad I get 3528/3779/3630 msec to finish one sdpc1016freq loop
                        // we should make screen refresh at least twice per real world second or screen will never been updated
                        // 1000->500 2000->250 4000->125
                        batchlimiter = 500 * spdc1016freq / realworldtime;
                        if (remeasure) {
                            qDebug("remeasure on batchlimiter: %u", batchlimiter);
                            fprintf(stderr, "remeasure on batchlimiter: %u\n", batchlimiter);
                            measured = false;
                            totalcycle = 0;
                            remeasure--;
                        }
                        batchcount = batchlimiter;
                    } else if (batchlimiter == 0) {
                        // 1000 - realworldtime = overflow time, overflow time / 10 = sleepcount, freq / sleepcount = batchcount
                        //batchlimiter = spdc1016freq / ((1000 - realworldtime) / 10);
                        sleepcount = (1000 - realworldtime) / sleepgap;
                        batchlimiter = spdc1016freq * sleepgap / (1000 - realworldtime);
                    } else {
                        // wrong path?
                        // sleep(0) is less than 10ms, but we'd never go here
                    }
                    batchcount = batchlimiter;
                } else {
                    // totalcycle > spdc1016freq * 2
                    // TODO:  check once more
                }
#endif // TARGET_IPHONE_SIMULATOR
            } // measured == false && totalcycle % spdc1016freq < 10 && totalcycle > spdc1016freq 
            if (totalcycle % spdc1016freq > 10 && totalcycle > spdc1016freq) {
                // FIXME: bug on slow device
                //measured = false;
            }

            if (batchlimiter != 0) {
                batchcount -= CpuTicks;
            }

            //usleep(10);
            //Sleep(0);
        }

        if (memcmp(&fixedram0000[lcdbuffaddr & lcdbuffaddrmask], fLCDBuffer, 160*80/8) != 0) {
            memcpy(fLCDBuffer, &fixedram0000[lcdbuffaddr & lcdbuffaddrmask], 160*80/8);
            qDebug("lcdBufferChanged");
            //fprintf(stderr, "lcdBufferChanged\n");
            //emit lcdBufferChanged(new QByteArray((const char*)fLCDBuffer, 160*80/8));
            memcpy(renderLCDBuffer.fPixel, fLCDBuffer, 160*80/8);
            if (fLCDBufferChangeCallback) {
                fLCDBufferChangeCallback();
            }
        }

        usleep(10000); // SleepGap. 10ms = 10us
        if (batchlimiter > 0) {
            batchcount = batchlimiter;
        } else {
            batchcount = spdc1016freq * 2; // dirty fix
        }
    }
    //this->deleteLater();
    RemoveHotlinkMapping();
}

void EmulatorThread::StopKeeping()
{
    fKeeping = false;
}

#ifdef AUTOTEST
void EmulatorThread::TryTest( unsigned line )
{
    // Network
    if (line == 1024000) {
        keypadmatrix[1][6] = 1;
        CheckSleepFlagAndForceWakeup();
    }
    if (line == 1064000) {
        keypadmatrix[1][6] = 0;
        CheckSleepFlagAndForceWakeup();
    }
    // Down
    if (line == 1224000) {
        keypadmatrix[6][3] = 1;
        CheckSleepFlagAndForceWakeup();
    }
    if (line == 1264000) {
        keypadmatrix[6][3] = 0;
        CheckSleepFlagAndForceWakeup();
    }
    // Enter
    if (line == 1424000) {
        keypadmatrix[6][5] = 1;
        CheckSleepFlagAndForceWakeup();
        enablelogging = true;
    }
    if (line == 1524000) {
        keypadmatrix[6][5] = 0;
        CheckSleepFlagAndForceWakeup();
    }
    // Splash
    if (line == 4724000) {
        keypadmatrix[6][5] = 1;
        CheckSleepFlagAndForceWakeup();
    }
    if (line == 4764000) {
        keypadmatrix[6][5] = 0;
        CheckSleepFlagAndForceWakeup();
    }
}
#endif
    
void EmulatorThread::start()
{
    // Create the thread using POSIX routines.
    pthread_attr_t  attr;
    
    int returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!returnVal);
    
    fKeeping = true;
    
    int threadError = pthread_create(&fThreadID, &attr, &EmulatorThread::OnTheadExecute, this);
    
    returnVal = pthread_attr_destroy(&attr);
    assert(!returnVal);
    
    if (threadError) {
        // Report an error.
    }
}

void* EmulatorThread::OnTheadExecute(void *data)
{
    EmulatorThread* that = (EmulatorThread*)data;
    that->run();
    return 0;
}

void EmulatorThread::SetLCDBufferChangedCallback(LCDBufferChangeCallback callback)
{
    fLCDBufferChangeCallback = callback;
}
    
void CheckSleepFlagAndForceWakeup()
{
    matrixupdated = true;
    if (lcdoffshift0flag) {
        // we don't have invert bit for row6,7
        //bool row67down = false;
        for (int y = 0; y < 2; y++) {
            for (int x = 0; x < 8; x++) {
                if (keypadmatrix[y][x] == 1) {
                    //row6,7down = true;
                    EnableWatchDogFlag();
                    lcdoffshift0flag = false;
                    return;
                }
            }
        }
    } else {
        /*
        if (keypadmatrix[0][2] == 1) {
            lcdoffshift0flag = true; // this flag is used for UI? (IO05_ClockControl)
        }*/
    }
}

void CheckTimebaseAndSetIRQTBI()
{
    if (zpioregs[io04_general_ctrl] & 0x0F) {
        gThreadFlags |= 0x10; // Add IRQ flag
        //irq = 0; // TODO: move to NMI check
        zpioregs[io01_int_status] |= 0x8; // TIMEBASE INTERRUPT
    }
}

void CheckTimebaseSetTimer0IntStatusAddIRQFlag()
{
    if ( zpioregs[io04_general_ctrl] & 0x0F )
    {
        gThreadFlags |= 0x10u; // Add 0x10 Flag to gThreadFlag
        //irq = 0; // TODO: move to 
        zpioregs[io01_int_status] |= 0x10u; // TIMER/COUNTER 0 INTERRUPT : TMODE0: TMI / TMODE1;3: TM0I
    }
}

void EnableWatchDogFlag()
{
    gThreadFlags |= 0x80;
}

// TODO: increase timer value by speed
// seems PC1000's rom never start timer0/1 in tracing
bool KeepTimer01( unsigned int cpuTick )
{
    bool needirq = false;
    // 0: no timerbase 1~15 = LN0,L0..L13
    unsigned char tbc = zpioregs[io04_general_ctrl] & 0xF;
    //if (tbc == 0) {
    //    return false;
    //}
    // proctimeer0 first
    if (timer0run) {
        timer0ticks += cpuTick;
        qDebug("timer0ticks: %d", timer0ticks);
        int mul0 = 1 + (w0c_b67_TMODESL == 1?w0c_b45_TM0S:w0c_b345_TMS);
        int inc0, inc1;
        inc0 = timer0ticks >> mul0;
        if (inc0) {
            timer0ticks -= inc0 << mul0;
        }
        if (w0c_b67_TMODESL == 1 || w0c_b67_TMODESL == 0) {
            // TODO: speed by CpuTicks
            unsigned short newt = zpioregs[io02_timer0_val] + inc0;
            bool overflow = newt > 0xFF;
            if (overflow) {
                if (w0c_b67_TMODESL == 1) {
                    _ADD_TM0I_BIT();
                    needirq = true;
                } else if (timer1run_tmie) {
                    _ADD_TM0I_BIT();
                    needirq = true;
                }
            }
            zpioregs[io02_timer0_val] = w0c_b67_TMODESL==1?newt:newt + zpioregs[io03_timer1_val]; // as reload value
        }
        // 16bit
        if (w0c_b67_TMODESL == 2) {
            unsigned short newt = zpioregs[io02_timer0_val] + inc0;
            zpioregs[io02_timer0_val] = newt;
            bool overflow = newt > 0xFF;
            if (overflow) {
                unsigned short newt1 = zpioregs[io03_timer1_val] + (newt >> 8);
                if (newt1 > 0xFF) {
                    _ADD_TM1I_BIT();
                    needirq = true;
                }
                zpioregs[io03_timer1_val] = newt1;
            }
        }
        if (w0c_b67_TMODESL == 3) {
            unsigned short newt = zpioregs[io02_timer0_val] + inc0;
            zpioregs[io02_timer0_val] = newt;
            bool overflow = newt > 0xFF;
            if (overflow) {
                _ADD_TM0I_BIT();
                needirq = true;
                if (timer1run_tmie) {
                    unsigned short newt1 = zpioregs[io03_timer1_val] + (newt >> 8);
                    if (newt1 > 0xFF) {
                        _ADD_TM1I_BIT();
                        needirq = true;
                    }
                    zpioregs[io03_timer1_val] = newt1;
                }
            }

        }
    }
    // timer 1 next, only mode1
    if (timer1run_tmie && w0c_b67_TMODESL == 1) {
        timer1ticks += cpuTick;
        qDebug("timer1ticks: %d", timer1ticks);

        int inc1 = timer1ticks >> (1 + w0c_b23_TM1S);
        if (inc1) {
            timer1ticks -= inc1 << (1 + w0c_b23_TM1S);
        }
        unsigned short newt = zpioregs[io03_timer1_val] + inc1;
        zpioregs[io03_timer1_val] = newt;
        bool overflow = newt > 0xFF;
        if (overflow) {
            _ADD_TM1I_BIT();
            needirq = true;
        }
    }
    return needirq;
}
