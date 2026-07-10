FROM debian:trixie as build

WORKDIR /build

RUN apt update && apt -y install clang llvm git make ninja-build cmake wget

RUN git clone https://git.code.sf.net/p/mingw-w64/mingw-w64
RUN cd mingw-w64 && git checkout v14.0.0
RUN wget https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-22.1.3.tar.gz
RUN tar xzf llvmorg-22.1.3.tar.gz

# MinGW headers
RUN mkdir /build/build-headers-i686
WORKDIR /build/build-headers-i686
RUN /build/mingw-w64/mingw-w64-headers/configure --prefix=/build/i686-w64-mingw32  --enable-idl --with-default-win32-winnt=0x601 --with-default-msvcrt=ucrt
RUN make
RUN make install

RUN mkdir /build/build-headers-x86_64
WORKDIR /build/build-headers-x86_64
RUN /build/mingw-w64/mingw-w64-headers/configure --prefix=/build/x86_64-w64-mingw32  --enable-idl --with-default-win32-winnt=0x601 --with-default-msvcrt=ucrt
RUN make
RUN make install

RUN mkdir /build/build-headers-aarch64
WORKDIR /build/build-headers-aarch64
RUN /build/mingw-w64/mingw-w64-headers/configure --prefix=/build/aarch64-w64-mingw32  --enable-idl --with-default-win32-winnt=0x601 --with-default-msvcrt=ucrt
RUN make
RUN make install

# MinGW libs
RUN mkdir /build/build-crt-i686
WORKDIR /build/build-crt-i686
RUN AS=llvm-as-19 AR=llvm-ar-19 RANLIB=llvm-ranlib-19 DLLTOOL=llvm-dlltool-19 CC="clang-19 --target=i686-w64-mingw32 --sysroot=/build/i686-w64-mingw32" CXX="clang++-19 --target=i686-w64-mingw32 --sysroot=/build/i686-w64-mingw32" /build/mingw-w64/mingw-w64-crt/configure --host=i686-w64-mingw32 --prefix=/build/i686-w64-mingw32 --enable-lib32 --disable-lib64 --with-default-msvcrt=ucrt --enable-cfguard
RUN make -j$(nproc)
RUN make install

RUN mkdir /build/build-crt-x86_64
WORKDIR /build/build-crt-x86_64
RUN AS=llvm-as-19 AR=llvm-ar-19 RANLIB=llvm-ranlib-19 DLLTOOL=llvm-dlltool-19 CC="clang-19 --target=x86_64-w64-mingw32 --sysroot=/build/x86_64-w64-mingw32" CXX="clang++-19 --target=x86_64-w64-mingw32 --sysroot=/build/x86_64-w64-mingw32" /build/mingw-w64/mingw-w64-crt/configure --host=x86_64-w64-mingw32 --prefix=/build/x86_64-w64-mingw32 --disable-lib32 --enable-lib64 --with-default-msvcrt=ucrt --enable-cfguard
RUN make -j$(nproc)
RUN make install

RUN mkdir /build/build-crt-aarch64
WORKDIR /build/build-crt-aarch64
RUN AS=llvm-as-19 AR=llvm-ar-19 RANLIB=llvm-ranlib-19 DLLTOOL=llvm-dlltool-19 CC="clang-19 --target=aarch64-w64-mingw32 --sysroot=/build/aarch64-w64-mingw32" CXX="clang++-19 --target=aarch64-w64-mingw32 --sysroot=/build/aarch64-w64-mingw32" /build/mingw-w64/mingw-w64-crt/configure --host=aarch64-w64-mingw32 --prefix=/build/aarch64-w64-mingw32 --disable-lib32 --disable-lib64  --enable-libarm64 --with-default-msvcrt=ucrt --enable-cfguard
RUN make -j$(nproc)
RUN make install

# libunwind
COPY <<EOF /build/toolchain-i686.cmake
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSROOT /build/i686-w64-mingw32)

set(CMAKE_ASM_COMPILER clang-19)
set(CMAKE_ASM_COMPILER_TARGET i686-w64-mingw32)
set(CMAKE_C_COMPILER clang-19)
set(CMAKE_C_COMPILER_TARGET i686-w64-mingw32)
set(CMAKE_CXX_COMPILER clang++-19)
set(CMAKE_CXX_COMPILER_TARGET i686-w64-mingw32)

set(CMAKE_AR llvm-ar-19)
set(CMAKE_RANLIB llvm-ranlib-19)
EOF
RUN mkdir /build/build-unwind-i686
WORKDIR /build/build-unwind-i686
RUN cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=/build/toolchain-i686.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/build/i686-w64-mingw32 -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DCXX_SUPPORTS_FNO_EXCEPTIONS_FLAG=ON  -DLLVM_ENABLE_RUNTIMES="libunwind" -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_STATIC=ON -DCMAKE_C_FLAGS_INIT="-mguard=cf -D__USE_MINGW_ANSI_STDIO=1" -DCMAKE_CXX_FLAGS_INIT="-mguard=cf -D__USE_MINGW_ANSI_STDIO=1" /build/llvm-project-llvmorg-22.1.3/runtimes
RUN cmake --build .
RUN cmake --install .

COPY <<EOF /build/toolchain-x86_64.cmake
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSROOT /build/x86_64-w64-mingw32)

set(CMAKE_ASM_COMPILER clang-19)
set(CMAKE_ASM_COMPILER_TARGET x86_64-w64-mingw32)
set(CMAKE_C_COMPILER clang-19)
set(CMAKE_C_COMPILER_TARGET x86_64-w64-mingw32)
set(CMAKE_CXX_COMPILER clang++-19)
set(CMAKE_CXX_COMPILER_TARGET x86_64-w64-mingw32)

