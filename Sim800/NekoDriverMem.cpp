#include "NekoDriver.h"
#include "wintypes.h"
extern "C" {
#ifdef HANDYPSP
#include "ANSI/w65c02.h"
#else
#include "ANSI/65C02.h"
#endif
}
#include <QtCore/QFile>
#include "CC800IOName.h"
#include "NekoDriverIO.h"


iofunction1 ioread[0x40]  = {
    Read00BankSwitch,       // $00
    Read01IntStatus,       // $01
    NullRead,       // $02
    NullRead,       // $03
    Read04StopTimer0,     // $04
    Read05StartTimer0,    // $05
    Read06StopTimer1,     // $06
    Read07StartTimer1,    // $07
    ReadPort0,      // $08
    ReadPort1,      // $09
    NullRead,       // $0A
    NullRead,       // $0B
    NullRead,       // $0C
    NullRead,       // $0D
    NullRead,       // $0E
    NullRead,       // $0F
    NullRead,       // $10
    NullRead,       // $11
    NullRead,       // $12
    NullRead,       // $13
    NullRead,       // $14
    NullRead,       // $15
    NullRead,       // $16
    NullRead,       // $17
    Read18Port4,       // $18
    NullRead,       // $19
    NullRead,       // $1A
    NullRead,       // $1B
    NullRead,       // $1C
    NullRead,       // $1D
    NullRead,       // $1E
    NullRead,       // $1F
    NullRead,       // $20
    NullRead,       // $21
    NullRead,       // $22
    NullRead,       // $23
    NullRead,       // $24
    NullRead,       // $25
    NullRead,       // $26
    NullRead,       // $27
    NullRead,       // $28
    NullRead,       // $29
    NullRead,       // $2A
    NullRead,       // $2B
    NullRead,       // $2C
    NullRead,       // $2D
    NullRead,       // $2E
    NullRead,       // $2F
    NullRead,       // $30
    NullRead,       // $31
    NullRead,       // $32
    NullRead,       // $33
    NullRead,       // $34
    NullRead,       // $35
    NullRead,       // $36
    NullRead,       // $37
    NullRead,       // $38
    NullRead,       // $39
    NullRead,       // $3A
    NullRead,       // $3B
    NullRead,       // $3C
    NullRead,       // $3D
    NullRead,       // $3E
    NullRead,       // $3F
};

iofunction2 iowrite[0x40] = {
    Write00BankSwitch,          // $00
    Write01IntEnable,      // $01
    NullWrite,          // $02 Timer0不需特殊处理
    NullWrite,          // $03 Timer1也不须?
    Write04GeneralCtrl,      // $04
    Write05ClockCtrl,           // $05
    Write06LCDStartAddr,        // $06
    Write07PortConfig,      // $07
    Write08Port0,               // $08
    Write09Port1,               // $09
    Write0AROABBS,                // $0A
    NullWrite,      // $0B
    WriteTimer01Control,        // $0C
    Write0DVolumeIDLCDSegCtrl,  // $0D
    NullWrite,      // $0E
    WriteZeroPageBankswitch,    // $0F
    NullWrite,      // $10
    NullWrite,      // $11
    NullWrite,      // $12
    NullWrite,      // $13
    NullWrite,      // $14
    Write15Dir1,               // $15
    NullWrite,      // $16
    NullWrite,      // $17
    Write18Port4,      // $18
    Write19CkvSelect,      // $19
    NullWrite,      // $1A
    NullWrite,      // $1B
    NullWrite,      // $1C
    NullWrite,      // $1D
    NullWrite,      // $1E
    NullWrite,      // $1F
    Write20JG,      // $20
    NullWrite,      // $21
    NullWrite,      // $22
    NullWrite,      // $23
    NullWrite,      // $24
    NullWrite,      // $25
    NullWrite,      // $26
    NullWrite,      // $27
    NullWrite,      // $28
    NullWrite,      // $29
    NullWrite,      // $2A
    NullWrite,      // $2B
    NullWrite,      // $2C
    NullWrite,      // $2D
    NullWrite,      // $2E
    NullWrite,      // $2F
    NullWrite,      // $30
    NullWrite,      // $31
    NullWrite,      // $32
    NullWrite,      // $33
    NullWrite,      // $34
    NullWrite,      // $35
    NullWrite,      // $36
    NullWrite,      // $37
    NullWrite,      // $38
    NullWrite,      // $39
    NullWrite,      // $3A
    NullWrite,      // $3B
    NullWrite,      // $3C
    NullWrite,      // $3D
    NullWrite,      // $3E
    NullWrite,      // $3F
};

