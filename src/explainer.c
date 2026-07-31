#include "explainer.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LOCATION_LEN 1024
#define MAX_MESSAGE_LEN 2048
#define INITIAL_ENTRY_CAPACITY 32

typedef struct {
    char location[MAX_LOCATION_LEN];
    char message[MAX_MESSAGE_LEN];
    int is_warning;
} diagnostic_entry;

static int contains(const char *text, const char *needle) {
    return text != NULL && needle != NULL && strstr(text, needle) != NULL;
}

static void copy_bounded(char *destination, size_t destination_size, const char *source, size_t source_len) {
    size_t bytes_to_copy;

    if (destination == NULL || destination_size == 0) {
        return;
    }

    bytes_to_copy = source_len;
    if (bytes_to_copy >= destination_size) {
        bytes_to_copy = destination_size - 1;
    }

    memcpy(destination, source, bytes_to_copy);
    destination[bytes_to_copy] = '\0';
}

static void trim_trailing_whitespace(char *text) {
    size_t length = strlen(text);

    while (length > 0 &&
           (text[length - 1] == '\r' ||
            text[length - 1] == '\n' ||
            text[length - 1] == ' ' ||
            text[length - 1] == '\t')) {
        text[length - 1] = '\0';
        --length;
    }
}

/* Grows *entries_out with realloc as needed, so a file with hundreds or
   thousands of diagnostics is parsed in full; nothing here caps the
   number of errors/warnings or how long an individual line can be. */
static int parse_diagnostics(const char *compiler_output, diagnostic_entry **entries_out) {
    const char *line_start = compiler_output;
    diagnostic_entry *entries = NULL;
    size_t capacity = 0;
    int count = 0;

    while (*line_start != '\0') {
        const char *line_end = strchr(line_start, '\n');
        size_t line_len = (line_end != NULL)
            ? (size_t)(line_end - line_start)
            : strlen(line_start);
        char *line_buffer = (char *)malloc(line_len + 1);
        const char *error_marker;
        const char *warning_marker;
        const char *marker = NULL;
        size_t marker_len = 0;
        int is_warning = 0;

        if (line_buffer == NULL) {
            break;
        }

        memcpy(line_buffer, line_start, line_len);
        line_buffer[line_len] = '\0';
        trim_trailing_whitespace(line_buffer);

        error_marker = strstr(line_buffer, " error: ");
        warning_marker = strstr(line_buffer, " warning: ");

        if (error_marker != NULL && (warning_marker == NULL || error_marker < warning_marker)) {
            marker = error_marker;
            marker_len = strlen(" error: ");
            is_warning = 0;
        } else if (warning_marker != NULL) {
            marker = warning_marker;
            marker_len = strlen(" warning: ");
            is_warning = 1;
        }

        if (marker != NULL) {
            size_t location_len = (size_t)(marker - line_buffer);

            if (location_len > 0 && line_buffer[location_len - 1] == ':') {
                --location_len;
            }

            if ((size_t)count == capacity) {
                size_t new_capacity = (capacity == 0) ? INITIAL_ENTRY_CAPACITY : capacity * 2;
                diagnostic_entry *grown = (diagnostic_entry *)realloc(
                    entries,
                    new_capacity * sizeof(diagnostic_entry)
                );

                if (grown == NULL) {
                    free(line_buffer);
                    break;
                }

                entries = grown;
                capacity = new_capacity;
            }

            copy_bounded(
                entries[count].location,
                sizeof(entries[count].location),
                line_buffer,
                location_len
            );
            copy_bounded(
                entries[count].message,
                sizeof(entries[count].message),
                marker + marker_len,
                strlen(marker + marker_len)
            );
            entries[count].is_warning = is_warning;
            ++count;
        }

        free(line_buffer);

        if (line_end == NULL) {
            break;
        }
        line_start = line_end + 1;
    }

    *entries_out = entries;
    return count;
}

