#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <float.h>
#include "../include/triangle_types.h"

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
    printf("vertex count: %ld\n", total_lines);

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

bool sample_triangle_height(vec3 p0, vec3 p1, vec3 p2, double x, double z, double *out_y) {
    if ((x>p0.x&&x>p1.x&&x>p2.x)||(x<p0.x&&x<p1.x&&x<p2.x)||(z>p0.z&&z>p1.z&&z>p2.z)||(z<p0.z&&z<p1.z&&z<p2.z)){
        return false;
    }
    double det = (p1.z - p2.z) * (p0.x - p2.x) + (p2.x - p1.x) * (p0.z - p2.z);
    
    if (det == 0.0) return false;

    double l1 = ((p1.z - p2.z) * (x - p2.x) + (p2.x - p1.x) * (z - p2.z)) / det;
    double l2 = ((p2.z - p0.z) * (x - p2.x) + (p0.x - p2.x) * (z - p2.z)) / det;
    double l3 = 1.0 - l1 - l2;

    const double eps = -1e-5; 
    if (l1 >= eps && l2 >= eps && l3 >= eps) {
        *out_y = l1 * p0.y + l2 * p1.y + l3 * p2.y;
        return true;
    }

    return false;
}

int main(int argc, char *argv[]) {

    // C:/Users/zacha/AppData/Roaming/Godot/app_userdata/idp rover/vertices.txt

    if (argc != 3) {
        printf("usage: %s input_file output_file\n",argv[0]);
        printf("inputted args: %d\n",argc);
        for (int i = 0; i < argc; i++){
            printf("%d: %s\n",i+1,argv[i]);
        }
        exit(EXIT_FAILURE);
    }

    vec3_list mesh = load_vertices(argv[1]);
    triangle_list_node *triangles = triangulate_vertices(mesh.vertices,mesh.count);

    double min_x = mesh.vertices[0].x;
    double max_x = mesh.vertices[0].x;
    double min_z = mesh.vertices[0].z;
    double max_z = mesh.vertices[0].z;

    for (size_t i = 1; i < mesh.count; i++) {
        if (mesh.vertices[i].x < min_x) min_x = mesh.vertices[i].x;
        if (mesh.vertices[i].x > max_x) max_x = mesh.vertices[i].x;
        if (mesh.vertices[i].z < min_z) min_z = mesh.vertices[i].z;
        if (mesh.vertices[i].z > max_z) max_z = mesh.vertices[i].z;
    }

    size_t width = (size_t)ceil((max_x - min_x) / pixel_size) + 1;
    size_t height = (size_t)ceil((max_z - min_z) / pixel_size) + 1;

    double *heightmap = (double *)malloc(width * height * sizeof(double));
    if (!heightmap) return 1;

    for (size_t grid_z = 0; grid_z < height; grid_z++) {
        for (size_t grid_x = 0; grid_x < width; grid_x++) {
            printf("\rPoint %4zu/%zu, %4zu/%zu",grid_x,width,grid_z,height);
            double world_x = min_x + (double)grid_x * pixel_size;
            double world_z = min_z + (double)grid_z * pixel_size;
            
            double found_height = 0.0;
            bool hit = false;

            triangle_list_node *current = triangles;
            while (current != NULL) {
                triangle tri = current->triangle;
                
                vec3 p0 = mesh.vertices[tri.i0];
                vec3 p1 = mesh.vertices[tri.i1];
                vec3 p2 = mesh.vertices[tri.i2];

                if (sample_triangle_height(p0, p1, p2, world_x, world_z, &found_height)) {
                    hit = true;
                    break; 
                }
                current = current->next;
            }

            heightmap[grid_z * width + grid_x] = hit ? found_height : 0.0;
        }
    }

    // draw to ppn file for debug

    if (!heightmap || width == 0 || height == 0) {
        printf("invalid heightmap\n");
        return 1;
    }

    double min_h = DBL_MAX;
    double max_h = -DBL_MAX;

    for (size_t i = 0; i < width * height; i++) {
        if (heightmap[i] < min_h) min_h = heightmap[i];
        if (heightmap[i] > max_h) max_h = heightmap[i];
    }

    double range = max_h - min_h;
    if (range == 0.0) {
        range = 1.0;
    }

    char output_image_path[300];
    snprintf(output_image_path,sizeof(output_image_path),"%s.test.pgm",argv[2]);

    FILE *fp = fopen(output_image_path, "wb");
    if (!fp) {
        printf("failed to open file for writing");
        return 1;
    }

    fprintf(fp, "P5\n%zu %zu\n255\n", width, height);

    unsigned char *row_buffer = (unsigned char *)malloc(width);
    if (!row_buffer) {
        fclose(fp);
        return 1;
    }

    for (size_t z = 0; z < height; z++) {
        for (size_t x = 0; x < width; x++) {
            double current_h = heightmap[z * width + x];

            double normalized = (current_h - min_h) / range;
            
            row_buffer[x] = (unsigned char)(normalized * 255.0);
        }
        fwrite(row_buffer, 1, width, fp);
    }

    free(row_buffer);
    fclose(fp);

    printf("\nrun: ffmpeg -i %s %s.png",output_image_path,output_image_path);
    // printf("hi");

    FILE *out_file = fopen(argv[2], "wb");
    if (!out_file) {
        printf("error opening file for writing");
        return 1;
    }

    const char magic[4] = {'r', 'v', 'h', 'p'};
    fwrite(magic, sizeof(char), 4, out_file);

    fwrite(&min_x,sizeof(double),1,out_file);
    fwrite(&min_z,sizeof(double),1,out_file);

    fwrite(&width, sizeof(int32_t), 1, out_file);
    fwrite(&height, sizeof(int32_t), 1, out_file);

    size_t total_elements = (size_t)width * (size_t)height;
    size_t written = fwrite(heightmap, sizeof(double), total_elements, out_file);

    fclose(out_file);
    
    return 0;
}