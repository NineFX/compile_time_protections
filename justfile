rust_rpi_target := "armv7-unknown-linux-gnueabihf"
clang_rpi_target := "arm-linux-gnueabihf"
cpp := "clang++-16"
cpp_flags := "-D_FORTIFY_SOURCE=3"
cpp_source := "toy_service.cpp"
executable := "vulnerable_binary"
version := `echo "${GITHUB_REF_NAME}" || echo "0.0.0-dev"`

default:
  @just --list

[working-directory: 'vulnerable_binary']
build-cpp:
    {{cpp}} {{cpp_flags}} -g -o {{executable}} {{cpp_source}} 

[working-directory: 'vulnerable_binary']
build-cpp-release:
    {{cpp}} {{cpp_flags}} -o {{executable}} {{cpp_source}}

[working-directory: 'vulnerable_binary']
build-cpp-release-rpi:
    # Create symlink only for cross-compilation
    sudo mkdir -p /usr/lib/llvm-16/lib/clang/16/lib/linux/
    sudo ln -sf {{absolute_path("vulnerable_binary/lib/arm/libclang_rt.ubsan_minimal-armhf.a")}} \
                 /usr/lib/llvm-16/lib/clang/16/lib/linux/libclang_rt.ubsan_minimal-armhf.a
    {{cpp}} -O2 \
            -s \
            -fuse-ld=gold \
            -fsanitize=undefined \
            -fsanitize-minimal-runtime \
            -fno-sanitize-trap=all \
            -fstack-protector-strong \
            -D_FORTIFY_SOURCE=3 \
            -fPIE -pie \
            -Wl,-z,relro,-z,now \
            -Wl,-z,noexecstack \
            -target arm-linux-gnueabihf \
            -I/usr/arm-linux-gnueabihf/include \
            -I/usr/arm-linux-gnueabihf/include/c++/10 \
            -I/usr/arm-linux-gnueabihf/include/c++/10/arm-linux-gnueabihf \
            -L/usr/arm-linux-gnueabihf/lib \
            -Wl,-dynamic-linker,/lib/ld-linux-armhf.so.3 \
            -o vulnerable_binary toy_service.cpp
    # Clean up symlink after build
    @sudo rm -f /usr/lib/llvm-16/lib/clang/16/lib/linux/libclang_rt.ubsan_minimal-armhf.a

[working-directory: 'toy_service']
build-rust-release: 
    cargo build --release

[working-directory: 'toy_service']
build-rust-release-rpi:
    cargo build --release --target {{rust_rpi_target}}

[working-directory: 'toy_service']
package: build-cpp-release
    @echo 'Generating a Debian package'
    cargo deb --strip --deb-version {{version}}
    dpkg-deb -c target/debian/toy-service_{{version}}-1_arm64.deb

[working-directory: 'toy_service/target/debian']
install_package: package
    @echo 'Generating a Debian package'
    sudo apt-get remove toy-service || true
    sudo apt-get install -y -f ./toy-service_{{version}}-1_arm64.deb

[working-directory: 'toy_service']
package-rpi: build-cpp-release-rpi
    @echo 'Generating a cross-compiled Debian package for Raspberry Pi'
    CARGO_DEB_DPKG_SHLIBDEPS=false cargo deb --strip --deb-version {{version}} --target {{rust_rpi_target}}

clean: clean-rust

[working-directory: 'toy_service']
clean-rust:
    cargo clean

apt-repo:
    rm -rf apt-repo
    aptly repo create -config=.aptly.conf -distribution=bullseye -component=main compile_time_protections
    aptly repo add -config=.aptly.conf compile_time_protections toy_service/target/debian/*.deb
    aptly publish repo -config=.aptly.conf --skip-signing compile_time_protections

# Install prerequisites on a Debian Linux distro
bootstrap:
    apt-get update
    apt-get install -y clang-16 clang-tools-16 gdb valgrind curl wget \
                       gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
                       libc6-dev-armhf-cross libc6-armhf-cross \
                       libstdc++6-armhf-cross libgcc-s1-armhf-cross \
                       libc++1-16 libc++abi1-16 libclang-rt-16-dev libstdc++6 \
                       checksec aptly
    cargo install cargo-deb
    rustup target add {{rust_rpi_target}}

ci-build: bootstrap build-cpp-release-rpi build-rust-release-rpi

ci-release: build-cpp-release-rpi package-rpi apt-repo
