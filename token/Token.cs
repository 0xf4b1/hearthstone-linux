using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

class TestClass {
    static void Main(string[] args) {
        if (args.Length != 1) {
            Console.WriteLine("Usage: token.exe <token>");
            Environment.Exit(-1);
        }
        string token = args[0];
        if (token[2] != '-' || token[35] != '-') {
            Console.WriteLine("The token should look like this: XX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXX");
            Environment.Exit(-1);
        }
        byte[] encrypted = Encryption.EncryptStringToBytes(args[0], GetEncryptionKey(), GetEncryptionIV());
        File.WriteAllBytes("token", encrypted);
        Console.WriteLine("Created token");
    }

    private static readonly int KEY_ITERATIONS = 1000;

    private static byte[] GetEncryptionKey() {
        byte[] array = new byte[16];
        Buffer.BlockCopy(s_entropy, 0, array, 0, s_entropy.Length);
        string userName = Environment.UserName;
        int num = 0;
        while (num < userName.Length && (long) num < 16L) {
            byte[] expr_31_cp_0 = array;
            int expr_31_cp_1 = num;
            expr_31_cp_0[expr_31_cp_1] ^= (byte) userName[num];
            num++;
        }
        byte[] bytes = Encoding.ASCII.GetBytes("someSalt");
        Rfc2898DeriveBytes rfc2898DeriveBytes = new Rfc2898DeriveBytes(array, bytes, KEY_ITERATIONS);
        return rfc2898DeriveBytes.GetBytes(16);
    }

    private static byte[] GetEncryptionIV() {
        byte[] array = new byte[16];
        int num = 0;
        while ((long) num < 16L) {
            array[num] = 0;
            num++;
        }
        return array;
    }

    public static readonly byte[] s_entropy =
        new byte[]{200, 118, 244, 174, 76, 149, 46, 254, 242, 250, 15, 84, 25, 192, 156, 67};
}
