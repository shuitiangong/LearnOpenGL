#version 330 core

in vec2 TexCoords;

struct Material {
    sampler2D texture_diffuse0;
    sampler2D texture_specular0;

    float shininess;
}; 

uniform Material material;

struct DirLight {
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform DirLight dirLight;

vec3 CalcDirLight(DirLight dirLight, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(-dirLight.direction);
    vec3 reflectDir = reflect(-lightDir, normal);
    vec3 ambient = dirLight.ambient * vec3(texture(material.texture_diffuse0, TexCoords));
    //漫反射
    float diff = max(dot(normal, lightDir), 0.0f);
    vec3 diffuse = dirLight.diffuse * diff * vec3(texture(material.texture_diffuse0, TexCoords));
    //镜面光
    float spec = pow(max(dot(viewDir, reflectDir), 0.0f), material.shininess);
    vec3 specular = dirLight.specular * spec * vec3(texture(material.texture_specular0, TexCoords));
    return (ambient + diffuse + specular);
}

struct PointLight {
    vec3 position;

    float constant;
    float linear;
    float quadratic;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

#define NR_POINT_LIGHTS 4
uniform PointLight pointLights[NR_POINT_LIGHTS];

vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 lightDir = normalize(light.position - fragPos);
    vec3 reflectDir = reflect(-lightDir, normal);

    vec3 ambient = light.ambient * vec3(texture(material.texture_diffuse0, TexCoords));
    //漫反射
    float diff = max(dot(normal, lightDir), 0.0f);
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.texture_diffuse0, TexCoords));
    //镜面光
    float spec = pow(max(dot(viewDir, reflectDir), 0.0f), material.shininess);
    vec3 specular = light.specular * spec * vec3(texture(material.texture_specular0, TexCoords));

    //衰减
    float distance = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * distance * distance);
    return (ambient + (diffuse + specular) * attenuation);
}

struct SpotLight {
    float cutOff;
    float outerCutOff;
  
    vec3 position;
    vec3 direction;

    float constant;
    float linear;
    float quadratic;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform SpotLight spotLight;

vec3 CalcSpotLight(SpotLight spotLight, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 lightDir = normalize(spotLight.position - fragPos);
    
    // check if lighting is inside the spotlight cone
    float theta = dot(lightDir, normalize(-spotLight.direction)); 

    // remember that we're working with angles as cosines instead of degrees so a '>' is used.    
    if(theta > spotLight.outerCutOff) {
        // ambient
        vec3 ambient = spotLight.ambient * texture(material.texture_diffuse0, TexCoords).rgb;
        
        // diffuse 
        float diff = max(dot(normal, lightDir), 0.0);
        vec3 diffuse = spotLight.diffuse * diff * texture(material.texture_diffuse0, TexCoords).rgb;  
        
        // specular
        vec3 reflectDir = reflect(-lightDir, normal);  
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
        vec3 specular = spotLight.specular * spec * texture(material.texture_specular0, TexCoords).rgb;  
        
        // attenuation
        float distance    = length(spotLight.position - fragPos);
        float attenuation = 1.0 / (spotLight.constant + spotLight.linear * distance + spotLight.quadratic * (distance * distance));    

        // ambient  *= attenuation; // remove attenuation from ambient, as otherwise at large distances the light would be darker inside than outside the spotlight due the ambient term in the else branch
        diffuse  *= attenuation;
        specular *= attenuation;   

        float epsilon = spotLight.cutOff - spotLight.outerCutOff;
        float intensity = clamp((theta - spotLight.outerCutOff) / epsilon, 0.0, 1.0);            
        vec3 result = ambient + (diffuse + specular) * intensity;
        return result * vec3(1.0f, 0.0f, 0.0f) * 5;
    }
    else {
        // else, use ambient light so scene isn't completely dark outside the spotlight.
        return spotLight.ambient * texture(material.texture_diffuse0, TexCoords).rgb * vec3(0.0f, 1.0f, 0.0f) * 5;
    }
}

in vec3 FragPos;  
in vec3 Normal;  
  
uniform vec3 viewPos;
out vec4 FragColor;

void main() {
    //属性
    vec3 norm = normalize(Normal);
    vec3 viewDir = normalize(viewPos - FragPos);
    
    vec3 result = CalcDirLight(dirLight, norm, viewDir);
    for (int i = 0; i<NR_POINT_LIGHTS; ++i) {
        result += CalcPointLight(pointLights[i], norm, FragPos, viewDir);
    }
    result += CalcSpotLight(spotLight, norm, FragPos, viewDir);

    FragColor = vec4(result, 1.0);
} 