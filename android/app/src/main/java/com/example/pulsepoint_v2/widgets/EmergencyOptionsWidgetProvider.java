package com.example.pulsepoint_v2.widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.util.Log;
import android.widget.RemoteViews;

import com.example.pulsepoint_v2.R;

import es.antonborri.home_widget.HomeWidgetBackgroundIntent;
import es.antonborri.home_widget.HomeWidgetLaunchIntent;
import es.antonborri.home_widget.HomeWidgetPlugin;

/**
 * Emergency Options widget provider that displays quick access to emergency functions
 */
public class EmergencyOptionsWidgetProvider extends AppWidgetProvider {
    private static final String TAG = "EmergencyOptionsWidget";
    private static final String DEFAULT_EMERGENCY_NUMBER = "108"; // Default emergency number in India

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        Log.d(TAG, "onUpdate called for appWidgetIds: " + java.util.Arrays.toString(appWidgetIds));
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    private void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        // Get the stored emergency number or use the default
        String emergencyNumber = getEmergencyNumberFromPreferences(context);
        Log.d(TAG, "Updating widget with emergency number: " + emergencyNumber);

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
        
        // Use HomeWidgetBackgroundIntent for hospitals
        PendingIntent hospitalBackgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context, Uri.parse("pulsepoint://emergency/hospitals"));
        views.setOnClickPendingIntent(R.id.container_find_hospitals, hospitalBackgroundIntent);
        
        // Use HomeWidgetBackgroundIntent for blood request
        PendingIntent bloodRequestBackgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context, Uri.parse("pulsepoint://blood_request"));
        views.setOnClickPendingIntent(R.id.container_blood_request, bloodRequestBackgroundIntent);
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
    
    /**
     * Gets emergency number from preferences
     */
    private String getEmergencyNumberFromPreferences(Context context) {
        // Try home_widget's preferences first
        SharedPreferences homeWidgetPrefs = HomeWidgetPlugin.getSharedPreferences(context);
        String number = homeWidgetPrefs.getString("emergency_number", null);
        
        if (number != null && !number.isEmpty()) {
            Log.d(TAG, "Found emergency number in HomeWidgetPlugin preferences: " + number);
            return number;
        }
        
        // Try other possible preference files
        try {
            // Try widget-specific preferences
            SharedPreferences widgetPrefs = context.getSharedPreferences(
                    "com.example.pulsepoint_v2.widgets.EmergencyOptionsWidgetProvider", 
                    Context.MODE_PRIVATE);
            number = widgetPrefs.getString("emergency_number", null);
            
            if (number != null && !number.isEmpty()) {
                Log.d(TAG, "Found emergency number in widget-specific preferences: " + number);
                return number;
            }
            
            // Try Flutter shared preferences
            SharedPreferences flutterPrefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", 
                    Context.MODE_PRIVATE);
            number = flutterPrefs.getString("flutter.emergency_number", null);
            
            if (number != null && !number.isEmpty()) {
                Log.d(TAG, "Found emergency number in Flutter shared preferences: " + number);
                return number;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error reading from preferences", e);
        }
        
        // Return default number if nothing found
        Log.d(TAG, "No emergency number found in any preferences, returning default");
        return DEFAULT_EMERGENCY_NUMBER;
    }
    
    public static void updateEmergencyNumber(Context context, String newEmergencyNumber) {
        // Save to HomeWidgetPlugin preferences
        SharedPreferences homeWidgetPrefs = HomeWidgetPlugin.getSharedPreferences(context);
        homeWidgetPrefs.edit().putString("emergency_number", newEmergencyNumber).apply();
        
        // Also save to widget-specific preferences for compatibility
        SharedPreferences widgetPrefs = context.getSharedPreferences(
                "com.example.pulsepoint_v2.widgets.EmergencyOptionsWidgetProvider", 
                Context.MODE_PRIVATE);
        widgetPrefs.edit().putString("emergency_number", newEmergencyNumber).apply();
        
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