regsrec regs;
// LPBYTE  mem          = NULL;
unsigned char fixedram0000[0x10002]; // just like simulator
unsigned char* pmemmap[8]; // 0000~1FFF ... E000~FFFF
unsigned char* may4000ptr;
unsigned char* norbankheader[0x10];
unsigned char* volume0array[0x100]; // even volume
unsigned char* volume1array[0x100]; // odd volume
#ifdef USE_BUSROM
unsigned char* volume2array[0x100];
unsigned char* volume3array[0x100];
#endif
unsigned char* bbsbankheader[0x10];


// WQXSIM
extern bool timer0waveoutstart;
extern int prevtimer0value;
extern unsigned short gThreadFlags;
extern unsigned char* gGeneralCtrlPtr;
extern unsigned short mayGenralnClockCtrlValue;

void FillC000BIOSBank(unsigned char** array);
void InitRAM0IO();


void MemDestroy () {

}

void MemInitialize ()
{
    memset(&fixedram0000[0], 0, 0x10002);
    zp40ptr = &fixedram0000[0x40];

    qDebug("RESET will jump to 0x0418 in norflash page1.");

    MemReset();
    InitRAM0IO();
}


void MemReset ()
{
    pmemmap[map0000] = &fixedram0000[0];
    pmemmap[map2000] = &fixedram0000[0x2000];
    pmemmap[map4000] = &fixedram0000[0x4000];
    pmemmap[map6000] = &fixedram0000[0x6000];
    pmemmap[map8000] = &fixedram0000[0x8000];
    pmemmap[mapA000] = &fixedram0000[0xA000];
    pmemmap[mapC000] = &fixedram0000[0xC000];
    pmemmap[mapE000] = &fixedram0000[0xE000];

    // InitInternalAddress
    theNekoDriver->InitInternalAddrs();

    // Initialize the cpu
    CpuInitialize(); // Read pc from reset vector
#ifdef HANDYPSP
    setPS(0x24);
#else
    regs.ps = 0x24; // 00100100 unused P(bit5) = 1, I(bit3) = 1, B(bit4) = 0
#endif
}

void InitRAM0IO() 
{
   memset(zpioregs, 0, sizeof(zpioregs));
    zpioregs[io1B_pwm_data] = 0;
    zpioregs[io01_int_status] = 0; 
    w01_int_enable = 0; // Enable all IRQ int
    zpioregs[io04_general_ctrl] = 0;
    zpioregs[io05_clock_ctrl] = 0;
    gThreadFlags = 0;
    //zpioregs[io08_port0_data] = 0;
    r08_port0_ID = 0;
    w08_port0_OL = 0;
    zpioregs[io00_bank_switch] = 0;
    //zpioregs[io09_port1_data] = 0;
    r09_port1_ID = 0;
    w08_port0_OL = 0;
}

// TODO: iofunction?
unsigned char GetByte( unsigned short address )
{
    //unsigned int row = address / 0x2000; // SHR
    //return *(pmemmap[row] + address % 0x2000);
    unsigned int row = address >> 0xD; // 0000 0000 0000 0111 0~7
    return *(pmemmap[row] + (address & 0x1FFF)); // 0001 1111 1111 1111
}

unsigned short GetWord( unsigned short address )
{
    unsigned char low = GetByte(address);
    unsigned char high = GetByte(address == 0xFFFF?0:address + 1);
    return ((high << 8) | low);
}

void SetByte( unsigned short address, unsigned char value )
{
    unsigned int row = address / 0x2000; // SHR
    *(pmemmap[row] + address % 0x2000) = value;
}

BYTE __iocallconv NullRead (BYTE address) {
    //qDebug("ggv wanna read io, [%04x] -> %02x", address, mem[address]);
    return zpioregs[address];
}

void __iocallconv NullWrite(BYTE address, BYTE value) {
    //qDebug("ggv wanna write io, [%04x] (%02x) -> %02x", address, mem[address], value);
    zpioregs[address] = value;
}


void TNekoDriver::InitInternalAddrs()
{
    FillC000BIOSBank(volume0array);
    pmemmap[mapC000] = bbsbankheader[0];
    may4000ptr = volume0array[0];
    // E000~FFFF stores jsr E006 (and almost nmi/irq/reset handler)
    pmemmap[mapE000] = volume0array[0] + 0x2000; // lea     ecx, [eax+2000h]
    Switch4000toBFFF(0);

    //mayGenralnClockCtrlValue = 0;
    //regs.sp = 0x100;

    //b5 :  BOUT   : Battery detect output of level 1
    //b3 :  AUTOBRK: Battery detect output of level 2
    zpioregs[io0C_general_status] = 0x28; // ([0C] & 3) * 1000 || [06] * 10 = LCDAddr
}


