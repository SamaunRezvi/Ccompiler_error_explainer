#include "compiler.h"
#include "explainer.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void print_usage(const char *program_name) {
    printf("C Compiler Error Explainer\n\n");
    printf("Usage:\n");
    printf("  %s <source.c> [--offline]\n\n", program_name);
    printf("Examples:\n");
    printf("  %s examples/missing_semicolon.c --offline\n", program_name);
    printf("  %s playground/user_code.c\n", program_name);
}

static int has_c_extension(const char *path) {
    const char *extension;

    if (path == NULL) {
        return 0;
    }

    extension = strrchr(path, '.');
    if (extension == NULL || extension[1] == '\0' || extension[2] != '\0') {
        return 0;
    }

    return extension[1] == 'c' || extension[1] == 'C';
}

int main(int argc, char *argv[]) {
    const char *source_path;
    int offline_only = 0;
    char *compiler_output = NULL;
    char binary_path[256];
    int compile_result;
    char *source_code;

    if (argc < 2 || argc > 3) {
        print_usage(argv[0]);
        return 1;
    }

    source_path = argv[1];

    if (argc == 3) {
        if (strcmp(argv[2], "--offline") != 0) {
            fprintf(stderr, "Error: Unsupported option '%s'.\n\n", argv[2]);
            print_usage(argv[0]);
            return 1;
        }
        offline_only = 1;
    }

    if (!has_c_extension(source_path)) {
        fprintf(stderr, "Error: Please provide a C source file with a .c extension.\n");
        return 1;
    }

    if (!is_safe_path(source_path)) {
        fprintf(stderr, "Error: The provided file path is unsafe or unsupported.\n");
        return 1;
    }

    if (!is_gcc_available()) {
        fprintf(stderr, "Error: GCC was not found.\n");
        fprintf(stderr, "Run 'gcc --version' in the VS Code terminal to verify the installation.\n");
#ifdef _WIN32
        fprintf(stderr, "For MSYS2 UCRT64, add C:\\msys64\\ucrt64\\bin to PATH.\n");
#endif
        return 1;
    }

    source_code = read_text_file(source_path, (size_t)-1);
    if (source_code == NULL) {
        fprintf(stderr, "Error: Unable to read the source file: %s\n", source_path);
        return 1;
    }

    printf("\nCompiling: %s\n", source_path);

    compile_result = compile_c_file(
        source_path,
        &compiler_output,
        binary_path,
        sizeof(binary_path)
    );

    if (compile_result == -1) {
        fprintf(stderr, "Error: Unable to create or execute the compiler command.\n");
        free(compiler_output);
        free(source_code);
        return 1;
    }

    if (compile_result == 0) {
        printf("\n========================================\n");
        printf("Compilation Successful\n");
        printf("========================================\n");
        printf("Generated executable: %s\n", binary_path);

        if (compiler_output[0] != '\0') {
            printf("\nThe program compiled, but GCC reported warnings.\n");
            printf("\n=== Raw GCC Warning Output ===\n%s\n", compiler_output);
            explain_diagnostics(compiler_output);
        } else {
            printf("No compiler errors or warnings were detected.\n");
        }

        free(compiler_output);
        free(source_code);
        return 0;
    }

    printf("\n========================================\n");
    printf("Compilation Failed\n");
    printf("========================================\n");
    printf("\n=== Raw GCC Diagnostic Output ===\n%s\n", compiler_output);

    explain_diagnostics(compiler_output);

    (void)offline_only;
    free(compiler_output);
    free(source_code);
    return 2;
}
