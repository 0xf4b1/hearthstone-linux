#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <cryptopp/modes.h>
#include <cryptopp/osrng.h>
#include <cryptopp/pwdbased.h>
#include <cryptopp/rijndael.h>
#include <cryptopp/sha.h>

using namespace CryptoPP;

void getEncryptionKey(unsigned char *key, int size) {
    unsigned char s_entropy[16] = {200, 118, 244, 174, 76, 149, 46, 254,
                                   242, 250, 15, 84, 25, 192, 156, 67};

    struct passwd *pwd = getpwuid(getuid());
    int length = strlen(pwd->pw_name);
    for (int i = 0; i < length; i++) {
        s_entropy[i] ^= pwd->pw_name[i];
    }

    unsigned char salt[] = {'s', 'o', 'm', 'e', 'S', 'a', 'l', 't'};
    byte unused = 0;
    PKCS5_PBKDF2_HMAC<SHA1> pbkdf;
    pbkdf.DeriveKey(key, size, unused, s_entropy, sizeof(s_entropy), salt, sizeof(salt), 1000, 0.0f);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("用法: %s <token>\n", argv[0]);
        printf("示例: %s CN-5bb2de31fba875c01427f99d696fe47f-206371446\n", argv[0]);
        return 1;
    }
    
    char *token = argv[1];
    
    // 检查token格式
    if (strlen(token) < 10 || strstr(token, "CN-") != token) {
        printf("错误: Token格式不正确，应以CN-开头\n");
        return 1;
    }
    
    unsigned char key[16] = {0};
    getEncryptionKey(key, sizeof(key));
    
    byte iv[16] = {0};
    byte cipher[48]; // KEY_LENGTH = 0x30 = 48
    
    try {
        CBC_Mode<AES>::Encryption e;
        e.SetKeyWithIV(key, 16, iv);
        StringSource s(token, true,
                       new StreamTransformationFilter(e, new ArraySink(cipher, sizeof(cipher)),
                                                      StreamTransformationFilter::PKCS_PADDING));
    } catch(const Exception &e) {
        printf("加密失败: %s\n", e.what());
        return 1;
    }
    
    FILE *file = fopen("token", "wb");
    if (!file) {
        printf("无法创建token文件\n");
        return 1;
    }
    
    fwrite(cipher, sizeof(cipher), 1, file);
    fclose(file);
    
    printf("Token加密成功！\n");
    printf("原始token: %s\n", token);
    printf("加密后大小: %lu 字节\n", sizeof(cipher));
    printf("已写入: token\n");
    
    // 显示hex
    printf("\nHex输出:\n");
    for (int i = 0; i < sizeof(cipher); i++) {
        printf("%02x", cipher[i]);
        if ((i + 1) % 16 == 0) printf("\n");
        else if ((i + 1) % 4 == 0) printf(" ");
    }
    printf("\n");
    
    return 0;
}