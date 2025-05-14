package com.example.pulsepoint_v2.widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.widget.RemoteViews;

import com.example.pulsepoint_v2.R;

/**
 * Health Tip widget provider that displays a random health tip and allows refreshing
 */
public class HealthTipWidgetProvider extends AppWidgetProvider {

    private static final String PREFS_NAME = "com.example.pulsepoint_v2.widgets.HealthTipWidgetProvider";
    private static final String PREF_TIP_KEY = "current_health_tip";
    private static final String ACTION_REFRESH = "com.example.pulsepoint_v2.widgets.ACTION_REFRESH_TIP";

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);
        if (ACTION_REFRESH.equals(intent.getAction())) {
            AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
            int[] appWidgetIds = appWidgetManager.getAppWidgetIds(intent.getComponent());
            onUpdate(context, appWidgetManager, appWidgetIds);
        }
    }

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    private void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        // Get the stored health tip or use a default one
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        String healthTip = prefs.getString(PREF_TIP_KEY, "Stay hydrated! Drink at least 8 glasses of water daily for better blood flow.");

        // Create an intent for refreshing the tip
        Intent refreshIntent = new Intent(context, HealthTipWidgetProvider.class);
        refreshIntent.setAction(ACTION_REFRESH);
        PendingIntent refreshPendingIntent = PendingIntent.getBroadcast(
                context, 0, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        // Create an intent to launch the app
        Intent openAppIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (openAppIntent != null) {
            openAppIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        }
        PendingIntent openAppPendingIntent = PendingIntent.getActivity(
                context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        // Create an intent for widget click to refresh via Flutter
        Intent flutterRefreshIntent = new Intent(Intent.ACTION_VIEW);
        flutterRefreshIntent.setData(Uri.parse("pulsepoint://refreshtip"));
        flutterRefreshIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent flutterRefreshPendingIntent = PendingIntent.getActivity(
                context, 0, flutterRefreshIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        // Set up the RemoteViews
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.health_tip_widget);
        views.setTextViewText(R.id.text_health_tip, healthTip);
        views.setOnClickPendingIntent(R.id.btn_refresh, refreshPendingIntent);
        
        // Make the entire widget clickable to open app
        views.setOnClickPendingIntent(views.getLayoutId(), flutterRefreshPendingIntent);

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
} 