void __iocallconv Write00BankSwitch( BYTE write, BYTE bank )
{
    //qDebug("ggv wanna switch to bank 0x%02x", bank);
    //theNekoDriver->SwitchNorBank(value);
    if (zpioregs[io0A_roa] & 0x80) {
        // ROA == 1
        // RAM (norflash?!)
        char norbank = bank & 0xF; // nor only have 0~F page
        may4000ptr = norbankheader[norbank];
        theNekoDriver->Switch4000toBFFF(norbank);
    } else {
        // ROA == 0
        // BROM
        if (zpioregs[io0D_volumeid] & 1) {
            // VolumeID == 1, 3
            may4000ptr = volume1array[bank];
            theNekoDriver->Switch4000toBFFF(bank);
        } else {
            // VolumeID == 0, 2
            may4000ptr = volume0array[bank];
            theNekoDriver->Switch4000toBFFF(bank);
        }
    }
    // update at last
    zpioregs[io00_bank_switch] = bank;
    (void) write;
}

BYTE __iocallconv Read00BankSwitch( BYTE )
{
    BYTE r = zpioregs[io00_bank_switch];
    //qDebug("ggv wanna read bank. current bank 0x%02x", r);
    return r;
}

void FillC000BIOSBank(unsigned char** array) {
    //DWORD *result; // eax@4
    //signed int i; // edx@4
    //DWORD **maybank5addr; // ecx@4
    //DWORD *volumexpage1addr; // esi@5

    //gBBSBankHeader[0] = (char *)*array;           // bank[0] = array[0];
    //if ( gFixedRAM0[(unsigned __int8)io0D_lcd_segment_volumeID] & 1 )
    //    // Volume1
    //    gBBSBank1 = (int)(g_pNorBankHeader + 2048); // 43BF28[0] + 800*4
    //// bank[1] = nor[0] + 0x2000;
    //else
    //    // Volume0
    //    // C000~DFFF is shadow of RAM4000~5FFF?
    //    gBBSBank1 = (int)&gFixedRAM4000;            // bank[1] = &ram[0x4000];
    //gBBSBank2 = *array + 0x4000;                  // bank[2] = array[0] + 0x4000;
    //result = array + 1;
    //gBBSBank3 = *array + 0x6000;                  // bank[3] = array[0] + 0x6000;
    //maybank5addr = (DWORD **)&gBBSBank5;
    //i = 3;
    //do
    //{
    //    volumexpage1addr = (DWORD *)*result;        // page1addr = array[1];
    //    ++result;                                   // result = array[2]
    //    *(maybank5addr - 1) = volumexpage1addr;     // bank[4*] = array[1*]
    //    *maybank5addr = (DWORD *)(*(result - 1) + 0x2000);// bank[5*] = array[1*] + 0x2000;
    //    maybank5addr[1] = (DWORD *)(*(result - 1) + 0x4000);// bank[6*] = array[1*] + 0x4000;
    //    maybank5addr[2] = (DWORD *)(*(result - 1) + 0x6000);// bank[7*] = array[1*] + 0x6000;
    //    maybank5addr += 4;
    //    --i;                                        // bank+=4;
    //    // array+=1;
    //    // pass2 8,9,A,B pass3 C,D,E,F
    //}
    //while ( i );
    //return result;
    bbsbankheader[0] = array[0];
    if (zpioregs[io0D_volumeid] & 1) {
        // Volume1,3
        bbsbankheader[1] = norbankheader[0] + 0x2000;
    } else {
        // Volume0,2
        bbsbankheader[1] = &fixedram0000[0x4000];
    }
    bbsbankheader[2] = array[0] + 0x4000;
    bbsbankheader[3] = array[0] + 0x6000;
    for (int i = 0; i < 3; i++)
    {
        // 4567, 89AB, CDEF take first 4page 0000~7FFF in BROM
        bbsbankheader[i * 4 + 4] = array[i + 1];
        bbsbankheader[i * 4 + 5] = array[i + 1] + 0x2000;
        bbsbankheader[i * 4 + 6] = array[i + 1] + 0x4000;
        bbsbankheader[i * 4 + 7] = array[i + 1] + 0x6000;
    }
}

