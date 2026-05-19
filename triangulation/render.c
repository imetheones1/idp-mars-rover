#include <SDL3/SDL.h>
#include "../include/triangle_types.h"

typedef struct mat4 {
    double m[4][4];
} mat4;

mat4 mat4_multiply(mat4 a, mat4 b) {
    mat4 result = {0};
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            result.m[i][j] = a.m[i][0] * b.m[0][j] +
                             a.m[i][1] * b.m[1][j] +
                             a.m[i][2] * b.m[2][j] +
                             a.m[i][3] * b.m[3][j];
        }
    }
    return result;
}

mat4 calculate_view_matrix(double yaw, double pitch, double zoom) {
    const double cos_y = SDL_cos(yaw);
    const double sin_y = SDL_sin(yaw);
    const double cos_p = SDL_cos(pitch);
    const double sin_p = SDL_sin(pitch);

    mat4 identity = {{
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 0, 1}
    }};

    mat4 translation = identity;
    translation.m[2][3] = -zoom; 

    mat4 rotation_p = identity;
    rotation_p.m[1][1] = cos_p;
    rotation_p.m[1][2] = sin_p;
    rotation_p.m[2][1] = -sin_p;
    rotation_p.m[2][2] = cos_p;

    mat4 rotation_y = identity;
    rotation_y.m[0][0] = cos_y;
    rotation_y.m[0][2] = -sin_y;
    rotation_y.m[2][0] = sin_y;
    rotation_y.m[2][2] = cos_y;

    mat4 view = mat4_multiply(translation, mat4_multiply(rotation_p, rotation_y));

    return view;
}

// static vec3 *vertices = NULL;
// static size_t vertex_count = 0;
// static size_t vertex_capacity = 0;

// void init_vertices(size_t initial_capacity){
//     vertex_capacity = initial_capacity;
//     vertices = SDL_malloc(initial_capacity * sizeof(vec3));
// }

// void push_vertex(vec3 vertex) {
//     if (vertex_count>=vertex_capacity){
//         if (vertex_capacity <= 0) {
//             vertex_capacity = 2;
//         }
//         vertex_capacity*=2;
//         vertices = SDL_realloc(vertices,vertex_capacity * sizeof(vec3));
//     }
//     vertices[vertex_count++] = vertex;
// }

vec3 transform_point(vec3 p, mat4 m) {
    return (vec3) {
        .x = m.m[0][0] * p.x + m.m[0][1] * p.y + m.m[0][2] * p.z + m.m[0][3],
        .y = m.m[1][0] * p.x + m.m[1][1] * p.y + m.m[1][2] * p.z + m.m[1][3],
        .z = m.m[2][0] * p.x + m.m[2][1] * p.y + m.m[2][2] * p.z + m.m[2][3]
    };
}

static int window_width = 800;
static int window_height= 600;

static SDL_Window *window;
static SDL_Renderer *renderer;

#define test_vertex_count 5000

static double calculate_test_terrain_height(double x, double z) {
    return (SDL_sin(3*x) + SDL_sin(5*z))*0.1;
}

int main() {
    bool result;

    // init_vertices(test_vertex_count);
    // SDL_srand(255255255255);
    // for (size_t i = 0; i < test_vertex_count; i++){
    //     vec3 cur = {
    //         .x = SDL_randf()*2 - 1,
    //         .z = SDL_randf()*2 - 1
    //     };
    //     cur.y = calculate_test_terrain_height(cur.x,cur.z);
    //     push_vertex(cur);
    // }

    vec3_list real_vertices = load_vertices("C:/Users/zacha/AppData/Roaming/Godot/app_userdata/idp rover/vertices.txt");

    triangle_list_node *triangles = triangulate_vertices(real_vertices.vertices,real_vertices.count);

    result = SDL_Init(SDL_INIT_VIDEO);
    if (!result) {
        SDL_Log("Failed to initialize SDL: %s",SDL_GetError());
        return 1;
    }

    result = SDL_CreateWindowAndRenderer("super awesome triangulator",window_width,window_height,0,&window,&renderer);
    if (!result) {
        SDL_Log("Failed to create window and renderer: %s",SDL_GetError());
        return 1;
    }

    SDL_SetRenderVSync(renderer,1);

    bool running = true;

    uint64_t now;
    uint64_t last = SDL_GetTicksNS();
    double dt;

    SDL_Event event;

    double pitch = 0;
    double yaw = 0;
    double zoom = 50;

    do {
        now = SDL_GetTicksNS();
        dt = (now - last)/1000000000.0;
        last = now;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT || event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED) {
                running = false;
            }
            if (!running) break;
        }
        if (!running) break;
        SDL_SetRenderDrawColor(renderer,0,0,0,255);
        SDL_RenderClear(renderer);

        bool w, a, s, d, q, e;

        SDL_PumpEvents();
        const bool *key_state = SDL_GetKeyboardState(NULL);

        w = key_state[SDL_SCANCODE_W];
        a = key_state[SDL_SCANCODE_A];
        s = key_state[SDL_SCANCODE_S];
        d = key_state[SDL_SCANCODE_D];
        e = key_state[SDL_SCANCODE_E];
        q = key_state[SDL_SCANCODE_Q];

        if (w&&!s) pitch += dt;
        else if (s&&!w) pitch -= dt;

        pitch = SDL_clamp(pitch,-1,1);

        if (a&&!d) yaw += dt;
        else if (d&&!a) yaw -= dt;

        if (e&&!q) zoom -= dt;
        else if (q&&!e) zoom += dt;
        if (zoom<0) zoom=0;

        // SDL_Log("%f,%f,%f",pitch,yaw,zoom);

        // transform points

        mat4 m = calculate_view_matrix(yaw,pitch,zoom);

        vec3 *transformed = SDL_malloc(real_vertices.count * sizeof(vec3));
        for (size_t i = 0; i < real_vertices.count; i++) {
            transformed[i] = transform_point(real_vertices.vertices[i],m);
        }

        SDL_SetRenderDrawColor(renderer,255,255,255,255);

        double *projected_x = SDL_malloc(real_vertices.count * sizeof(double));
        double *projected_y = SDL_malloc(real_vertices.count * sizeof(double));
        bool *valid = SDL_calloc(real_vertices.count * sizeof(bool), sizeof(bool));

        for (size_t i = 0; i < real_vertices.count; i++) {
            vec3 cur = transformed[i];
            if (cur.z > -0.01) continue;
            double inv_z = 1/cur.z;
            double x = (cur.x*inv_z +0.5) * window_width;
            double y = (cur.y*inv_z +0.5) * window_height;
            SDL_RenderPoint(renderer,x,y);
            projected_x[i] = x;
            projected_y[i] = y;
            valid[i] = true;
        }

        triangle_list_node *curr = triangles;
        do {
            int i0 = curr->triangle.i0;
            int i1 = curr->triangle.i1;
            int i2 = curr->triangle.i2;
            if (!valid[i0]||!valid[i1]||!valid[i2]) continue;
            SDL_RenderLine(renderer,projected_x[i0],projected_y[i0],projected_x[i1],projected_y[i1]);
            SDL_RenderLine(renderer,projected_x[i1],projected_y[i1],projected_x[i2],projected_y[i2]);
            SDL_RenderLine(renderer,projected_x[i0],projected_y[i0],projected_x[i2],projected_y[i2]);
            curr = curr->next;
        } while (curr);

        SDL_free(transformed);
        SDL_free(projected_x);
        SDL_free(projected_y);
        SDL_free(valid);

        SDL_RenderPresent(renderer);

    } while (running);

    return 0;
}