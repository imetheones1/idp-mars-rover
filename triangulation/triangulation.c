#include "triangle_types.h"
#include <stdlib.h>

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

triangle_list_node* triangulate_vertices(vec3 *vertices, size_t vertex_count){
    
}