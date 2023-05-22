# 获取当前platform
ifndef UNAME_S
UNAME_S := $(shell uname -s)
endif

# 获取当前处理器架构
ifndef UNAME_P
UNAME_P := $(shell uname -p)
endif

# 获取当前机器的体系结构
ifndef UNAME_M
UNAME_M := $(shell uname -m)
endif

# 获取编译器的版本信息
CCV := $(shell $(CC) --version | head -n 1)	# 获取 C 编译器的版本信息
CXXV := $(shell $(CXX) --version | head -n 1)	# 获取 C++ 编译器的版本信息

# 检测是否在 macOS 平台上的 Arm 架构，并进行相应的处理
# Mac OS + Arm can report x86_64
# ref: https://github.com/ggerganov/whisper.cpp/issues/66#issuecomment-1282546789
ifeq ($(UNAME_S),Darwin)
	ifneq ($(UNAME_P),arm)
		SYSCTL_M := $(shell sysctl -n hw.optional.arm64)
		ifeq ($(SYSCTL_M),1)
			# UNAME_P := arm
			# UNAME_M := arm64
			warn := $(warning Your arch is announced as x86_64, but it seems to actually be ARM64. Not fixing that can lead to bad performance. For more info see: https://github.com/ggerganov/whisper.cpp/issues/66\#issuecomment-1282546789)
		endif
	endif
endif

#
# Compile flags
#

# 定义了编译时的flags
CFLAGS   = -I.              -O3 -std=c11   -fPIC
CXXFLAGS = -I. -I./examples -O3 -std=c++11 -fPIC
LDFLAGS  =

# 根据操作系统类型为编译标志(CFLAGS和CXXFLAGS)添加适当的选项
# OS specific
# TODO: support Windows
ifeq ($(UNAME_S),Linux)
	CFLAGS   += -pthread
	CXXFLAGS += -pthread
endif
ifeq ($(UNAME_S),Darwin)
	CFLAGS   += -pthread
	CXXFLAGS += -pthread
endif
ifeq ($(UNAME_S),FreeBSD)
	CFLAGS   += -pthread
	CXXFLAGS += -pthread
endif
ifeq ($(UNAME_S),Haiku)
	CFLAGS   += -pthread
	CXXFLAGS += -pthread
endif

# Architecture specific
# TODO: probably these flags need to be tweaked on some architectures
#       feel free to update the Makefile for your architecture and send a pull request or issue
# 根据不同的系统架构和选项设置相应的编译选项
ifeq ($(UNAME_M),$(filter $(UNAME_M),x86_64 i686))
	ifeq ($(UNAME_S),Darwin)
		CFLAGS += -mf16c
		AVX1_M := $(shell sysctl machdep.cpu.features)
		ifneq (,$(findstring FMA,$(AVX1_M)))
			CFLAGS += -mfma
		endif
		ifneq (,$(findstring AVX1.0,$(AVX1_M)))
			CFLAGS += -mavx
		endif
		AVX2_M := $(shell sysctl machdep.cpu.leaf7_features)
		ifneq (,$(findstring AVX2,$(AVX2_M)))
			CFLAGS += -mavx2
		endif
	else ifeq ($(UNAME_S),Linux)
		AVX1_M := $(shell grep "avx " /proc/cpuinfo)
		ifneq (,$(findstring avx,$(AVX1_M)))
			CFLAGS += -mavx
		endif
		AVX2_M := $(shell grep "avx2 " /proc/cpuinfo)
		ifneq (,$(findstring avx2,$(AVX2_M)))
			CFLAGS += -mavx2
		endif
		FMA_M := $(shell grep "fma " /proc/cpuinfo)
		ifneq (,$(findstring fma,$(FMA_M)))
			CFLAGS += -mfma
		endif
		F16C_M := $(shell grep "f16c " /proc/cpuinfo)
		ifneq (,$(findstring f16c,$(F16C_M)))
			CFLAGS += -mf16c
		endif
		SSE3_M := $(shell grep "sse3 " /proc/cpuinfo)
		ifneq (,$(findstring sse3,$(SSE3_M)))
			CFLAGS += -msse3
		endif
	else ifeq ($(UNAME_S),Haiku)
		AVX1_M := $(shell sysinfo -cpu | grep "AVX ")
		ifneq (,$(findstring avx,$(AVX1_M)))
			CFLAGS += -mavx
		endif
		AVX2_M := $(shell sysinfo -cpu | grep "AVX2 ")
		ifneq (,$(findstring avx2,$(AVX2_M)))
			CFLAGS += -mavx2
		endif
		FMA_M := $(shell sysinfo -cpu | grep "FMA ")
		ifneq (,$(findstring fma,$(FMA_M)))
			CFLAGS += -mfma
		endif
		F16C_M := $(shell sysinfo -cpu | grep "F16C ")
		ifneq (,$(findstring f16c,$(F16C_M)))
			CFLAGS += -mf16c
		endif
	else
		CFLAGS += -mfma -mf16c -mavx -mavx2
	endif
endif
ifeq ($(UNAME_M),amd64)
	CFLAGS += -mavx -mavx2 -mfma -mf16c
endif
ifneq ($(filter ppc64%,$(UNAME_M)),)
	POWER9_M := $(shell grep "POWER9" /proc/cpuinfo)
	ifneq (,$(findstring POWER9,$(POWER9_M)))
		CFLAGS += -mpower9-vector
	endif
	# Require c++23's std::byteswap for big-endian support.
	ifeq ($(UNAME_M),ppc64)
		CXXFLAGS += -std=c++23 -DGGML_BIG_ENDIAN
	endif
endif
ifndef WHISPER_NO_ACCELERATE
	# Mac M1 - include Accelerate framework
	ifeq ($(UNAME_S),Darwin)
		CFLAGS  += -DGGML_USE_ACCELERATE
		LDFLAGS += -framework Accelerate
	endif
endif
ifdef WHISPER_OPENBLAS
	CFLAGS  += -DGGML_USE_OPENBLAS -I/usr/local/include/openblas
	LDFLAGS += -lopenblas
endif
ifdef WHISPER_GPROF
	CFLAGS   += -pg
	CXXFLAGS += -pg
endif
ifneq ($(filter aarch64%,$(UNAME_M)),)
	CFLAGS += -mcpu=native
	CXXFLAGS += -mcpu=native
endif
ifneq ($(filter armv6%,$(UNAME_M)),)
	# Raspberry Pi 1, 2, 3
	CFLAGS += -mfpu=neon-fp-armv8 -mfp16-format=ieee -mno-unaligned-access
endif
ifneq ($(filter armv7%,$(UNAME_M)),)
	# Raspberry Pi 4
	CFLAGS += -mfpu=neon-fp-armv8 -mfp16-format=ieee -mno-unaligned-access -funsafe-math-optimizations
endif
ifneq ($(filter armv8%,$(UNAME_M)),)
	# Raspberry Pi 4
	CFLAGS += -mfp16-format=ieee -mno-unaligned-access
endif

#
# Print build information 打印构建信息
#

$(info I whisper.cpp build info: )
$(info I UNAME_S:  $(UNAME_S))	# 操作系统名称
$(info I UNAME_P:  $(UNAME_P))	# 处理器类型
$(info I UNAME_M:  $(UNAME_M))	# 机器架构类型
$(info I CFLAGS:   $(CFLAGS))	# C 编译器的选项
$(info I CXXFLAGS: $(CXXFLAGS))	# C++ 编译器的选项
$(info I LDFLAGS:  $(LDFLAGS))	# 链接器的选项
$(info I CC:       $(CCV))		# C 编译器的版本
$(info I CXX:      $(CXXV))		# C++ 编译器的版本
$(info )

default: main

#
# Build library 构建库文件
#

ggml.o: ggml.c ggml.h
	$(CC)  $(CFLAGS)   -c ggml.c -o ggml.o

whisper.o: whisper.cpp whisper.h
	$(CXX) $(CXXFLAGS) -c whisper.cpp -o whisper.o

libwhisper.a: ggml.o whisper.o
	$(AR) rcs libwhisper.a ggml.o whisper.o

libwhisper.so: ggml.o whisper.o
	$(CXX) $(CXXFLAGS) -shared -o libwhisper.so ggml.o whisper.o $(LDFLAGS)

clean:
	rm -f *.o main stream command talk bench libwhisper.a libwhisper.so

#
# Examples 构建示例程序
#

CC_SDL=`sdl2-config --cflags --libs`	# 获取 SDL2 的编译选项和库链接选项

SRC_COMMON = examples/common.cpp
SRC_COMMON_SDL = examples/common-sdl.cpp

# 不同示例程序的构建规则
main: examples/main/main.cpp $(SRC_COMMON) ggml.o whisper.o
	$(CXX) $(CXXFLAGS) examples/main/main.cpp $(SRC_COMMON) ggml.o whisper.o -o main $(LDFLAGS)
	./main -h

stream: examples/stream/stream.cpp $(SRC_COMMON) $(SRC_COMMON_SDL) ggml.o whisper.o
	$(CXX) $(CXXFLAGS) examples/stream/stream.cpp $(SRC_COMMON) $(SRC_COMMON_SDL) ggml.o whisper.o -o stream $(CC_SDL) $(LDFLAGS)

command: examples/command/command.cpp $(SRC_COMMON) $(SRC_COMMON_SDL) ggml.o whisper.o
	$(CXX) $(CXXFLAGS) examples/command/command.cpp $(SRC_COMMON) $(SRC_COMMON_SDL) ggml.o whisper.o -o command $(CC_SDL) $(LDFLAGS)

talk: examples/talk/talk.cpp examples/talk/gpt-2.cpp $(SRC_COMMON) $(SRC_COMMON_SDL) ggml.o whisper.o
	$(CXX) $(CXXFLAGS) examples/talk/talk.cpp examples/talk/gpt-2.cpp $(SRC_COMMON) $(SRC_COMMON_SDL) ggml.o whisper.o -o talk $(CC_SDL) $(LDFLAGS)

bench: examples/bench/bench.cpp ggml.o whisper.o
	$(CXX) $(CXXFLAGS) examples/bench/bench.cpp ggml.o whisper.o -o bench $(LDFLAGS)

#
# Audio samples
#

# 用于下载音频样本并将其转换为 16 位 WAV 格式
# download a few audio samples into folder "./samples":
.PHONY: samples
samples:
	@echo "Downloading samples..."
	@mkdir -p samples
	@wget --quiet --show-progress -O samples/gb0.ogg https://upload.wikimedia.org/wikipedia/commons/2/22/George_W._Bush%27s_weekly_radio_address_%28November_1%2C_2008%29.oga
	@wget --quiet --show-progress -O samples/gb1.ogg https://upload.wikimedia.org/wikipedia/commons/1/1f/George_W_Bush_Columbia_FINAL.ogg
	@wget --quiet --show-progress -O samples/hp0.ogg https://upload.wikimedia.org/wikipedia/en/d/d4/En.henryfphillips.ogg
	@wget --quiet --show-progress -O samples/mm1.wav https://cdn.openai.com/whisper/draft-20220913a/micro-machines.wav
	@echo "Converting to 16-bit WAV ..."
	@ffmpeg -loglevel -0 -y -i samples/gb0.ogg -ar 16000 -ac 1 -c:a pcm_s16le samples/gb0.wav
	@ffmpeg -loglevel -0 -y -i samples/gb1.ogg -ar 16000 -ac 1 -c:a pcm_s16le samples/gb1.wav
	@ffmpeg -loglevel -0 -y -i samples/hp0.ogg -ar 16000 -ac 1 -c:a pcm_s16le samples/hp0.wav
	@ffmpeg -loglevel -0 -y -i samples/mm1.wav -ar 16000 -ac 1 -c:a pcm_s16le samples/mm0.wav
	@rm samples/mm1.wav

#
# Models
#

# 定义了几个模型相关的目标和一个测试目标
# if not already downloaded, the following targets download the specified model and
# runs it on all samples in the folder "./samples":

.PHONY: tiny.en
.PHONY: tiny
.PHONY: base.en
.PHONY: base
.PHONY: small.en
.PHONY: small
.PHONY: medium.en
.PHONY: medium
.PHONY: large-v1
.PHONY: large

# 定义多个目标，用于下载和运行特定的模型以及运行测试。
# 它依赖于 main 目标，并通过执行相应的脚本来完成下载、模型运行和测试操作
tiny.en tiny base.en base small.en small medium.en medium large-v1 large: main
	bash ./models/download-ggml-model.sh $@
	@echo ""
	@echo "==============================================="
	@echo "Running $@ on all samples in ./samples ..."
	@echo "==============================================="
	@echo ""
	@for f in samples/*.wav; do \
		echo "----------------------------------------------" ; \
		echo "[+] Running $@ on $$f ... (run 'ffplay $$f' to listen)" ; \
	    echo "----------------------------------------------" ; \
		echo "" ; \
		./main -m models/ggml-$@.bin -f $$f ; \
		echo "" ; \
	done

#
# Tests
#

.PHONY: tests
tests:
	bash ./tests/run-tests.sh
