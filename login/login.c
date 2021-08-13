#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#include <string>

static void destroyWinCb(GtkWidget* widget, GtkWidget* window)
{
    gtk_main_quit();
}

static gboolean closeWebCb(WebKitWebView* webView, GtkWidget* window)
{
    gtk_widget_destroy(window);
    return TRUE;
}


static void checkUri (const char* uri)
{
	char token[70] = "";
	int j = 0;
	int i = 23;
	for( i ; i < strlen(uri); i++ )
	{
		if (uri[i] == '&'){
			break;
		}
			token[j] = uri[i];
			j++;
	}
	token[j] = '\0';
	printf("%s\n",token);
if (token[2] == '-' && token[35] == '-') 
//printf("this not token!");	
{
	char* cmd = strcpy("mono token.exe ",token);
	system(cmd);
	gtk_main_quit();
}
}

static void web_view_load_changed (WebKitWebView  *web_view,
                                   WebKitLoadEvent load_event,
                                   gpointer        user_data)
{
    switch (load_event) {
    case WEBKIT_LOAD_STARTED:
	    {
		    /* New load, we have now a provisional URI 
	    	    const char* provisional_uri = webkit_web_view_get_uri (web_view);
         Here we could start a spinner or update the
         * location bar with the provisional URI */
	    	    break;
	    }
    case WEBKIT_LOAD_REDIRECTED:
	    {
	//	    const char* redirected_uri = webkit_web_view_get_uri (web_view);
	//	    printf("%s\n",redirected_uri);
	    	    break;
	    }
    case WEBKIT_LOAD_COMMITTED:
        /* The load is being performed. Current URI is
         * the final one and it won't change unless a new
         * load is requested or a navigation within the
         * same page is performed */
	    {
	//	    const char* uri = webkit_web_view_get_uri (web_view);
	//	    printf("%s\n",uri);
	    	    break;
	    }
    case WEBKIT_LOAD_FINISHED:
        /* Load finished, we can now stop the spinner */
	    {
		    const char* uri = webkit_web_view_get_uri (web_view);
        //            printf("%s\n",uri);
		    checkUri(uri);
	    	    break;
	    }
    }
}

/*static void checkUri (const char* uri)
{
	char token = uri[5-10];
	printf(token);

}
*/
int main(int argc, char* argv[])
{
    GtkWidget *win;
    WebKitWebView *web;
    gchar * url = "https://eu.battle.net/login/ru-ru/?app=wtcg";
    gtk_init(&argc, &argv);

    win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(GTK_WINDOW(win), 480, 420);
    gtk_window_set_position (GTK_WINDOW (win), GTK_WIN_POS_CENTER);

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
