## Try locate the environment variable where LLDB build exists
if ( NOT DEFINED ENV{LLVM_HOME} )
    message("--")
    message("**** NOTICE **** : Could not locate environment variable LLVM_HOME. Please set it to your local LLVM root folder")
    message("**** NOTICE **** : LLDB Debugger is disabled")
    message("--")
else()
    set( LLVM_HOME $ENV{LLVM_HOME} )
    message("-- LLVM_HOME is set to ${LLVM_HOME}")
    if ( UNIX AND NOT APPLE )
        set ( LLDB_LIB liblldb.so )
    else()
        set ( LLDB_LIB liblldb.dylib )
    endif()
    
    set( LLDB_BUILD_DIRS "" )
    # define the search order of the folder
    if(DEBUG_BUILD MATCHES 1)
        message("-- Will search for LLBM Debug build first")
        LIST(APPEND LLDB_BUILD_DIRS "build-debug")
        LIST(APPEND LLDB_BUILD_DIRS "build")
        LIST(APPEND LLDB_BUILD_DIRS "build-release")
    else ()
        message("-- Will search for LLBM Release build first")
        LIST(APPEND LLDB_BUILD_DIRS "build-release")
        LIST(APPEND LLDB_BUILD_DIRS "build")
        LIST(APPEND LLDB_BUILD_DIRS "build-debug")
    endif()
    
    ## determine the build folder
    set( LLDB_BUILD_DIR "" )
    set ( BUILD_DIR_FOUND 0 )
    foreach(build_tmp_dir ${LLDB_BUILD_DIRS})
        if ( BUILD_DIR_FOUND MATCHES 0 ) 
            if ( EXISTS ${LLVM_HOME}/${build_tmp_dir} AND EXISTS ${LLVM_HOME}/${build_tmp_dir}/lib/${LLDB_LIB} )
                set( LLDB_BUILD_DIR ${LLVM_HOME}/${build_tmp_dir} )
                set( BUILD_DIR_FOUND 1 )
                message("-- ${LLVM_HOME}/${build_tmp_dir} Found!")
            endif()
        endif()
    endforeach()

    if ( BUILD_DIR_FOUND MATCHES 0 )
        message("**** NOTICE: Could not locate LLVM build folder")
    endif()
    
    if ( LLDB_BUILD_DIR STREQUAL "" )
        ## We could not locate the binary
        message("**** NOTICE: Could not locate LLVM build directory")
        
    else()
        message("-- LLDB_BUILD_DIR is set to ${LLDB_BUILD_DIR}")
        set(LLDB_LIB_PATH ${LLDB_BUILD_DIR}/lib)
        set(LLDB_INCLUDE_PATH ${LLVM_HOME}/tools/lldb/include)
        message("-- LLDB_LIB_PATH is set to ${LLDB_LIB_PATH}")
        message("-- LLDB_INCLUDE_PATH is set to ${LLDB_INCLUDE_PATH}")
        
        include_directories(${LLDB_INCLUDE_PATH})
        link_directories(${LLDB_LIB_PATH})
        add_definitions(-std=c++11)
        ## We are good to go - include this plugin
        CL_PLUGIN(LLDBDebugger "${LLDB_LIB}")
        
        ## Since lldb.so is a symlink, make sure we install the actual file and not 
        ## the symbolic file name
        set( LLDB_LIB_ABS ${LLDB_LIB_PATH}/${LLDB_LIB} )
        if ( IS_SYMLINK ${LLDB_LIB_ABS} )
            message( "-- ${LLDB_LIB_ABS} is a symbolic link ")
            get_filename_component(LLDB_LIB_TMP ${LLDB_LIB_ABS} REALPATH)
            set( LLDB_LIB_ABS ${LLDB_LIB_TMP})
        endif()
        
        message("-- Will install file ${LLDB_LIB_ABS}")
        install(FILES ${LLDB_LIB_ABS} DESTINATION ${PLUGINS_DIR} PERMISSIONS ${EXE_PERM})
    endif()
endif()
