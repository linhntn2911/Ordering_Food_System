#
# Generated file. Do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  cloud_firestore
  file_selector_windows
  firebase_auth
  firebase_core
  firebase_storage
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  target_include_directories(${BINARY_NAME} PRIVATE ${${plugin}_plugin_include_directories})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${ffi_plugin})
  target_include_directories(${BINARY_NAME} PRIVATE ${${ffi_plugin}_include_directories})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${ffi_plugin}>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
