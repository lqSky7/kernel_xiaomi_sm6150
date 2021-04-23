#!/usr/bin/env bash

echo "Kanging shits"

git clone --depth=1 https://github.com/Ca5-n/kernel_xiaomi_phoenix -b rs kernel
cd kernel
git clone --depth=1 https://github.com/kdrag0n/proton-clang clang

echo "Kanged!"

IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
CLANG_VERSION=$(clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export CONFIG_PATH=$PWD/arch/arm64/configs/phoenix_defconfig
export PATH=$PWD/clang/bin:$PATH

export ARCH=arm64
export KBUILD_BUILD_HOST=cato
export KBUILD_BUILD_USER="Ca5"

# Send sticker

function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgUAAxkBAAE2GJxf6Ds5YGyXiLHSRvWJ6z8W6KxysAACfAEAAlKsMFU12WW56-aEOx4E" \
        -d chat_id=$chat_id
}
# Send info to channel 
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• R •</b>%0ABuild started on <code>Circle CI/CD</code>%0A <b>For device</b> <i>Xiaomi Poco X2/Redmi K30 (phoenix)</i>%0A<b>branch:-</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0A<b>Under commit</b> <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0A<b>Using compiler:- </b> <code>$CLANG_VERSION</code>%0A<b>Started on:- </b> <code>$(date)</code>%0A<b>Build Status:</b> #Test"
}
# Push kernel to channel

function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="{R - PREBUILT - MIUI } Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Xiaomi Poco X2/Redmi K30 {Q - Q} (phoenix)</b> | <b>$CLANG_VERSION</b>"
}
# Fin Error

function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s) RIP"
    exit 1
}
echo "building!"
# Compiling build
export ARCH=arm64

function compile() {
   make O=out ARCH=arm64 phoenix_defconfig
       make -j$(nproc --all) O=out \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip
ls out/arch/arm64/boot/

if [[ -f ${IMAGE} &&  ${DTBO} ]]; then
     mv -f $IMAGE ${DTBO} AnyKernel
else
     finerr
fi
}
# Zipping

function zipping() {
    cd AnyKernel || exit 1
    zip -r9 Ca5-R.zip *
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
