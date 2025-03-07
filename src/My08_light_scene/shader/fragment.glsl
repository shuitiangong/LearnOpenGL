#version 330 core
out vec4 FragColor;

in vec3 ourColor;
in vec2 TexCoord;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform vec3 objectColor;
uniform vec3 lightColor;

void main() {
    //FragColor = texture(ourTexture, TexCoord)*vec4(ourColor, 1.0f);
    FragColor = mix(texture(texture1, TexCoord), texture(texture2, vec2(TexCoord.x, TexCoord.y)), 0.2);
    FragColor = FragColor * vec4(objectColor*lightColor, 1.0);
    //FragColor = vec4(1.0f, 0, 0, 1.0f);
}