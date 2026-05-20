#ifndef TRIANGLE_TYPES_H_
#define TRIANGLE_TYPES_H_

#include <stdint.h>

typedef struct vec3 {
    double x;
    double y;
    double z;
} vec3;

typedef struct vec3_list {
    vec3 *vertices;
    size_t count;
} vec3_list;

typedef struct triangle {
    size_t i0;
    size_t i1;
    size_t i2;
} triangle;

typedef struct triangle_list_node {
    triangle triangle;
    struct triangle_list_node *next;
    struct triangle_list_node *prev;
} triangle_list_node;

typedef struct edge {
    size_t i0;
    size_t i1;
} edge;

triangle_list_node* triangulate_vertices(vec3 *vertices, size_t vertex_count);

vec3_list load_vertices(char *path);

#define pixel_size 2

#endif