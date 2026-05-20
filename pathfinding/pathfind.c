#include "../include/triangle_types.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <string.h>
#include <float.h>

#define SQRT_2 1.41421356237f
#define flatness_weight 5.0f

// maximum allowed step height between neighbors
#define MAX_SLOPE 2.0f

// sentinel invalid terrain value
#define INVALID_HEIGHT -99999.0f

#define IS_INVALID(val) ((val) <= INVALID_HEIGHT)

typedef struct heap_node {
    int idx;
    float f_score;
} heap_node;

typedef struct min_heap {
    heap_node *data;
    size_t size;
    size_t capacity;
} min_heap;

static void heap_swap(heap_node *a, heap_node *b) {
    heap_node tmp = *a;
    *a = *b;
    *b = tmp;
}

static void heap_push(min_heap *heap, int idx, float f_score) {
    if (heap->size >= heap->capacity) {
        heap->capacity *= 2;
        heap->data = realloc(heap->data, heap->capacity * sizeof(heap_node));

        if (!heap->data) {
            printf("heap realloc failed\n");
            exit(1);
        }
    }

    size_t i = heap->size++;

    heap->data[i] = (heap_node){
        .idx = idx,
        .f_score = f_score
    };

    while (i > 0) {
        size_t parent = (i - 1) / 2;

        if (heap->data[parent].f_score <= heap->data[i].f_score) {
            break;
        }

        heap_swap(&heap->data[parent], &heap->data[i]);

        i = parent;
    }
}

static heap_node heap_pop(min_heap *heap) {
    heap_node result = heap->data[0];

    heap->data[0] = heap->data[--heap->size];

    size_t i = 0;

    while (1) {
        size_t left = i * 2 + 1;
        size_t right = i * 2 + 2;
        size_t smallest = i;

        if (left < heap->size && heap->data[left].f_score < heap->data[smallest].f_score) {
            smallest = left;
        }

        if (right < heap->size && heap->data[right].f_score < heap->data[smallest].f_score) {
            smallest = right;
        }

        if (smallest == i) {
            break;
        }

        heap_swap(&heap->data[i], &heap->data[smallest]);

        i = smallest;
    }

    return result;
}

static inline float heuristic(int dx, int dy) {
    dx = abs(dx);
    dy = abs(dy);

    int min_d = dx < dy ? dx : dy;
    int max_d = dx > dy ? dx : dy;

    return (float)(max_d - min_d) + ((float)min_d * SQRT_2);
}

