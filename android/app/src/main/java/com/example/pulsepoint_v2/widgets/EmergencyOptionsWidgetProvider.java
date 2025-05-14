package com.example.pulsepoint_v2.widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.widget.RemoteViews;

import com.example.pulsepoint_v2.R;

/**
 * Emergency Options widget provider that displays quick access to emergency functions
 */
public class EmergencyOptionsWidgetProvider extends AppWidgetProvider {

    private static final String PREFS_NAME = "com.example.pulsepoint_v2.widgets.EmergencyOptionsWidgetProvider";
    private static final String PREF_EMERGENCY_NUMBER_KEY = "emergency_number";
    private static final String DEFAULT_EMERGENCY_NUMBER = "108"; // Default emergency number in India

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    private void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        // Get the stored emergency number or use the default
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        String emergencyNumber = prefs.getString(PREF_EMERGENCY_NUMBER_KEY, DEFAULT_EMERGENCY_NUMBER);

        // Set up the RemoteViews
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.emergency_options_widget);
        
        // Update the emergency number text
        views.setTextViewText(R.id.text_emergency_number, "Call Emergency (" + emergencyNumber + ")");
        
        // Create emergency call intent
        Intent callIntent = new Intent(Intent.ACTION_DIAL);
        callIntent.setData(Uri.parse("tel:" + emergencyNumber));
        PendingIntent callPendingIntent = PendingIntent.getActivity(
                context, 0, callIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.container_call_emergency, callPendingIntent);
        
        // Create Flutter-specific intent for hospital finder
        Intent hospitalIntent = new Intent(Intent.ACTION_VIEW);
        hospitalIntent.setData(Uri.parse("pulsepoint://emergency/hospitals"));
        hospitalIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent hospitalPendingIntent = PendingIntent.getActivity(
                context, 1, hospitalIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.container_find_hospitals, hospitalPendingIntent);
        
        // Create Flutter-specific intent for blood request
        Intent bloodRequestIntent = new Intent(Intent.ACTION_VIEW);
        bloodRequestIntent.setData(Uri.parse("pulsepoint://blood_request"));
        bloodRequestIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent bloodRequestPendingIntent = PendingIntent.getActivity(
                context, 2, bloodRequestIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.container_blood_request, bloodRequestPendingIntent);
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
    
    public static void updateEmergencyNumber(Context context, String newEmergencyNumber) {
        // Save the new emergency number
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(PREF_EMERGENCY_NUMBER_KEY, newEmergencyNumber);
        editor.apply();
        
        // Update all widgets
        AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
        ComponentName thisWidget = new ComponentName(context, EmergencyOptionsWidgetProvider.class);
        int[] appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget);
        
        Intent updateIntent = new Intent(context, EmergencyOptionsWidgetProvider.class);
        updateIntent.setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
        updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds);
        context.sendBroadcast(updateIntent);
    }
} 