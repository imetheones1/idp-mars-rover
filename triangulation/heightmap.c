#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "triangle_types.h"

#define LINE_LEN 51

vec3_list load_vertices(char *path){
    FILE *file_pointer = fopen(path, "r");
    if (file_pointer == NULL){
        printf("failed");
        exit(1);
    }

    fseek(file_pointer, 0, SEEK_END);
    long total_bytes = ftell(file_pointer);
    fseek(file_pointer, 0, SEEK_SET);

    long total_lines = total_bytes / LINE_LEN;
    // printf("vertex count:: %ld\n\n", total_lines);

    vec3 *vertexes = malloc(total_lines * sizeof(vec3));

    char buffer[LINE_LEN + 1]; 
    long current_line = 0;

    char *x, *y, *z;

    while (fgets(buffer, sizeof(buffer), file_pointer) != NULL) {

        // printf("Line %ld/%ld: %s", current_line+1, total_lines, buffer);

        x = strtok(buffer, ",");
        y = strtok(NULL, ",");
        z = strtok(NULL, ",");

        // printf("vertexes: %s, %s, %s",x,y,z);

        vertexes[current_line] = (vec3){
            .x = strtod(x,NULL),
            .y = strtod(y,NULL),
            .z = strtod(z,NULL),
        };

        current_line++;
    }

    fclose(file_pointer);

    return (vec3_list){
        .vertices = vertexes,
        .count = total_lines
    };
}

int main_fake(int argc, char *argv[]) {

    // C:/Users/zacha/AppData/Roaming/Godot/app_userdata/idp rover/vertices.txt

    if (argc != 3) {
        printf("usage: %s input_file output_file",argv[0]);
        exit(EXIT_FAILURE);
    }

    
    return 0;
}