int main(int argc, char *argv[]) {
    if (argc != 7) {
        printf("usage: %s input_file output_file start_x start_z goal_x goal_z\n", argv[0]);
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

    double min_x = 0.0;
    double min_z = 0.0;

    fread(&min_x, sizeof(double), 1, file);
    fread(&min_z, sizeof(double), 1, file);

    double real_pixel_size = pixel_size;
    fread(&real_pixel_size, sizeof(double), 1, file);

    int32_t width = 0;
    int32_t height = 0;

    fread(&width, sizeof(int32_t), 1, file);
    fread(&height, sizeof(int32_t), 1, file);

    size_t grid_size = (size_t)width * (size_t)height;
    float *heightmap = malloc(grid_size * sizeof(float));

    if (!heightmap) {
        printf("memory allocation failed\n");
        fclose(file);
        return 1;
    }

    double temp_height = 0.0;
    for (size_t i = 0; i < grid_size; i++) {
        if (fread(&temp_height, sizeof(double), 1, file) != 1) {
            printf("read error");
            fclose(file);
            free(heightmap);
            return 1;
        }

        heightmap[i] = (float)temp_height;
    }

    fclose(file);

    float start_world_x = (float)atof(argv[3]);
    float start_world_z = (float)atof(argv[4]);

    float goal_world_x = (float)atof(argv[5]);
    float goal_world_z = (float)atof(argv[6]);

    int start_x = (int)roundf((start_world_x - (float)min_x) / real_pixel_size);
    int start_y = (int)roundf((start_world_z - (float)min_z) / real_pixel_size);
    int goal_x  = (int)roundf((goal_world_x  - (float)min_x) / real_pixel_size);
    int goal_y  = (int)roundf((goal_world_z  - (float)min_z) / real_pixel_size);

    if (
        start_x < 0 || start_x >= width ||
        start_y < 0 || start_y >= height ||
        goal_x < 0 || goal_x >= width ||
        goal_y < 0 || goal_y >= height
    ) {
        printf("positions outside heightmap");
        free(heightmap);
        return 1;
    }

    float *g_score = malloc(grid_size * sizeof(float));
    int32_t *came_from = malloc(grid_size * sizeof(int32_t));

    uint8_t *open_set = calloc(grid_size, sizeof(uint8_t));
    uint8_t *closed_set = calloc(grid_size, sizeof(uint8_t));

    if (
        !g_score ||
        !came_from ||
        !open_set ||
        !closed_set
    ) {
        printf("memory allocation failed\n");

        free(heightmap);
        free(g_score);
        free(came_from);
        free(open_set);
        free(closed_set);

        return 1;
    }

    for (size_t i = 0; i < grid_size; i++) {
        g_score[i] = FLT_MAX;
        came_from[i] = -1;
    }

    static const int move_x[8] = {
        -1, 0, 1,
        -1,    1,
        -1, 0, 1
    };

    static const int move_y[8] = {
       -1, -1, -1,
        0,      0,
        1,  1,  1
    };

    static const float move_cost[8] = {
        SQRT_2, 1.0f, SQRT_2,
        1.0f,         1.0f,
        SQRT_2, 1.0f, SQRT_2
    };

    min_heap heap = {
        .size = 0,
        .capacity = 1024,
        .data = malloc(1024 * sizeof(heap_node))
    };

    if (!heap.data) {
        printf("heap allocation failed\n");
        return 1;
    }

    int start_idx = start_y * width + start_x;

    g_score[start_idx] = 0.0f;

    heap_push(
        &heap,
        start_idx,
        heuristic(goal_x - start_x, goal_y - start_y)
    );

    open_set[start_idx] = 1;

    int path_found = 0;

    while (heap.size > 0) {

        heap_node current_node = heap_pop(&heap);

        int current_idx = current_node.idx;

        if (closed_set[current_idx]) {
            continue;
        }

        closed_set[current_idx] = 1;

        int cur_x = current_idx % width;
        int cur_y = current_idx / width;

        if (cur_x == goal_x && cur_y == goal_y) {
            path_found = 1;
            break;
        }

        float current_height = heightmap[current_idx];

        for (int i = 0; i < 8; i++) {

            int neighbor_x = cur_x + move_x[i];
            int neighbor_y = cur_y + move_y[i];

            if (
                neighbor_x < 0 ||
                neighbor_x >= width ||
                neighbor_y < 0 ||
                neighbor_y >= height
            ) {
                continue;
            }

            int neighbor_idx = neighbor_y * width + neighbor_x;

            if (closed_set[neighbor_idx]) {
                continue;
            }

            float neighbor_height = heightmap[neighbor_idx];

            if (IS_INVALID(neighbor_height)) {
                continue;
            }

            float height_diff = fabsf(neighbor_height - current_height);

            if (height_diff > MAX_SLOPE) {
                continue;
            }

            float step_cost = (move_cost[i] * real_pixel_size) + (height_diff * flatness_weight);

            float tentative_g = g_score[current_idx] + step_cost;

            if (tentative_g < g_score[neighbor_idx]) {
                came_from[neighbor_idx] = current_idx;

                g_score[neighbor_idx] = tentative_g;

                float h = heuristic(
                    goal_x - neighbor_x,
                    goal_y - neighbor_y
                );

                float f = tentative_g + h;

                heap_push(&heap, neighbor_idx, f);

                open_set[neighbor_idx] = 1;
            }
        }
    }

    if (path_found) {
        printf("path found\n");

        FILE *out = fopen(argv[2], "w");

        if (!out) {
            printf("error opening output file\n");
        } else {

            int goal_idx = goal_y * width + goal_x;

            size_t path_capacity = 1024;
            size_t path_count = 0;

            int32_t *path = malloc(path_capacity * sizeof(int32_t));

            if (!path) {
                printf("path allocation failed\n");
                return 1;
            }

            int current = goal_idx;

            while (current != -1) {
                if (path_count >= path_capacity) {

                    path_capacity *= 2;

                    path = realloc(
                        path,
                        path_capacity * sizeof(int32_t)
                    );

                    if (!path) {
                        printf("path realloc failed");
                        return 1;
                    }
                }

                path[path_count++] = current;

                current = came_from[current];
            }

            for (size_t i = path_count; i > 0; i--) {
                int idx = path[i - 1];

                int map_x = idx % width;
                int map_y = idx / width;

                float world_x = (float)min_x + ((float)map_x * real_pixel_size);

                float world_z = (float)min_z + ((float)map_y * real_pixel_size);

                float world_y = heightmap[idx];

                fprintf(
                    out,
                    "%f,%f,%f\n",
                    world_x,
                    world_y,
                    world_z
                );
            }

            fclose(out);

            free(path);

            printf("successfully wrote %zu vertices to %s\n",path_count,argv[2]);
        }
    } else {
        printf("no valid path");
        return 1;
    }

    free(heap.data);

    free(g_score);
    free(came_from);

    free(open_set);
    free(closed_set);

    free(heightmap);

    printf("success");

    return 0;
}