void __iocallconv Write0AROABBS( BYTE write, BYTE value )
{
    //char bank; // al@3
    //DWORD addr4000; // edx@3

    //if ( tmpAXYValue != mayPrevDestAddrValue )
    //{
    //    // Update memory pointers only on value changed
    //    if ( tmpAXYValue & 0x80 )
    //    {
    //        // 0A[7] == 1
    //        // RAM
    //        bank = (unsigned __int8)gFixedRAM0[io00_bank_switch] % 16;// bank = 0~F
    //        addr4000 = (DWORD)(&g_pNorBankHeader)[(unsigned __int8)bank];
    //    }
    //    else
    //    {
    //        // 0A[7] == 0
    //        // Nor flash or BROM?
    //        bank = gFixedRAM0[io00_bank_switch];// bank read from 00
    //        if ( gFixedRAM0[io0D_lcd_segment_volumeID] & 1 )
    //            // b0 VSL0 == 1 (Volume select bit0)
    //            // Volume1,3
    //            // LPDWORD Volume1Array[0x100];
    //            addr4000 = *(&gVolume1Array + (unsigned __int8)gFixedRAM0[io00_bank_switch]);
    //        else
    //            // b0 VSL0 == 0 (Volume select bit0)
    //            // Volume0,2
    //            // LPDWORD Volume0Array[0x100];
    //            addr4000 = *(&gVolume0Array + (unsigned __int8)gFixedRAM0[io00_bank_switch]);
    //    }
    //    may4000ptr = addr4000;
    //    Switch4000_BFFF(bank);                  // Fill lpRAM[2..5]
    //    g__pRAMC000 = gBBSBankHeader[tmpAXYValue & 0xF];// bit0~bit3 = BBS0~BBS3
    //    // bios bank switch (C000~DFFF)
    //}
    if (value != zpioregs[io0A_roa]) {
        // Update memory pointers only on value changed
        unsigned char bank;
        if (value & 0x80u) {
            // ROA == 1
            // RAM (norflash)
            bank = (zpioregs[io00_bank_switch] & 0xF); // bank = 0~F
            may4000ptr = norbankheader[bank];
        } else {
            // ROA == 0
            // ROM (MASKROM/BUSROM)
            bank = zpioregs[io00_bank_switch];
            if (zpioregs[io0D_volumeid] & 1) {
                // Volume1,3
                may4000ptr = volume1array[bank];
            } else {
                // Volume0,2
                may4000ptr = volume0array[bank];
            }
        }
        zpioregs[io0A_roa] = value;
        theNekoDriver->Switch4000toBFFF(bank);
        pmemmap[mapC000] = bbsbankheader[value & 0xF];
    }
    // in simulator destination memory is updated before call WriteIO0A_ROA_BBS
    //fixedzpiocache[io0A_roa] = value;
    (void)write;
}

// TODO: bank0~127 and bank128~255 to different array
void __iocallconv Write0DVolumeIDLCDSegCtrl(BYTE write, BYTE value)
{
    // b76543 = lcd
    unsigned short lcdwidth = value >> 3;
    if (lcdwidth == 0) {
        lcdwidth |= 0x20;
    }
    lcdwidth <<= 4;
    if (value ^ zpioregs[io0D_volumeid] & 1) {
        // bit0 changed.
        // volume1,3 != volume0,2
        unsigned char bank = zpioregs[io00_bank_switch];
        if (value & 1) {
            // Volume1,3
            FillC000BIOSBank(volume1array);
            may4000ptr = volume1array[bank];
            pmemmap[mapE000] = volume1array[0] + 0x2000;
        } else {
            // Volume0.2
            FillC000BIOSBank(volume0array);
            may4000ptr = volume0array[bank];
            pmemmap[mapE000] = volume0array[0] + 0x2000;
        }
        unsigned char roabbs = zpioregs[io0A_roa];
        if (roabbs & 0x80) {
            // ROA == 1
            // RAM(nor)
            bank = bank & 0x0F;
            may4000ptr = norbankheader[bank];
        }
        pmemmap[mapC000] = bbsbankheader[roabbs & 0x0F];
        theNekoDriver->Switch4000toBFFF(bank);
    }
    zpioregs[io0D_volumeid] = value;
    (void)write;
}

// unsigned char zp40cache[0x40]; // the real storage for built-in sram 0x00~0x3F

unsigned char* GetZeroPagePointer(unsigned char bank) {
    unsigned char* result;

    if (bank >= 4) {
        // 4,5,6,7
        // 4 -> 200 5-> 240
        // 6 -> 280 7 -> 2C0
        result = &fixedram0000[(bank + 4) << 6];
    } else {
        // 1,2,3
        result = &fixedram0000[0];
    }
    return result;
}

unsigned char* zp40ptr;

