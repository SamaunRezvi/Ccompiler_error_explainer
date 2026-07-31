#include "compiler.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#define NULL_DEVICE "NUL"
#define TEMP_BINARY ".error_explainer_build.exe"
#define TEMP_DIAGNOSTICS ".error_explainer_diagnostics.txt"
#else
#define NULL_DEVICE "/dev/null"
#define TEMP_BINARY ".error_explainer_build"
#define TEMP_DIAGNOSTICS ".error_explainer_diagnostics.txt"
#endif

static const char *find_gcc_command(void) {
#ifdef _WIN32
    static const char *candidates[] = {
        "gcc",
        "C:\\msys64\\ucrt64\\bin\\gcc.exe",
        "C:\\msys64\\mingw64\\bin\\gcc.exe",
        "C:\\MinGW\\bin\\gcc.exe"
    };
    static char selected_command[512];
    char check_command[1024];
    size_t candidate_count = sizeof(candidates) / sizeof(candidates[0]);

    for (size_t index = 0; index < candidate_count; ++index) {
        int written = snprintf(
            check_command,
            sizeof(check_command),
            "%s --version > %s 2>&1",
            candidates[index],
            NULL_DEVICE
        );

        if (written < 0 || (size_t)written >= sizeof(check_command)) {
            continue;
        }

        if (system(check_command) == 0) {
            (void)snprintf(
                selected_command,
                sizeof(selected_command),
                "%s",
                candidates[index]
            );
            return selected_command;
        }
    }

    return NULL;
#else
    return system("gcc --version > /dev/null 2>&1") == 0 ? "gcc" : NULL;
#endif
}

int is_gcc_available(void) {
    return find_gcc_command() != NULL;
}

int is_safe_path(const char *path) {
    const char *dangerous_characters = "\"`$!%^&|<>;\n\r";

    if (path == NULL || *path == '\0') {
        return 0;
    }

    for (const unsigned char *cursor = (const unsigned char *)path;
         *cursor != '\0';
         ++cursor) {
        if (*cursor < 32 ||
            strchr(dangerous_characters, (int)*cursor) != NULL) {
            return 0;
        }
    }

    return 1;
}

char *read_text_file(const char *path, size_t max_bytes) {
    FILE *file;
    long file_length;
    size_t bytes_to_read;
    size_t bytes_read;
    char *buffer;

    if (path == NULL || max_bytes == 0) {
        return NULL;
    }

    file = fopen(path, "rb");
    if (file == NULL) {
        return NULL;
    }

    if (fseek(file, 0, SEEK_END) != 0) {
        fclose(file);
        return NULL;
    }

    file_length = ftell(file);
    if (file_length < 0) {
        fclose(file);
        return NULL;
    }

    if (fseek(file, 0, SEEK_SET) != 0) {
        fclose(file);
        return NULL;
    }

    bytes_to_read = (size_t)file_length;
    if (bytes_to_read > max_bytes) {
        bytes_to_read = max_bytes;
    }

    buffer = (char *)calloc(bytes_to_read + 1, sizeof(char));
    if (buffer == NULL) {
        fclose(file);
        return NULL;
    }

    bytes_read = fread(buffer, 1, bytes_to_read, file);
    if (ferror(file) != 0 && bytes_read == 0) {
        free(buffer);
        fclose(file);
        return NULL;
    }

    buffer[bytes_read] = '\0';
    fclose(file);
    return buffer;
}

int compile_c_file(
    const char *source_path,
    char **diagnostic_output_out,
    char *binary_path,
    size_t binary_path_size
) {
    char command[4096];
    int command_length;
    int compile_result;
    const char *gcc_command;

    if (!is_safe_path(source_path) ||
        diagnostic_output_out == NULL ||
        binary_path == NULL || binary_path_size == 0) {
        return -1;
    }

    *diagnostic_output_out = NULL;
    binary_path[0] = '\0';

    gcc_command = find_gcc_command();
    if (gcc_command == NULL) {
        return -1;
    }

    if (snprintf(binary_path, binary_path_size, "%s", TEMP_BINARY) < 0) {
        return -1;
    }

    remove(TEMP_BINARY);
    remove(TEMP_DIAGNOSTICS);

    command_length = snprintf(
        command,
        sizeof(command),
        "%s -std=c11 -Wall -Wextra -Wpedantic "
        "-fdiagnostics-color=never \"%s\" -o \"%s\" "
        "2> \"%s\"",
        gcc_command,
        source_path,
        TEMP_BINARY,
        TEMP_DIAGNOSTICS
    );

    if (command_length < 0 || (size_t)command_length >= sizeof(command)) {
        return -1;
    }

    compile_result = system(command);

    /* (size_t)-1 tells read_text_file to keep the whole file, however
       large; GCC diagnostics for even a heavily broken, thousand-line
       file are nowhere near what this would actually need to cap. */
    *diagnostic_output_out = read_text_file(TEMP_DIAGNOSTICS, (size_t)-1);
    if (*diagnostic_output_out == NULL) {
        *diagnostic_output_out = (char *)calloc(1, sizeof(char));
    }

    remove(TEMP_DIAGNOSTICS);
    return compile_result;
}
