#include "DbCentre.h"

TPathRecItem PathSetting; // imp
TStateRecItem StateSetting; // imp
TGlobalRecItem GlobalSetting;

void LoadAppSettings( void )
{
    //QSettings settings(QApplication::applicationDirPath() + "/ConfMachine.ini",
    //    QSettings::IniFormat);
    PathSetting.LastSelectedItemIndex = 0;

    StateSetting.RegEditorMaxium = true;

    GlobalSetting.SPDC1016Frequency = 3686400 * 2;
}

void SaveAppSettings( void )
{

}