void __iocallconv WriteZeroPageBankswitch (BYTE write, BYTE value)
{
    unsigned char oldzpbank = zpioregs[io0F_zp_bsw] & 7;
    unsigned char newzpbank = value & 7;
    if (oldzpbank != newzpbank) {
        if (newzpbank == 0) {
            zp40ptr = &fixedram0000[0x40];
        } else {
            zp40ptr = GetZeroPagePointer(newzpbank);
        }
    }
    zpioregs[io0F_zp_bsw] = value;
    rw0f_b4_DIR00 = (value & 0x10) != 0;
    rw0f_b5_DIR01 = (value & 0x20) != 0;
    rw0f_b6_DIR023 = (value & 0x40) != 0;
    rw0f_b7_DIR047 = (value & 0x80) != 0;
    (void)write;
}

void TNekoDriver::SwitchNorBank( int bank )
{
    // TODO: norbank header
    zpioregs[io0A_roa] = zpioregs[io0A_roa] | 0x80u;
    //memcpy(&fixedram0000[0x4000], &fNorBuffer[bank * 0x8000], 0x8000);
    pmemmap[map4000] = (unsigned char*)&fNorBuffer[bank * 0x8000]; // 4000
    pmemmap[map6000] = (unsigned char*)&fNorBuffer[bank * 0x8000 + 0x2000]; // 6000
    pmemmap[map8000] = (unsigned char*)&fNorBuffer[bank * 0x8000 + 0x4000]; // 8000
    pmemmap[mapA000] = (unsigned char*)&fNorBuffer[bank * 0x8000 + 0x6000]; // A000
}

void TNekoDriver::Switch4000toBFFF( unsigned char bank )
{
    //void *addr6000; // ecx@4
    //DWORD result; // eax@7

    //if ( bank || gFixedRAM0[(unsigned __int8)io0A_bios_bsw_roa] & 0x80 )
    //{
    //    // bank != 0 || ROA == RAM
    //    g__pRAM4000 = (void *)may4000ptr;
    //    addr6000 = (void *)(may4000ptr + 0x2000);
    //}
    //else
    //{
    //    // bank == 0 && ROA == ROM
    //    if ( gFixedRAM0[(unsigned __int8)io0D_lcd_segment_volumeID] & 1 )
    //    {
    //        // Volume1
    //        g__pRAM4000 = g_pNorBankHeader;
    //        addr6000 = g_pNorBankHeader + 2048;       // 43BF28 + 2000 = 43DF28 (800*4)
    //    }
    //    else
    //    {
    //        // Volume0
    //        // 6000~7FFF is mirror of 4000~5FFF
    //        addr6000 = &gFixedRAM4000;
    //        g__pRAM4000 = &gFixedRAM4000;
    //    }
    //}
    //result = may4000ptr + 0x6000;
    //g__pRAM6000 = addr6000;
    //g__pRAM8000 = may4000ptr + 0x4000;
    //g__pRAMA000 = may4000ptr + 0x6000;

    if (bank != 0 || zpioregs[io0A_roa] & 0x80) {
        // bank != 0 || ROA == RAM
        pmemmap[map4000] = may4000ptr;
        pmemmap[map6000] = may4000ptr + 0x2000;
    } else {
        // bank == 0 && ROA == ROM
        if (zpioregs[io0D_volumeid] & 0x1) {
            // Volume1,3
            // 4000~7FFF is 0 page of Nor.
            // 8000~BFFF is relative to may4000ptr
            pmemmap[map4000] = norbankheader[0];
            pmemmap[map6000] = norbankheader[0] + 0x2000;
        } else {
            // Volume0,2
            // 4000~5FFF is RAM
            // 6000~7FFF is mirror of 4000~5FFF
            pmemmap[map4000] = &fixedram0000[0x4000];
            pmemmap[map6000] = &fixedram0000[0x4000];
        }
    }
    pmemmap[map8000] = may4000ptr + 0x4000;
    pmemmap[mapA000] = may4000ptr + 0x6000;
}

void checkflashprogram(WORD addr16, BYTE data)
{
    unsigned char* lpaddr16ram = &pmemmap[addr16 >> 13][addr16 & 0x1FFF];
    if ((lpaddr16ram >= &fixedram0000[0x4000]) && (lpaddr16ram < &fixedram0000[0x6000])) {
        // Real physics memory inside 4000~5FFF
        *lpaddr16ram = data;
        return;
    }
    // consider addr16 >= 0x4000, and is not fixed ram
    // goto label_checkregister is not necessary now
    if (addr16 < 0xC000u && zpioregs[io0A_roa] && 0x80u) {
        // addr16 inside 4000~BFFF and ROA is RAM(norflash)
        theNekoDriver->CheckFlashProgramming(addr16, data);
    }
}

