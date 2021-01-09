TARGET := iphone:clang:10.3:7.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Freeza

Freeza_FILES = src/FreezeListener.x src/ResumeListener.x
Freeza_LIBRARIES = activator
Freeza_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
