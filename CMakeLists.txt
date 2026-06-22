cmake_minimum_required(VERSION 3.10.2)

project(finance_engine VERSION 1.0.0 LANGUAGES CXX)

# Set standar C++ ke C++17 agar kompilasi modern & cepat
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Langsung arahkan ke folder src di root proyek
add_library(finance_engine SHARED src/finance_engine.cpp)
