find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appwebassembly
    main.cpp
)

qt_add_qml_module(appwebassembly
    URI webassembly
    QML_FILES
        Main.qml
)

set_target_properties(appwebassembly PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appwebassembly
    PRIVATE Qt6::Quick Qt6::Network
)

if(NOT EMSCRIPTEN)
    add_custom_target(run-app
        DEPENDS appwebassembly
        COMMAND $<TARGET_FILE:appwebassembly>
        COMMENT "Running app"
        USES_TERMINAL
    )
endif()

if(EMSCRIPTEN)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)

    add_custom_command(TARGET appwebassembly POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_CURRENT_SOURCE_DIR}/loading.html"
            "${CMAKE_CURRENT_BINARY_DIR}/index.html"
        COMMENT "Applying custom loading screen"
    )

    set(DEPLOY_DIR "${CMAKE_BINARY_DIR}/deploy")
    set(DEPLOY_SRC "${DEPLOY_DIR}/sources")

    add_custom_target(deploy
        DEPENDS appwebassembly
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEPLOY_SRC}"
        COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_CURRENT_SOURCE_DIR}/loading.html"
            "${DEPLOY_SRC}/index.html"
        COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_CURRENT_BINARY_DIR}/appwebassembly.js"
            "${CMAKE_CURRENT_BINARY_DIR}/appwebassembly.wasm"
            "${CMAKE_CURRENT_BINARY_DIR}/qtloader.js"
            "${CMAKE_CURRENT_BINARY_DIR}/qtlogo.svg"
            "${CMAKE_SOURCE_DIR}/server/serve.py"
            "${DEPLOY_SRC}"
        COMMAND ${CMAKE_COMMAND} -E chdir "${DEPLOY_SRC}"
            ${CMAKE_COMMAND} -E tar "czf"
            "${DEPLOY_DIR}/appwebassembly.tar.gz"
            --format=gnutar
            -- "index.html" "appwebassembly.js" "appwebassembly.wasm" "qtloader.js" "qtlogo.svg" "serve.py"
        COMMENT "Creating deploy package in ${DEPLOY_DIR}"
    )

    add_custom_target(serve
        DEPENDS deploy
        COMMAND Python3::Interpreter "${CMAKE_SOURCE_DIR}/server/serve.py" 8080 "${DEPLOY_SRC}"
        COMMENT "Serving app at http://localhost:8080/"
        USES_TERMINAL
    )
endif()
