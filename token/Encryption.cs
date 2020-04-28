using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public static class Encryption {
    public static byte[] EncryptStringToBytes(string plainText, byte[] key, byte[] iv) {
        Encryption.CheckArgumentsAndThrow<char>(plainText.ToCharArray(), key, iv);
        byte[] result;
        using(RijndaelManaged rijndaelManaged = new RijndaelManaged()) {
            rijndaelManaged.Key = key;
            rijndaelManaged.IV = iv;
            rijndaelManaged.Mode = CipherMode.CBC;
            rijndaelManaged.Padding = PaddingMode.PKCS7;
            ICryptoTransform transform = rijndaelManaged.CreateEncryptor(rijndaelManaged.Key, rijndaelManaged.IV);
            using(MemoryStream memoryStream = new MemoryStream()) {
                using(CryptoStream cryptoStream = new CryptoStream(memoryStream, transform, CryptoStreamMode.Write)) {
                    using(StreamWriter streamWriter = new StreamWriter(cryptoStream)) { streamWriter.Write(plainText); }
                    result = memoryStream.ToArray();
                }
            }
        }
        return result;
    }

    public static string DecryptStringFromBytes(byte[] cipherText, byte[] key, byte[] iv) {
        Encryption.CheckArgumentsAndThrow<byte>(cipherText, key, iv);
        string result = null;
        using(RijndaelManaged rijndaelManaged = new RijndaelManaged()) {
            rijndaelManaged.Key = key;
            rijndaelManaged.IV = iv;
            rijndaelManaged.Mode = CipherMode.CBC;
            rijndaelManaged.Padding = PaddingMode.PKCS7;
            ICryptoTransform transform = rijndaelManaged.CreateDecryptor(rijndaelManaged.Key, rijndaelManaged.IV);
            using(MemoryStream memoryStream = new MemoryStream(cipherText)) {
                using(CryptoStream cryptoStream = new CryptoStream(memoryStream, transform, CryptoStreamMode.Read)) {
                    using(StreamReader streamReader = new StreamReader(cryptoStream, Encoding.UTF8)) {
                        result = streamReader.ReadToEnd();
                    }
                }
            }
        }
        return result;
    }

    public static byte[] EncryptBytesFromBytes(byte[] inBytes, byte[] key, byte[] iv) {
        string plainText = Convert.ToBase64String(inBytes);
        return Encryption.EncryptStringToBytes(plainText, key, iv);
    }

    public static byte[] DecryptBytesFromBytes(byte[] cipherBytes, byte[] key, byte[] iv) {
        string s = Encryption.DecryptStringFromBytes(cipherBytes, key, iv);
        return Convert.FromBase64String(s);
    }

    private static void CheckArgumentsAndThrow<T>(T[] inData, byte[] key, byte[] iv) {
        if (inData == null || inData.Length <= 0) {
            throw new ArgumentNullException("inData");
        }
        if (key == null || key.Length <= 0) {
            throw new ArgumentNullException("key");
        }
        if (iv == null || iv.Length <= 0) {
            throw new ArgumentNullException("iv");
        }
    }
}