#ifndef _DBCENTRE_H
#define _DBCENTRE_H

#include <string>

typedef struct tagPathRecItem {
    std::string LastBinFolder; // Mario
    int LastSelectedItemIndex;
} TPathRecItem;

typedef struct tagStateRecItem {
    bool RegEditorMaxium;
} TStateRecItem;

typedef struct tagGlobalRecItem {
    bool AutoExposure; // Gamma?
    bool RemoveJPEGArtifacts;
    bool AutoCrop;
    bool UseSurfaceBlur;
    int SPDC1016Frequency;
} TGlobalRecItem;




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Used in NekoDriver etc
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
extern TPathRecItem PathSetting;
extern TStateRecItem StateSetting;
extern TGlobalRecItem GlobalSetting;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void LoadAppSettings( void );
void SaveAppSettings( void );

#endif
