#!/usr/bin/env python3
import os
import sys
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Hash import SHA1
import struct

def get_encryption_key():
    """模拟C++中的getEncryptionKey函数"""
    # 原始熵值
    s_entropy = bytearray([200, 118, 244, 174, 76, 149, 46, 254,
                           242, 250, 15, 84, 25, 192, 156, 67])
    
    # 获取当前用户名
    username = os.getlogin()
    
    # XOR操作
    for i in range(len(username)):
        s_entropy[i] ^= ord(username[i])
    
    # PBKDF2密钥派生
    salt = b'someSalt'
    key = PBKDF2(bytes(s_entropy), salt, dkLen=16, count=1000, hmac_hash_module=SHA1)
    return key

def encrypt_token(token):
    """加密token"""
    key = get_encryption_key()
    iv = bytes(16)  # 全零IV
    
    # PKCS7填充
    pad_len = 16 - (len(token) % 16)
    padded_token = token.encode() + bytes([pad_len] * pad_len)
    
    # AES-CBC加密
    cipher = AES.new(key, AES.MODE_CBC, iv)
    encrypted = cipher.encrypt(padded_token)
    
    return encrypted

def main():
    if len(sys.argv) != 2:
        print(f"用法: {sys.argv[0]} <token>")
        print("示例: CN-5bb2de31fba875c01427f99d696fe47f-206371446")
        sys.exit(1)
    
    token = sys.argv[1]
    
    # 验证token格式
    if not token.startswith("CN-") or token.count("-") != 2:
        print("错误: Token格式不正确，应为 CN-xxxxx-xxxxxx 格式")
        sys.exit(1)
    
    try:
        encrypted = encrypt_token(token)
        
        # 写入文件
        with open("token", "wb") as f:
            f.write(encrypted)
        
        print(f"Token加密成功！")
        print(f"原始token: {token}")
        print(f"加密后大小: {len(encrypted)} 字节")
        print(f"已写入: {os.path.abspath('token')}")
        
        # 显示hex格式
        print("\nHex输出:")
        hex_str = encrypted.hex()
        for i in range(0, len(hex_str), 32):
            print(hex_str[i:i+32])
            
    except Exception as e:
        print(f"加密失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()