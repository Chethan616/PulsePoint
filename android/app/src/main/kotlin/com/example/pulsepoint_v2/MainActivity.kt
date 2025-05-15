package com.example.pulsepoint_v2

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.example.pulsepoint_v2.widgets.HealthTipWidgetProvider
import com.example.pulsepoint_v2.widgets.EmergencyOptionsWidgetProvider

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up the HomeWidgetPlugin
        HomeWidgetPlugin.setup(
            context = context,
            widgetProviders = listOf(
                HealthTipWidgetProvider::class.java,
                EmergencyOptionsWidgetProvider::class.java
            )
        )
        
        // Add your old channel setup if needed
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "home_widget")
            .setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
    }
    
    // This is a legacy method to support any older implementations
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "Method call: " + call.method)
        
        // Forward to home_widget plugin
        when (call.method) {
            "saveWidgetData" -> {
                val id = call.argument<String>("id")
                val data = call.argument<Any>("data")
                
                if (id != null && data != null) {
                    // Save to preferences accessible by home_widget plugin
                    val prefs = HomeWidgetPlugin.widgetPreferences(context)
                    val editor = prefs.edit()
                    editor.putString(id, data.toString())
                    editor.apply()
                    
                    // Also save to our widget-specific preferences for compatibility
                    if (id == "tip") {
                        val widgetPrefs = context.getSharedPreferences(
                            "com.example.pulsepoint_v2.widgets.HealthTipWidgetProvider", 
                            Context.MODE_PRIVATE
                        )
                        widgetPrefs.edit().putString("current_health_tip", data.toString()).apply()
                    } else if (id == "emergency_number") {
                        val widgetPrefs = context.getSharedPreferences(
                            "com.example.pulsepoint_v2.widgets.EmergencyOptionsWidgetProvider", 
                            Context.MODE_PRIVATE
                        )
                        widgetPrefs.edit().putString("emergency_number", data.toString()).apply()
                    }
                    
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "id and data must not be null", null)
                }
            }
            "updateWidget" -> {
                val androidName = call.argument<String>("android")
                
                if (androidName != null) {
                    when (androidName) {
                        "HealthTipWidgetProvider" -> {
                            val intent = Intent(context, HealthTipWidgetProvider::class.java)
                            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                            val ids = AppWidgetManager.getInstance(context)
                                .getAppWidgetIds(ComponentName(context, HealthTipWidgetProvider::class.java))
                            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                            context.sendBroadcast(intent)
                            result.success(true)
                        }
                        "EmergencyOptionsWidgetProvider" -> {
                            val intent = Intent(context, EmergencyOptionsWidgetProvider::class.java)
                            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                            val ids = AppWidgetManager.getInstance(context)
                                .getAppWidgetIds(ComponentName(context, EmergencyOptionsWidgetProvider::class.java))
                            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                            context.sendBroadcast(intent)
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Widget name must not be null", null)
                }
            }
            "getWidgetData" -> {
                val id = call.argument<String>("id")
                
                if (id != null) {
                    val prefs = HomeWidgetPlugin.widgetPreferences(context)
                    val value = prefs.getString(id, null)
                    result.success(value)
                } else {
                    result.error("INVALID_ARGUMENTS", "id must not be null", null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
