#!/bin/sh
set -ex

wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz
tar -xzvf libsodium-1.0.18.tar.gz
cd libsodium-1.0.18
./configure --prefix=/usr
make && make install