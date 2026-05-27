shader_type canvas_item;

void fragment() {
    // Read the texture (which only has data in the Red channel)
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Copy the Red channel's value across Red, Green, and Blue to make it grayscale
    COLOR = vec4(vec3(tex_color.r), 1.0);
}