# Makefile for router.cpp

CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
TARGET = router
SRC = router.cpp

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)
