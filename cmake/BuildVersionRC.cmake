#macro (createResourcesVersion ResourseName ComponentName ProductName Comment)
macro (createResourcesVersion ProductName
							  ProjectName
							  ComponentName
							  CompanyName
							  Comment)
if(WIN32)
	set(ResourseName ${ProjectName}_RC)
	set (${ResourseName} "${CMAKE_CURRENT_BINARY_DIR}/${ProjectName}_ver.rc")
	string(TIMESTAMP CURRENT_YEAR "%Y" UTC)
	file( WRITE ${${ResourseName}} "
\#include \"winresrc.h\"
\#ifdef _WIN32
LANGUAGE LANG_RUSSIAN, SUBLANG_DEFAULT
\#pragma code_page(1251)
\#endif //_WIN32
VS_VERSION_INFO VERSIONINFO
 FILEVERSION ${${ProjectName}_VERSION_MAJOR},${${ProjectName}_VERSION_MINOR},${${ProjectName}_VERSION_PATCH},${${ProjectName}_VERSION_TWEAK}
 PRODUCTVERSION ${${ProductName}_VERSION_MAJOR},${${ProductName}_VERSION_MINOR},${${ProductName}_VERSION_PATCH},${${ProductName}_VERSION_TWEAK}
\#ifdef _DEBUG
 FILEFLAGS 0x1L
\#else
 FILEFLAGS 0x0L
\#endif
 FILEOS 0x4L
 FILETYPE 0x2L
 FILESUBTYPE 0x0L
BEGIN
    BLOCK \"StringFileInfo\"
    BEGIN
        BLOCK \"041904b0\"
        BEGIN
            VALUE \"Comments\", \"${Comment}\"
            VALUE \"CompanyName\", \"${CompanyName}\"
            VALUE \"FileVersion\", \"${${ProjectName}_VERSION_MAJOR}.${${ProjectName}_VERSION_MINOR}.${${ProjectName}_VERSION_PATCH}\"
            VALUE \"InternalName\", \"${ProjectName}\"
            VALUE \"LegalCopyright\", \"Copyright ${CompanyName} (C) ${CURRENT_YEAR}\"
            VALUE \"OriginalFilename\", \"${ProjectName}\"
            VALUE \"ProductName\",    \"${ProductName}\"
            VALUE \"ProductVersion\", \"${${ProductName}_VERSION_MAJOR}.${${ProductName}_VERSION_MINOR}.${${ProductName}_VERSION_PATCH}\"
            VALUE \"SpecialBuild\",\"${CMAKE_BUILD_TYPE} ${ProjectName}_VERSION_PATCH\"
        END
    END
    BLOCK \"VarFileInfo\"
    BEGIN
        VALUE \"Translation\", 0x419, 1200
    END
END
" )	
endif(WIN32)
endmacro(createResourcesVersion)