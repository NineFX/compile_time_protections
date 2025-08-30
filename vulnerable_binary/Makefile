# Makefile for Bad Cast Example with Unit Tests
# Compiler and flags
CXX = clang++
# Configured for macOS and Homebrew
CXXFLAGS = -std=c++17 -Wall -Wextra -Wpedantic -g -O0  -I/opt/homebrew/include/ -fsanitize=address -fsanitize=undefined
# Configured for macOS and Homebrew
LDFLAGS = -lpthread -lgtest -lgtest_main -L/opt/homebrew/lib -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address"
# Google Test flags (adjust paths as needed)
GTEST_FLAGS = -lgtest -lgtest_main -lpthread -L/opt/homebrew/lib

# Source files
MAIN_SOURCE = toy_service.cpp
TEST_SOURCE = test_bad_cast.cpp
MAIN_TARGET = toy_service

TEST_TARGET = test_bad_cast

# Object files
MAIN_OBJECT = $(MAIN_SOURCE:.cpp=.o)
TEST_OBJECT = $(TEST_SOURCE:.cpp=.o)

# Default target
all: $(MAIN_TARGET)

# Build the main executable
$(MAIN_TARGET): $(MAIN_OBJECT)
	$(CXX) $(LDFLAGS) -o $@ $^

# Build the test executable
$(TEST_TARGET): $(TEST_OBJECT)
	$(CXX) $(LDFLAGS) $(GTEST_FLAGS) -o $@ $^

# Build object files
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

# Test-specific object compilation
$(TEST_OBJECT): $(TEST_SOURCE)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

# Debug builds
debug: CXXFLAGS += -DDEBUG -fsanitize=address -fsanitize=undefined -fsanitize-trap  
debug: LDFLAGS += -fsanitize=address -fsanitize=undefined -fsanitize-trap  
debug: $(MAIN_TARGET)

debug-test: CXXFLAGS += -DDEBUG -fsanitize=address -fsanitize=undefined
debug-test: LDFLAGS += -fsanitize=address -fsanitize=undefined
debug-test: $(TEST_TARGET)

# Release builds
release: CXXFLAGS = -std=c++17 -Wall -Wextra -O2 -DNDEBUG
release: $(MAIN_TARGET)

release-test: CXXFLAGS = -std=c++17 -Wall -Wextra -O2 -DNDEBUG
release-test: $(TEST_TARGET)

# Test targets
test: $(TEST_TARGET)
	./$(TEST_TARGET)

test-debug: debug-test
	./$(TEST_TARGET)

test-verbose: $(TEST_TARGET)
	./$(TEST_TARGET) --gtest_verbose

test-filter: $(TEST_TARGET)
	./$(TEST_TARGET) --gtest_filter="*BadCast*"

# Run specific test that triggers vulnerability
test-vulnerability: $(TEST_TARGET)
	./$(TEST_TARGET) --gtest_filter="*InvalidRectangleCastThrowsBadCast*"

# Clean build artifacts
clean:
	rm -f $(MAIN_OBJECT) $(TEST_OBJECT) $(MAIN_TARGET) $(TEST_TARGET)

# Run the main program
run: $(MAIN_TARGET)
	./$(MAIN_TARGET)

run-debug: debug
	./$(MAIN_TARGET)


# Install Google Test (Ubuntu/Debian)
install-gtest:
	sudo apt-get update
	sudo apt-get install libgtest-dev cmake
	cd /usr/src/gtest && sudo cmake CMakeLists.txt && sudo make && sudo cp lib/*.a /usr/lib

# Install Google Test (macOS with Homebrew)
install-gtest-mac:
	brew install googletest

# Check if Google Test is available
check-gtest:
	@echo "Checking for Google Test..."
	@pkg-config --exists gtest && echo "Google Test found" || echo "Google Test not found - run 'make install-gtest' or 'make install-gtest-mac'"

# Display info
info:
	@echo "Compiler: $(CXX)"
	@echo "Flags: $(CXXFLAGS)"
	@echo "Main Source: $(MAIN_SOURCE)"
	@echo "Test Source: $(TEST_SOURCE)"
	@echo "Main Target: $(MAIN_TARGET)"
	@echo "Test Target: $(TEST_TARGET)"
	@$(CXX) --version

# Force rebuild
rebuild: clean all
rebuild-test: clean test

# Help target
help:
	@echo "Available targets:"
	@echo "  all           - Build main executable (default)"
	@echo "  test          - Build and run unit tests"
	@echo "  test-debug    - Build and run tests with debug flags"
	@echo "  test-verbose  - Run tests with verbose output"
	@echo "  test-filter   - Run only BadCast tests"
	@echo "  test-vulnerability - Run specific vulnerability test"
	@echo "  debug         - Build main with debug flags"
	@echo "  debug-test    - Build tests with debug flags"
	@echo "  release       - Build optimized main"
	@echo "  release-test  - Build optimized tests"
	@echo "  run           - Build and run main program"
	@echo "  run-debug     - Build and run with debug flags"
	@echo "  clean         - Remove build artifacts"
	@echo "  rebuild       - Clean and rebuild main"
	@echo "  rebuild-test  - Clean and rebuild tests"
	@echo "  valgrind      - Run main with valgrind"
	@echo "  valgrind-test - Run tests with valgrind"
	@echo "  install-gtest - Install Google Test (Ubuntu/Debian)"
	@echo "  install-gtest-mac - Install Google Test (macOS)"
	@echo "  check-gtest   - Check if Google Test is available"
	@echo "  info          - Display compiler information"
	@echo "  help          - Show this help message"

# Declare phony targets
.PHONY: all test test-debug test-verbose test-filter test-vulnerability debug debug-test release release-test clean run run-debug valgrind valgrind-test install-gtest install-gtest-mac check-gtest info rebuild rebuild-test help