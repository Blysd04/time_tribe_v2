package com.example.time_tribe_v2

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Màn hình chờ (splash) của Android được hệ thống vẽ TRƯỚC khi Flutter chạy, nên nó chỉ biết
 * chế độ sáng/tối của hệ thống chứ không biết lựa chọn trong app.
 *
 * Từ Android 12 có UiModeManager.setApplicationNightMode: báo cho hệ thống biết app muốn
 * sáng hay tối, hệ thống ghi nhớ và dùng luôn cho splash ở những lần mở sau.
 * Flutter gọi kênh "timetribe/theme" mỗi khi người dùng đổi giao diện.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "timetribe/theme"
        private const val NATIVE_PREFS = "timetribe_native"
        private const val KEY_APPLIED = "applied_night_mode"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Phòng khi bản cũ của app chưa kịp báo xuống: đọc lựa chọn Flutter đã lưu
        applyNightMode(readSavedThemeMode())
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setThemeMode" -> {
                        applyNightMode(call.arguments as? String)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Giá trị ThemeProvider lưu bằng shared_preferences: "light", "dark" hoặc "system". */
    private fun readSavedThemeMode(): String? = try {
        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.settings.theme_mode", null)
    } catch (e: Exception) {
        null
    }

    private fun applyNightMode(mode: String?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val target = when (mode) {
            "light" -> UiModeManager.MODE_NIGHT_NO
            "dark" -> UiModeManager.MODE_NIGHT_YES
            else -> UiModeManager.MODE_NIGHT_AUTO // theo hệ thống
        }
        val prefs = getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        if (prefs.getInt(KEY_APPLIED, -1) == target) return
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager ?: return
        try {
            uiModeManager.setApplicationNightMode(target)
            prefs.edit().putInt(KEY_APPLIED, target).apply()
        } catch (e: Exception) {
            // Một số ROM chặn API này, splash vẫn theo hệ thống như cũ
        }
    }
}
