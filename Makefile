CC = gcc
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -O2 -fdiagnostics-color=never
TARGET = error-explainer
CORE_SOURCES = src/main.c src/compiler.c src/explainer.c

all: $(TARGET)

$(TARGET): $(CORE_SOURCES)
	$(CC) $(CFLAGS) $(CORE_SOURCES) -o $(TARGET)

run-example: $(TARGET)
	-./$(TARGET) examples/missing_semicolon.c --offline

test: $(TARGET)
	-./$(TARGET) examples/missing_semicolon.c --offline
	-./$(TARGET) examples/undeclared_variable.c --offline
	./$(TARGET) examples/correct_program.c --offline
	./$(TARGET) examples/unused_variable.c --offline

clean:
	rm -f $(TARGET) .error_explainer_build .error_explainer_build.exe .error_explainer_diagnostics.txt

.PHONY: all run-example test clean
