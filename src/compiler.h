#ifndef COMPILER_H
#define COMPILER_H

#include <stddef.h>

int is_gcc_available(void);
int is_safe_path(const char *path);
char *read_text_file(const char *path, size_t max_bytes);

/* diagnostic_output_out receives a malloc'd string (caller must free it).
   The diagnostic text is captured in full, with no artificial size cap,
   so files with hundreds or thousands of errors are never truncated. */
int compile_c_file(
    const char *source_path,
    char **diagnostic_output_out,
    char *binary_path,
    size_t binary_path_size
);

#endif
