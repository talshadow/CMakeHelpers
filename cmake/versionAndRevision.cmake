if(NOT create_version_and_revision)
#-m32 -march=i686 -mtune=core2 -mcx16 -msahf -mfpmath=sse -mstackrealign -mmmx -msse -msse2 -mms-bitfields -O2 -fms-extensions -fomit-frame-pointer -Wall -funswitch-loops -fpredictive-commoning -ftree-vectorize -fvect-cost-model -Wl,--as-needed -Wl,--strip-all -fgcse-after-reload
macro (create_version_and_revision CurrentMajor CurrentMinor CurrentRevision)
	if(EXISTS ${${PROJECT_NAME}_SOURCE_DIR}/.git)
		find_package(Git REQUIRED)
		if(GIT_FOUND)
			EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} rev-list HEAD --count
				WORKING_DIRECTORY "${${PROJECT_NAME}_SOURCE_DIR}"
				OUTPUT_VARIABLE revision
			)
			EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} describe --tags
				WORKING_DIRECTORY "${${PROJECT_NAME}_SOURCE_DIR}"
				OUTPUT_VARIABLE version
			)
		string(REGEX MATCHALL "[0-9]+" versionout ${version})
		string(REGEX MATCHALL "[0-9]+" revisionout ${revision})
		list(GET versionout  0 ${CurrentMajor})
		list(GET versionout 1  ${CurrentMinor})
		list(GET revisionout 0 ${CurrentRevision})
		endif(GIT_FOUND)
	elseif(EXISTS ${${PROJECT_NAME}_SOURCE_DIR}/.svn)
		find_package(Subversion REQUIRED)
		if(Subversion_FOUND)
			Subversion_WC_INFO(${${PROJECT_NAME}_SOURCE_DIR} SOURCE_INFO)
			set(${CurrentRevision} ${SOURCE_INFO_WC_REVISION})
		endif(Subversion_FOUND)
	endif(EXISTS ${${PROJECT_NAME}_SOURCE_DIR}/.git)
endmacro(create_version_and_revision)
endif(NOT create_version_and_revision)