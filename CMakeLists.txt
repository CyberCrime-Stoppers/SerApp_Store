cmake_minimum_required(VERSION 3.21)

project(SereneAppStore VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2 Network Concurrent)
find_package(OpenSSL REQUIRED)
qt_standard_project_setup()

qt_add_executable(SereneAppStore
    src/main.cpp
    src/PackageManager.cpp
    src/AppPackage.cpp
    src/SignatureVerifier.cpp
)

# qt_add_qml_module generates its module artifacts in build/<module-name>/,
# which would collide with the executable of the same name in the build root.
# Put the binary in a bin/ subdir so the two can never clash.
set_target_properties(SereneAppStore PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

qt_add_qml_module(SereneAppStore
    URI SereneAppStore
    VERSION 1.0
    QML_FILES
        ui/Main.qml
        ui/HomePage.qml
        ui/BrowsePage.qml
        ui/AppDetailPage.qml
        ui/LibraryPage.qml
        ui/UpdatesPage.qml
        ui/components/NavRail.qml
        ui/components/AppCard.qml
        ui/components/RatingStars.qml
        ui/components/HeroBanner.qml
)

target_link_libraries(SereneAppStore PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Concurrent
    OpenSSL::Crypto
)

include(GNUInstallDirs)
install(TARGETS SereneAppStore BUNDLE DESTINATION . RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
