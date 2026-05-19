#include "../include/triangle_types.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#define SQRT_2 1.41421356237
#define flatness_weight 5

#define IS_INVALID(val) (fabsf(val) < 0.01)

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("usage: %s input_file output_file",argv[0]);
        return 1;
    }

    FILE *file = fopen(argv[1], "rb");
    if (!file) {
        printf("error opening file for reading");
        return 1;
    }

    char magic[4];
    if (fread(magic, sizeof(char), 4, file) != 4 || memcmp(magic, "rvhp", 4) != 0) {
        printf("heightmap file invalid, magic number incorrect\n");
        fclose(file);
        return 1;
    }

    double min_x = 0, min_z = 0;
    fread(&min_x, sizeof(double), 1, file);
    fread(&min_z, sizeof(double), 1, file);

    int32_t width = 0, height = 0;
    fread(&width, sizeof(int32_t), 1, file);
    fread(&height, sizeof(int32_t), 1, file);

    size_t total_elements = (size_t)width * (size_t)height;
    double *heightmap = (double *)malloc(total_elements * sizeof(double));
    if (!heightmap) {
        printf("memory allocation failed\n");
        fclose(file);
        return 1;
    }

    size_t read_elements = fread(heightmap, sizeof(double), total_elements, file);
    fclose(file);

    if (read_elements != total_elements) {
        fprintf(stderr, "read error or unexpected EOF\n");
        free(heightmap);
        return 1;
    }

    int start_x = 140, start_y = 140; 
    int goal_x = 160, goal_y = 160;

    int grid_size = width * height;
    double* g_score = (double*)malloc(grid_size * sizeof(double));
    double* f_score = (double*)malloc(grid_size * sizeof(double));
    int* came_from = (int*)malloc(grid_size * sizeof(int));
    int* open_set = (int*)malloc(grid_size * sizeof(int)); // 1 if in open set, 0 otherwise

    for (int i = 0; i < grid_size; i++) {
        g_score[i] = 1e9;
        f_score[i] = 1e9;
        came_from[i] = -1;
        open_set[i] = 0;
    }

    int start_idx = start_y * width + start_x;
    g_score[start_idx] = 0.0;

    double dx = (goal_x - start_x) * pixel_size;
    double dy = (goal_y - start_y) * pixel_size;
    f_score[start_idx] = sqrt(dx * dx + dy * dy);
    open_set[start_idx] = 1;

    int open_set_empty = 0;
    int path_found = 0;

    while (!open_set_empty) {
        int current_idx = -1;
        double min_f = 1e9;
        
        for (int i = 0; i < grid_size; i++) {
            if (open_set[i] && f_score[i] < min_f) {
                min_f = f_score[i];
                current_idx = i;
            }
        }

        if (current_idx == -1) {
            break;
        }

        int cur_x = current_idx % width;
        int cur_y = current_idx / width;

        if (cur_x == goal_x && cur_y == goal_y) {
            path_found = 1;
            break;
        }

        open_set[current_idx] = 0;

        for (int move_y = -1; move_y <= 1; move_y++) {
            for (int move_x = -1; move_x <= 1; move_x++) {
                if (move_x == 0 && move_y == 0) continue;

                int neighbor_x = cur_x + move_x;
                int neighbor_y = cur_y + move_y;

                if (neighbor_x >= 0 && neighbor_x < width && neighbor_y >= 0 && neighbor_y < height) {
                    int neighbor_idx = neighbor_y * width + neighbor_x;

                    if (IS_INVALID(heightmap[neighbor_idx])) {
                        continue;
                    }

                    double horiz_dist = ((move_x != 0 && move_y != 0) ? SQRT_2 : 1.0) * pixel_size;
                    
                    double height_diff = fabs(heightmap[neighbor_idx] - heightmap[current_idx]);
                    double flatness_penalty = height_diff * flatness_weight;

                    double step_cost = horiz_dist + flatness_penalty;
                    double tentative_g_score = g_score[current_idx] + step_cost;

                    if (tentative_g_score < g_score[neighbor_idx]) {
                        came_from[neighbor_idx] = current_idx;
                        g_score[neighbor_idx] = tentative_g_score;
                        
                        double h_dx = (goal_x - neighbor_x) * pixel_size;
                        double h_dy = (goal_y - neighbor_y) * pixel_size;
                        double h_score = sqrt(h_dx * h_dx + h_dy * h_dy);
                        
                        f_score[neighbor_idx] = g_score[neighbor_idx] + h_score;
                        open_set[neighbor_idx] = 1;
                    }
                }
            }
        }
    }

    if (path_found) {
        printf("path found\n");
        
        FILE *file = fopen(argv[2], "w");
        if (file == NULL) {
            printf("error opening file for writing\n");
        } else {
            int cur = goal_y * width + goal_x;
            
            int path_length = 0;
            int temp_cur = cur;
            while (temp_cur != -1) {
                path_length++;
                temp_cur = came_from[temp_cur];
            }
            
            int* path_indices = (int*)malloc(path_length * sizeof(int));
            
            int idx = path_length - 1;
            while (cur != -1) {
                path_indices[idx] = cur;
                cur = came_from[cur];
                idx--;
            }
            
            for (int i = 0; i < path_length; i++) {
                int node_idx = path_indices[i];
                int map_x = node_idx % width;
                int map_y = node_idx / width;
                
                double godot_x = min_x + (map_x * pixel_size);
                double godot_z = min_z + (map_y * pixel_size);
                double godot_y = heightmap[node_idx];
                
                fprintf(file, "%f,%f,%f\n", godot_x, godot_y, godot_z);
            }
            
            fclose(file);
            free(path_indices);
            printf("successfully wrote %d vertices to %s\n", path_length, argv[2]);
        }
    } else {
        printf("No valid path could be found.\n");
    }

    free(g_score);
    free(f_score);
    free(came_from);
    free(open_set);

    printf("success");
}