bool TNekoDriver::LoadDemoNor(const QString& filename)
{
    QFile mariofile(filename);
    mariofile.open(QFile::ReadOnly);
    int page = 1;
    while (mariofile.atEnd() == false) {
        mariofile.read(fNorBuffer + 0x8000 * page + 0x4000, 0x4000);
        mariofile.read(fNorBuffer + 0x8000 * page, 0x4000);
        page++;
    }

    mariofile.close();
    return true;
}

bool TNekoDriver::LoadBROM( const QString& filename )
{
    QFile romfile(filename);
    romfile.open(QFile::ReadOnly);
    // TODO: use proper separate mapper for 0~127 and 128~255
    int page = 0;
#ifdef USE_BUSROM
    while (romfile.atEnd() == false) {
        romfile.read(fBROMBuffer + 0x8000 * page + 0x4000, 0x4000);
        romfile.read(fBROMBuffer + 0x8000 * page, 0x4000);
        page++;
    }
#else
    while (romfile.atEnd() == false) {
        romfile.read(fBROMBuffer + 0x8000 * page + 0x4000, 0x4000);
        romfile.read(fBROMBuffer + 0x8000 * page, 0x4000);
        page++;
    }
    if (page < 0x200) {
        // PC1000a
        for (int i = page - 1; i < 256; i++) {
            volume1array[i] = volume1array[0];
        }
    }
#endif
    return true;
}

bool TNekoDriver::LoadFullNorFlash( const QString& filename )
{
    fNorFilename = filename;
    QFile norfile(filename);
    norfile.open(QFile::ReadOnly);

    int page = 0;
    while (norfile.atEnd() == false) {
        norfile.read(fNorBuffer + 0x8000 * page + 0x4000, 0x4000);
        norfile.read(fNorBuffer + 0x8000 * page, 0x4000);
        page++;
    }
    norfile.close();
    fFlashUpdated = false;
    return true;
}

bool TNekoDriver::SaveFullNorFlash()
{
    QFile norfile(fNorFilename);
    norfile.open(QFile::WriteOnly);
    int page = 0;
    while (page < 0x10) {
        norfile.write(fNorBuffer + 0x8000 * page + 0x4000, 0x4000);
        norfile.write(fNorBuffer + 0x8000 * page, 0x4000);
        page++;
    }
    norfile.close();
    fFlashUpdated = false;
    return true;
}

unsigned char gNor5555_AAFlag = 0, gNorAAAA_AAFlag = 0, gNor8555_AAFlag = 0;
unsigned char gNorSingleByteStep = 0, gNorPageEraseStep = 0;
unsigned char gPrevNor8000 = 0, gPrevNor8001 = 0;
int gErasePos = 0, gEraseBlockAddr = 0;

