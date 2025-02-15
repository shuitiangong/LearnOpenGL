#version 330 core
out vec4 FragColor;

in vec3 ourColor;
in vec2 TexCoord;
in vec3 Normal;
in vec3 FragPos;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 viewPos;

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    sampler2D emission;
    float shininese;
};

uniform Material material;

struct Light {
    vec3 position;
    
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform Light light;

void main() {
    //FragColor = texture(ourTexture, TexCoord)*vec4(ourColor, 1.0f);
    //FragColor = texture(texture1, TexCoord);
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, TexCoord)) * lightColor;
    
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(Normal, lightDir), 0);
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, TexCoord)) * lightColor;

    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, Normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininese);
    vec3 specular = light.specular * vec3(texture(material.specular, TexCoord)) * spec;

    vec3 result = (ambient + diffuse + specular) * objectColor;

    vec4 emission = texture(material.emission, TexCoord);
    FragColor = mix(vec4(result, 1.0f), emission, 0.3);
    //FragColor = emission;
    //FragColor = vec4(1.0f, 0, 0, 1.0f);
}