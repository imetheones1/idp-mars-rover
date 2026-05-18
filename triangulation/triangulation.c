#include "triangle_types.h"
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

static triangle_list_node* create_node(triangle t) {
    triangle_list_node *new_node = (triangle_list_node*)malloc(sizeof(triangle_list_node));
    if (new_node == NULL) {
        return NULL; 
    }
    new_node->triangle = t;
    new_node->next = NULL;
    new_node->prev = NULL;
    return new_node;
}

static void append_node(triangle_list_node **head, triangle t) {
    triangle_list_node *new_node = create_node(t);
    if (new_node == NULL) return;

    if (*head == NULL) {
        *head = new_node;
        return;
    }

    triangle_list_node *current = *head;
    while (current->next != NULL) {
        current = current->next;
    }

    current->next = new_node;
    new_node->prev = current;
}

static void remove_node(triangle_list_node **head, triangle_list_node *node_to_remove) {
    if (head == NULL || *head == NULL || node_to_remove == NULL) {
        return;
    }

    if (*head == node_to_remove) {
        *head = node_to_remove->next;
    }

    if (node_to_remove->next != NULL) {
        node_to_remove->next->prev = node_to_remove->prev;
    }

    if (node_to_remove->prev != NULL) {
        node_to_remove->prev->next = node_to_remove->next;
    }

    free(node_to_remove);
}

static bool in_circumcircle(vec3 p, vec3 a, vec3 b, vec3 c) {
    double ab_x = a.x - p.x;
    double ab_z = a.z - p.z;
    double bb_x = b.x - p.x;
    double bb_z = b.z - p.z;
    double cb_x = c.x - p.x;
    double cb_z = c.z - p.z;

    double ab_sq = ab_x * ab_x + ab_z * ab_z;
    double bb_sq = bb_x * bb_x + bb_z * bb_z;
    double cb_sq = cb_x * cb_x + cb_z * cb_z;

    double det = ab_x * (bb_z * cb_sq - cb_z * bb_sq) -
                 ab_z * (bb_x * cb_sq - cb_x * bb_sq) +
                 ab_sq * (bb_x * cb_z - cb_x * bb_z);


    double ccw = (b.x - a.x) * (c.z - a.z) - (b.z - a.z) * (c.x - a.x);
    
    if (ccw < 0.0) {
        return det < -1e-9;
    }
    return det > 1e-9;
}

triangle_list_node* triangulate_vertices(vec3 *vertices, size_t vertex_count) {
    if (vertex_count == 0) return NULL;
    
    double max_x = vertices[0].x;
    double min_x = vertices[0].x;
    double max_z = vertices[0].z;
    double min_z = vertices[0].z;
    double avg_y = vertices[0].y;
    
    for (size_t i = 1; i < vertex_count; ++i) {
        vec3 *cur = &vertices[i];
        if (cur->x > max_x) max_x = cur->x;
        if (cur->x < min_x) min_x = cur->x;
        if (cur->z > max_z) max_z = cur->z;
        if (cur->z < min_z) min_z = cur->z;
        avg_y += cur->y;
    }
    avg_y /= (double)vertex_count;

    size_t total_vertex_count = vertex_count + 4;
    vec3 *all_vertices = (vec3*)malloc(sizeof(vec3) * total_vertex_count);
    if (!all_vertices) return NULL;

    for (size_t i = 0; i < vertex_count; i++) {
        all_vertices[i] = vertices[i];
    }

    size_t c0 = vertex_count;
    size_t c1 = vertex_count + 1;
    size_t c2 = vertex_count + 2;
    size_t c3 = vertex_count + 3;

    // padding
    double dx = max_x - min_x;
    double dz = max_z - min_z;
    double delta = (dx > dz ? dx : dz) * 10.0;
    if (delta < 1e-4) delta = 10.0;

    double mid_x = (min_x + max_x) * 0.5;
    double mid_z = (min_z + max_z) * 0.5;

    all_vertices[c0] = (vec3){mid_x - delta, avg_y, mid_z - delta};
    all_vertices[c1] = (vec3){mid_x + delta, avg_y, mid_z - delta};
    all_vertices[c2] = (vec3){mid_x + delta, avg_y, mid_z + delta};
    all_vertices[c3] = (vec3){mid_x - delta, avg_y, mid_z + delta};

    triangle_list_node *head = NULL;

    triangle super_t1 = {c0, c1, c2};
    triangle super_t2 = {c0, c2, c3};
    append_node(&head, super_t1);
    append_node(&head, super_t2);

    // Bowyer–Watson algorithm
    for (size_t i = 0; i < vertex_count; ++i) {
        vec3 p = all_vertices[i];

        size_t max_bad = 0;
        triangle_list_node *curr = head;
        while (curr) { max_bad++; curr = curr->next; }

        triangle_list_node **bad_triangles = malloc(sizeof(triangle_list_node*) * max_bad);
        edge *polygon = malloc(sizeof(edge) * max_bad * 3);
        size_t bad_count = 0;
        size_t edge_count = 0;

        curr = head;
        while (curr != NULL) {
            triangle t = curr->triangle;
            if (in_circumcircle(p, all_vertices[t.i0], all_vertices[t.i1], all_vertices[t.i2])) {
                bad_triangles[bad_count++] = curr;
            }
            curr = curr->next;
        }

        for (size_t j = 0; j < bad_count; ++j) {
            triangle t = bad_triangles[j]->triangle;
            edge edges[3] = { {t.i0, t.i1}, {t.i1, t.i2}, {t.i2, t.i0} };

            for (int e = 0; e < 3; ++e) {
                bool shared = false;
                for (size_t k = 0; k < bad_count; ++k) {
                    if (j == k) continue;
                    triangle ot = bad_triangles[k]->triangle;
                    if ((edges[e].i0 == ot.i0 || edges[e].i0 == ot.i1 || edges[e].i0 == ot.i2)&&(edges[e].i1 == ot.i0 || edges[e].i1 == ot.i1 || edges[e].i1 == ot.i2)) {
                        shared = true;
                        break;
                    }
                }
                if (!shared) {
                    polygon[edge_count++] = edges[e];
                }
            }
        }

        for (size_t j = 0; j < bad_count; ++j) {
            remove_node(&head, bad_triangles[j]);
        }

        for (size_t j = 0; j < edge_count; ++j) {
            triangle new_t = {polygon[j].i0, polygon[j].i1, i};
            append_node(&head, new_t);
        }

        free(bad_triangles);
        free(polygon);
    }

    triangle_list_node *curr = head;
    while (curr != NULL) {
        triangle_list_node *next_node = curr->next;
        triangle t = curr->triangle;
        if (t.i0 >= vertex_count || t.i1 >= vertex_count || t.i2 >= vertex_count) {
            remove_node(&head, curr);
        }
        curr = next_node;
    }

    free(all_vertices);
    return head;
}