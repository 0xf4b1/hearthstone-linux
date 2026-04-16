#include <cstdlib>
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

void getEncryptionKey(unsigned char *key, int size)
{
    unsigned char s_entropy[16] = {200, 118, 244, 174, 76, 149, 46, 254,
                                   242, 250, 15, 84, 25, 192, 156, 67};

    struct passwd *pwd = getpwuid(getuid());
    int length = strlen(pwd->pw_name);
    for (int i = 0; i < length; i++)
    {
        s_entropy[i] ^= pwd->pw_name[i];
    }

    unsigned char salt[] = {'s', 'o', 'm', 'e', 'S', 'a', 'l', 't'};
    byte unused = 0;
    PKCS5_PBKDF2_HMAC<SHA1> pbkdf;
    pbkdf.DeriveKey(key, size, unused, s_entropy, sizeof(s_entropy), salt, sizeof(salt), 1000,
                    0.0f);
}

void encrypt(char *token, byte *key, byte *iv, byte *cipher)
{
    try
    {
        CBC_Mode<AES>::Encryption e;
        e.SetKeyWithIV(key, 16, iv);
        StringSource s(token, true,
                       new StreamTransformationFilter(e, new ArraySink(cipher, KEY_LENGTH),
                                                      StreamTransformationFilter::PKCS_PADDING));
    }
    catch(const Exception &e)
    {
        std::cerr << e.what() << std::endl;
        exit(1);
    }
}

void processToken(char *token)
{
    unsigned char key[16] = {0};
    getEncryptionKey(key, sizeof(key));

    byte iv[16] = {0};
    byte cipher[KEY_LENGTH];
    encrypt(token, key, iv, cipher);

    FILE *file = fopen("token", "wb");
    fwrite(cipher, sizeof(cipher), 1, file);
    fclose(file);
}

static void checkUri(const char *uri)
{
    std::cout << "Checking URI: " << uri << std::endl;

    // 查找ST参数（新格式 CN-xxxxx-xxxxxx）
    const char *st_pos = strstr(uri, "ST=");
    if (st_pos)
    {
        st_pos += 3; // 跳过 "ST="
        const char *end = strchr(st_pos, '&');
        if (!end)
            end = uri + strlen(uri);

        int length = end - st_pos;
        if (length > 0 && length < 200)
        {
            char token[200];
            memcpy(token, st_pos, length);
            token[length] = '\0';

            if (strstr(token, "CN-"))
            {
                std::cout << "Found Token (ST): " << token << std::endl;
                processToken(token);
                std::cout << "Login successful" << std::endl;
                gtk_main_quit();
                return;
            }
        }
    }

    // 检查老格式token
    const char *start = strchr(uri, '=');
    if (!start)
    {
        return;
    }
    start++;

    const char *end = strchr(start, '&');
    if (!end)
    {
        return;
    }

    int length = end - start;
    if (length >= 50)
    {
        return;
    }

    char token[50];
    memcpy(token, start, length);
    token[length] = '\0';

    if (token[2] == '-' && token[35] == '-')
    {
        std::cout << "Found Token: " << token << std::endl;
        processToken(token);
        std::cout << "Login successful" << std::endl;
        gtk_main_quit();
    }
}

static void web_view_load_changed(WebKitWebView *web_view, WebKitLoadEvent load_event,
                                  gpointer user_data)
{
    switch (load_event)
    {
    case WEBKIT_LOAD_STARTED:
    {
        std::cout << "Page load started" << std::endl;
        break;
    }
    case WEBKIT_LOAD_REDIRECTED:
    {
        const char *uri = webkit_web_view_get_uri(web_view);
        std::cout << "Page redirected to: " << uri << std::endl;
        break;
    }
    case WEBKIT_LOAD_COMMITTED:
    {
        const char *uri = webkit_web_view_get_uri(web_view);
        std::cout << "Page load committed: " << uri << std::endl;
        break;
    }
    case WEBKIT_LOAD_FINISHED:
    {
        const char *uri = webkit_web_view_get_uri(web_view);
        std::cout << "Page load finished: " << uri << std::endl;
        checkUri(uri);
        break;
    }
    }
}

static void destroyWinCb(GtkWidget *widget, GtkWidget *window) { gtk_main_quit(); }

static gboolean closeWebCb(WebKitWebView *webView, GtkWidget *window)
{
    gtk_widget_destroy(window);
    return TRUE;
}

static gboolean navigation_decision(WebKitWebView *web_view, WebKitPolicyDecision *decision, gpointer user_data)
{
    if (!WEBKIT_IS_NAVIGATION_POLICY_DECISION(decision))
    {
        webkit_policy_decision_use(decision);
        return TRUE;
    }

    WebKitNavigationAction *action = webkit_navigation_policy_decision_get_navigation_action(WEBKIT_NAVIGATION_POLICY_DECISION(decision));
    WebKitURIRequest *request = webkit_navigation_action_get_request(action);
    const char *uri = webkit_uri_request_get_uri(request);

    std::cout << "Navigation decision for URI: " << uri << std::endl;

    // 检查重定向URL中的token（localhost:0这样的回调URL）
    if (g_str_has_prefix(uri, "http://localhost"))
    {
        std::cout << "Redirect URI detected, extracting token..." << std::endl;
        checkUri(uri);
        webkit_policy_decision_ignore(decision);
        return TRUE;
    }

    // 允许所有导航
    webkit_policy_decision_use(decision);
    return TRUE;
}

int main(int argc, char *argv[])
{
    GtkWidget *win;
    WebKitWebView *web;
    gchar *url = const_cast<gchar *>("https://account.battlenet.com.cn/login/?app=wtcg");
    gtk_init(&argc, &argv);

    win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(GTK_WINDOW(win), 1024, 768);
    gtk_window_set_position(GTK_WINDOW(win), GTK_WIN_POS_CENTER);
    gtk_window_set_title(GTK_WINDOW(win), "Battle.net Login");

    web = WEBKIT_WEB_VIEW(webkit_web_view_new());
    gtk_container_add(GTK_CONTAINER(win), GTK_WIDGET(web));

    // 先尝试在系统默认浏览器中打开登录页面
    std::cout << "Opening login page in default browser: " << url << std::endl;
    std::string browser_cmd = "xdg-open '" + std::string(url) + "'";
    system(browser_cmd.c_str());

    g_signal_connect(win, "destroy", G_CALLBACK(destroyWinCb), NULL);
    g_signal_connect(web, "close", G_CALLBACK(closeWebCb), win);
    g_signal_connect(web, "load-changed", G_CALLBACK(web_view_load_changed), NULL);
    g_signal_connect(web, "decide-policy", G_CALLBACK(navigation_decision), NULL);

    std::cout << "Loading Battle.net login page in embedded WebKit as fallback: " << url << std::endl;
    webkit_web_view_load_uri(web, url);

    GdkRGBA color = {0.082, 0.09, 0.118, 1.0};
    webkit_web_view_set_background_color(web, &color);

    gtk_widget_grab_focus(GTK_WIDGET(web));
    gtk_widget_show_all(win);

    std::cout << "Please complete authentication in the window." << std::endl;
    std::cout << "Token will be extracted automatically upon successful login." << std::endl;

    gtk_main();

    return 0;
}
