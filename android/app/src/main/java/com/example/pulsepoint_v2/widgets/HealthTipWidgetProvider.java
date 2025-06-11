package com.example.pulsepoint_v2.widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.util.Log;
import android.widget.RemoteViews;

import com.example.pulsepoint_v2.R;

/**
 * Health Tip widget provider that displays a random health tip and allows refreshing
 */
public class HealthTipWidgetProvider extends AppWidgetProvider {
    private static final String TAG = "HealthTipWidgetProvider";
    private static final String ACTION_REFRESH = "com.example.pulsepoint_v2.widgets.ACTION_REFRESH_TIP";
    private static final String DEFAULT_TIP = "Stay hydrated! Drink at least 8 glasses of water daily for better blood flow.";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, " " + intent.getAction() + (intent.getExtras() != null ? ", " + intent.getExtras() : ""));
        super.onReceive(context, intent);
        if (ACTION_REFRESH.equals(intent.getAction())) {
            AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
            int[] appWidgetIds = appWidgetManager.getAppWidgetIds(intent.getComponent());
            onUpdate(context, appWidgetManager, appWidgetIds);
        }
    }

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        Log.d(TAG, "onUpdate called for appWidgetIds: " + java.util.Arrays.toString(appWidgetIds));
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    private void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        // Get the stored health tip
        String healthTip = getHealthTipFromPreferences(context);
        Log.d(TAG, "Updating widget with tip: " + healthTip);

        // Create an intent for refreshing the tip
        Intent refreshIntent = new Intent(context, HealthTipWidgetProvider.class);
        refreshIntent.setAction(ACTION_REFRESH);
        PendingIntent refreshPendingIntent = PendingIntent.getBroadcast(
                context, 0, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        // Create a regular intent to refresh the tip (replacing HomeWidgetBackgroundIntent)
        Intent backgroundRefreshIntent = new Intent(context, HealthTipWidgetProvider.class);
        backgroundRefreshIntent.setAction(ACTION_REFRESH);
        PendingIntent backgroundIntent = PendingIntent.getBroadcast(
                context, 1, backgroundRefreshIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        // Create an intent to launch the app when widget is tapped
        Intent launchAppIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        PendingIntent launchIntent = PendingIntent.getActivity(
                context, 0, launchAppIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        // Set up the RemoteViews
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.health_tip_widget);
        views.setTextViewText(R.id.text_health_tip, healthTip);
        
        // Set the refresh button to use the background intent
        views.setOnClickPendingIntent(R.id.btn_refresh, backgroundIntent);
        
        // Set the entire widget to launch the app
        views.setOnClickPendingIntent(views.getLayoutId(), launchIntent);

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
    
    /**
     * Reads health tip from SharedPreferences
     */
    private String getHealthTipFromPreferences(Context context) {
        // Try custom preferences repository (replacing HomeWidgetPlugin)
        SharedPreferences homeWidgetPrefs = context.getSharedPreferences("home_widget_preferences", Context.MODE_PRIVATE);
        String tip = homeWidgetPrefs.getString("tip", null);
        
        if (tip != null && !tip.isEmpty()) {
            Log.d(TAG, "Found tip in home_widget_preferences: " + tip);
            return tip;
        }
        
        // Try other possible preference files
        try {
            // Try widget-specific preferences
            SharedPreferences widgetPrefs = context.getSharedPreferences(
                    "com.example.pulsepoint_v2.widgets.HealthTipWidgetProvider", 
                    Context.MODE_PRIVATE);
            tip = widgetPrefs.getString("current_health_tip", null);
            
            if (tip != null && !tip.isEmpty()) {
                Log.d(TAG, "Found tip in widget-specific preferences: " + tip);
                return tip;
            }
            
            // Try Flutter shared preferences
            SharedPreferences flutterPrefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", 
                    Context.MODE_PRIVATE);
            tip = flutterPrefs.getString("flutter.current_health_tip", null);
            
            if (tip != null && !tip.isEmpty()) {
                Log.d(TAG, "Found tip in Flutter shared preferences: " + tip);
                return tip;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error reading from preferences", e);
        }
        
        // Return default tip if nothing found
        Log.d(TAG, "No tip found in any preferences, returning default");
        return DEFAULT_TIP;
    }
} 