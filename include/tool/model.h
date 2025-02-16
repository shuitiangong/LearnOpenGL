#ifndef MODEL_H
#define MODEL_H
#include <glad/glad.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>

#include <tool/mesh.h>
#include <tool/shader.h>
#define STB_IMAGE_IMPLEMENTATION
#include <tool/stb_image.h>

#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <map>
#include <vector>
using namespace std;

class Model {
public:
	Model(char *path) {
		loadModel(path);
	}
	void Draw(Shader &shader) {
		for (unsigned int i = 0; i<meshes.size(); ++i) {
			meshes[i].Draw(shader);
		}
	}
private:
	vector<Mesh> meshes;
	string directory;
	unordered_map<string, bool> mpTexLoaded;

	void loadModel(string path) {
		Assimp::Importer import;
		const aiScene *scene = import.ReadFile(path, aiProcess_Triangulate | aiProcess_FlipUVs);
		if (!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode) {
			cout << "ERROR::ASSIMP::" << import.GetErrorString() << endl;
        	return;
		}
		directory = path.substr(0, path.find_last_of('/'));

		processNode(scene->mRootNode, scene);
	}
	void processNode(aiNode *node, const aiScene *scene) {
		//处理节点所有的网格
		for (unsigned int i = 0; i<node->mNumMeshes; ++i) {
			aiMesh *mesh = scene->mMeshes[node->mMeshes[i]];
			meshes.push_back(processMesh(mesh, scene));
		}

		std::cout << node->mName.C_Str() << std::endl;
		//处理子节点
		for (unsigned int i = 0; i<node->mNumChildren; ++i) {
			processNode(node->mChildren[i], scene);
		}

		//可以直接遍历所有mesh，但是如果需要建立mesh之间的父子关系，还是要递归处理
	}
	Mesh processMesh(aiMesh *mesh, const aiScene *scene) {
		vector<Vertex> vertices;
		vector<unsigned int> indices;
		vector<Texture> textures;

		for (unsigned int i = 0; i<mesh->mNumVertices; ++i) {
			Vertex vertex;
			//处理顶点位置、法线、纹理坐标
			auto &v1 = mesh->mVertices[i];
			vertex.Position = glm::vec3(v1.x, v1.y, v1.z);
			auto &v2 = mesh->mNormals[i];
			vertex.Normal = glm::vec3(v2.x, v2.y, v2.z);

			//检查是否有纹理坐标
			if (mesh->mTextureCoords[0]) {
				glm::vec2 vec;
				auto &v3 = mesh->mTextureCoords[0][i];
				vertex.TexCoords = glm::vec2(v3.x, v3.y);
			}
			else {
				vertex.TexCoords = glm::vec2(0.0f, 0.0f);
			}

			vertices.push_back(vertex);
		}
		//处理索引
		for (unsigned int i = 0; i<mesh->mNumFaces; ++i) {
			aiFace face = mesh->mFaces[i];
			for (unsigned int j = 0; j<face.mNumIndices; ++j) {
				indices.push_back(face.mIndices[j]);
			}
		}
		//处理材质
		if (mesh->mMaterialIndex >= 0){
			aiMaterial *material = scene->mMaterials[mesh->mMaterialIndex];
			vector<Texture> diffuseMaps = loadMaterialTextures(material, aiTextureType_DIFFUSE, "texture_diffuse");
			textures.insert(textures.end(), diffuseMaps.begin(), diffuseMaps.end());
			vector<Texture> specularMaps = loadMaterialTextures(material, aiTextureType_SPECULAR, "texture_specular");
			textures.insert(textures.end(), specularMaps.begin(), specularMaps.end());
		}

		return Mesh(vertices, indices, textures);
	}
	vector<Texture> loadMaterialTextures(aiMaterial *mat, aiTextureType type, string typeName) {
		vector<Texture> textures;
		for (unsigned int i = 0; i<mat->GetTextureCount(type); ++i) {
			aiString str;
			mat->GetTexture(type, i, &str);
			if (mpTexLoaded.find(str.C_Str()) == mpTexLoaded.end()) {
				Texture texture;
				texture.id = TextureFromFile(str.C_Str(), directory);
				texture.type = typeName;
				texture.path = str.C_Str();
				textures.push_back(texture);
			}
		}

		return textures;
	}

	unsigned int TextureFromFile(const char *path, const string &directory) {
		string filename = string(path);
		filename = directory + '/' + filename;

		unsigned int textureID;
		glGenTextures(1, &textureID);

		int width, height, nrComponents;
		unsigned char *data = stbi_load(filename.c_str(), &width, &height, &nrComponents, 0);
		if (data)
		{
			GLenum format;
			if (nrComponents == 1)
				format = GL_RED;
			else if (nrComponents == 3)
				format = GL_RGB;
			else if (nrComponents == 4)
				format = GL_RGBA;

			glBindTexture(GL_TEXTURE_2D, textureID);
			glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
			glGenerateMipmap(GL_TEXTURE_2D);

			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

			stbi_image_free(data);
		}
		else
		{
			std::cout << "Texture failed to load at path: " << path << std::endl;
			stbi_image_free(data);
		}

		return textureID;
	}
};

#endif