void TNekoDriver::CheckFlashProgramming( unsigned short addr16, unsigned char data )
{
    //qDebug("ggv wanna erase flash!");
    // TODO: rewrite to only support SST/BSI flash
    // consider addr16 >= 0x4000, and is not fixed ram
    // goto label_checkregister is not necessary now
    // addr16 inside 4000~BFFF and ROA is RAM(norflash)
    unsigned char nor5555_AAflag = gNor5555_AAFlag;
    // first step
    if ( !gNorSingleByteStep && !gNor5555_AAFlag )
    {
        if ( !gNorAAAA_AAFlag && !gNor8555_AAFlag )
        {
            if ( !gNorPageEraseStep )
            {
                switch ( addr16 )
                {
                case 0x8555:
                    if ( data == 0xAA )
                        gNor8555_AAFlag = 1;
                    break;
                case 0x5555:
                    if ( data == 0xAA )
                    {
                        gNor5555_AAFlag = 1;
                        gNorSingleByteStep = 1;
                        gNorPageEraseStep = 1;
                    }
                    break;
                case 0xAAAA:
                    if ( data == 0xAA )
                        gNorAAAA_AAFlag = 1;
                    break;
                }
                return; //goto label_checkregister;
            }
            goto label_checkpageerase;
        }
        nor5555_AAflag = gNor5555_AAFlag;
    }
    // read ID step (AMD)
    if ( gNor8555_AAFlag )
    {
        // dead code
        // assume every nor operation is start with 5555<-AA
        switch ( gNor8555_AAFlag )
        {
        case 1:
            if ( addr16 == 0x82AA && data == 0x55 )
            {
                gNor8555_AAFlag = 2;
                return; //goto label_checkregister;
            }
            break;
        case 2:
            if ( addr16 == 0x8555 && data == 0x90 )
            {
                gNor8555_AAFlag = 3;
                return; //goto label_checkregister;
            }
            break;
        case 3:
            if ( addr16 == 0xAAAA && data == 0xAA )
            {
                gNor8555_AAFlag = 4;
                return; //goto label_checkregister;
            }
            break;
        case 4:
            if ( addr16 == 0x5555 && data == 0x55 )
            {
                gNor8555_AAFlag = 5;
                return; //goto label_checkregister;
            }
            break;
        case 5:
            if ( addr16 == 0xAAAA && data == 0xA0 )
            {
                gNor8555_AAFlag = 6;
                return; //goto label_checkregister;
            }
            break;
        default:
            if ( gNor8555_AAFlag == 6 && addr16 == 0x8000 && data == 0xF0 )
            {
                gNor8555_AAFlag = 0;
                return; //goto label_checkregister;
            }
            break;
        }
        qDebug("error occurs when read AMD id!");
        return; //goto label_printerr_DestToAddr16_checkregister;
    }
    // read ID step (ST)
    if ( gNorAAAA_AAFlag )
    {
        // assume every nor operation is start with 5555<-AA
        if ( gNorAAAA_AAFlag == 1 )
        {
            // we have an AAAA<-AA
            if ( addr16 == 0x5555 && data == 0x55 )
            {
                gNorAAAA_AAFlag = 2;        // 2 means AAAA<-AA, AAAA<-55
                return; //goto label_checkregister;
            }
        }
        else
        {
            if ( gNorAAAA_AAFlag == 2 )
            {
                // we have two AAAA<-AA, AAAA<-55
                if ( addr16 == 0xAAAA && data == 0x90 )
                {
                    gNorAAAA_AAFlag = 3;    // 3 means AAAA<-AA, AAAA<-55, AAAA<-90
                    return; //goto label_checkregister;
                }
            }
            else
            {
                if ( gNorAAAA_AAFlag == 3 && addr16 == 0x8000 && data == 0xF0 )
                {
                    gNorAAAA_AAFlag = 0;    // reset
                    return; //goto label_checkregister;
                }
            }
        }
        qDebug("error occurs when read ST id!");
        return; //goto label_printerr_DestToAddr16_checkregister;
    }
    // normal second step check
    switch ( nor5555_AAflag )
    {
    case 1:
        // we have an nice 5555<-AA step
        if ( addr16 == 0xAAAA && data == 0x55 )
        {
            gNor5555_AAFlag = 2;        // 2 means 5555<-AA, AAAA<-55
            ++gNorPageEraseStep;
            ++gNorSingleByteStep;
            return; //goto label_checkregister;
        }
        break;
    case 2:
        if ( addr16 == 0x5555 && data == 0x90 )
        {
            // Modify 8000 in bank1
            //gPrevNor8000 = *(unsigned char *)(norbankheader[1] + 0x4000);
            //gPrevNor8001 = *(unsigned char *)(norbankheader[1] + 0x4001);
            //*(unsigned char *)(norbankheader[1] + 0x4000) = 0xBFu;
            //*(unsigned char *)(norbankheader[1] + 0x4001) = 0xD7u;
            qDebug("ggv wanna update bank1 8000 flash!");
            gPrevNor8000 = norbankheader[1][0x4000];
            gPrevNor8001 = norbankheader[1][0x4001];
            norbankheader[1][0x4000] = 0xBFu;
            norbankheader[1][0x4001] = 0xD7u;
            gNorPageEraseStep = 0;
            ++gNor5555_AAFlag;          // 3 means 5555<-AA, AAAA<-55, 5555<-90
            gNorSingleByteStep = 0;
            return; //goto label_DestToAddr16_checkregister;
        }
        break;
    case 3:
        //mayDestAddr = 0x8000u;          // Check range, dead condtion
        if ( data == 0xF0 )
        {
            // Restore 8000 in bank1
            //*(unsigned char *)(norbankheader[1] + 0x4000) = gPrevNor8000;
            //*(unsigned char *)(norbankheader[1] + 0x4001) = gPrevNor8001;
            qDebug("ggv wanna restore bank1 8000 flash!");
            norbankheader[1][0x4000] = gPrevNor8000;
            norbankheader[1][0x4001] = gPrevNor8001;
            gNor5555_AAFlag = 0;        // Finish!
            return; //goto label_DestToAddr16_checkregister;
        }
        qDebug("error occurs when read SST id!");
        return; //goto label_printerr_DestToAddr16_checkregister;
    }
    if ( gNorSingleByteStep == 2 )
    {
        if ( addr16 == 0x5555 && data == 0xA0 )
        {
            gNorSingleByteStep = 3;         // Single byte last check
            gNor5555_AAFlag = 0;            // Finish!
            gNorPageEraseStep = 0;
            return; //goto label_checkregister;
        }
    }
    else
    {
        if ( gNorSingleByteStep == 3 )
        {
            // Single byte mode write step
            // use &= because only can write on dest addr is earse to FF
            //*(unsigned char *)((unsigned __int16)addr16 + may4000ptr - 0x4000) &= data;
            // addr16 = 4000~BFFF -> 0000~7FFF
            qDebug("ggv wanna change single byte flash!");
            unsigned char norbank = zpioregs[io00_bank_switch] & 0xF;
            norbankheader[norbank][addr16 - 0x4000] &= data;
            gNorSingleByteStep = 0;
            fFlashUpdated = true;
            return; //goto label_DestToAddr16_checkregister;
        }
    }
label_checkpageerase:
    if ( gNorPageEraseStep == 2 )
    {
        if ( addr16 == 0x5555 && data == 0x80 )
        {
            // Step3 of PAGE ERASE
            gNorPageEraseStep = 3;
            gNor5555_AAFlag = 0;
            gNorSingleByteStep = 0;
            return; //goto label_checkregister;
        }
    }
    else
    {
        // gNorFlag0 != 2
        if ( (unsigned char)gNorPageEraseStep > 2u )
        {
            // Check ERASE mode
            switch ( gNorPageEraseStep )
            {
            case 3:
                if ( addr16 == 0x5555 && data == 0xAA )
                {
                    // Step4 of PAGE ERASE
                    gNorPageEraseStep = 4;
                    return; //goto label_checkregister;
                }
                break;
            case 4:
                if ( addr16 == 0xAAAA && data == 0x55 )
                {
                    // Step5 of PAGE ERASE
                    gNorPageEraseStep = 5;
                    return; //goto label_checkregister;
                }
                break;
            case 5:
                // 5555<-10 erase all
                // dest<-30 erase 4K
                if ( addr16 == 0x5555 && data == 0x10 )
                {
                    // PAGE EARSE - earse every bank of 16 banks
                    // using gnorflag0 as norbank
                    qDebug("ggv wanna erase 0~F bank flash!");
                    gNorPageEraseStep = 0;
                    do
                    {
                        int i = 0;
                        gErasePos = 0;
                        do
                        {
                            //*(unsigned char *)(norbankheader[(unsigned __int8)gNorPageEraseStep] + i) = 0xFFu;
                            norbankheader[(unsigned char)gNorPageEraseStep][i] = 0xFFu;
                            i = gErasePos++ + 1;
                        }
                        while ( (unsigned int)gErasePos < 0x8000 );
                        ++gNorPageEraseStep;
                    }
                    while ( (unsigned char)gNorPageEraseStep < 0x10u );
                    gErasePos = 0;
                    gNorPageEraseStep = 0;
                    fFlashUpdated = true;
                    return; //goto label_DestToAddr16_checkregister;
                }
                if ( data == 0x30 )
                {
                    // PAGE ERASE - 4K mode
                    // still use gnorflag0 as norbank
                    qDebug("ggv wanna erase one block of flash!");
                    gNorPageEraseStep = zpioregs[io00_bank_switch];// cross?! 557
                    // 5018 -> 5018 - 18 - 4000 = 1000
                    gEraseBlockAddr = (unsigned short)addr16 - (unsigned short)addr16 % 0x1000 - 0x4000;
                    int i2 = 0;
                    gErasePos = 0;
                    do
                    {
                        *(unsigned char *)(gEraseBlockAddr + norbankheader[(unsigned char)gNorPageEraseStep] + i2) = 0xFFu;
                        i2 = gErasePos++ + 1;
                    }
                    while ( (unsigned int)gErasePos < 0x1000 );
                    gErasePos = 0;
                    gNor8555_AAFlag = 0;
                    gNorPageEraseStep = 0;
                    fFlashUpdated = true;
                    return; //goto label_DestToAddr16_checkregister;
                }
                break;
            }
            qDebug("error occurs when erase flash!");
            return; //goto label_printerr_DestToAddr16_checkregister;
        }
    }
    qDebug("error occurs when put a byte in flash!");
//label_printerr_DestToAddr16_checkregister:
//    //printf(errmsg);
//    return; //goto label_DestToAddr16_checkregister;
//label_DestToAddr16_checkregister:
//    // addr16 = mayDestAddr
//    // return; //goto label_checkregister;
//label_checkregister:
//    //if ( addr16 < (unsigned __int16)(unsigned __int8)RegisterRange )
//    //    JUMPOUT(loc_40D680);
//    return;
}
