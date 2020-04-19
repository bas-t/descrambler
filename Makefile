VERSION = $(shell git describe --always)

include config.mak

CC       ?= gcc
CXX      ?= g++
CXXFLAGS ?= -Wall -D__user= 

DEFINES += -DRELEASE_VERSION=\"$(VERSION)\" -D__KERNEL_STRICT_NAMES
LBDIR = src
TOOL = ffdecsawrapper
LIBS = -lcrypto -lcrypt -lv4l1 -lpthread
SCDIR = sc/PLUGINS/src
SCLIBS = -Wl,-whole-archive ./sc/PLUGINS/lib/libsc-*.a -Wl,-no-whole-archive \
	./sc/PLUGINS/lib/libffdecsawrapper-sc.a

ifneq ($(RELEASE),1)
CXXFLAGS += -g
endif

OBJ  := forward.o process_req.o msg_passing.o plugin_getsid.o plugin_ringbuf.o\
	plugin_showioctl.o plugin_legacysw.o plugin_dss.o plugin_cam.o \
	plugin_ffdecsa.o version.o

OBJ_SC := misc.o dvbdevice.o osdbase.o menuitems.o device.o thread.o \
	tools.o sasccam.o log.o compat.o libsi.a

OBJS := $(foreach ob,$(OBJ) $(OBJ_SC), objs/$(ob)) FFdecsa/FFdecsa.o
INCLUDES_SC := -I$(SCDIR) -I./sc/include

INCLUDES_SI := -Isc/include/libsi
OBJ_LIBSI := objs/si_descriptor.o objs/si_section.o objs/si_si.o objs/si_util.o

INC_DEPS := $(shell ls $(LBDIR)/*.h)
INC_DEPS_LB := $(shell ls dvblb_plugins/*.h)

all: $(TOOL)

$(TOOL): $(OBJS) | sc-plugin
	$(CXX) $(CXXFLAGS) -o $(TOOL) $(SCLIBS) $(OBJS) $(LIBS)

clean:
	@git clean -xfd

distclean:
	@git clean -xfd
	@git reset --hard HEAD

sc-plugin:
	$(MAKE) -C $(SCDIR) CXX=$(CXX) CXXFLAGS=$(SC_FLAGS) STATIC=1 all

FFdecsa/FFdecsa.o:
	$(MAKE) -C FFdecsa $(FFDECSA_OPTS)

objs/libsi.a: $(OBJ_LIBSI)
	ar ru $@ $(OBJ_LIBSI)

objs/%.o: $(LBDIR)/%.c $(INC_DEPS)
	$(CXX) $(CXXFLAGS) -o $@ -c  $(DEFINES) -I$(LBDIR) $<

objs/%.o: dvblb_plugins/%.c $(INC_DEPS) $(INC_DEPS_LB)
	$(CXX) $(CXXFLAGS) -o $@ -c  $(DEFINES) -I$(LBDIR) $<

objs/%.o: sc/%.cpp
	$(CXX) $(CXXFLAGS) -o $@ -c  $(DEFINES) $(INCLUDES_SC) $<

objs/si_%.o: sc/libsi/%.c
	$(CXX) $(CXXFLAGS) -o $@ -c  $(DEFINES) $(INCLUDES_SI) $<