set(CMAKE_AR llvm-ar-19)
set(CMAKE_RANLIB llvm-ranlib-19)
EOF
RUN mkdir /build/build-unwind-x86_64
WORKDIR /build/build-unwind-x86_64
RUN cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=/build/toolchain-x86_64.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/build/x86_64-w64-mingw32 -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DCXX_SUPPORTS_FNO_EXCEPTIONS_FLAG=ON  -DLLVM_ENABLE_RUNTIMES="libunwind" -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_STATIC=ON -DCMAKE_C_FLAGS_INIT="-mguard=cf -D__USE_MINGW_ANSI_STDIO=1" -DCMAKE_CXX_FLAGS_INIT="-mguard=cf -D__USE_MINGW_ANSI_STDIO=1" /build/llvm-project-llvmorg-22.1.3/runtimes
RUN cmake --build .
RUN cmake --install .

COPY <<EOF /build/toolchain-aarch64.cmake
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSROOT /build/aarch64-w64-mingw32)

set(CMAKE_ASM_COMPILER clang-19)
set(CMAKE_ASM_COMPILER_TARGET aarch64-w64-mingw32)
set(CMAKE_C_COMPILER clang-19)
set(CMAKE_C_COMPILER_TARGET aarch64-w64-mingw32)
set(CMAKE_CXX_COMPILER clang++-19)
set(CMAKE_CXX_COMPILER_TARGET aarch64-w64-mingw32)

set(CMAKE_AR llvm-ar-19)
set(CMAKE_RANLIB llvm-ranlib-19)
EOF
RUN mkdir /build/build-unwind-aarch64
WORKDIR /build/build-unwind-aarch64
RUN cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=/build/toolchain-aarch64.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/build/aarch64-w64-mingw32 -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DCXX_SUPPORTS_FNO_EXCEPTIONS_FLAG=ON  -DLLVM_ENABLE_RUNTIMES="libunwind" -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_STATIC=ON -DCMAKE_C_FLAGS_INIT="-mguard=cf -D__USE_MINGW_ANSI_STDIO=1" -DCMAKE_CXX_FLAGS_INIT="-mguard=cf -D__USE_MINGW_ANSI_STDIO=1" /build/llvm-project-llvmorg-22.1.3/runtimes
RUN cmake --build .
RUN cmake --install .

# compiler-rt (for __chkstk etc)
RUN mkdir /build/build-rt-i686
WORKDIR /build/build-rt-i686
RUN cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=/build/toolchain-i686.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/build/i686-w64-mingw32 -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=FALSE -DCOMPILER_RT_BUILD_SANITIZERS=OFF -DCOMPILER_RT_BUILD_XRAY=OFF -DCOMPILER_RT_BUILD_MEMPROF=OFF -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF -DCOMPILER_RT_BUILD_LIBFUZZER=OFF -DCOMPILER_RT_BUILD_PROFILE=OFF -DCOMPILER_RT_BUILD_ORC=OFF -DCMAKE_CXX_FLAGS_INIT="-mguard=cf" -DCMAKE_C_FLAGS_INIT="-mguard=cf" /build/llvm-project-llvmorg-22.1.3/compiler-rt
RUN cmake --build .
RUN cmake --install .

RUN mkdir /build/build-rt-x86_64
WORKDIR /build/build-rt-x86_64
RUN cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=/build/toolchain-x86_64.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/build/x86_64-w64-mingw32 -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=FALSE -DCOMPILER_RT_BUILD_SANITIZERS=OFF -DCOMPILER_RT_BUILD_XRAY=OFF -DCOMPILER_RT_BUILD_MEMPROF=OFF -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF -DCOMPILER_RT_BUILD_LIBFUZZER=OFF -DCOMPILER_RT_BUILD_PROFILE=OFF -DCOMPILER_RT_BUILD_ORC=OFF -DCMAKE_CXX_FLAGS_INIT="-mguard=cf" -DCMAKE_C_FLAGS_INIT="-mguard=cf" /build/llvm-project-llvmorg-22.1.3/compiler-rt
RUN cmake --build .
RUN cmake --install .

RUN mkdir /build/build-rt-aarch64
WORKDIR /build/build-rt-aarch64
RUN cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=/build/toolchain-aarch64.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/build/aarch64-w64-mingw32 -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=FALSE -DCOMPILER_RT_BUILD_SANITIZERS=OFF -DCOMPILER_RT_BUILD_XRAY=OFF -DCOMPILER_RT_BUILD_MEMPROF=OFF -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF -DCOMPILER_RT_BUILD_LIBFUZZER=OFF -DCOMPILER_RT_BUILD_PROFILE=OFF -DCOMPILER_RT_BUILD_ORC=OFF -DCMAKE_CXX_FLAGS_INIT="-mguard=cf" -DCMAKE_C_FLAGS_INIT="-mguard=cf" /build/llvm-project-llvmorg-22.1.3/compiler-rt
RUN cmake --build .
RUN cmake --install .

WORKDIR /build
RUN tar czf mingw-w64-v14.0.0.tar.gz aarch64-w64-mingw32 i686-w64-mingw32 x86_64-w64-mingw32
COPY --chmod=755 <<EOF /build/copy-to-github.sh
cp /build/mingw-w64-v14.0.0.tar.gz /github/workspace
EOF

# Copy the result to GHA output
ENTRYPOINT [ "/build/copy-to-github.sh" ]
