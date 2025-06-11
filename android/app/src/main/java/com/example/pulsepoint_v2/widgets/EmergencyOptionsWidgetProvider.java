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

/**
 * Emergency Options widget provider that displays quick access to emergency functions
 */
public class EmergencyOptionsWidgetProvider extends AppWidgetProvider {
    private static final String TAG = "EmergencyOptionsWidget";
    private static final String DEFAULT_EMERGENCY_NUMBER = "108"; // Default emergency number in India
    private static final String ACTION_FIND_HOSPITALS = "com.example.pulsepoint_v2.widgets.ACTION_FIND_HOSPITALS";
    private static final String ACTION_BLOOD_REQUEST = "com.example.pulsepoint_v2.widgets.ACTION_BLOOD_REQUEST";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "onReceive: " + intent.getAction());
        super.onReceive(context, intent);
        
        // Handle widget button actions
        if (ACTION_FIND_HOSPITALS.equals(intent.getAction()) || ACTION_BLOOD_REQUEST.equals(intent.getAction())) {
            // Launch the app
            Intent launchAppIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
            if (launchAppIntent != null) {
                // Add action as extra so the app knows what to do when launched
                launchAppIntent.putExtra("widget_action", intent.getAction());
                launchAppIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(launchAppIntent);
            }
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
        
        // Create regular intent for hospitals (replacing HomeWidgetBackgroundIntent)
        Intent hospitalIntent = new Intent(context, EmergencyOptionsWidgetProvider.class);
        hospitalIntent.setAction(ACTION_FIND_HOSPITALS);
        PendingIntent hospitalPendingIntent = PendingIntent.getBroadcast(
                context, 1, hospitalIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.container_find_hospitals, hospitalPendingIntent);
        
        // Create regular intent for blood request (replacing HomeWidgetBackgroundIntent)
        Intent bloodRequestIntent = new Intent(context, EmergencyOptionsWidgetProvider.class);
        bloodRequestIntent.setAction(ACTION_BLOOD_REQUEST);
        PendingIntent bloodRequestPendingIntent = PendingIntent.getBroadcast(
                context, 2, bloodRequestIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.container_blood_request, bloodRequestPendingIntent);
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
    
    /**
     * Gets emergency number from preferences
     */
    private String getEmergencyNumberFromPreferences(Context context) {
        // Try custom preferences repository (replacing HomeWidgetPlugin)
        SharedPreferences homeWidgetPrefs = context.getSharedPreferences("home_widget_preferences", Context.MODE_PRIVATE);
        String number = homeWidgetPrefs.getString("emergency_number", null);
        
        if (number != null && !number.isEmpty()) {
            Log.d(TAG, "Found emergency number in home_widget_preferences: " + number);
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
        // Save to custom preferences (replacing HomeWidgetPlugin)
        SharedPreferences homeWidgetPrefs = context.getSharedPreferences("home_widget_preferences", Context.MODE_PRIVATE);
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