static void explain_message(const char *message, const char **out_cause, const char **out_fix) {
    if (contains(message, "expected ',' or ';'") || contains(message, "expected ';'")) {
        *out_cause = "A statement or declaration just above this line is missing a semicolon (;).";
        *out_fix = "Add the missing semicolon at the end of the previous line, then recompile.";
    } else if (contains(message, "undeclared")) {
        *out_cause = "This name is used before it was declared, or an earlier missing semicolon broke the "
                     "statement so the declaration never took effect.";
        *out_fix = "Declare the variable or function before using it, check the spelling, and fix any error "
                    "reported above this one first.";
    } else if (contains(message, "expected ')'")) {
        *out_cause = "A closing parenthesis is missing, or an earlier token inside the parentheses is invalid.";
        *out_fix = "Check that every '(' in this statement has a matching ')' and that the expression inside "
                    "is complete.";
    } else if (contains(message, "expected '}'") ||
               contains(message, "expected declaration or statement at end of input")) {
        *out_cause = "A closing brace '}' is missing, so the compiler reached the end of the file while still "
                     "inside a block.";
        *out_fix = "Check that every '{' has a matching '}', especially around the function or block "
                    "mentioned above.";
    } else if (contains(message, "expected statement")) {
        *out_cause = "This is a knock-on effect of the error reported just above it; the parser could not "
                     "recover cleanly.";
        *out_fix = "Fix the error above first, then recompile. This one will likely disappear on its own.";
    } else if (contains(message, "too few arguments")) {
        *out_cause = "This function is being called with fewer arguments than its declaration requires.";
        *out_fix = "Check the function's prototype and pass every required argument.";
    } else if (contains(message, "too many arguments")) {
        *out_cause = "This function is being called with more arguments than its declaration accepts.";
        *out_fix = "Remove the extra argument(s), or update the function's prototype.";
    } else if (contains(message, "implicit declaration")) {
        *out_cause = "This function is called before it has been declared, or its header was not included.";
        *out_fix = "Add a prototype above main(), or #include the header that declares it.";
    } else if (contains(message, "conflicting types")) {
        *out_cause = "This function or variable is declared more than once with different types or signatures.";
        *out_fix = "Make sure every declaration of this name uses the same return type and parameter list.";
    } else if (contains(message, "incompatible pointer") || contains(message, "incompatible type")) {
        *out_cause = "A value of one type is being assigned to, or compared with, an incompatible type.";
        *out_fix = "Check the types on both sides and add an explicit cast only if the conversion is intentional.";
    } else if (contains(message, "unused variable") || contains(message, "unused parameter")) {
        *out_cause = "This variable or parameter is declared but never used anywhere in the function.";
        *out_fix = "Remove it if it is not needed, or use it if it was meant to be used.";
    } else if (contains(message, "control reaches end of non-void function")) {
        *out_cause = "This function is declared to return a value, but at least one code path falls off the "
                     "end without a return statement.";
        *out_fix = "Add a return statement that covers every possible path through the function.";
    } else if (contains(message, "redefinition")) {
        *out_cause = "This name is defined more than once in a way the compiler cannot merge.";
        *out_fix = "Keep only one definition, or move the extra one into a header guarded with "
                    "#ifndef/#define.";
    } else {
        *out_cause = "GCC reported this exact issue below; no specific pattern is matched for it.";
        *out_fix = "Read the message together with the quoted source line and the caret (^) position above.";
    }
}

void explain_diagnostics(const char *compiler_output) {
    diagnostic_entry *entries = NULL;
    int count;
    int index;

    if (compiler_output == NULL || *compiler_output == '\0') {
        return;
    }

    count = parse_diagnostics(compiler_output, &entries);
    if (count == 0) {
        free(entries);
        return;
    }

    printf("\n=== Smart Explanation ===\n");

    for (index = 0; index < count; ++index) {
        const char *cause = NULL;
        const char *fix = NULL;

        explain_message(entries[index].message, &cause, &fix);

        printf(
            "\n[%d] %s: %s\n",
            index + 1,
            entries[index].is_warning ? "Warning" : "Error",
            entries[index].message
        );
        printf("    Location     : %s\n", entries[index].location);
        printf("    Likely Cause : %s\n", cause);
        printf("    Suggested Fix: %s\n", fix);
    }

    free(entries);
}
