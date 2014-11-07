#!/bin/sh

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi
. "${DIR}/iconVersioning.sh"
. "${DIR}/lines.sh"
. "${DIR}/todo.sh"
. "${DIR}/user.sh"

bundled_plist=$(find "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" -name "KZBEnvironments.plist" | tr -d '\r')
bundled_settings=$(find "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" -name "Settings.bundle" | tr -d '\r')
src_plist=$(find "${SRCROOT}" -name "KZBEnvironments.plist" | tr -d '\r')

if [[ "${CONFIGURATION}" == *Release*  ]]; then
  env -i xcrun -sdk macosx swift ${DIR}/processEnvironments.swift "${bundled_plist}" "${src_plist}" "${bundled_settings}" "PRODUCTION"
else
  env -i xcrun -sdk macosx swift ${DIR}/processEnvironments.swift "${bundled_plist}" "${src_plist}" "${bundled_settings}"
fi
