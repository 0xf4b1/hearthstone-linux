#include <cryptopp/modes.h>
#include <cryptopp/osrng.h>
#include <cryptopp/pwdbased.h>
#include <cryptopp/rijndael.h>
#include <gtk/gtk.h>
#include <iostream>
#include <pwd.h>
#include <string>
#include <webkit2/webkit2.h>

#define KEY_LENGTH 0x30

using namespace CryptoPP;

typedef unsigned char byte;

void getEncryptionKey(unsigned char *key, int size) {
    unsigned char s_entropy[16] = {200, 118, 244, 174, 76, 149, 46,  254,
                                   242, 250, 15,  84,  25, 192, 156, 67};

    struct passwd *pwd = getpwuid(getuid());
    int length = strlen(pwd->pw_name);
    for (int i = 0; i < length; i++) {
        s_entropy[i] ^= pwd->pw_name[i];
    }

    unsigned char salt[] = {'s', 'o', 'm', 'e', 'S', 'a', 'l', 't'};
    byte unused = 0;
    PKCS5_PBKDF2_HMAC<SHA1> pbkdf;
    pbkdf.DeriveKey(key, size, unused, s_entropy, sizeof(s_entropy), salt, sizeof(salt), 1000,
                    0.0f);
}

void encrypt(char *token, byte *key, byte *iv, byte *cipher) {
    try {
        CBC_Mode<AES>::Encryption e;
        e.SetKeyWithIV(key, 16, iv);
        StringSource s(token, true,
                       new StreamTransformationFilter(e, new ArraySink(cipher, KEY_LENGTH),
                                                      StreamTransformationFilter::PKCS_PADDING));
    } catch (const Exception &e) {
        std::cerr << e.what() << std::endl;
        exit(1);
    }
}

void processToken(char *token) {
    unsigned char key[16] = {0};
    getEncryptionKey(key, sizeof(key));

    byte iv[16] = {0};
    byte cipher[KEY_LENGTH];
    encrypt(token, key, iv, cipher);

    FILE *file = fopen("token", "wb");
    fwrite(cipher, sizeof(cipher), 1, file);
}

static void checkUri(const char *uri) {
    const char *start = strchr(uri, '=');
    if (!start) {
        return;
    }
    start++;

    const char *end = strchr(start, '&');
    if (!end) {
        return;
    }

    int length = end - start;
    if (length >= 50) {
        return;
    }

    char token[50];
    memcpy(token, start, length);
    token[length] = '\0';

    if (token[2] == '-' && token[35] == '-') {
        std::cout << "Found Token: " << token << std::endl;
        processToken(token);
        std::cout << "Login successful" << std::endl;
        gtk_main_quit();
    }
}

static void web_view_load_changed(WebKitWebView *web_view, WebKitLoadEvent load_event,
                                  gpointer user_data) {
    switch (load_event) {
    case WEBKIT_LOAD_STARTED: {
        break;
    }
    case WEBKIT_LOAD_REDIRECTED: {
        break;
    }
    case WEBKIT_LOAD_COMMITTED: {
        break;
    }
    case WEBKIT_LOAD_FINISHED: {
        const char *uri = webkit_web_view_get_uri(web_view);
        checkUri(uri);
        break;
    }
    }
}

static void destroyWinCb(GtkWidget *widget, GtkWidget *window) { gtk_main_quit(); }

static gboolean closeWebCb(WebKitWebView *webView, GtkWidget *window) {
    gtk_widget_destroy(window);
    return TRUE;
}

int main(int argc, char *argv[]) {
    GtkWidget *win;
    WebKitWebView *web;
    gchar *url = "https://battle.net/login/?app=wtcg";
    gtk_init(&argc, &argv);

    win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(GTK_WINDOW(win), 480, 420);
    gtk_window_set_position(GTK_WINDOW(win), GTK_WIN_POS_CENTER);

    web = WEBKIT_WEB_VIEW(webkit_web_view_new());
    gtk_container_add(GTK_CONTAINER(win), GTK_WIDGET(web));

    g_signal_connect(win, "destroy", G_CALLBACK(destroyWinCb), NULL);
    g_signal_connect(web, "close", G_CALLBACK(closeWebCb), win);
    g_signal_connect(web, "load-changed", G_CALLBACK(web_view_load_changed), NULL);
    webkit_web_view_load_uri(web, url);

    gtk_widget_grab_focus(GTK_WIDGET(web));

    gtk_widget_show_all(win);

    gtk_main();

    return 0;
}
