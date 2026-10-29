ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FLEXLoader

FLEXLoader_FILES = Tweak.xm $(shell find ../Classes -type f \( -name '*.m' -o -name '*.mm' -o -name '*.c' \))
FLEXLoader_CFLAGS = -fobjc-arc -Wno-error -Wno-unused-but-set-variable -Wno-deprecated-declarations -Wno-unsupported-availability-guard $(shell find ../Classes -type d -exec printf ' -I%s' {} \;)
FLEXLoader_CXXFLAGS = -std=gnu++11
FLEXLoader_FRAMEWORKS = UIKit Foundation CoreGraphics ImageIO QuartzCore WebKit Security SceneKit
FLEXLoader_LIBRARIES = sqlite3 z c++

include $(THEOS_MAKE_PATH)/tweak.mk
